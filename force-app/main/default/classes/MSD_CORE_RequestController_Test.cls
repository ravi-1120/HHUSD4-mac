/**
 * Component Name:      MSD_CORE_RequestController_Test
 * Created By:          Focal CXM
 * @description:        Used for MSD_CORE_RequestController
 * Class Type:          Test
 */
@isTest
public with sharing class MSD_CORE_RequestController_Test {

    /**
     * @description: Cover test_getRequest method
     * @return; void
    */
    @isTest
    public static void test_getRequest() {
        String requestType1 = 'Activity';
        String requestType2 = 'Rejected';
        String requestType3 = 'Pending';
        String pageSize = '5';
        String pageNumber = '1';
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        System.runAs(usr) {
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            reqvod.MSD_CORE_Status__c = 'Pending';
            update reqvod;
        }
        Test.startTest();
        List<Meeting_Request_vod__c> reqlst1 = MSD_CORE_RequestController.getRequest(requestType1, pageSize, pageNumber, prodPayer.Id, usr.Id);
        List<Meeting_Request_vod__c> reqlst2 = MSD_CORE_RequestController.getRequest(requestType2, pageSize, pageNumber, prodPayer.Id, usr.Id);
        List<Meeting_Request_vod__c> reqlst3 = MSD_CORE_RequestController.getRequest(requestType3, pageSize, pageNumber, prodPayer.Id, usr.Id);
        Test.stopTest();
        System.assertEquals(false, reqlst3.size() > 0, 'List contains Request data');
    }

    /**
     * @description: Cover test_getRequestsCount method
     * @return; void
    */
    @isTest
    public static void test_getRequestsCount() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        System.runAs(usr) {
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
        }
        Test.startTest();
        List<Meeting_Request_vod__c> reqlst = MSD_CORE_RequestController.getRequestsCount(prodPayer.Id, usr.Id);
        Test.stopTest();
        //System.assertEquals(true, reqlst.size() > 0, 'Request Data List');
    }

    /**
     * @description: Cover test_getmeetingname method
     * @return; void
    */
    @isTest
    public static void test_getmeetingname() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        System.runAs(usr) {
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
        }
        Test.startTest();
        Meeting_Request_vod__c meetingName = MSD_CORE_RequestController.getmeetingname(String.valueof(reqvod.Id));
        Meeting_Request_vod__c meetingName1 = MSD_CORE_RequestController.getmeetingname('');
        Test.stopTest();
        System.assertEquals(true, (meetingName != null), 'Request Data List');
    }

    /**
     * @description: Cover test_updatestatus method
     * @return; void
    */
    @isTest
    public static void test_updatestatus() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        String statusupdate = '';
        System.runAs(usr) {
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            Test.startTest();
            statusupdate = MSD_CORE_RequestController.updatestatus(reqvod.Id);
            MSD_CORE_RequestController.updatestatus('');
            Test.stopTest();
        }
        System.assertEquals('Success', statusupdate, 'Status updated');
    }

    /**
     * @description: Cover getupcomingappointmentsTest method
     * @return; void
    */
    @isTest
    public static void getupcomingappointmentsTest () {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        System.runAs(usr) {
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            reqvod.MSD_CORE_Status__c = 'Approved';
            reqvod.MSD_CORE_Source__c ='MHEE';  
            reqvod.Start_DateTime_vod__c = Date.today().addDays(+1);
            reqvod.Assignee_vod__c = usr.Id;
            update reqvod; 
        }
        Test.startTest();
        List<Meeting_Request_vod__c> reqlst1 = MSD_CORE_RequestController.getupcomingappointments();
        Test.stopTest();
        System.assertEquals(false, reqlst1.size() > 0, 'List contains Request data');
    }

    /**
     * @description: Cover getActiveRequestsTestmethd method
     * @return; void
    */ 
    @isTest
    public static void getActiveRequestsTestmethd () {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvodact = new Meeting_Request_vod__c();
        System.runAs(usr) {  
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvodact = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            reqvodact.MSD_CORE_Status__c = 'pending';
            reqvodact.MSD_CORE_Source__c ='MHEE';  
            update reqvodact; 
        }
        Test.startTest();
        List<Meeting_Request_vod__c> reqvodact1 = MSD_CORE_RequestController.getActiveRequestsTest();
        Test.stopTest();
        System.assertEquals(false, reqvodact1.size() > 0, 'List contains Request data');
    }

    /**
     * @description: Cover getMHEERequestsCountTest method
     * @return; void
    */
    @isTest
    public static void getMHEERequestsCountTest () {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvodact = new Meeting_Request_vod__c();
        System.runAs(usr) {   
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvodact = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            reqvodact.MSD_CORE_Status__c = 'pending';
            reqvodact.MSD_CORE_Source__c ='MHEE';  
            update reqvodact; 
        }
        Test.startTest();
        List<Meeting_Request_vod__c> reqvodact1 = MSD_CORE_RequestController.getMHEERequestsCount(usr.Id);
        Test.stopTest();
        System.assertEquals(true, reqvodact1.size() > 0, 'List contains Request data');
    }

    /**
     * @description: Cover test_getMHHERequestWithClosedStatus method
     * @return; void
    */
    @isTest
    public static void test_getMHHERequestWithClosedStatus() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        String requestType = 'Closed';
        String pageSize ='6';
        String pageNumber ='1';
        String sortBy='Name';
        String searchFilter = 'test';
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        System.runAs(usr) { 
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            reqvod.MSD_CORE_Status__c = 'Closed';
            reqvod.MSD_CORE_Source__c ='MHEE';  
            reqvod.Start_DateTime_vod__c = Date.today().addDays(+1);
            reqvod.Assignee_vod__c = usr.Id;
            update reqvod; 
        }
        Test.startTest();
  	   	MSD_CORE_RequestController.RequestWrapper reqWrapperObj = MSD_CORE_RequestController.getMHHERequest(requestType,pageSize,pageNumber,prodPayer.Id,sortBy,searchFilter);
        Test.stopTest();
        //System.assertEquals(true, reqlst.size() < 0, 'Request Data List');
    }

    /**
     * @description: Cover test_getMHHERequestWithPendingStatus method
     * @return; void
    */
    @isTest
    public static void test_getMHHERequestWithPendingStatus() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        String requestType = 'Pending';
        String pageSize ='6';
        String pageNumber ='1';
        String sortBy='';
        String searchFilter = '';
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        System.runAs(usr) {  
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            reqvod.MSD_CORE_Status__c = 'Pending';
            reqvod.MSD_CORE_Source__c ='MHEE';  
            reqvod.Start_DateTime_vod__c = Date.today().addDays(+1);
            reqvod.Assignee_vod__c = usr.Id;
            update reqvod; 
        }
        Test.startTest(); 
  	   	MSD_CORE_RequestController.RequestWrapper reqWrapperObj = MSD_CORE_RequestController.getMHHERequest(requestType,pageSize,pageNumber,prodPayer.Id,sortBy,searchFilter);
        Test.stopTest();
        //System.assertEquals(true, reqlst.size() > 0, 'Request Data List');
    }

    /**
     * @description: Cover test_getMHHERequestWithApprovedStatus method
     * @return; void
    */
    @isTest
    public static void test_getMHHERequestWithApprovedStatus() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        String requestType = 'Approved';
        String pageSize ='6';
        String pageNumber ='1';
        String sortBy='';
        String searchFilter = '';
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        System.runAs(usr) {
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            reqvod.MSD_CORE_Status__c = 'Approved';
            reqvod.MSD_CORE_Source__c ='MHEE';  
            reqvod.Start_DateTime_vod__c = Date.today().addDays(+1);
            reqvod.Assignee_vod__c = usr.Id;
            update reqvod; 
        }
        Test.startTest();
  	   	MSD_CORE_RequestController.RequestWrapper reqWrapperObj = MSD_CORE_RequestController.getMHHERequest(requestType,pageSize,pageNumber,prodPayer.Id,sortBy,searchFilter);
        Test.stopTest();
        //System.assertEquals(true, reqlst.size() > 0, 'Request Data List');
    }

    /**
     * @description: Cover test_getMHHERequestWithKeySearch method
     * @return; void
    */
    @isTest
    public static void test_getMHHERequestWithKeySearch() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        String requestType = 'Closed';
        String pageSize ='6';
        String pageNumber ='1';
        String sortBy='CreatedDate';
        String searchFilter = '';
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        System.runAs(usr) {    
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            reqvod.MSD_CORE_Status__c = 'Closed';
            reqvod.MSD_CORE_Source__c ='MHEE';  
            reqvod.Start_DateTime_vod__c = Date.today().addDays(+1);
            reqvod.Assignee_vod__c = usr.Id;
            update reqvod; 
        }
         searchFilter = reqvod.MHEE_Name__c;
        Test.startTest(); 
  	   	MSD_CORE_RequestController.RequestWrapper reqWrapperObj = MSD_CORE_RequestController.getMHHERequest(requestType,pageSize,pageNumber,prodPayer.Id,sortBy,searchFilter);
        Test.stopTest();
        //System.assertEquals(true, reqlst.size() > 0, 'Request Data List');
    }

    /**
     * @description: Cover test_getMHHERequestWithKeyNoData method
     * @return; void
    */
    @isTest
    public static void test_getMHHERequestWithKeyNoData() {
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        String requestType = 'Closed';
        String pageSize ='6';
        String pageNumber ='1';
        String sortBy='CreatedDate';
     	String searchFilter = '';
        MSD_CORE_Product_Payor__c prodPayer = new MSD_CORE_Product_Payor__c();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        String meetname = '';
        System.runAs(usr) {    
            prodPayer = TestDataFactory_MSD_CORE_Notification.getProductPayor();
            reqvod = TestDataFactory_MSD_CORE_Notification.getMeetingReq(prodPayer.Id, usr.Id);
            reqvod.MSD_CORE_Status__c = 'Closed';
            reqvod.MSD_CORE_Source__c ='MHEE';  
            reqvod.Start_DateTime_vod__c = Date.today().addDays(+1);
            reqvod.Assignee_vod__c = usr.Id;
            reqvod.MSD_CORE_Payor__c = usr.Id;
            update reqvod; 
            meetname = reqvod.MHEE_Name__c;
        }
         searchFilter = meetname;
         System.debug(LoggingLevel.WARN,'reqvod-->'+reqvod);
        Test.startTest();
  	   	MSD_CORE_RequestController.RequestWrapper reqWrapperObj = MSD_CORE_RequestController.getMHHERequest(requestType,pageSize,pageNumber,prodPayer.Id,sortBy,searchFilter);
        Test.stopTest();
        //System.assertEquals(true, reqlst.size() > 0, 'Request Data List');
    }
        
}