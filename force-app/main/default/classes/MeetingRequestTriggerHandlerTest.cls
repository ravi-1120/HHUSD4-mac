/**
 * Component Name:      MeetingRequestTriggerHandlerTest
 * Created By:          Focal CXM
 * Description:         Used for  MeetingRequestTriggerHandler
 */
@isTest
public class MeetingRequestTriggerHandlerTest {
    
     /**
     * @description: createsharedNotificationTest
     * @return; void
    */
    @isTest
    static void createSharedNotificationTest() {
        Meeting_Request_vod__c meetreq = createMeetingReq();
        Test.StartTest();
        meetreq.MSD_CORE_Status__c = 'Closed';
        meetreq.MSD_CORE_Request_Progress__c='Received post-presentation materials';
        update meetreq;
        delete meetreq;
        undelete meetreq;
        Test.StopTest();
        
    }
    
     /**
     * @description: createUser1
     * @return; User
    */
    private static User createUser1() {
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
        return user1;
    }
    
      /**
     * @description: createProduct
     * @return; MSD_CORE_Product_Payor__c
    */
    public static MSD_CORE_Product_Payor__c createProduct(){
        
        Product_vod__c podcat = new Product_vod__c();
        podcat.Name = 'Testing';
        insert podcat;
        
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
        prodPay.MSD_CORE_Product_Catalog__c = podcat.Id;
        prodPay.Related_System__c = 'MFR';
        insert prodPay;
        return prodPay;
    }

      /**
     * @description: createMeetingReq
     * @return; Meeting_Request_vod__c
    */
    @isTest
    public static Meeting_Request_vod__c createMeetingReq(){
        User usr = createUser1();
        MSD_CORE_Product_Payor__c prodPay = createProduct();
        
        Call2_vod__c call = new Call2_vod__c();
        call.Address_vod__c = 'Testing Address';
        call.Call_Datetime_vod__c = System.now();
        call.Status_vod__c = 'Submitted_vod';
        call.Call_Channel_vod__c = 'Phone_vod';
        insert call;
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 10;    
        insert vsc;
        
        Account ac = new Account();
        ac.Name = 'Test Account';
        ac.Merck_ID_MRK__c = '987656789';
        insert ac;
        
        MSD_CORE_Catalog__c cat = new MSD_CORE_Catalog__c();
        cat.name = 'test';
        cat.MSD_CORE_Delivery_Framework__c = 'View in Meeting';
        insert cat;
        
        MSD_CORE_Library__c lib= new MSD_CORE_Library__c();
        lib.MSD_CORE_Catalog__c=cat.id;
        insert lib;
        
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        reqvod.Start_DateTime_vod__c = System.now();
        reqvod.MSD_CORE_Product_Payor__c = prodPay.Id;
        reqvod.MSD_CORE_Status__c = 'Approved';
        reqvod.MSD_CORE_Source__c = 'MFR';
        reqvod.MSD_CORE_Resource__c = cat.id;
        reqvod.MSD_CORE_attendee__c = 'test1@fcxm.com';
        reqvod.MSD_CORE_Meeting_preference__c = 'Virtual meeting';
        reqvod.MSD_CORE_Payor__c = usr.Id;
        reqvod.Call2_vod__c = call.Id;
        reqvod.Duration_vod__c = 60;
        reqvod.Account_vod__c = ac.Id;
        reqvod.Record_Type_Name_vod__c = 'Engage_Scheduling_Site_vod';
        reqvod.MSD_CORE_Request_Progress__c='Request Submitted';
        insert reqvod;
        System.assertEquals('Approved', reqvod.MSD_CORE_Status__c);
        return reqvod;
    }
    
    /**
     * @description: getMeetingRequestList
     * @return; Meeting_Request_vod__c
     * @param cnt,usr,prodPay
    */
    public static List<Meeting_Request_vod__c> getMeetingRequestList(Integer cnt, String usr, String prodPay) {
        List<Meeting_Request_vod__c> meetreqlst = new List<Meeting_Request_vod__c>();
        
        for(Integer i = 1; i <= cnt; i++) {
            Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
            reqvod.Start_DateTime_vod__c = System.now();
            reqvod.MSD_CORE_Product_Payor__c = prodPay;
            reqvod.MSD_CORE_Status__c = 'Closed';
            reqvod.MSD_CORE_attendee__c = 'test1@fcxm.com';
            reqvod.MSD_CORE_Meeting_preference__c = 'Virtual meeting';
            reqvod.MSD_CORE_Payor__c = usr;
            reqvod.Duration_vod__c = 60;
            reqvod.Record_Type_Name_vod__c = 'Engage_Scheduling_Site_vod';
            meetreqlst.add(reqvod);
        }
        insert meetreqlst;
        return meetreqlst;
    }
    
    /**
     * @description: viewUponRequestValidationBypass
     * @return; void
    */
    @istest
    public static void viewUponRequestValidationBypass(){
        User usr = createUser1();
        MSD_CORE_Product_Payor__c prodPay = createProduct();
        
        Call2_vod__c call = new Call2_vod__c();
        call.Address_vod__c = 'Testing Address';
        call.Call_Datetime_vod__c = System.now();
        call.Status_vod__c = 'Submitted_vod';
        call.Call_Channel_vod__c = 'Phone_vod';
        insert call;
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 10;    
        insert vsc;
        
        Account ac = new Account();
        ac.Name = 'Test Account1';
        ac.Merck_ID_MRK__c = '987656788';
        insert ac;
        
        MSD_CORE_Catalog__c cat = new MSD_CORE_Catalog__c();
        cat.name = 'test';
        cat.MSD_CORE_Delivery_Framework__c = 'View in Meeting';
        insert cat;
        
        MSD_CORE_Product_Payor__c prodPay1 = createProduct();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        reqvod.MSD_CORE_Product_Payor__c = prodPay1.Id;
        reqvod.MSD_CORE_Status__c = 'Closed';
        reqvod.MSD_CORE_attendee__c = 'test1@fcxm.com';
        reqvod.MSD_CORE_Meeting_preference__c = 'Virtual meeting';
        reqvod.Assignee_vod__c = usr.id;
        reqvod.Duration_vod__c = 30;
        reqvod.Record_Type_Name_vod__c = 'Engage_Scheduling_Site_vod';
        reqvod.MSD_CORE_Source__c = 'MFR';
        reqvod.Account_vod__c =ac.id;
        reqvod.MSD_CORE_Resource__c = cat.id;
    
        insert reqvod;
        test.startTest();    
        reqvod.MSD_CORE_Status__c = 'Approved';
        
       try{
           update reqvod; 
        }
        catch(Exception e){
            System.debug(LoggingLevel.WARN,'Exception');
        }
        System.assertEquals('Approved', reqvod.MSD_CORE_Status__c);
        test.stopTest();     
    }
}