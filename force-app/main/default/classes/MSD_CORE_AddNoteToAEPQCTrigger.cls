/*
* MSD_CORE_AddNoteToAEPQCTrigger
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This trigger handler adds a note to Closed Adverse Events and Product Quality
*                Complaints as well as Submitted Product Quality Complaints, in order
*                to trigger a Drawloop process that will send a notification to the respective group
*                with information about the case.
*/
public with sharing class MSD_CORE_AddNoteToAEPQCTrigger implements TriggersMVN.HandlerInterface{
     private Service_Cloud_Settings_MVN__c settings; 
     public void handle() {
        settings = Service_Cloud_Settings_MVN__c.getInstance(); 
        
        Set<Id> parentCaseIds = new Set<Id>(); 

        List<Attachment> attachmentList = Trigger.new;
        
        for(Attachment a:attachmentList) {
            if(!doesContain(a.Name)) {
                parentCaseIds.add(a.ParentId);
            }
        }

        Set<String> rtNames = new Set<String>();
        rtNames.add(settings.MSD_CORE_Product_Comp_Submitted_Type__c);
        rtNames.add(settings.MSD_CORE_Prod_Complaint_Closed_Rec_Type__c);
        rtNames.add(settings.MSD_CORE_Adverse_Event_Closed_Rec_Type__c);
        rtNames.add(settings.MSD_CORE_Adverse_Event_Submitted_RT__c);
        rtNames.add(settings.MSD_CORE_Combo_Submitted__c);
        rtNames.add(settings.MSD_CORE_Combo_Closed_Rec_Type__c);
        rtNames.add(settings.Adverse_Event_Record_Type_MVN__c);
        rtNames.add(settings.Product_Complaint_Record_Type_MVN__c);
        rtNames.add(settings.Combo_Case_Record_Type_MVN__c);

        Set<String> statuses = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Submitted_Status__c));
        statuses.add(settings.Closed_Status_MVN__c);
        statuses.add(settings.Open_Status_MVN__c);

        List<Case> caseList = [SELECT Id FROM Case WHERE Id IN :parentCaseIds AND RecordType.DeveloperName IN :rtNames AND Status IN :statuses]; 
        
        List<MSD_CORE_Note__c> notes = new List<MSD_CORE_Note__c>(); 
        for(Case c:caseList) {
            MSD_CORE_Note__c n = new MSD_CORE_Note__c(); 
            n.MSD_CORE_Case__c = c.Id; 
            n.MSD_CORE_Note__c = Label.MSD_CORE_NewAttachementAddedToAEPQC; 
            notes.add(n); 
        }
        insert notes;
    }

    private Boolean doesContain(String name) {
        List<String> prefixes = UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_AEPQC_Note_Filter__c);
        for(String pre:prefixes) {
            if(name.containsIgnoreCase(pre)) {
                return true; 
            }
        }
        return false; 
    }
}