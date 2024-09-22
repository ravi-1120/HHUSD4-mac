/*
* MSD_CORE_CopyLotNumToCRFromTETrigTest
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This is a test class for MSD_CORE_CopyLotNumbersToCRFromTETrigger class
*/
@isTest
private class MSD_CORE_CopyLotNumToCRFromTETrigTest {
    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Case interaction = new Case();  
    private static Id tempERecordTypeId = null; 
    private static Id compRRecordTypeId = null;
    private static Product_vod__c product = null;
    
    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();
        interaction.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.Interaction_Record_Type_MVN__c].Id; 
        insert interaction; 

        tempERecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.MSD_CORE_Temp_Excursion_Record_Type__c].Id; 
        compRRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.MSD_CORE_Compensation_Req_Record_Type__c].Id; 

        product = new Product_vod__c(Name='Test Product', External_ID_vod__c = 'testid', Active_MRK__c = true, Company_Product_vod__c = true, Product_Type_vod__c = 'Family');
        insert product;
    }

    // Create an Unsupported Temperature Excursion Product and then
    // create a Compensation Request
    @isTest static void testLotNumberCreatedOnCompRequest() {
        Case tempE = new Case(); 
        tempE.ParentId = interaction.Id; 
        tempE.RecordTypeId = tempERecordTypeId;
        insert tempE;

        MSD_CORE_Temperature_Excursion_Product__c tep = new MSD_CORE_Temperature_Excursion_Product__c();
        tep.MSD_CORE_Lot_Number__c = '15';
        tep.MSD_CORE_Expiration_Date__c = Date.today();
        tep.MSD_CORE_Case__c = tempE.Id; 
        tep.MSD_CORE_Outcome__c = 'Not Supported'; 
        tep.MSD_CORE_Product__c = product.Id; 
        insert tep; 

        Test.startTest();
            Case cr = new Case(); 
            cr.ParentId = interaction.Id; 
            cr.RecordTypeId = compRRecordTypeId;
            cr.Status = 'Open';
            insert cr;
        Test.stopTest();

        List<MSD_CORE_Lot_Number__c> lotNumberList = [SELECT MSD_CORE_Lot_Number__c, MSD_CORE_Product_Expiration_Date__c FROM MSD_CORE_Lot_Number__c WHERE MSD_CORE_Case__c =: cr.Id]; 
        System.assertEquals(1, lotNumberList.size());
        System.assertEquals('15', lotNumberList[0].MSD_CORE_Lot_Number__c); 
        System.assertEquals(Date.today(), lotNumberList[0].MSD_CORE_Product_Expiration_Date__c); 
    }

    // Create two Unsupported Temperature Excursion Products for a single 
    // Temperature Excursion and then create a Compensation Request
    @isTest static void testTwoLotNumbersCreatedOnCompRequest() {
        Case tempE = new Case(); 
        tempE.ParentId = interaction.Id; 
        tempE.RecordTypeId = tempERecordTypeId;
        insert tempE;

        MSD_CORE_Temperature_Excursion_Product__c tep = new MSD_CORE_Temperature_Excursion_Product__c();
        tep.MSD_CORE_Lot_Number__c = '15';
        tep.MSD_CORE_Expiration_Date__c = Date.today();
        tep.MSD_CORE_Case__c = tempE.Id; 
        tep.MSD_CORE_Outcome__c = 'Not Supported'; 
        tep.MSD_CORE_Product__c = product.Id; 
        insert tep; 

        MSD_CORE_Temperature_Excursion_Product__c tep2 = new MSD_CORE_Temperature_Excursion_Product__c();
        tep2.MSD_CORE_Lot_Number__c = '16';
        tep2.MSD_CORE_Expiration_Date__c = Date.today();
        tep2.MSD_CORE_Case__c = tempE.Id; 
        tep2.MSD_CORE_Outcome__c = 'Not Supported'; 
        tep2.MSD_CORE_Product__c = product.Id; 
        insert tep2; 

        Test.startTest();
            Case cr = new Case(); 
            cr.ParentId = interaction.Id; 
            cr.RecordTypeId = compRRecordTypeId;
            cr.Status = 'Open';
            insert cr;
        Test.stopTest();

        List<MSD_CORE_Lot_Number__c> lotNumberList = [SELECT MSD_CORE_Lot_Number__c, MSD_CORE_Product_Expiration_Date__c FROM MSD_CORE_Lot_Number__c WHERE MSD_CORE_Case__c =: cr.Id ORDER BY MSD_CORE_Lot_Number__c]; 
        System.assertEquals(2, lotNumberList.size());
        System.assertEquals('15', lotNumberList[0].MSD_CORE_Lot_Number__c); 
        System.assertEquals(Date.today(), lotNumberList[0].MSD_CORE_Product_Expiration_Date__c); 
        System.assertEquals('16', lotNumberList[1].MSD_CORE_Lot_Number__c); 
        System.assertEquals(Date.today(), lotNumberList[1].MSD_CORE_Product_Expiration_Date__c); 
    }

    // Create two Temperature Excursion Products for two Temperature
    // Excursions and then create a Compensation Request (only the Unsupported Temp
    // Excursion Product from the most recently created Temp Excursion will be used)
    @isTest static void testSingleLotNumberAddedWhenTwoTempExcursionsPresent() {
        Case tempE = new Case(); 
        tempE.ParentId = interaction.Id; 
        tempE.RecordTypeId = tempERecordTypeId;
        insert tempE;

        Case tempE2 = new Case(); 
        tempE2.ParentId = interaction.Id; 
        tempE2.RecordTypeId = tempERecordTypeId;
        insert tempE2;

        Test.startTest();
            MSD_CORE_Temperature_Excursion_Product__c tep = new MSD_CORE_Temperature_Excursion_Product__c();
            tep.MSD_CORE_Lot_Number__c = '15';
            tep.MSD_CORE_Expiration_Date__c = Date.today();
            tep.MSD_CORE_Case__c = tempE.Id; 
            tep.MSD_CORE_Outcome__c = 'Not Supported'; 
            tep.MSD_CORE_Product__c = product.Id; 
            insert tep; 

            MSD_CORE_Temperature_Excursion_Product__c tep2 = new MSD_CORE_Temperature_Excursion_Product__c();
            tep2.MSD_CORE_Lot_Number__c = '16';
            tep2.MSD_CORE_Expiration_Date__c = Date.today();
            tep2.MSD_CORE_Case__c = tempE2.Id; 
            tep2.MSD_CORE_Outcome__c = 'Not Supported'; 
            tep2.MSD_CORE_Product__c = product.Id; 
            insert tep2; 

            Case cr = new Case();
            cr.ParentId = interaction.Id; 
            cr.RecordTypeId = compRRecordTypeId;
            cr.Status = 'Open';
            insert cr;
        Test.stopTest();

        List<MSD_CORE_Lot_Number__c> lotNumberList = [SELECT MSD_CORE_Lot_Number__c, MSD_CORE_Product_Expiration_Date__c FROM MSD_CORE_Lot_Number__c WHERE MSD_CORE_Case__c =: cr.Id]; 
        System.assertEquals(1, lotNumberList.size());  
        System.assertEquals(Date.today(), lotNumberList[0].MSD_CORE_Product_Expiration_Date__c); 
    }

    // Create a Supported Temperature Excursion Product and then create
    // a Compensation Request
    @isTest static void testLotNumberNotCreatedForSupportedTempExProduct() {
        Case tempE = new Case(); 
        tempE.ParentId = interaction.Id; 
        tempE.RecordTypeId = tempERecordTypeId;
        insert tempE;

        MSD_CORE_Temperature_Excursion_Product__c tep = new MSD_CORE_Temperature_Excursion_Product__c();
        tep.MSD_CORE_Lot_Number__c = '15';
        tep.MSD_CORE_Expiration_Date__c = Date.today();
        tep.MSD_CORE_Case__c = tempE.Id; 
        tep.MSD_CORE_Outcome__c = 'Supported'; 
        tep.MSD_CORE_Product__c = product.Id; 
        insert tep; 

        Test.startTest();
            Case cr = new Case(); 
            cr.ParentId = interaction.Id; 
            cr.RecordTypeId = compRRecordTypeId;
            cr.Status = 'Open';
            insert cr;
        Test.stopTest();

        List<MSD_CORE_Lot_Number__c> lotNumberList = [SELECT MSD_CORE_Lot_Number__c, MSD_CORE_Product_Expiration_Date__c 
                                                            FROM MSD_CORE_Lot_Number__c 
                                                            WHERE MSD_CORE_Case__c =: cr.Id]; 
        System.assertEquals(0, lotNumberList.size());
    }
}