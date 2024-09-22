public class MSD_CORE_CC_CaseConsController {

    @AuraEnabled
    public static String getRecordType(String csId){
        Case cs = [SELECT Id, RecordType.DeveloperName FROM Case WHERE Id = :csId];
        if(cs.RecordType.DeveloperName == 'Product_Complaint_MVN'){
            return Schema.SObjectType.MSD_CORE_AE_Contact__c.getRecordTypeInfosByDeveloperName().get('Product_Complaint_MVN').getRecordTypeId();
        }
        else{
            return Schema.SObjectType.MSD_CORE_AE_Contact__c.getRecordTypeInfosByDeveloperName().get('Adverse_Event_MVN').getRecordTypeId();
        }
    }
}