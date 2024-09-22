/*
 * CaseAnonymizerBatchMVN
 * Created By:      Thomas Hajcak
 * Created Date:    6/7/2013
 * Description:     Removes personally identifiable consumer information from Cases/Fulfillments for countries
 *					where this type of information cannot be stored.
 *
 *  **** NOTE: Currently not used for the Merck implementation. ***
 */
global class CaseAnonymizerBatchMVN implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	/*
	 * Case Anonymizer
	 * When this class runs it find all Consumer Cases (determined by record
	 * type of the Account on the Case) that have Addresses in Countries
	 * that require anonymization (specified as a list of comma separated
	 * country codes in the Service Cloud Settings custom setting).
	 *
	 * If a case falls into this category the AccountId, ContactId, and
	 * Address are removed from the case. The case is also flagged as needing
	 * anonymization which removes all other consumer data from the case
	 * via a workflow.
	 */

	public static Boolean testSendEmail = false;

	List<Case> failedInteractions = new List<Case>();
	List<Fulfillment_MVN__c> failedFulfillments = new List<Fulfillment_MVN__c>();
	List<Id> failedAccounts = new List<Id>();
	List<Id> failedEmailMessages = new List<Id>();
	List<Id> failedTasks = new List<Id>();

	public List<String> anonymizeCountriesList = new List<String>();
	public static final String consumerRecordType = Service_Cloud_Settings_MVN__c.getInstance().Consumer_Record_Type_MVN__c;
	public static final Datetime excludeAfterDate;
    static
    {
        Service_Cloud_Settings_MVN__c scs = Service_Cloud_Settings_MVN__c.getInstance();
        if (scs.Temporary_Account_Hold_Period_Days_MVN__c != null)
        {
            Decimal tempAccountHoldPeriod = scs.Temporary_Account_Hold_Period_Days_MVN__c;
            excludeAfterDate = Datetime.now().addDays(tempAccountHoldPeriod.intValue() * -1);
        }
        else
        {
            excludeAfterDate = null;
        }
    }

    public final List<String> closedStatuses;

	/************************************************************************************
        SCHEDULABLE METHOD
    ************************************************************************************/
    global void execute(SchedulableContext sc) {
        CaseAnonymizerBatchMVN anonymizer = new CaseAnonymizerBatchMVN();
        Database.executeBatch(anonymizer);
    }

    /************************************************************************************
        SCHEDULABLE METHOD INITIALIZER
    ************************************************************************************/
    public static String scheduleHourlyJob() {
        CaseAnonymizerBatchMVN anonymizer = new CaseAnonymizerBatchMVN();
        String schedule = '0 0 * * * ?';
        return System.schedule('Case Anonymizer', schedule, anonymizer);
    }

	global CaseAnonymizerBatchMVN() {
		String countriesString = Service_Cloud_Settings_MVN__c.getInstance().Interaction_Anonymize_Countries_MVN__c;
		if (countriesString != null) {
			anonymizeCountriesList = countriesString.split(',', 0);
		}
		for(Integer x=0; x<anonymizeCountriesList.size(); x++){
			if(anonymizeCountriesList[x] != null){
				anonymizeCountriesList[x] = anonymizeCountriesList[x].trim();
			}
		}
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, (SELECT Id, AccountId, ContactId, Address_MVN__c, Anonymize_MVN__c, Status, IsClosed, ClosedDate FROM Cases) ' +
                        'FROM Account ' +
                        'WHERE RecordType.DeveloperName = :consumerRecordType ' +
                               'AND (MSD_CORE_Country_Code__c IN :anonymizeCountriesList OR Anonymize_MVN__c = True)';
        if (excludeAfterDate != null)
        {
            query += 'AND CreatedDate <= :excludeAfterDate';
        }

		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		UtilitiesMVN.isAnonymizing = true;

		System.debug('Anonymize: '+UtilitiesMVN.isAnonymizing);

        List<Id> accountIdsToDelete = new List<Id>();
        List<Case> casesToClean = new List<Case>();
        List<Fulfillment_MVN__c> fulfillmentsToAnonymize = new List<Fulfillment_MVN__c>();

        for(Account account : (List<Account>)scope){
            Boolean allClosed = true;
            List<Case> casesToAdd = new List<Case>();

            for(Case interaction : account.Cases){
                if(!interaction.isClosed || (excludeAfterDate != null && interaction.ClosedDate > excludeAfterDate)) {
                    allClosed = false;
                    break;
                }
                else
                    casesToAdd.add(interaction);
            }

            if(allClosed){
                accountIdsToDelete.add(account.Id);
                casesToClean.addAll(casesToAdd);
            }
        }

		// Clean Cases
		for (Case interaction : casesToClean) {
			interaction.AccountId = null;
			interaction.ContactId = null;
			interaction.Address_MVN__c = null;
			interaction.Anonymize_MVN__c = true;
		}

		// Anonymize Cases
		Database.SaveResult[] saveResults = Database.update(casesToClean, false);
		for (Integer i=0; i<saveResults.size(); i++) {
            if (!saveResults[i].isSuccess() || testSendEmail) {
                System.debug('This case here: ' + saveResults[i]); 
                System.debug('This case here: ' + casesToClean[i]);
                failedInteractions.add(casesToClean[i]);
            }
        }

        List<Fulfillment_MVN__c> fulfillments = [select Id, Name, Account_Name_MVN__c,Anonymize_MVN__c from Fulfillment_MVN__c where Case_MVN__c in :casesToClean];
        for (Fulfillment_MVN__c ful : fulfillments) {
        	ful.Account_Name_MVN__c = null;
        	ful.Anonymize_MVN__c = true;
        	fulfillmentsToAnonymize.add(ful);
        }

        // Anonymize Fulfillments
        Database.SaveResult[] fulfillmentResults = Database.update(fulfillmentsToAnonymize, false);
        for (Integer i=0; i<fulfillmentResults.size(); i++) {
            if (!fulfillmentResults[i].isSuccess() || testSendEmail) {
                failedFulfillments.add(fulfillmentsToAnonymize[i]);
            }
        }

        // Delete anonymous accounts
        Database.DeleteResult[] deleteResults = Database.delete(accountIdsToDelete, false);
        for (Integer i=0; i<deleteResults.size(); i++) {
            if (!deleteResults[i].isSuccess() || testSendEmail) {
                failedAccounts.add(accountIdsToDelete[i]);
            }
        }

        List<EmailMessage> emailMessagesToDelete = [select Id from EmailMessage where ParentId in :casesToClean];

        // Delete email messages
        Database.DeleteResult[] deleteEmailMessages = Database.delete(emailMessagesToDelete, false);
        for (Integer i=0; i<deleteEmailMessages.size(); i++) {
            if (!deleteEmailMessages[i].isSuccess() || testSendEmail) {
                failedEmailMessages.add(deleteEmailMessages[i].Id);
            }
        }

        List<Task> tasksToDelete = [select Id from Task where WhatId in :casesToClean];

        // Delete tasks
        Database.DeleteResult[] deleteTasks = Database.delete(tasksToDelete, false);
        for (Integer i=0; i<deleteTasks.size(); i++) {
            if (!deleteTasks[i].isSuccess() || testSendEmail) {
                failedTasks.add(deleteTasks[i].Id);
            }
        }
	}

	global void finish(Database.BatchableContext BC) {

		if (!failedInteractions.isEmpty() || !failedFulfillments.isEmpty() || !failedAccounts.isEmpty() ||
			!failedEmailMessages.isEmpty() || !failedTasks.isEmpty()) {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            String adminEmailAddress = Service_Cloud_Settings_MVN__c.getInstance().Administrator_Email_MVN__c;
            mail.setToAddresses(new String[] {adminEmailAddress});
            mail.setSenderDisplayName('Case Anonymizer Error');
            mail.setSubject('Error(s) in the Case Anonymizer Job');
            mail.setBccSender(false);
            mail.setUseSignature(false);

            String plainTextBody = '';

            if(failedInteractions.size() > 0){
            	plainTextBody += '\nThe following Cases could not be Anonymized:\n';
            	for (Case c : failedInteractions) {
                	plainTextBody += 'Case Id: ' + c.Id + ' ---- Case Number: ' + c.CaseNumber + '\n';
           		}
            }
            if(failedFulfillments.size() > 0){
            	plainTextBody += '\nThe following Fulfillments could not be Anonymized:\n';
            	for (Fulfillment_MVN__c fulfillment : failedFulfillments) {
                	plainTextBody += 'Fulfillment Id: ' + fulfillment.Id + ' ---- Fulfillment Name: ' + fulfillment.Name + '\n';
           		}
            }
            if(failedAccounts.size() > 0){
            	plainTextBody += '\nThe following Accounts could not be deleted:\n';
            	for (Account acct : [select Id, Name from Account where Id in :failedAccounts]) {
                	plainTextBody += 'Account Id: ' + acct.Id + ' ---- Account Name: ' + acct.Name + '\n';
           		}
            }
            if(failedEmailMessages.size() > 0){
            	plainTextBody += '\nThe following Email Messages could not be deleted:\n';
            	for (Id emailMessageId : failedEmailMessages) {
                	plainTextBody += 'Email Message Id: ' + emailMessageId + '\n';
           		}
            }
            if(failedTasks.size() > 0){
            	plainTextBody += '\nThe following Tasks could not be deleted:\n';
            	for (Id failedTaskId : failedTasks) {
                	plainTextBody += 'Task Id: ' + failedTaskId + '\n';
           		}
            }

            mail.setPlainTextBody(plainTextBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
	}

}