@isTest(seeAllData=true)
public class MRK_PermSet_AutoAssign_Test {

Static testmethod void test1(){

      
    try{
     //insert user to test
    List<Profile> profile=[Select id from Profile where Name='MRK - Sales Representative' LIMIT 1];
    User inactiveUser = new User(
        FirstName='test',
        LastName='inactiveuser',
        Email='testinactiveuser@merck.com',
        UserName='testinactiveuser@merck.com',
        Alias='TIU',
        ProfileId=profile[0].Id,
      	TimeZoneSidKey='America/New_York', 
        LocaleSidKey='en_US', 
        EmailEncodingKey='ISO-8859-1', 
        LanguageLocaleKey='en_US'
     );
    insert inactiveuser;
        System.Debug('^^^^^User^inactiveuser*****'+inactiveuser.ProfileId);
    
    List<Profile> medprofile=[Select id from Profile where Name='MRK - HS Medical User' LIMIT 1];
    User activemedUser = new User(
        FirstName='test',
        LastName='activeuser',
        Email='testactivemeduser@merck.com',
        UserName='testactivemeduser@merck.com',
        Alias='TAU',
        ProfileId=medprofile[0].Id,
        TimeZoneSidKey='America/New_York', 
        LocaleSidKey='en_US', 
        EmailEncodingKey='ISO-8859-1', 
        LanguageLocaleKey='en_US'
     );
    insert activemedUser;
        
        System.Debug('^^^^^User^activemedUser*****'+activemedUser.ProfileId);
    
    List<Profile> salesprofile=[Select id from Profile where Name ='MRK - Sales Representative' LIMIT 1];
       
    User activeSalesUser = new User(
        FirstName='test',
        LastName='activeuser',
        Email='testactivesalesuser@merck.com',
        UserName='testactivesalesuser@merck.com',
        Alias='TAU',
        ProfileId=salesprofile[0].Id,
        IsActive=True,
        TimeZoneSidKey='America/New_York', 
        LocaleSidKey='en_US', 
        EmailEncodingKey='ISO-8859-1', 
        LanguageLocaleKey='en_US'
        
    );
            insert activeSalesUser;
        
        System.Debug('^^^^^User^activeSalesUser*****'+activeSalesUser.ProfileId);
     //   System.Debug('^^^^^User^activeMedicalsUser*****'+activeSalesUser.ProfileId);
        
      /*   PermissionSet salespermset =[Select id from PermissionSet where Name like '%MSD_CORE_MultiFactor_Authentication_Waived%' LIMIT 1];
	 PermissionSetAssignment SalesPermIns = new PermissionSetAssignment(
         AssigneeId =inactiveUser.id,
         PermissionSetId =salespermset.id
         );
        insert SalesPermIns;
        
        PermissionSet medicalpermset =[Select id from PermissionSet where Name like '%MSD_CORE_Engage_Medical_Meeting_User%' LIMIT 1];
	 PermissionSetAssignment MedPermIns = new PermissionSetAssignment(
         AssigneeId =activemedUser.id,
         PermissionSetId =medicalpermset.id
         );
        insert MedPermIns;
//        PermissionSetAssignment*/
			
        
         String CRON_EXP = '0 2 0 * * ? 2024';

		MRK_PermSet_AutoAssign UpdatePerm = new MRK_PermSet_AutoAssign();
        System.Debug('^^^^^MRK_PermSet_AutoAssign*****'+UpdatePerm);
       String jobId = System.schedule('MRK_PermSet_AutoAssign', CRON_EXP, UpdatePerm);
        
        Test.startTest();
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    
   //User
  //  User updUser = [SELECT Id, Name FROM User WHERE id = :activeSalesUser.id];
 //  System.Debug('^^^^^User^'+updUser);
         //System.Debug('^^^^^User^'+updUser);
        
        System.assertEquals(CRON_EXP, ct.CronExpression);
        Set<Id> psid = new Set<Id>();
        For(PermissionSetAssignment ps: [Select AssigneeId, PermissionSetId from PermissionSetAssignment Where AssigneeId=:activeSalesUser.id])
        {
            psid.add(ps.PermissionSetId);
            System.Debug('^^^^^psid^'+psid);
        }
        
      //  Integer countPermission = [Select COUNT() from PermissionSetAssignment Where AssigneeId=:activeSalesUser.id];
        
       // System.assertEquals(1,countPermission, 'At leasr 1 permission setto be assigned to user');
        
         System.assertEquals(true,psid.contains('0PS0P000000imKkWAI'), 'Sales Auto Assignment failed.0PS0P000000imKkWAI');
      //  System.assertEquals(true,psid.contains('0PS0P000000igQDWAY'), 'Sales Auto Assignment failed.0PS0P000000igQDWAY');
        System.assertEquals(true,psid.contains('0PS0P000000imKjWAI'), 'Sales Auto Assignment failed.0PS0P000000imKjWAI');//0PS4U0000011yzLWAQ
      //  System.assertEquals(true,psid.contains('0PS4U0000011yzLWAQ'), 'Sales Auto Assignment failed.0PS4U0000011yzLWAQ');
       
         Set<Id> psidmed = new Set<Id>();
        For(PermissionSetAssignment pss: [Select AssigneeId, PermissionSetId from PermissionSetAssignment Where AssigneeId=:activemedUser.id])
        {
            psidmed.add(pss.PermissionSetId);
            System.Debug('^^^^^psidmed^'+psidmed);
        }
        
      /*   System.assertEquals(true,psidmed.contains('0PS0P000000igQ8WAI'), 'Medical Auto Assignment failed.0PS0P000000igQ8WAI');
         System.assertEquals(true,psidmed.contains('0PS0P000000zp07WAA'), 'Medical Auto Assignment failed.0PS0P000000zp07WAA');
        System.assertEquals(true,psidmed.contains('0PS0P000000zp08WAA'), 'Medical Auto Assignment failed.0PS0P000000zp08WAA');
        System.assertEquals(true,psidmed.contains('0PSU0000000zfjCOAQ'), 'Medical Auto Assignment failed.0PSU0000000zfjCOAQ');
        System.assertEquals(true,psidmed.contains('0PS0P000000imKkWAI'), 'Medical Auto Assignment failed.0PS0P000000imKkWAI');
    */
Test.stopTest();        
    }
    Catch(Exception e){
         
        System.Debug('^^^^^^^^^^ Error^^^^^'+e.getMessage());
        System.Debug('^^^^^^^^^^ Error^^^^^'+e.getLinenumber());
    }
     }

}