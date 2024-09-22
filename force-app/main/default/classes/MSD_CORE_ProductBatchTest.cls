/*
* MSD_CORE_ProductBatchTest
* Created By:    Prasanjeet Sharma
* Created Date:  6/3/2019
* Description:   This is a test class for the MSD_CORE_ProductBatch class
*/
@isTest
public class MSD_CORE_ProductBatchTest {
    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Case interaction;
    private static MSD_CORE_Source__c source; 

    static {
        TestDataFactoryMVN.createSettings(true);
        settings = [select id, Combo_Case_Preview_Record_Type__c from Service_Cloud_Settings_MVN__c];
        
        settings.Combo_Case_Preview_Record_Type__c = 'Combo_Case_Preview';
        update settings;
        
        settings = Service_Cloud_Settings_MVN__c.getInstance();
        
        Product_vod__c product = new Product_vod__c(Name = 'test',
                                                    Active_MRK__c = true,
                                                    Product_Type_vod__c = 'Family');
        insert product;
        
        interaction = new Case(); 
        interaction.recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Adverse Event' and sObjectType = 'Case'].Id;
        interaction.Origin = settings.MSD_CORE_Case_Origin_Email__c; 
        interaction.MSD_CORE_Date_PQC_first_identified__c = system.now().format('mm/dd/yyyy');
        interaction.MSD_CORE_PQC_Description__c = 'test';
        interaction.Product_MVN__c = product.Id;
        insert interaction; 

        source = new MSD_CORE_Source__c(); 
        source.Name = 'Source';
        source.MSD_CORE_External_Id__c = 'jimmy@gmail.com';
        source.MSD_CORE_Active__c = true;

        insert source; 
    }

    @isTest static void TestMSD_CORE_ProductBatch() {
        MSD_CORE_ProductBatch batch = new MSD_CORE_ProductBatch();
        Database.executeBatch(batch, 1);
        
        MSD_CORE_PreComboBatch batch2 = new MSD_CORE_PreComboBatch();
        Database.executeBatch(batch2, 1);
    }
}