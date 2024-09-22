/*
* MSD_CORE_RollupRelatedListTriggerTest
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This is the test class for the MSD_CORE_RollupRelatedListTrigger class
*/
@isTest
private class MSD_CORE_RollupRelatedListTriggerTest {
    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Case testCase = new Case(); 
    
    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();

        testCase.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.Product_Complaint_Record_Type_MVN__c].Id; 
        insert testCase; 
    }

    @isTest static void addAndRemoveOneTrackingNumber() {
        Test.startTest();
            Case c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id]; 
            System.assertEquals(null, c.MSD_CORE_PQC_Delivery_Tracking_Numbers__c);
            MSD_CORE_Delivery_Tracking_Number__c dtn = new MSD_CORE_Delivery_Tracking_Number__c(); 
            dtn.MSD_CORE_Case__c = c.Id;
            dtn.MSD_CORE_Tracking_Number__c = '12345678';
            insert dtn;
        Test.stopTest();

        c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('12345678', c.MSD_CORE_PQC_Delivery_Tracking_Numbers__c); 
        delete dtn;

        c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(null, c.MSD_CORE_PQC_Delivery_Tracking_Numbers__c);
    }

    @isTest static void addAndRemoveMultipleTrackingNumber() {
        Test.startTest();
            Case c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id]; 
            System.assertEquals(null, c.MSD_CORE_PQC_Delivery_Tracking_Numbers__c);
            List<MSD_CORE_Delivery_Tracking_Number__c> trackingList = new List<MSD_CORE_Delivery_Tracking_Number__c>(); 
            MSD_CORE_Delivery_Tracking_Number__c dtn1 = new MSD_CORE_Delivery_Tracking_Number__c(); 
            dtn1.MSD_CORE_Case__c = c.Id;
            dtn1.MSD_CORE_Tracking_Number__c = '12345678';
            trackingList.add(dtn1);
        Test.stopTest();

        MSD_CORE_Delivery_Tracking_Number__c dtn2 = new MSD_CORE_Delivery_Tracking_Number__c(); 
        dtn2.MSD_CORE_Case__c = c.Id;
        dtn2.MSD_CORE_Tracking_Number__c = '87654321';
        trackingList.add(dtn2);

        MSD_CORE_Delivery_Tracking_Number__c dtn3 = new MSD_CORE_Delivery_Tracking_Number__c(); 
        dtn3.MSD_CORE_Case__c = c.Id;
        dtn3.MSD_CORE_Tracking_Number__c = '1234';
        trackingList.add(dtn3);

        insert trackingList; 

        c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('1234, 87654321, 12345678', c.MSD_CORE_PQC_Delivery_Tracking_Numbers__c); 
        trackingList.remove(0); 
        delete dtn1;

        c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('1234, 87654321', c.MSD_CORE_PQC_Delivery_Tracking_Numbers__c);
        delete trackingList;

        c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(null, c.MSD_CORE_PQC_Delivery_Tracking_Numbers__c);

    }

    @isTest static void addAndRemoveOneLotNumber() {
        Test.startTest();
            Case c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id]; 
            System.assertEquals(null, c.MSD_CORE_PQC_Lot_Numbers__c);
            MSD_CORE_Lot_Number__c ln = new MSD_CORE_Lot_Number__c(); 
            ln.MSD_CORE_Case__c = c.Id;
            ln.MSD_CORE_Lot_Number__c = '12345678';
            insert ln; 
        Test.stopTest();

        c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('12345678', c.MSD_CORE_PQC_Lot_Numbers__c); 
        delete ln;

        c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(null, c.MSD_CORE_PQC_Lot_Numbers__c);
    }

    @isTest static void addAndRemoveMultipleLotNumbers() {
        Test.startTest();
            Case c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id]; 
            System.assertEquals(null, c.MSD_CORE_PQC_Lot_Numbers__c);
            MSD_CORE_Lot_Number__c ln = new MSD_CORE_Lot_Number__c(); 
            ln.MSD_CORE_Case__c = c.Id;
            ln.MSD_CORE_Lot_Number__c = '12345678';
            insert ln; 

            MSD_CORE_Lot_Number__c ln1 = new MSD_CORE_Lot_Number__c(); 
            ln1.MSD_CORE_Case__c = c.Id;
            ln1.MSD_CORE_Lot_Number__c = '87654321';
            insert ln1; 
        Test.stopTest();

        c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('12345678, 87654321', c.MSD_CORE_PQC_Lot_Numbers__c); 
        delete ln;
        c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('87654321', c.MSD_CORE_PQC_Lot_Numbers__c);  
        delete ln1;
        c = [SELECT MSD_CORE_PQC_Delivery_Tracking_Numbers__c, MSD_CORE_PQC_Lot_Numbers__c, Id FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(null, c.MSD_CORE_PQC_Lot_Numbers__c);
    }
}