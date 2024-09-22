/*
* MSD_CORE_CaseCampaignProductTriggerTest
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This is a test class for the MSD_CORE_CaseCampaignProductTrigger class
*/
@isTest
private class MSD_CORE_CaseCampaignProductTriggerTest {

    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Case request = new Case();  
    private static Case interaction = new Case(); 
    private static Id requestRecordTypeId = null; 
    private static Product_vod__c product; 
    
    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();

        product = new Product_vod__c(Name='Test Product', External_ID_vod__c = 'testid', Active_MRK__c = true, Company_Product_vod__c = true, Product_Type_vod__c = 'Family');
        insert product; 
    }

    @isTest static void createRequest() {

        Campaign camp = new Campaign(); 
        camp.MSD_CORE_Product__c = product.Id; 
        camp.Name = 'Test Campaign';
        camp.IsActive = true;
        insert camp; 

        interaction.RecordTypeId = [SELECT Id FROM RecordType WHERE  SObjectType = 'Case'  and DeveloperName = :settings.Interaction_Record_Type_MVN__c].Id; 
        interaction.MSD_CORE_Campaign__c = camp.Id; 
        insert interaction; 

        requestRecordTypeId = [SELECT Id FROM RecordType WHERE  SObjectType = 'Case' and DeveloperName = :settings.Request_Record_Type_MVN__c].Id; 
        request.ParentId = interaction.Id; 
        request.RecordTypeId = requestRecordTypeId;
        request.MSD_CORE_Campaign__c = camp.Id; 

        Test.startTest();
            insert request;
        Test.stopTest(); 

        Case r = [SELECT Product_MVN__c FROM Case WHERE Id =:request.Id];
        System.assertEquals(product.Id, r.Product_MVN__c); 
    }
}