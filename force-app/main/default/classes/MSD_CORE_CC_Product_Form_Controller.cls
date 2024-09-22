public class MSD_CORE_CC_Product_Form_Controller {
    
    @AuraEnabled
    public static MSD_CORE_AE_Product__c getProdInfo(string prodId){
        return [SELECT Id, CreatedBy.Name, MSD_CORE_Related_to__c, CreatedById, MSD_CORE_Primary_Product__c, MSD_CORE_Adverse_Event__c, MSD_CORE_Adverse_Event__r.RecordTypeId, MSD_CORE_Adverse_Event__r.RecordType.Name, MSD_CORE_Adverse_Event__r.IsClosed, MSD_CORE_Adverse_Event__r.MSD_CORE_Is_Submitted__c FROM MSD_CORE_AE_Product__c WHERE Id = :prodId];
    }
    
    
    @AuraEnabled
    public static String getProfileName(){
        List<User> userList = [SELECT Id, Profile.Name
                               FROM User 
                               WHERE Id =: UserInfo.getUserId()];
        
        return userList[0].Profile.Name;
    }
}