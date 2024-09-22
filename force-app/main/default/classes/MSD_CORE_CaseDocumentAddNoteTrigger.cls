/*
* MSD_CORE_CaseDocumentAddNoteTrigger
* Created By:    Samuel Rosen
* Created Date:  5/20/2015
* Description:   This trigger handler adds a note to a Case with a set
*                of questions when an article with the "Questions" field
*                populated is attached to the Case.
*/
public with sharing class MSD_CORE_CaseDocumentAddNoteTrigger implements TriggersMVN.HandlerInterface{
    public void handle() {
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
        List<Case_Document_MVN__c> caseDocuments = Trigger.new; 
        Map<Id, Case_Document_MVN__c> caseToCaseDocument = new Map<Id, Case_Document_MVN__c>(); 
        for(Case_Document_MVN__c cd: caseDocuments) { 
            System.debug('cd.MSD_CORE_Questions__c -->'+cd.MSD_CORE_Questions__c); 
            if(!String.isBlank(cd.MSD_CORE_Questions__c)) {
                caseToCaseDocument.put(cd.Case_MVN__c, cd); 
            }
        }
        System.debug('caseToCaseDocument -->'+caseToCaseDocument);
        List<Case> cases = [SELECT Id FROM Case WHERE Id IN :caseToCaseDocument.keySet()];
        System.debug('cases -->'+cases);
        List<MSD_CORE_Note__c> notes = new List<MSD_CORE_Note__c>(); 
        for(Case c : cases) {
            MSD_CORE_NOTE__c note = new MSD_CORE_NOTE__c(); 
            note.MSD_CORE_Note__c = caseToCaseDocument.get(c.Id).MSD_CORE_Questions__c; 
            note.MSD_CORE_Case__c = c.Id; 
            notes.add(note); 
        }
        System.debug('notes -->'+notes);
        if(notes.size() > 0) {
            insert notes; 
        } 
    }
}