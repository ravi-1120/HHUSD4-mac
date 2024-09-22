@isTest
public class TestDataFactory_MSD_CORE_Notification {
    /*
    @description getCommunityUser is used to create a community user to use in test classes
    @return user
     */
    public static User getCommunityUser(String accName, String confirstname, String conlastname, Boolean vscbool) {
        String conId = '';
        System.runAs(createUser()) {
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
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            ContactId = conId
        );
        insert userr;
        return userr;
    }

    public static User createUser() {
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
@description getProductPayor is used to create the MSD_CORE_Product_Payor__c record to use in testclasses 
@return MSD_CORE_Product_Payor__c
*/
    public static MSD_CORE_Product_Payor__c getProductPayor() {
        MSD_CORE_Product_Payor__c prodPay = new MSD_CORE_Product_Payor__c();
        prodPay.Name = 'TESTING®';
        prodPay.MSD_CORE_Active__c = true;
        prodPay.MSD_CORE_Product_Family__c = 'TESTING®';
        prodPay.MSD_CORE_Product_ID__c = 'test1';
        prodPay.MSD_CORE_Selected_Safety_Information__c = 'Test Safety';
        prodPay.MSD_CORE_Source__c = '10';
        prodPay.MSD_CORE_Colourcode__c = '#FFFFFF';
        prodPay.Related_System__c = 'MFR';
        insert prodPay;
        return prodPay;
    }

/* 
@description getMeetingReq is used to create the Meeting_Request_vod__c record to use in testclasses 
@return Meeting_Request_vod__c
*/

    public static Meeting_Request_vod__c getMeetingReq(String prodPay, String usr) {
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        reqvod.Start_DateTime_vod__c = System.now();
        reqvod.MSD_CORE_Product_Payor__c = prodPay;
        reqvod.MSD_CORE_Status__c = 'Closed';
        reqvod.MSD_CORE_attendee__c = 'test1@fcxm.com';
        reqvod.MSD_CORE_Meeting_preference__c = 'Virtual meeting';
        reqvod.MSD_CORE_Payor__c = usr;
        reqvod.Duration_vod__c = 60;
        reqvod.Record_Type_Name_vod__c = 'Engage_Scheduling_Site_vod';
        insert reqvod;
        return reqvod;
    }

/* 
@description getMeetingReqWithAppointmentMFR is used to create the Meeting_Request_vod__c record to use in testclasses 
@return Meeting_Request_vod__c
*/

     public static Meeting_Request_vod__c getMeetingReqWithAppointmentMFR(String prodPay, String usr) {
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        reqvod.Start_DateTime_vod__c = System.now();
        reqvod.MSD_CORE_Product_Payor__c = prodPay;
        reqvod.MSD_CORE_Status__c = 'Approved';
        reqvod.MSD_CORE_Source__c='MFR';
        reqvod.MSD_CORE_attendee__c = 'test1@fcxm.com';
        reqvod.MSD_CORE_Meeting_preference__c = 'Virtual meeting';
        reqvod.MSD_CORE_Payor__c = usr;
        reqvod.Duration_vod__c = 60;
        reqvod.Record_Type_Name_vod__c = 'Engage_Scheduling_Site_vod';
        insert reqvod;
        return reqvod;
    }

    /* 
    @description getNotification is used to create the MSD_CORE_Notification__c record to use in testclasses 
    @return List<MSD_CORE_Notification__c>
    */

    public static List<MSD_CORE_Notification__c> getNotification(Integer cnt, String usr, String prodPay, String reqvod) {
        List<MSD_CORE_Notification__c> notionList = new List<MSD_CORE_Notification__c>();
        
        for(Integer i = 1; i <= cnt; i++) {
            MSD_CORE_Notification__c notion = new MSD_CORE_Notification__c();
            notion.MSD_CORE_Payor__c = usr;
            notion.MSD_CORE_Product_Payor__c = prodPay;
            notion.MSD_CORE_Label__c = 'Appointments'; 
            notion.MSD_CORE_Read__c = true;
            notion.MSD_CORE_Meeting_Request__c = reqvod;
            notion.MSD_CORE_Activity__c= 'Test';
            notionList.add(notion);
        }
        insert notionList;
        return notionList;
    }     
}