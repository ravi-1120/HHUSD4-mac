@isTest
public with sharing class MSD_CORE_NotificationTriggerHandlerTest {

    @isTest
    public static void test1(){

        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReqWithAppointmentMFR(prodPayer.Id, usr.Id);
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
}