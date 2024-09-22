public class CaseIconChangeController {
 @AuraEnabled
    public  static string getIcon(Id caseId)
    {
        if(caseId != null)
        {
            Case caseRec = [select Id, CaseNumber, Origin, RecordType.Name, MSD_CORE_Event_Case_Type__c from Case where Id =: caseId];
            
            return caseRec.RecordType.Name;
        }
        
        return '';
    }
}