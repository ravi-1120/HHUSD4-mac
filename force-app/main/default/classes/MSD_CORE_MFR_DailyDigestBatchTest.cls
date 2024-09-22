@isTest
public class MSD_CORE_MFR_DailyDigestBatchTest {

    @testSetup
    static void setupTestData() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        usr.Daily_Digest_Summary__c = true;
        usr.Prior_Days_to_Expire__c = '10';
        update usr;
        
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReqWithAppointmentMFR(prodPayer.Id, usr.Id);
            
            MSD_CORE_Catalog__c catalog = new MSD_CORE_Catalog__c();
            catalog.MSD_CORE_Meeting_Request__c = reqvod.Id;
            catalog.MSD_CORE_Product_Payor__c = prodPayer.Id;
            catalog.MSD_CORE_Payor__c = usr.Id;
            catalog.MSD_CORE_Resource_Status__c = 'Published';
            catalog.MSD_CORE_Expiration_Date__c = Date.today().addDays(-10);
            catalog.MSD_CORE_Post_Presentation__c = true;
            insert catalog;
            
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);    
            MSD_CORE_Notification__c notion = new MSD_CORE_Notification__c();
            notion.CreatedDate = System.today().addMonths(-3);
            notion.MSD_CORE_Payor__c = notionList[0].MSD_CORE_Payor__c;
            notion.MSD_CORE_Product_Payor__c = notionList[0].MSD_CORE_Product_Payor__c;
            notion.MSD_CORE_Label__c = 'Appointments'; 
            notion.MSD_CORE_Read__c = true;
            notion.MSD_CORE_Meeting_Request__c = notionList[0].MSD_CORE_Meeting_Request__c;
            insert notion;

            delete notion;
            undelete notion;
            system.assert(notion!=null, 'notion not deleted');

        }
    }

    @isTest
    static void testBatch() {
        Test.startTest();
        // Invoke the batch
        Database.executeBatch(new MSD_CORE_MFR_DailyDigestBatch(), 2000);
        Test.stopTest();
    }
}