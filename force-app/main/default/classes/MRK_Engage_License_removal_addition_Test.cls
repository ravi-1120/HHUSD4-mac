@isTest(seeAllData=true)
public class MRK_Engage_License_removal_addition_Test {

Static testmethod void test1(){

try{
    User adminUser = [SELECT Id,Name FROM User WHERE Id =: UserInfo.getUserId()];
System.runAs(adminUser){
    //insert user to test
    Profile profile=[Select id from Profile where Name='MRK - Sales Representative' LIMIT 1];
    User inactiveUser = new User(
        FirstName='test',
        LastName='inactiveuser',
        Email='testinactiveuser@merck.com',
        UserName='testinactiveuser@merck.com',
        Alias='TIU',
        ProfileId=profile.Id,
        IsActive=False,
        TimeZoneSidKey='America/New_York', 
        LocaleSidKey='en_US', 
        EmailEncodingKey='ISO-8859-1', 
        LanguageLocaleKey='en_US',
        Engage_Group_Request_vod__c ='Offline and Online Users No Desktop Sharing',
        Engage_Group_Provisioning_Status_vod__c='Retry_Request_vod'
    );
    insert inactiveuser;
        
        System.Debug('^^^^^User^inactiveuser*****'+inactiveuser.Engage_Group_Request_vod__c);
    
    Profile medprofile=[Select id from Profile where Name='MRK - HS Medical User' LIMIT 1];
    User activemedUser = new User(
        FirstName='test',
        LastName='activeuser',
        Email='testactivemeduser@merck.com',
        UserName='testactivemeduser@merck.com',
        Alias='TAU',
        ProfileId=medprofile.Id,
        IsActive=True,
        TimeZoneSidKey='America/New_York', 
        LocaleSidKey='en_US', 
        EmailEncodingKey='ISO-8859-1', 
        LanguageLocaleKey='en_US'
        
        
    );
    insert activemedUser;
        System.Debug('^^^^^User^activemedUser*****'+activemedUser.Engage_Group_Request_vod__c);
    
    Profile salesprofile=[Select id from Profile where Name ='MRK - Sales Representative' LIMIT 1];
    User activeSalesUser = new User(
        FirstName='test',
        LastName='activeuser',
        Email='testactivesalesuser@merck.com',
        UserName='testactivesalesuser@merck.com',
        Alias='TAU',
        ProfileId=salesprofile.Id,
        IsActive=True,
        TimeZoneSidKey='America/New_York', 
        LocaleSidKey='en_US', 
        EmailEncodingKey='ISO-8859-1', 
        LanguageLocaleKey='en_US'
        
    );
    insert activeSalesUser;
			System.Debug('^^^^^User^activeSalesUser*****'+activeSalesUser.Engage_Group_Request_vod__c);
    
    System.Debug('inactiveuser ID *****'+inactiveuser.Id);
    	System.Debug('activeSalesUser ID*****'+activeSalesUser.Id);
    	System.Debug('activemedUser ID*****'+activemedUser.Id);
    
       String CRON_EXP = '0 2 0 * * ? 2024';

    
     // MRK_Engage_License_removal_addition
     
		MRK_Engage_License_removal_addition UpdateUser = new MRK_Engage_License_removal_addition();
     System.Debug('^^^^^MRK_Engage_License_removal_addition*****'+UpdateUser);
       String jobId = System.schedule('Engage License Removal Addtion', CRON_EXP, UpdateUser);
    
       Test.startTest();
         CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    
			System.assertEquals(CRON_EXP, ct.CronExpression);
        System.Debug('inactiveuser After *****'+inactiveuser.Engage_Group_Request_vod__c);
    	System.Debug('activeSalesUser After*****'+activeSalesUser.Engage_Group_Request_vod__c);
    	System.Debug('activemedUser After*****'+activemedUser.Engage_Group_Request_vod__c);
    
    
      //  User inactUser = [SELECT Id, Name, Engage_Group_Provisioning_Status_vod__c, Engage_Group_Request_vod__c, Engage_Group_vod__c, IsActive FROM User WHERE id = :inactiveuser.id];
      //  System.Debug('^^^^^inactUser*****'+inactUser.Engage_Group_Request_vod__c);
      //  System.assertEquals('',inactUser.Engage_Group_Request_vod__c, 'License Not Removed : Inactive User');
                
    /*    User salesUser = [SELECT Id, Name, Engage_Group_Provisioning_Status_vod__c, Engage_Group_Request_vod__c, Engage_Group_vod__c, IsActive FROM User WHERE id = :activeSalesUser.id];
        System.Debug('^^^^^salesUser*****'+salesUser.Engage_Group_Request_vod__c);
        System.assertEquals('Offline and Online Users No Desktop Sharing',salesUser.Engage_Group_Request_vod__c, 'License Not Assigned : Sales User');
        
        User mediUser = [SELECT Id, Name, Engage_Group_Provisioning_Status_vod__c, Engage_Group_Request_vod__c, Engage_Group_vod__c, IsActive FROM User WHERE id = :activemedUser.id];
        System.Debug('^^^^^mediUser*****'+mediUser.Engage_Group_Request_vod__c);
        System.assertEquals('Offline and Online Users',mediUser.Engage_Group_Request_vod__c, 'License Not Assigned : Medical User');
        */
        
        
    Test.stopTest();   }     
    }
    Catch(Exception e){
        System.Debug('^^^^^^^^^^ Error^^^^^'+e.getMessage());
        System.Debug('^^^^^^^^^^ Error^^^^^'+e.getLinenumber());
    }
     }

}