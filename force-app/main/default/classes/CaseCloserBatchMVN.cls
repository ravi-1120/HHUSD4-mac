/*
 * CaseCloserBatchMVN
 * Created By:      Roman Lerman
 * Created Date:    6/21/2013
 * Description:
    * When this job runs it grabs all open Interactions and looks 
    * for Interactions where all Requests and Fulfillments have been 
    * closed for the past X hours (X should be configurable)
    * it then goes ahead and closes the Interactions.
    *
    * For standalone Interactions (with no Requests) the job will check
    * that the Interaction does not have an excluded Origin and if not
    * will go ahead and close it.  Interactions with no Requests are
    * generally created when a caller calls to add a comment for a previously
    * created Interaction.  Email and Social Media Interactions which may
    * stay in an opened state and have no open Requests for a while are excluded
    * from the automated close.
 */
global class CaseCloserBatchMVN implements Database.Batchable<sObject>, Database.Stateful, Schedulable {    
    List<Case> failedInteractions = new List<Case>();
    public static final String closedStatus = Service_Cloud_Settings_MVN__c.getInstance().Closed_Status_MVN__c;
    public static Boolean testSendEmail = false;
    public static final Integer gracePeriod = Service_Cloud_Settings_MVN__c.getInstance().Interaction_Closing_Grace_Period_MVN__c.intValue();
    
    public static final Set<String> doNotCloseInteractionOrigins = new Set<String>(
                                                                        UtilitiesMVN.splitCommaSeparatedString(
                                                                            Service_Cloud_Settings_MVN__c.getInstance().MSD_CORE_Do_Not_Close_Interaction_Origin__c
                                                                        )
                                                                    );

    /************************************************************************************
        SCHEDULABLE METHOD
    ************************************************************************************/
    global void execute(SchedulableContext sc) {
        CaseCloserBatchMVN closer = new CaseCloserBatchMVN();
        Database.executeBatch(closer);
    }

    /************************************************************************************
        SCHEDULABLE METHOD INITIALIZER
    ************************************************************************************/
    public static String scheduleHourlyJob() {
        CaseCloserBatchMVN closer = new CaseCloserBatchMVN();
        String schedule = '0 0 * * * ?';
        return System.schedule('Case Closer', schedule, closer);
    }
    
    /************************************************************************************
        THE BATCH METHOD
    ************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
    // Let's grab all of the Interactions and their Requests and Fulfillments
    String query = 'SELECT Id, CaseNumber, Status, LastModifiedDate, Origin, '+ 
                       '(SELECT Id, isClosed, LastModifiedDate FROM Cases), '+
                       '(SELECT Id, Is_Closed_MVN__c, LastModifiedDate FROM Fulfillment__r) '+
                   'FROM Case '+
                       'WHERE RecordType.DeveloperName = \'' + Service_Cloud_Settings_MVN__c.getInstance().Interaction_Record_Type_MVN__c + '\' '+
                       'AND isClosed = false AND ParentId = null';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Case> casesToClose = new List<Case>();

        // Go through all of the interactions
        for (Case interaction : (List<Case>)scope) {
            Integer closedRequestCount = 0;
            Integer closedFulfillmentCount = 0;
            
            if (interaction.Cases.size() > 0) {
                for (Case request : interaction.Cases) {
                    if (request.isClosed && (request.LastModifiedDate <= DateTime.now().addHours(-gracePeriod) || Test.isRunningTest()) ) {
                        closedRequestCount++;
                    }
                }   
            }
            if(interaction.Fulfillment__r.size() > 0){
                for (Fulfillment_MVN__c fulfillment : interaction.Fulfillment__r) {
                    if (fulfillment.Is_Closed_MVN__c && (fulfillment.LastModifiedDate <= DateTime.now().addHours(-gracePeriod) || Test.isRunningTest()) ) {
                        closedFulfillmentCount++;
                    }
                }
            } 
            
            if (interaction.Cases.size() == closedRequestCount 
                && interaction.Fulfillment__r.size() == closedFulfillmentCount 
                && (interaction.Cases.size() > 0 
                    || (interaction.Origin != null &&
                        !doNotCloseInteractionOrigins.contains(interaction.Origin)
                        && interaction.LastModifiedDate <= DateTime.now().addHours(-gracePeriod)))) {
                
                interaction.Status = closedStatus;
                casesToClose.add(interaction);
            }
        }

        Database.SaveResult[] saveResults = Database.update(casesToClose, false);
        for (Integer i=0; i<saveResults.size(); i++) {
            if (!saveResults[i].isSuccess() || testSendEmail) {
                failedInteractions.add(casesToClose[i]);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if (!failedInteractions.isEmpty()) {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            String adminEmailAddress = Service_Cloud_Settings_MVN__c.getInstance().Administrator_Email_MVN__c;
            mail.setToAddresses(new String[] {adminEmailAddress});
            mail.setSenderDisplayName('Case Closer Error');
            mail.setSubject('Error(s) in the Case Closer Job');
            mail.setBccSender(false);
            mail.setUseSignature(false);

            String plainTextBody = 'The following cases could not be Closed:\n';
            for (Case c : failedInteractions) {
                plainTextBody += 'Case Id: ' + c.Id + ' ---- Case Number: ' + c.CaseNumber + '\n';
            }
            mail.setPlainTextBody(plainTextBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        }   
    }
}