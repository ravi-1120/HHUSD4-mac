/*
* CloseMedInqryWhenInteractClosedMVN
* Created By:    Kai Chen
* Created Date:  7/28/2013
* Description:   This class closes the Medical Inquiry that an Interaction is associated with when the Interaction is closed
*
* *** NOTE: Currently not used for the Merck implementation. ***
*/
public without sharing class CloseMedInqryWhenInteractClosedMVN implements TriggersMVN.HandlerInterface{
    public void execute(map<Id, Case> newCaseMap, map<Id, Case> oldCaseMap) {

        List<Id> inquiriesToUpdate = new List<Id>();
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();

        for (Case newCase : newCaseMap.values()) {
            if (UtilitiesMVN.matchCaseRecordTypeIdToName(newCase.RecordTypeId, settings.Interaction_Record_Type_MVN__c) ||
                UtilitiesMVN.matchCaseRecordTypeIdToName(newCase.RecordTypeId, settings.Interaction_Closed_Record_Type_MVN__c)) {
                Case oldCase = oldCaseMap.get(newCase.Id);

                if (newCase.Status == settings.Closed_Status_MVN__c && oldCase.Status != settings.Closed_Status_MVN__c) {
                    inquiriesToUpdate.add(newCase.Medical_Inquiry_MVN__c);
                }
            }
        }

        List<Medical_Inquiry_vod__c> inquiries = [select Id, Status_vod__c from Medical_Inquiry_vod__c where Id in :inquiriesToUpdate];

        // Required to get around the locking Veeva Trigger VOD_BEFORE_MED_INQ_UPD
        for(Medical_Inquiry_vod__c inquiry : inquiries){
            inquiry.Lock_vod__c = false;
        }

        update inquiries;
        for(Medical_Inquiry_vod__c inquiry : inquiries){
            inquiry.Status_vod__c = settings.Closed_Status_MVN__c;
        }

        update inquiries;
    }

    public void handle() {
        execute((Map<Id, Case>) trigger.newMap, (Map<Id, Case>) trigger.oldMap);
    }
}