public class MSD_CORE_CC_Notes_UtilityController {

    @AuraEnabled
    public static List<MSD_CORE_Note__c> getNotes(String caseId){
        return [Select Id, Name, CreatedDate, CreatedBy.Name, MSD_CORE_Note__c from MSD_CORE_Note__c where MSD_CORE_Case__c = :caseId ORDER BY CreatedDate Desc];
    }
    
    @AuraEnabled
    public static void saveCaseNote(String caseId, String note){
        MSD_CORE_Note__c objNote = new MSD_CORE_Note__c();
        objNote.MSD_CORE_Case__c = caseId;
        objNote.MSD_CORE_Note__c = note;
        insert objNote;
        //return [Select Id, Name, CreatedDate, CreatedBy.Name, MSD_CORE_Note__c from MSD_CORE_Note__c where MSD_CORE_Case__c = :caseId];
    }
    
      @AuraEnabled
    public static InteractionWrapper getCaseInfo(String caseId){
        InteractionWrapper wrap = new InteractionWrapper();
        wrap.userProfile = [SELECT Profile.Name FROM User WHERE Id =: UserInfo.getUserId()].Profile.Name;
        wrap.lstNotes = [Select Id, Name, CreatedDate, CreatedBy.Name, MSD_CORE_Note__c from MSD_CORE_Note__c where MSD_CORE_Case__c = :caseId ORDER BY CreatedDate Desc];
        wrap.restrictNew = false;
        Case objCase = [SELECT RecordType.DeveloperName FROM Case WHERE Id = :caseId];      
        String strCaseRT = String.valueOf(objCase.RecordType.DeveloperName);
        if(strCaseRT == 'Request_Closed_MVN' || strCaseRT == 'MSD_CORE_Compensation_Request_Closed'){
           // wrap.restrictNew = true;
           wrap.restrictNew = false;
        }
        return wrap;
    }
    
     public class InteractionWrapper{
        @AuraEnabled
        public String userProfile;
        @AuraEnabled
        public List<MSD_CORE_Note__c> lstNotes;
        @AuraEnabled
        public Boolean restrictNew;
    }
    
    @AuraEnabled
    public static String getCaseRT(String csId)
    {
        boolean isValid = true;
        String RtName = '';
        List<Case> csList = [select Id, CaseNumber, RecordType.Name, MSD_CORE_Event_Case_Type__c from Case where id =: csId limit 1];
        if(csList.size() > 0)
        {
            Case cs = csList[0];
            RtName =  cs.RecordType.Name;
            System.debug('test'+ RtName);
        }
        return RtName;
    }
    
}