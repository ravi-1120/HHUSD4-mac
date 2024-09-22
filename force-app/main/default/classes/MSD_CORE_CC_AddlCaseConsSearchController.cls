/**********************************************************************************************
Author  :  Haritha
Usage   :  This is controller class for MSD_CORE_CC_AddlCaseConsSearch Aura Cmp.
*********************************************************************************************/
public class MSD_CORE_CC_AddlCaseConsSearchController {
	@AuraEnabled
    public static List<MSD_CORE_AE_Contact__c> getRelatedListRecords(String caseId){
        return [SELECT Id, Name, MSD_CORE_First_Name__c, MSD_CORE_Last_Name__c FROM MSD_CORE_AE_Contact__c WHERE MSD_CORE_Adverse_Event__c = :caseId];
    }
}