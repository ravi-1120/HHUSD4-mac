/*
* UpdateRequestsWhenInteractionChangedMVN
* Created By:    Roman Lerman
* Created Date:  3/4/2013
* Description:   This class updates the Person and Address associated with the requests whenever
*				 those fields are updates on the corresponding Interaction.
* Change Log: 
* 				KRB REL 9.0 CR 3/13/2017 - Article Search will now be based on either the Customer 
                Type or (new for REL 9.0) the referredBy Customer Type. Need to make sure that any 
                changes to the referredBy Customer Type at the Interaction Level are propagated to the
			    associated Interaction Case's Requests. 
*/
public without sharing class UpdateRequestsWhenInteractionChangedMVN implements TriggersMVN.HandlerInterface
{
    public void execute(map<Id, Case> newCaseMap, map<Id, Case> oldCaseMap) {
    	Map <Id, Case> interactionsBeingUpdated = new Map <Id, Case> ();

		for (Case newCase : newCaseMap.values()) {
			if (UtilitiesMVN.matchCaseRecordTypeIdToName(newCase.RecordTypeId, Service_Cloud_Settings_MVN__c.getInstance().Interaction_Record_Type_MVN__c)) {
				Case oldCase = oldCaseMap.get(newCase.Id);
                 System.debug('KRB: oldCase.Customer_Type_MVN__c = ' + oldCase.Customer_Type_MVN__c);
                 System.debug('KRB: newCase.Customer_Type_MVN__c = ' + newCase.Customer_Type_MVN__c);
                
				if (oldCase.AccountId != newCase.AccountId
					|| oldCase.ContactId != newCase.ContactId
					|| oldCase.Address_MVN__c != newCase.Address_MVN__c
					|| oldCase.case_Account_Email_MVN__c != newCase.case_Account_Email_MVN__c
					|| oldCase.case_Account_Fax_MVN__c != newCase.case_Account_Fax_MVN__c
					|| oldCase.case_Account_Phone_MVN__c != newCase.case_Account_Phone_MVN__c
					|| oldCase.Referred_By_MVN__c != newCase.Referred_By_MVN__c
					|| oldCase.Origin != newCase.Origin
					|| oldCase.MSD_CORE_Source__c != newCase.MSD_CORE_Source__c
					|| oldCase.MSD_CORE_Business__c != newCase.MSD_CORE_Business__c
					|| oldCase.MSD_CORE_Business_Name__c != newCase.MSD_CORE_Business_Name__c
					|| oldCase.Customer_Type_MVN__c != newCase.Customer_Type_MVN__c
                   
                   //KRB REL 9.0 3/10/2017 
                    || oldCase.MSD_CORE_Referred_By_Customer_Type__c != newCase.MSD_CORE_Referred_By_Customer_Type__c
                    
                   ) {
					interactionsBeingUpdated.put(newCase.Id, newCase);
				}
			}
		}
		Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
		Set<String> statuses = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.Closed_Status_MVN__c)); 
		for(String s : UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Submitted_Status__c)) {
			statuses.add(s); 
		}
		for(String s : UtilitiesMVN.splitCommaSeparatedString(settings.Cancelled_Status_MVN__c)) {
			statuses.add(s); 
		}

		if (interactionsBeingUpdated.size() > 0) {
			List <Case> requestsToUpdate = [Select Id, ParentId, AccountId, ContactId, Origin, 
												Referred_By_MVN__c, Address_MVN__c, case_Account_Email_MVN__c,
												case_Account_Fax_MVN__c, case_Account_Phone_MVN__c, 
												MSD_CORE_Source__c, MSD_CORE_Business__c, MSD_CORE_Business_Name__c, Customer_Type_MVN__c
                                                
                                                //KRB REL 9.0 3/10/2017
                                                ,MSD_CORE_Referred_By_Customer_Type__c
                                            
												from Case where ParentId in :interactionsBeingUpdated.keySet() AND Status NOT IN :statuses];

			for (Case request : requestsToUpdate) {
                
                system.debug('KRB: request being updated: ' + request.id + 'with customer Type: '+ request.Customer_Type_MVN__c);
                
				Case interaction = interactionsBeingUpdated.get(request.ParentId);

				request.AccountId = interaction.AccountId;
				request.ContactId = interaction.ContactId;
				request.Origin = interaction.Origin;
				request.MSD_CORE_Source__c = interaction.MSD_CORE_Source__c;
				request.Referred_By_MVN__c = interaction.Referred_By_MVN__c;
				request.Address_MVN__c = interaction.Address_MVN__c;
				request.MSD_CORE_Business__c = interaction.MSD_CORE_Business__c;
				request.MSD_CORE_Business_Name__c = interaction.MSD_CORE_Business_Name__c;
				request.Customer_Type_MVN__c = interaction.Customer_Type_MVN__c;
				request.case_Account_Email_MVN__c = interaction.case_Account_Email_MVN__c;
				request.case_Account_Fax_MVN__c = interaction.case_Account_Fax_MVN__c;
				request.case_Account_Phone_MVN__c = interaction.case_Account_Phone_MVN__c;
                
                //KRB REL 9.0 3/10/2017
                system.debug('KRB A');
                request.MSD_CORE_Referred_By_Customer_Type__c = interaction.MSD_CORE_Referred_By_Customer_Type__c;
                system.debug('KRB B');
                System.debug('KRB: New Request Customer Type: ' + request.Customer_Type_MVN__c );
                system.debug('KRB C');

			}

			update requestsToUpdate;
		}
    }

    public void handle() {
        execute((Map<Id, Case>) trigger.newMap, (Map<Id, Case>) trigger.oldMap);
    }
}