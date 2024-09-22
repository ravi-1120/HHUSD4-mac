/*
* MSD_CORE_CasePopulateLegalAEPQCTrigger
* Created By:    Samuel Rosen
* Created Date:  5/21/2015
* Description:   This class populates the AE Present, Legal Alert Present, and PQC Present fields
*                on the Interaction when Adverse Events, Cases with Legal Alerts, and Product Quality
*                Complaints are created for the Interaction.

* Change Log:
* Updated Date: 7/7/2021
* Updated By:   Vamshi Bashyakarla
* Description: Code Refactor to reduce the SOQL Queries
*/
public without sharing class MSD_CORE_CasePopulateLegalAEPQCTrigger implements TriggersMVN.HandlerInterface {
    //private Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
    public static boolean checkRecursiveFlag = true;
    public void handle() {
        if(checkRecursiveFlag)
        {
            checkRecursiveFlag = false;
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        Map<Id, Case> oldCaseMap; 
        Map<Id, Case> newCaseMap = (Map<Id, Case>) Trigger.newMap;

        if(Trigger.oldMap != null){
            oldCaseMap = (Map<Id, Case>) Trigger.oldMap;
        }

        Set<Id> caseIdSet = new Set<Id>();
        
        for(Id caseId:newCaseMap.keySet()) {
            if(Trigger.isInsert 
                || (oldCaseMap.get(caseId).Status != newCaseMap.get(caseId).Status) 
                || (oldCaseMap.get(caseId).RecordTypeId != newCaseMap.get(caseId).RecordTypeId) 
                || (oldCaseMap.get(caseId).MSD_CORE_Legal_Alert__c != newCaseMap.get(caseId).MSD_CORE_Legal_Alert__c)) {
                caseIdSet.add(newCaseMap.get(caseId).ParentId);
            }
        }

        Map<Id, Case> interactionMap = new Map<Id, Case>(); 

        if(!caseIdSet.isEmpty())
        {
        List<Case> interactions = [SELECT Id, MSD_CORE_PQC_Present__c, MSD_CORE_AE_Present__c, MSD_CORE_Legal_Alert_Present__c, 
                                            (SELECT Id, RecordType.DeveloperName, MSD_CORE_Legal_Alert__c, MSD_CORE_Event_Case_Type__c
                                                FROM Cases 
                                                WHERE Status != :settings.Cancelled_Status_MVN__c) 
                                            FROM Case WHERE Id IN :caseIdSet]; 

        for(Case interaction:interactions) {
            interaction.MSD_CORE_PQC_Present__c = false;
            interaction.MSD_CORE_AE_Present__c = false;
            interaction.MSD_CORE_Legal_Alert_Present__c = false;
            interaction.MSD_CORE_CR_Present__c = false;
            for(Case childInteraction : interaction.Cases){
                if(childInteraction.RecordType.DeveloperName == settings.Product_Complaint_Record_Type_MVN__c 
                    || childInteraction.RecordType.DeveloperName == settings.MSD_CORE_Product_Comp_Submitted_Type__c 
                    || childInteraction.RecordType.DeveloperName == settings.MSD_CORE_Prod_Complaint_Closed_Rec_Type__c
                    || childInteraction.MSD_CORE_Event_Case_Type__c == 'AE and PQC'){
                    interaction.MSD_CORE_PQC_Present__c = true;
                }
                if(childInteraction.RecordType.DeveloperName == settings.Adverse_Event_Record_Type_MVN__c 
                    || childInteraction.RecordType.DeveloperName == settings.MSD_CORE_Adverse_Event_Submitted_RT__c
                   || childInteraction.RecordType.DeveloperName == settings.MSD_CORE_Adverse_Event_Closed_Rec_Type__c
                    || childInteraction.MSD_CORE_Event_Case_Type__c ==  'AE and PQC'){
                    interaction.MSD_CORE_AE_Present__c = true;
                }
                if(childInteraction.MSD_CORE_Legal_Alert__c){
                    interaction.MSD_CORE_Legal_Alert_Present__c = true;
                }
                if(childInteraction.RecordType.DeveloperName == settings.MSD_CORE_Compensation_Req_Record_Type__c 
                    || childInteraction.RecordType.DeveloperName == settings.MSD_CORE_Comp_Req_Closed_Record_Type__c){
                    interaction.MSD_CORE_CR_Present__c = true;
                }
            }

            interactionMap.put(interaction.Id, interaction);
        }

        if(!interactionMap.keySet().isEmpty()) {
            update interactionMap.values(); 
        }
        }
        }
    }
}