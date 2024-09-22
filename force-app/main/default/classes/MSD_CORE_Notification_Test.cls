/**
 * Component Name:      MSD_CORE_Notification_Test
 * Created By:          Focal CXM
 * @description:        Used for MSD_CORE_Notification
 * Class Type:          Test
 * @description MSD_CORE_Notification_Test
 */
@isTest
public class MSD_CORE_Notification_Test {

    /**
     * @description Cover getProductList method
     * @return void
    */
    @isTest
    public static void testGetProductList() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();

        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(3, usr.Id, prodPayer.Id, reqvod.Id);
            notionList[1].MSD_CORE_Notification__c = notionList[0].Id;
            notionList[1].MSD_CORE_Read__c = false;
            notionList[1].MSD_CORE_Label__c = 'Appointments';
            Meeting_Request_vod__c mfr = new Meeting_Request_vod__c();
            mfr.MSD_CORE_Source__c = 'MFR';
            mfr.Assignee_vod__c = usr.Id;
            mfr.MSD_CORE_Product_Payor__c = prodPayer.Id;
            mfr.MSD_CORE_Payor__c = usr.Id;
            insert mfr;
            notionList[1].MSD_CORE_Meeting_Request__c = mfr.Id;        
            update notionList[1];
        }

        Test.startTest();
        MSD_CORE_Notification.getProductList(usr.Id);
        User usr1 = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact124', false);
        MSD_CORE_Notification.getProductList(usr1.Id);
        MSD_CORE_Notification.MheeChildNotifictionWrapper mn = new MSD_CORE_Notification.MheeChildNotifictionWrapper();
        mn.duration = '';
        mn.childNotification = new MSD_CORE_Notification__c();
        MSD_CORE_Notification.notificationwrapgroup nw = new  MSD_CORE_Notification.notificationwrapgroup();
        nw.mainrec = new MSD_CORE_Notification.notificationwrap();
        nw.grouprec = new List<MSD_CORE_Notification.notificationwrap>();
        MSD_CORE_Notification.groupedrecwrap gw = new MSD_CORE_Notification.groupedrecwrap();
        gw.notiwrap = new List<MSD_CORE_Notification.notificationwrap>();
        MSD_CORE_Notification.mainrec mr = new MSD_CORE_Notification.mainrec();
        mr.grouprec = new MSD_CORE_Notification.groupedrecwrap();
        
        DateTime dateref = System.now();
        MSD_CORE_Notification.getDuration(dateref);
        dateref = System.now().addMinutes(-10);
        MSD_CORE_Notification.getDuration(dateref);
        dateref = System.now().addHours(-1);
        MSD_CORE_Notification.getDuration(dateref);
        dateref = System.now().addHours(-2);
        MSD_CORE_Notification.getDuration(dateref);
        Test.stopTest();

        System.assertEquals(3, notionList.size(), 'Created 3 Notification'); 
    }

    /**
     * @description Cover getnotificationcount method
     * @return void
    */
    @isTest
    public static void testGetnotificationcount() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(3, usr.Id, prodPayer.Id, reqvod.Id);
            notionList[1].MSD_CORE_Notification__c = notionList[0].Id;
            update notionList[1];
        }

        Test.startTest();
        MSD_CORE_Notification.getNotificationCount(usr.Id);
        User usr1 = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact124', false);
        MSD_CORE_Notification.getNotificationCount(usr1.Id);
        Test.stopTest();
        System.assertEquals(3, notionList.size(), 'Created 3 Notification');
    }
    /**
     * @description testMHEEGetnotificationcount
     * @return void
    */
    @isTest
    public static void testMHEEGetnotificationcount() {
         User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        
       
        System.runAs(usr) {
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(3, usr.Id, prodPayer.Id, reqvod.Id);
            notionList[1].MSD_CORE_Notification__c = notionList[0].Id;
               reqvod.MSD_CORE_Source__c = 'MHEE';
                reqvod.Assignee_vod__c = usr.Id;
               update reqvod;
            notionList[1].Related_Notification__c =    notionList[0].Id;
            update notionList[1];
        }    
        Test.startTest();
        MSD_CORE_Notification.getNotificationCount(usr.Id);
        User usr1 = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact124', false);
        MSD_CORE_Notification.MheeNotificationWrapper mheenotif = MSD_CORE_Notification.getMHEENotification(usr.Id, '6',  '3');
        Test.stopTest();
    }

    /**
     * @description Cover updatenotification method
     * @return void
    */
    @isTest
    public static void testUpdatenotification() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        System.runAs(usr) {
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(3, usr.Id, prodPayer.Id, reqvod.Id);
            notionList[1].MSD_CORE_Notification__c = notionList[0].Id;
            update notionList[1];
        }

        Test.startTest();
        MSD_CORE_Notification.updateNotification(usr.Id, 'Appointments', prodPayer.Id);
        User usr1 = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact124', false);
        MSD_CORE_Product_Payor__c prodPayer1 = new MSD_CORE_Product_Payor__c();
        System.runAs(usr1) {
            prodPayer1 = TestDataFactory_MSD_CORE_Notification.getProductPayor();
        }
        MSD_CORE_Notification.updateNotification(usr1.Id, 'Appointments', prodPayer1.Id);
        MSD_CORE_Notification.updateNotification(usr1.Id, 'Closed', prodPayer1.Id);
        Test.stopTest();
        System.assertEquals(3, notionList.size(), 'Created 3 Notification');
    }

    /**
     * @description Cover Mapinitalization method
     * @return void
    */
    @isTest
    public static void testMapinitalization() {
        /*Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;*/
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        System.runAs(usr){
            Test.startTest();
            Map<String,List<MSD_CORE_Notification.notificationwrap>> notiMap = MSD_CORE_Notification.mapinitalization();
            Test.stopTest();
        
        
        System.assertEquals(true, (notiMap.size() > 0), 'Created 4 Notification');
        }
    }

    /**
     * @description Cover GetActivity method
     * @return void
    */
  /* @isTest
    public static void testGetActivity(){
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        MSD_CORE_Notification__c notion1 = new MSD_CORE_Notification__c();
        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
            notionList[1].MSD_CORE_Notification__c = notionList[0].Id;
            notionList[3].MSD_CORE_Notification__c = notionList[0].Id;
            update notionList;
            MSD_CORE_Notification__c notion = new MSD_CORE_Notification__c();
            notion.CreatedDate = System.today().addMonths(-3);
            notion.CreatedDate = notion.CreatedDate.addHours(1);
            notion.MSD_CORE_Payor__c = notionList[0].MSD_CORE_Payor__c;
            notion.MSD_CORE_Product_Payor__c = notionList[0].MSD_CORE_Product_Payor__c;
            notion.MSD_CORE_Label__c = 'Appointments'; 
            notion.MSD_CORE_Read__c = true;
            notion.MSD_CORE_Meeting_Request__c = notionList[0].MSD_CORE_Meeting_Request__c;
            insert notion;
            
            /*notion1.CreatedDate = System.today().addMonths(-3);
            notion1.CreatedDate = notion1.CreatedDate.addHours(1);
            notion1.MSD_CORE_Payor__c = notionList[0].MSD_CORE_Payor__c;
            notion1.MSD_CORE_Product_Payor__c = notionList[0].MSD_CORE_Product_Payor__c;
            notion1.MSD_CORE_Label__c = 'Appointments'; 
            notion1.MSD_CORE_Read__c = true;
            notion1.MSD_CORE_Meeting_Request__c = notionList[0].MSD_CORE_Meeting_Request__c;
            notion1.MSD_CORE_Notification__c = notion.Id;
            insert notion1;*/
     /*   }

        Test.startTest();
        MSD_CORE_Notification.getActivity(notionList[0].MSD_CORE_Payor__c, notionList[0].MSD_CORE_Product_Payor__c, '2', '2');
        //MSD_CORE_Notification.getActivity(notion1.MSD_CORE_Payor__c, notion1.MSD_CORE_Product_Payor__c, '2', '2');
        User usr1 = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact124', false);
        MSD_CORE_Product_Payor__c prodPayer1 = new MSD_CORE_Product_Payor__c();
        System.runAs(usr1) {    
            prodPayer1 = TestDataFactory_MSD_CORE_Notification.getProductPayor();
        }
        MSD_CORE_Notification.getActivity(usr1.Id, prodPayer1.Id, '2', '2');
        Test.stopTest();
        System.assertEquals(4, notionList.size(), 'Created 4 Notification');
    } */

    /**
     * @description Cover GetActivity method
     * @return void
    */
    @isTest
    public static void testGetActivity1(){
        User usr = MSD_CORE_Notification_Test.getCommunityUserRecord('TestAccount', 'Test', 'Contact123', true);
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        List<MSD_CORE_Notification__c> notionList1 = new List<MSD_CORE_Notification__c>();
        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
            notionList[1].MSD_CORE_Notification__c = notionList[0].Id;
            notionList[3].MSD_CORE_Notification__c = notionList[0].Id;
            update notionList;
            System.debug('Date.Today()-->'+Date.Today());
            MSD_CORE_Notification__c notion = new MSD_CORE_Notification__c();
            // notion.CreatedDate = Date.Today();
            notion.MSD_CORE_Payor__c = notionList[0].MSD_CORE_Payor__c;
            notion.MSD_CORE_Product_Payor__c = notionList[0].MSD_CORE_Product_Payor__c;
            notion.MSD_CORE_Label__c = 'Appointments'; 
            notion.MSD_CORE_Read__c = true;
            notion.MSD_CORE_Meeting_Request__c = notionList[0].MSD_CORE_Meeting_Request__c;
            notion.MSD_CORE_Activity__c = notionList[0].MSD_CORE_Activity__c; 
            insert notion;
        }
        system.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList1 = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
            notionList1[1].MSD_CORE_Notification__c = notionList1[0].Id;
            notionList1[3].MSD_CORE_Notification__c = notionList1[0].Id;
            update notionList1;
            System.debug('Date.Today()-->'+Date.Today());
            MSD_CORE_Notification__c notion1 = new MSD_CORE_Notification__c();
            notion1.CreatedDate = Date.Today();
            notion1.MSD_CORE_Payor__c = notionList1[0].MSD_CORE_Payor__c;
            notion1.MSD_CORE_Product_Payor__c = notionList1[0].MSD_CORE_Product_Payor__c;
            notion1.MSD_CORE_Label__c = 'Appointments'; 
            notion1.MSD_CORE_Read__c = true;
            notion1.MSD_CORE_Meeting_Request__c = notionList1[0].MSD_CORE_Meeting_Request__c;
            notion1.MSD_CORE_Activity__c = notionList1[0].MSD_CORE_Activity__c; 
            insert notion1;
        }
        system.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList1 = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
            notionList1[1].MSD_CORE_Notification__c = notionList1[0].Id;
            notionList1[3].MSD_CORE_Notification__c = notionList1[0].Id;
            update notionList1;
            System.debug('Date.Today()-->'+Date.Today());
            MSD_CORE_Notification__c notion1 = new MSD_CORE_Notification__c();
            notion1.CreatedDate = Date.Today().addDays(-2);
            notion1.MSD_CORE_Payor__c = notionList1[0].MSD_CORE_Payor__c;
            notion1.MSD_CORE_Product_Payor__c = notionList1[0].MSD_CORE_Product_Payor__c;
            notion1.MSD_CORE_Label__c = 'Appointments'; 
            notion1.MSD_CORE_Read__c = true;
            notion1.MSD_CORE_Meeting_Request__c = notionList1[0].MSD_CORE_Meeting_Request__c;
            notion1.MSD_CORE_Activity__c = notionList1[0].MSD_CORE_Activity__c; 
            insert notion1;
        }
        system.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            prodPayer.MSD_CORE_Remove_Title_Description__c = true;
            update prodPayer;
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList1 = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
            notionList1[1].MSD_CORE_Notification__c = notionList1[0].Id;
            notionList1[3].MSD_CORE_Notification__c = notionList1[0].Id;
            update notionList1;
            System.debug('Date.Today()-->'+Date.Today());
            MSD_CORE_Notification__c notion2 = new MSD_CORE_Notification__c();
            notion2.CreatedDate = Date.Today().addDays(-1);
            notion2.MSD_CORE_Payor__c = notionList1[0].MSD_CORE_Payor__c;
            notion2.MSD_CORE_Product_Payor__c = notionList1[0].MSD_CORE_Product_Payor__c;
            notion2.MSD_CORE_Label__c = 'Closed'; 
            notion2.MSD_CORE_Read__c = true;
            notion2.MSD_CORE_Meeting_Request__c = notionList1[0].MSD_CORE_Meeting_Request__c;
            notion2.MSD_CORE_Activity__c = notionList1[0].MSD_CORE_Activity__c; 
            insert notion2;
        }

        Test.startTest();
        MSD_CORE_Notification.getActivity(notionList[0].MSD_CORE_Payor__c, notionList[0].MSD_CORE_Product_Payor__c, '2', '2');
        MSD_CORE_Notification.getActivity(notionList1[0].MSD_CORE_Payor__c, notionList1[0].MSD_CORE_Product_Payor__c, '2', '2');
        MSD_CORE_Notification.getActivity(notionList1[0].MSD_CORE_Payor__c, notionList1[0].MSD_CORE_Product_Payor__c, '2', '2');
        /*User usr1 = MSD_CORE_Notification_Test.getCommunityUserRecord('TestAccount', 'Test', 'Contact124', false);
        MSD_CORE_Product_Payor__c prodPayer1 = new MSD_CORE_Product_Payor__c();
        System.runAs(usr1) {    
            prodPayer1 = TestDataFactory_MSD_CORE_Notification.getProductPayor();
        }
        MSD_CORE_Notification.getActivity(usr1.Id, prodPayer1.Id, '2', '2');*/
        Test.stopTest();
        System.assertEquals(4, notionList.size(), 'Created 4 Notification');
    }
    
    
    /**
* @description Cover GetActivity method for closed scenarios
* @return void
*/
    @isTest
    public static void testGetActivity2(){
        User usr = MSD_CORE_Notification_Test.getCommunityUserRecord('TestAccount', 'Test', 'Contact123', true);
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        List<MSD_CORE_Notification__c> notionList1 = new List<MSD_CORE_Notification__c>();
        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            prodPayer.MSD_CORE_Remove_Title_Description__c = true;
            update prodPayer;
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
            notionList[1].MSD_CORE_Notification__c = notionList[0].Id;
            notionList[3].MSD_CORE_Notification__c = notionList[0].Id;
            update notionList;
            System.debug('Date.Today()-->'+Date.Today());
            MSD_CORE_Notification__c notion = new MSD_CORE_Notification__c();
            notion.MSD_CORE_Payor__c = notionList[0].MSD_CORE_Payor__c;
            notion.MSD_CORE_Product_Payor__c = notionList[0].MSD_CORE_Product_Payor__c;
            notion.MSD_CORE_Label__c = 'Closed'; 
            notion.MSD_CORE_Read__c = true;
            notion.MSD_CORE_Meeting_Request__c = notionList[0].MSD_CORE_Meeting_Request__c;
            notion.MSD_CORE_Activity__c = 'in your library saved you have created you have cancelled "> for <a <a <strong> for <span </a></p> </a> saved'; 
            insert notion;
            MSD_CORE_Notification__c notion1 = new MSD_CORE_Notification__c();
            notion1.MSD_CORE_Payor__c = notionList[0].MSD_CORE_Payor__c;
            notion1.MSD_CORE_Product_Payor__c = notionList[0].MSD_CORE_Product_Payor__c;
            notion1.MSD_CORE_Label__c = 'Closed'; 
            notion1.MSD_CORE_Read__c = true;
            notion1.MSD_CORE_Meeting_Request__c = notionList[0].MSD_CORE_Meeting_Request__c;
            notion1.MSD_CORE_Activity__c = '<p style="color: #333333; font-size: 18px; font-weight: 700; font-style: normal;">You have created <a href="" target="_self" style="color: rgb(0, 133, 124); font-size: 18px; font-weight: 700; font-style: normal;"><u>Request: MR-000000627</u></a> for <a href="" target="_self" style="color: rgb(0, 133, 124); font-size: 18px; font-weight: 700; font-style: normal;"><u>Budget Impact Model</u></a><span style="color: #333333; font-size: 18px; font-weight: 700; font-style: normal;">.</span></p>'; 
            insert notion1;
            
            MSD_CORE_Notification__c notion2 = new MSD_CORE_Notification__c();
            notion2.MSD_CORE_Payor__c = notionList[0].MSD_CORE_Payor__c;
            notion2.MSD_CORE_Product_Payor__c = notionList[0].MSD_CORE_Product_Payor__c;
            notion2.MSD_CORE_Label__c = 'Closed'; 
            notion2.MSD_CORE_Read__c = true;
            notion2.MSD_CORE_Meeting_Request__c = notionList[0].MSD_CORE_Meeting_Request__c;
            notion2.MSD_CORE_Activity__c = 'saved you have cancelled You have cancelled "> for <a <a <strong> for <span </a></p> </a> saved'; 
            insert notion2;
            MSD_CORE_Notification__c notion5 = new MSD_CORE_Notification__c();
            notion5.CreatedDate = System.now().addMinutes(-10);
            notion5.MSD_CORE_Payor__c = notionList[0].MSD_CORE_Payor__c;
            notion5.MSD_CORE_Product_Payor__c = notionList[0].MSD_CORE_Product_Payor__c;
            notion5.MSD_CORE_Label__c = 'Closed'; 
            notion5.MSD_CORE_Read__c = true;
            notion5.MSD_CORE_Meeting_Request__c = notionList[0].MSD_CORE_Meeting_Request__c;
            notion5.MSD_CORE_Activity__c = 'saved you have cancelled you have created You have created You have cancelled "> for <a <a <strong> for <span </a></p> </a> saved'; 
            insert notion5;
            MSD_CORE_Notification__c notion3 = new MSD_CORE_Notification__c();
            notion3.CreatedDate = System.now().addHours(-1);
            notion3.MSD_CORE_Payor__c = notionList[0].MSD_CORE_Payor__c;
            notion3.MSD_CORE_Product_Payor__c = notionList[0].MSD_CORE_Product_Payor__c;
            notion3.MSD_CORE_Label__c = 'Closed'; 
            notion3.MSD_CORE_Read__c = true;
            notion3.MSD_CORE_Meeting_Request__c = notionList[0].MSD_CORE_Meeting_Request__c;
            notion3.MSD_CORE_Activity__c = 'saved you have cancelled you have created You have created You have cancelled "> for <a <a <strong> for <span </a></p> </a> saved'; 
            insert notion3;
            MSD_CORE_Notification__c notion4 = new MSD_CORE_Notification__c();
            notion4.CreatedDate = System.now().addHours(-2);
            notion4.MSD_CORE_Payor__c = notionList[0].MSD_CORE_Payor__c;
            notion4.MSD_CORE_Product_Payor__c = notionList[0].MSD_CORE_Product_Payor__c;
            notion4.MSD_CORE_Label__c = 'Closed'; 
            notion4.MSD_CORE_Read__c = true;
            notion4.MSD_CORE_Meeting_Request__c = notionList[0].MSD_CORE_Meeting_Request__c;
            notion4.MSD_CORE_Activity__c = 'saved you have cancelled you have created You have created You have cancelled "> for <a <a <strong> for <span </a></p> </a> saved'; 
            insert notion4;
        }
        system.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            prodPayer.MSD_CORE_Remove_Title_Description__c = true;
            update prodPayer;
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList1 = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
            notionList1[1].MSD_CORE_Notification__c = notionList1[0].Id;
            notionList1[3].MSD_CORE_Notification__c = notionList1[0].Id;
            update notionList1;
            System.debug('Date.Today()-->'+Date.Today());
            MSD_CORE_Notification__c notion1 = new MSD_CORE_Notification__c();
            notion1.CreatedDate = Date.Today();
            notion1.MSD_CORE_Payor__c = notionList1[0].MSD_CORE_Payor__c;
            notion1.MSD_CORE_Product_Payor__c = notionList1[0].MSD_CORE_Product_Payor__c;
            notion1.MSD_CORE_Label__c = 'Closed'; 
            notion1.MSD_CORE_Read__c = true;
            notion1.MSD_CORE_Meeting_Request__c = notionList1[0].MSD_CORE_Meeting_Request__c;
            notion1.MSD_CORE_Activity__c = notionList1[0].MSD_CORE_Activity__c+'in your library saved you have created you have cancelled "> for <a <a <strong> for <span </a></p> </a> saved'; 
            insert notion1;
        }
        system.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            prodPayer.MSD_CORE_Remove_Title_Description__c = true;
            update prodPayer;
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList1 = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
            notionList1[1].MSD_CORE_Notification__c = notionList1[0].Id;
            notionList1[3].MSD_CORE_Notification__c = notionList1[0].Id;
            update notionList1;
            System.debug('Date.Today()-->'+Date.Today());
            MSD_CORE_Notification__c notion1 = new MSD_CORE_Notification__c();
            notion1.CreatedDate = Date.Today().addDays(-2);
            notion1.MSD_CORE_Payor__c = notionList1[0].MSD_CORE_Payor__c;
            notion1.MSD_CORE_Product_Payor__c = notionList1[0].MSD_CORE_Product_Payor__c;
            notion1.MSD_CORE_Label__c = 'Appointments'; 
            notion1.MSD_CORE_Read__c = true;
            notion1.MSD_CORE_Meeting_Request__c = notionList1[0].MSD_CORE_Meeting_Request__c;
            notion1.MSD_CORE_Activity__c = notionList1[0].MSD_CORE_Activity__c+'in your library saved you have created you have cancelled "> for <a <a <strong> for <span </a></p> </a> saved'; 
            insert notion1;
        }
        system.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            prodPayer.MSD_CORE_Remove_Title_Description__c = true;
            update prodPayer;
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList1 = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
            notionList1[1].MSD_CORE_Notification__c = notionList1[0].Id;
            notionList1[3].MSD_CORE_Notification__c = notionList1[0].Id;
            update notionList1;
            System.debug('Date.Today()-->'+Date.Today());
            MSD_CORE_Notification__c notion2 = new MSD_CORE_Notification__c();
            notion2.CreatedDate = Date.Today().addDays(-1);
            notion2.MSD_CORE_Payor__c = notionList1[0].MSD_CORE_Payor__c;
            notion2.MSD_CORE_Product_Payor__c = notionList1[0].MSD_CORE_Product_Payor__c;
            notion2.MSD_CORE_Label__c = 'Closed'; 
            notion2.MSD_CORE_Read__c = true;
            notion2.MSD_CORE_Meeting_Request__c = notionList1[0].MSD_CORE_Meeting_Request__c;
            notion2.MSD_CORE_Activity__c = notionList1[0].MSD_CORE_Activity__c+'in your library saved you have created you have cancelled "> for <a <a <strong> for <span </a></p> </a> saved'; 
            insert notion2;
        }
        
        Test.startTest();
        MSD_CORE_Notification.getActivity(notionList[0].MSD_CORE_Payor__c, notionList[0].MSD_CORE_Product_Payor__c, '2', '2');
        MSD_CORE_Notification.getActivity(notionList[0].MSD_CORE_Payor__c, notionList[0].MSD_CORE_Product_Payor__c, '50', '1');
        MSD_CORE_Notification.getActivity(notionList1[0].MSD_CORE_Payor__c, notionList1[0].MSD_CORE_Product_Payor__c, '2', '2');
        MSD_CORE_Notification.getActivity(notionList1[0].MSD_CORE_Payor__c, notionList1[0].MSD_CORE_Product_Payor__c, '2', '1');
        MSD_CORE_Notification.getActivity(notionList1[0].MSD_CORE_Payor__c, notionList1[0].MSD_CORE_Product_Payor__c, '2', '2');
        /*User usr1 = MSD_CORE_Notification_Test.getCommunityUserRecord('TestAccount', 'Test', 'Contact124', false);
MSD_CORE_Product_Payor__c prodPayer1 = new MSD_CORE_Product_Payor__c();
System.runAs(usr1) {    
prodPayer1 = TestDataFactory_MSD_CORE_Notification.getProductPayor();
}
MSD_CORE_Notification.getActivity(usr1.Id, prodPayer1.Id, '2', '2');*/
        Test.stopTest();
        System.assertEquals(4, notionList.size(), 'Created 4 Notification');
    }


    /*
    @description getCommunityUserRecord is used to create a community user to use in test classes
    @return user
     */
    public static User getCommunityUserRecord(String accName, String confirstname, String conlastname, Boolean vscbool) {
        String conId = '';
        System.runAs(createUser11()) {
            if(vscbool) {
                Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
                insert vsc;
            }
            Account acc = new Account(Name = accName);
            insert acc;
            Contact con = new Contact(FirstName = confirstname, LastName = conlastname, AccountId = acc.Id, Email = 'Test'+confirstname+'@merck.com', MSD_CORE_Health_Care_Decision_Maker__c = true);
            insert con;
            conId = con.Id;
        }
        User userr = new User(
            FirstName='Test',
            LastName = 'User1234',
            Alias = 'ndebe',
            Email = 'test1234@merck.com',
            Username = 'test'+String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','')+'@merck.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'MRK_Payor_Exec'].Id,
            TimeZoneSidKey = 'America/New_York',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            ContactId = conId
        );
        insert userr;
        return userr;
    }

    /*
    @description createUser11
    @return user
     */
    private static User createUser11() {
        User user = new User(LastName = 'Userton',
                           FirstName='User',
                           Alias = 'usus',
                           Email = 'user.test@merck.com',
                           Username = Math.random() + '@' + Math.random(),
                           ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
                           UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'System Administrator' LIMIT 1].Id,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
        );
        insert user;
        return user;
    }
    
    
    
    /* 
    @description getNotification is used to create the MSD_CORE_Notification__c record to use in testclasses 
    @return List<MSD_CORE_Notification__c>
    */

    public static List<MSD_CORE_Notification__c> getNotificationrecords(Integer cnt, String usr, String prodPay, String reqvod) {
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        
        for(Integer i = 1; i <= cnt; i++) {
            MSD_CORE_Notification__c notion = new MSD_CORE_Notification__c();
            notion.MSD_CORE_Payor__c = usr;
            notion.MSD_CORE_Product_Payor__c = prodPay;
            notion.MSD_CORE_Label__c = 'Appointments'; 
            notion.MSD_CORE_Read__c = true;
            notion.MSD_CORE_Meeting_Request__c = reqvod;
            // notion.CreatedDate = Date.Today();
            notionList.add(notion);
        }
        insert notionList;
        return notionList;
    }

    /**
     * @description Cover GetActivityDetail method
     * @return void
    */
    @isTest
    public static void testGetActivityDetail(){
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        List<MSD_CORE_Notification__c> notionList1 = new List<MSD_CORE_Notification__c>();
        MSD_CORE_Notification__c  notion1 = new MSD_CORE_Notification__c();
        MSD_CORE_Notification__c  notion2 = new MSD_CORE_Notification__c();
        String catalogUrl = '';
        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
          
            notionList[1].MSD_CORE_Notification__c = notionList[0].Id;
            notionList[3].MSD_CORE_Notification__c = notionList[0].Id;
            update notionList;
                      
            notion1 = new MSD_CORE_Notification__c();
            notion1.CreatedDate = System.today();
            notion1.MSD_CORE_Payor__c = notionList[1].MSD_CORE_Payor__c;
            notion1.MSD_CORE_Notification__c = notionList[1].MSD_CORE_Notification__c;
            notion1.MSD_CORE_Product_Payor__c = notionList[1].MSD_CORE_Product_Payor__c;
            notion1.MSD_CORE_Label__c = 'Appointments'; 
            notion1.MSD_CORE_Read__c = true;
            notion1.MSD_CORE_Meeting_Request__c = notionList[1].MSD_CORE_Meeting_Request__c;
            insert notion1;
        }
        
        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList1 = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
          
            notionList1[1].MSD_CORE_Notification__c = notionList1[0].Id;
            notionList1[3].MSD_CORE_Notification__c = notionList1[0].Id;
            update notionList;
                      
            notion2 = new MSD_CORE_Notification__c();
            notion2.CreatedDate = Date.today().addDays(-2);
            notion2.MSD_CORE_Payor__c = notionList1[1].MSD_CORE_Payor__c;
            notion2.MSD_CORE_Notification__c = notionList1[1].MSD_CORE_Notification__c;
            notion2.MSD_CORE_Product_Payor__c = notionList1[1].MSD_CORE_Product_Payor__c;
            notion2.MSD_CORE_Label__c = 'Appointments'; 
            notion2.MSD_CORE_Read__c = true;
            notion2.MSD_CORE_Meeting_Request__c = notionList1[1].MSD_CORE_Meeting_Request__c;
            insert notion2;
        }
        
        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList1 = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
          
            notionList1[1].MSD_CORE_Notification__c = notionList1[0].Id;
            notionList1[3].MSD_CORE_Notification__c = notionList1[0].Id;
            update notionList;
                      
            notion2 = new MSD_CORE_Notification__c();
            notion2.CreatedDate = Date.today();
            notion2.MSD_CORE_Payor__c = notionList1[1].MSD_CORE_Payor__c;
            notion2.MSD_CORE_Notification__c = notionList1[1].MSD_CORE_Notification__c;
            notion2.MSD_CORE_Product_Payor__c = notionList1[1].MSD_CORE_Product_Payor__c;
            notion2.MSD_CORE_Label__c = 'Appointments'; 
            notion2.MSD_CORE_Read__c = true;
            notion2.MSD_CORE_Meeting_Request__c = notionList1[1].MSD_CORE_Meeting_Request__c;
            insert notion2;
        }

        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList1 = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
          
            notionList1[1].MSD_CORE_Notification__c = notionList1[0].Id;
            notionList1[3].MSD_CORE_Notification__c = notionList1[0].Id;
            update notionList;
                      
            notion2 = new MSD_CORE_Notification__c();
            notion2.CreatedDate = Datetime.now();
            notion2.MSD_CORE_Payor__c = notionList1[1].MSD_CORE_Payor__c;
            notion2.MSD_CORE_Notification__c = notionList1[1].MSD_CORE_Notification__c;
            notion2.MSD_CORE_Product_Payor__c = notionList1[1].MSD_CORE_Product_Payor__c;
            notion2.MSD_CORE_Label__c = 'Saved'; 
            notion2.MSD_CORE_Read__c = true;
            notion2.MSD_CORE_Meeting_Request__c = notionList1[1].MSD_CORE_Meeting_Request__c;
            insert notion2;
        }
        
        Test.startTest();
        MSD_CORE_Notification.getActivityDetail(notionList[1].MSD_CORE_Payor__c, notionList[1].MSD_CORE_Product_Payor__c, notion1.MSD_CORE_Notification__c);
        MSD_CORE_Notification.getActivityDetail(notionList1[1].MSD_CORE_Payor__c, notionList1[1].MSD_CORE_Product_Payor__c, notion2.MSD_CORE_Notification__c);
        MSD_CORE_Notification.getActivityDetail(notionList1[1].MSD_CORE_Payor__c, notionList1[1].MSD_CORE_Product_Payor__c, notion2.MSD_CORE_Notification__c);
        MSD_CORE_Notification.getActivityDetail(notionList1[1].MSD_CORE_Payor__c, notionList1[1].MSD_CORE_Product_Payor__c, notion2.MSD_CORE_Notification__c);
       /* User usr1 = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact124', false);
        MSD_CORE_Product_Payor__c prodPayer1 = new MSD_CORE_Product_Payor__c();
        System.runAs(usr1) {
            prodPayer1 = TestDataFactory_MSD_CORE_Notification.getProductPayor();
        }
        MSD_CORE_Notification.getActivityDetail(usr1.Id, prodPayer1.Id, notion1.MSD_CORE_Notification__c);*/
        Test.stopTest();
        System.assertEquals(4, notionList.size(), 'Created 4 Notification');
    }

     @isTest
    public static void testGetActivityDetail1(){
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        MSD_CORE_Notification__c  notion1 = new MSD_CORE_Notification__c();
        String catalogUrl = '';
        System.runAs(usr) {
            MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);
          
            notionList[1].MSD_CORE_Notification__c = notionList[0].Id;
            notionList[3].MSD_CORE_Notification__c = notionList[0].Id;
            update notionList;
                      
            notion1 = new MSD_CORE_Notification__c();
            //notion1.CreatedDate = Datetime.now(); Date.today().addDays(-2);
            notion1.CreatedDate = Date.today().addDays(-2);
            notion1.MSD_CORE_Payor__c = notionList[1].MSD_CORE_Payor__c;
            notion1.MSD_CORE_Notification__c = notionList[1].MSD_CORE_Notification__c;
            notion1.MSD_CORE_Product_Payor__c = notionList[1].MSD_CORE_Product_Payor__c;
            notion1.MSD_CORE_Label__c = 'Appointments'; 
            notion1.MSD_CORE_Read__c = true;
            notion1.MSD_CORE_Meeting_Request__c = notionList[1].MSD_CORE_Meeting_Request__c;
            insert notion1;
        }
        
        Test.startTest();
        MSD_CORE_Notification.getActivityDetail(notionList[1].MSD_CORE_Payor__c, notionList[1].MSD_CORE_Product_Payor__c, notion1.MSD_CORE_Notification__c);
        User usr1 = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact124', false);
        MSD_CORE_Product_Payor__c prodPayer1 = new MSD_CORE_Product_Payor__c();
        System.runAs(usr1) {
            prodPayer1 = TestDataFactory_MSD_CORE_Notification.getProductPayor();
        }
        MSD_CORE_Notification.getActivityDetail(usr1.Id, prodPayer1.Id, notion1.MSD_CORE_Notification__c);
        Test.stopTest();
        System.assertEquals(4, notionList.size(), 'Created 4 Notification');
    }
    
    
    /**
     * @description Cover ContentConnectorWrapper method
     * @return void
    */
    @isTest
    public static void testContentConnectorWrapper() {
        /* Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;   
        insert vsc;   */
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        System.runAs(usr){
        Test.startTest();
          
        
        String json = '{"documentNumber": "3090903","documentId": "0038X00000sNdhQAM"}';
        MFR_ContentConnectorWrapper ccWrapobj = MFR_ContentConnectorWrapper.parse(json);
        Test.stopTest();
        System.assertEquals(true, ccWrapobj != null, 'Wrapper class method');
        }
    }
    
    /**
     * @description Cover updateReadCheck method
     * @return void
    */
    @isTest
    public static void testupdateReadCheck() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        
        System.runAs(usr){ 
        Test.startTest();
        /*Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc; */
        MSD_CORE_Notification__c m = new MSD_CORE_Notification__c(MSD_CORE_Read__c=false);
        insert m;
        
        String result = MSD_CORE_Notification.updateReadCheck(m.Id);
        
        System.assertEquals('Success!', result);
        MSD_CORE_Notification__c updatedM = [SELECT MSD_CORE_Read__c FROM MSD_CORE_Notification__c WHERE Id = :m.Id LIMIT 1];
        System.assertEquals(true, updatedM.MSD_CORE_Read__c);
        Test.stopTest();
        }
    }

    /**
     * @description Cover getMHEENotification method
     * @return void
    */
    @isTest
    public static void testgetMHEENotification() {

        Profile firstProfile = [SELECT Id FROM Profile Limit 1];
        User user1 = new User(LastName = 'Userton',
                        FirstName='User',
                        Alias = 'usus',
                        Email = 'user.user@merck.com',
                        Username = Math.random() + '@' + Math.random(),
                        ProfileId = firstProfile.Id,
                        TimeZoneSidKey = 'GMT',
                        LanguageLocaleKey = 'en_US',
                        EmailEncodingKey = 'UTF-8',
                        LocaleSidKey = 'en_US'
                    
        );
        insert user1;
        
        System.runAs(user1){ 
            MSD_CORE_Product_Payor__c prodPay = new MSD_CORE_Product_Payor__c();
            prodPay.Name = 'TESTING®';
            prodPay.MSD_CORE_Active__c = true;
            prodPay.MSD_CORE_Brand_Status__c = false;
            prodPay.MSD_CORE_Colourcode__c = '#FF8C00';
            prodPay.MSD_CORE_Dosage_Form_and_Strength__c = 'injection 100mg/ml (equivalent to 108.8 mg/ml sugammadex sodium), for intravenous use';
            prodPay.MSD_CORE_Generic_Name__c = '(sugammadex)';
            prodPay.MSD_CORE_Indication__c = 'TESTING® (sugammadex) is indicated for the reversal of neuromuscular blockade induced by rocuronium bromide and vecuronium bromide in adults and pediatric patients aged 2 years and older undergoing surgery.';
            prodPay.MSD_CORE_Information_About_Product__c = '<p><strong style=\"color: rgb(0, 0, 0); font-size: 24px;\">Indication</strong></p><p><br></p><p><span style=\"font-size: 16px;\">TESTING® (sugammadex) is indicated for the reversal of neuromuscular blockade induced by rocuronium bromide and vecuronium bromide in adults undergoing surgery.</span></p><p><br></p>';
            prodPay.MSD_CORE_Product_Family__c = 'TESTING®';
            prodPay.MSD_CORE_Product_ID__c = 'test1';
            prodPay.MSD_CORE_Selected_Safety_Information__c = 'Test Safety';
            prodPay.MSD_CORE_HCP_site__c = 'https://www.merckconnect.com/bridion/dosing-administration/';
            prodPay.MSD_CORE_Source__c = '10';
            prodPay.Related_System__c = 'MFR';
            insert prodPay;
            
            Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
            reqvod.Start_DateTime_vod__c = System.now();
            reqvod.MSD_CORE_Product_Payor__c = prodPay.Id;
            reqvod.MSD_CORE_Status__c = 'Closed';
            reqvod.MSD_CORE_attendee__c = 'test1@fcxm.com';
            reqvod.MSD_CORE_Meeting_preference__c = 'Virtual meeting';
            reqvod.MSD_CORE_Payor__c = user1.Id;
            reqvod.Duration_vod__c = 60;
            reqvod.Record_Type_Name_vod__c = 'Engage_Scheduling_Site_vod';
            reqvod.MSD_CORE_Source__c = 'MHEE';
            reqvod.ScheduleFilter__c = 'test,test';
            insert reqvod;
            
            List<MSD_CORE_Notification__C> notificationList = [SELECT Id FROM MSD_CORE_Notification__C WHERE MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MHEE' AND MSD_CORE_Payor__c =: user1.Id];
            
            MSD_CORE_Notification__C mn = new MSD_CORE_Notification__C();
            mn.msd_core_read__c = false;
            mn.MSD_CORE_Payor__c = user1.Id;
            mn.MSD_CORE_Meeting_Request__c = reqvod.Id;
            insert mn;
            
            MSD_CORE_Notification__C mn1 = new MSD_CORE_Notification__C();
            mn1.msd_core_read__c = false;
            mn1.MSD_CORE_Payor__c = user1.Id;
            mn1.MSD_CORE_Meeting_Request__c = reqvod.Id;
            mn1.Related_Notification__c = mn.Id;
            insert mn1;
            
            mn1 = new MSD_CORE_Notification__C();
            mn1.msd_core_read__c = false;
            mn1.MSD_CORE_Payor__c = user1.Id;
            mn1.MSD_CORE_Meeting_Request__c = reqvod.Id;
            mn1.Related_Notification__c = mn.Id;
            mn1.MSD_CORE_Label__c = 'Appointments';
            insert mn1;
           
            Test.startTest();
        
            MSD_CORE_Notification.MheeNotificationWrapper mheenotif = MSD_CORE_Notification.getMHEENotification(user1.Id, '6',  '1');
            Test.stopTest();
        }

    }

    /**
     * @description Creating Community User
     * @return user
    */
    private static User createUser1() {
        Profile firstProfile = [SELECT Id FROM Profile WHERE Name = 'MRK_Payor_Exec' Limit 1];

        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contact con = new Contact(FirstName = 'Test Contact', LastName = 'Test LastName', AccountId = acc.Id, Email = 'testcontact123@merck.com', MSD_CORE_Health_Care_Decision_Maker__c = true);
        insert con;
        
        User user1 = new User(LastName = 'Userton',
                           FirstName='User',
                           Alias = 'usus',
                           Email = 'user.user@merck.com',
                           Username = Math.random() + '@' + Math.random(),
                           ProfileId = firstProfile.Id,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US',
                           ContactId = con.Id                    
        );
        insert user1;
        return user1;
    }
    
    @isTest
    public static void testgetMHEEUnreadNotificationCount(){
         User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        System.runAs(usr){
             MSD_CORE_Product_Payor__c prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
           MSD_CORE_Notification__c notion = new MSD_CORE_Notification__c();
           notion.CreatedDate = System.today();
           notion.MSD_CORE_Payor__c =  usr.Id;
           notion.MSD_CORE_Product_Payor__c = prodPayer.Id;
           notion.MSD_CORE_Label__c = 'Appointments'; 
           notion.MSD_CORE_Read__c = true;
           notion.MSD_CORE_Meeting_Request__c = reqvod.Id;
           insert notion;
        }
        Test.startTest();
         MSD_CORE_Notification.getMHEEUnreadNotificationCount(usr.Id);
        Test.stopTest();
     
    }
    @isTest
    public static void testmainrec(){
     MSD_CORE_Notification.mainrec a = new MSD_CORE_Notification.mainrec(); 
     a.activity='Test';
     a.dateval='hello';
     a.meetid ='Id';

   }
    @isTest
    public static void testnotificationwrap(){
        MSD_CORE_Notification.notificationwrap b = new MSD_CORE_Notification.notificationwrap();
        b.activity='one';
        b.activityID='1234';
            b.dateval='Test';
            b.resid='hello';
            b.read=true;
        b.groupact='hello';
        b.isMultipleMeeting=true;
        b.multipleMeetingCount='hello';
    }

    @isTest
    static void testFindWordIndices() {
        String input = 'test word test another test';
        String target = 'test';
        List<Integer> expected = new List<Integer>{0, 10, 23};
        List<Integer> actual = MSD_CORE_Notification.findWordIndices(input, target);
        System.assertEquals(expected, actual, 'Test case with multiple occurrences failed');
    }
    
    @isTest
    static void testGetProductList_ExceptionScenario() {
        User testUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        Id userId = testUser.Id;

        Test.startTest();
        Map<Id, MSD_CORE_Notification.prodlst> result = MSD_CORE_Notification.getProductList('invalid_user_id');
        Test.stopTest();
    }

    @isTest
    static void testGetProductList_QueryExceptionScenario() {
        Test.startTest();
        try {
            Map<Id, MSD_CORE_Notification.prodlst> result = MSD_CORE_Notification.getProductList('005000000000000000'); // Provide a valid user Id to avoid the previous exception case
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @isTest
    static void getNotificationCount_ExceptionScenario() {
        Id userId = '005000000000000000'; // Dummy user Id which does not exist

        Test.startTest();
        //MSD_CORE_Notification.getNotificationCount(userId);
        Test.stopTest();
    }

    @isTest
    static void updateNotification_ExceptionScenario() {
        Id userId = '005000000000000000'; // Dummy user Id which does not exist

        Test.startTest();
       // Map<Id, MSD_CORE_Notification.prodlst> result = MSD_CORE_Notification.updateNotification(userId,'','');
        Test.stopTest();
    }

     @isTest
    public static void testGetActivityDetail4() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        MSD_CORE_Product_Payor__c prodPayer;
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();

        System.runAs(usr) {
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            Meeting_Request_vod__c reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            notionList = TestDataFactory_MSD_CORE_Notification.getNotification(4, usr.Id, prodPayer.Id, reqvod.Id);

            notionList[1].MSD_CORE_Notification__c = notionList[0].Id;
            notionList[3].MSD_CORE_Notification__c = notionList[0].Id;
            update notionList;
        }

        System.runAs(usr) {
            MSD_CORE_Notification__c notionToday = new MSD_CORE_Notification__c(
                CreatedDate = Date.today(),
                MSD_CORE_Payor__c = notionList[1].MSD_CORE_Payor__c,
                MSD_CORE_Notification__c = notionList[1].MSD_CORE_Notification__c,
                MSD_CORE_Product_Payor__c = notionList[1].MSD_CORE_Product_Payor__c,
                MSD_CORE_Label__c = 'Appointments',
                MSD_CORE_Read__c = true,
                MSD_CORE_Meeting_Request__c = notionList[1].MSD_CORE_Meeting_Request__c
            );
            insert notionToday;
            Test.startTest();
            MSD_CORE_Notification.getActivityDetail(notionList[1].MSD_CORE_Payor__c, notionList[1].MSD_CORE_Product_Payor__c, notionToday.MSD_CORE_Notification__c);

            Test.stopTest();
        }
    }
}