/*
* MSD_CORE_ManageVeevaCaseTrigger
* Created By:    Roman Lerman
* Created Date:  7/15/2015
* Description:   This class creates a Veeva Case when a Request is created in Service Cloud.
*                It subsequently updates the Veeva Case if the Request is updated and deletes
*                the Veeva Case if the Request is Cancelled.
*/
public without sharing class MSD_CORE_ManageVeevaCaseTrigger implements TriggersMVN.HandlerInterface {
    public void execute(Map<Id, Case> newCases, Map<Id, Case> oldCases){
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();

        List<Case> cases = [select Id, CaseNumber, RecordType.Name, MSD_CORE_Case_Notes__c, AccountId, Account.Class_of_Trade_MRK__c,
                                Referred_By_MVN__c, Referred_By_MVN__r.Class_of_Trade_MRK__c, 
                                MSD_Core_Business__c, MSD_CORE_Product_Name__c, 
                                Category_MVN__c, MSD_CORE_Country_Code__c, Origin,
                                MSD_CORE_Owner_Role__c, Status, Type, Owner.Name, RecordTypeId, MSD_CORE_Legal_Alert__c 
                            from Case where Id in :newCases.values()];

        List<MSD_CORE_Veeva_Case__c> veevaCaseList = new List<MSD_CORE_Veeva_Case__c>();
        List<Id> cancelledVeevaCaseIdList = new List<Id>();

        for(Case cs:cases){
            if(!UtilitiesMVN.matchCaseRecordTypeIdToName(cs.RecordTypeId, settings.Interaction_Record_Type_MVN__c)
                && !UtilitiesMVN.matchCaseRecordTypeIdToName(cs.RecordTypeId, settings.Interaction_Closed_Record_Type_MVN__c)){
                if(cs.Status != settings.Cancelled_Status_MVN__c && cs.MSD_CORE_Legal_Alert__c == FALSE){
                    MSD_CORE_Veeva_Case__c veevaCase = new MSD_CORE_Veeva_Case__c();
                    veevaCase.MSD_CORE_External_ID__c = cs.Id;
                    veevaCase.MSD_CORE_Case_Number__c = cs.CaseNumber;
                    
                    if(cs.Account.Class_of_Trade_MRK__c != settings.MSD_CORE_Consumer_Type__c){
                        veevaCase.MSD_CORE_Customer__c = cs.AccountId;
                    }
                    
                    if(cs.Referred_By_MVN__r.Class_of_Trade_MRK__c != settings.MSD_CORE_Consumer_Type__c){
                        veevaCase.MSD_CORE_Referred_By__c = cs.Referred_By_MVN__c;
                    }
                    
                    veevaCase.MSD_CORE_Business__c = cs.MSD_CORE_Business__c;
                    veevaCase.MSD_CORE_Product__c = cs.MSD_CORE_Product_Name__c;
                    veevaCase.MSD_CORE_Category__c = cs.Category_MVN__c;
                    veevaCase.MSD_CORE_Country_Code__c = cs.MSD_CORE_Country_Code__c;
                    veevaCase.MSD_CORE_Origin__c = cs.Origin;
                    veevaCase.MSD_CORE_Owner_Role__c = cs.MSD_CORE_Owner_Role__c;
                    veevaCase.MSD_CORE_Status__c = cs.Status;
                    veevaCase.MSD_CORE_Type__c = cs.Type;
                    veevaCase.MSD_CORE_Case_Owner__c = cs.Owner.Name;
                    veevaCase.MSD_CORE_Case_Notes__c = cs.MSD_CORE_Case_Notes__c;
                    veevaCase.MSD_CORE_Record_Type__c = cs.RecordType.Name;

                    veevaCaseList.add(veevaCase);
                }else{
                    cancelledVeevaCaseIdList.add(cs.Id);
                }
            }
        }

        if(veevaCaseList != null && veevaCaseList.size() > 0){
            upsert veevaCaseList MSD_CORE_External_ID__c;
        }

        if(cancelledVeevaCaseIdList != null && cancelledVeevaCaseIdList.size() > 0){
            List<MSD_CORE_Veeva_Case__c> cancelledVeevaCases = [select Id 
                                                                    from MSD_CORE_Veeva_Case__c 
                                                                    where MSD_CORE_External_ID__c in :cancelledVeevaCaseIdList];
            delete cancelledVeevaCases;
        }
    }

    public void handle() {
        execute((Map<Id, Case>) trigger.newMap, (Map<Id, Case>) trigger.oldMap);
    }
}