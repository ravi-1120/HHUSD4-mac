/*
* CloseChildCasesWhenInteractClosedMVN
* Created By:    Kai Chen
* Created Date:  10/9/2014
* Description:   This trigger handler cancels any child Requests and Fulfillments when the Interaction is cancelled
*/
public without sharing class CloseChildCasesWhenInteractClosedMVN implements TriggersMVN.HandlerInterface{
    public void execute(map<Id, Case> newCaseMap, map<Id, Case> oldCaseMap) {

        List<Id> casesClosed = new List<Id>();

        for (Case newCase : newCaseMap.values()) {
            if (UtilitiesMVN.matchCaseRecordTypeIdToName(newCase.RecordTypeId, Service_Cloud_Settings_MVN__c.getInstance().Interaction_Record_Type_MVN__c) ||
                UtilitiesMVN.matchCaseRecordTypeIdToName(newCase.RecordTypeId, Service_Cloud_Settings_MVN__c.getInstance().Interaction_Closed_Record_Type_MVN__c)) {
                Case oldCase = oldCaseMap.get(newCase.Id);

                if (newCase.Status == Service_Cloud_Settings_MVN__c.getInstance().Cancelled_Status_MVN__c && oldCase.Status != Service_Cloud_Settings_MVN__c.getInstance().Cancelled_Status_MVN__c) {
                    casesClosed.add(newCase.Id);
                }
            }
        }

        List<Case> casesToClose = [select Id, Status 
        					from Case 
        					where ParentId in :casesClosed];

        for(Case caseToClose : casesToClose){
            caseToClose.Status = Service_Cloud_Settings_MVN__c.getInstance().Cancelled_Status_MVN__c;
        }

        update casesToClose;

		List<Fulfillment_MVN__c> fulfillmentsToClose = [select Id, Status_MVN__c
														from Fulfillment_MVN__c
														where Case_MVN__c in :casesClosed];

		for(Fulfillment_MVN__c fulfillment : fulfillmentsToClose){
			fulfillment.Status_MVN__c = Service_Cloud_Settings_MVN__c.getInstance().Cancelled_Status_MVN__c;
		}        

		update fulfillmentsToClose;

    }

    public void handle() {
        execute((Map<Id, Case>) trigger.newMap, (Map<Id, Case>) trigger.oldMap);
    }
}