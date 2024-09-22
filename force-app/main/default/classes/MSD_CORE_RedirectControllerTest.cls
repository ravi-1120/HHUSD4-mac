@isTest
public class MSD_CORE_RedirectControllerTest {
    @isTest
    public static void testGetAccountStatusLocked(){
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c(
            MSD_CORE_Status__c = 'Approved',
            MSD_CORE_Email__c = 'test@example.com',
            MSD_CORE_Payor__c = UserInfo.getUserId(),
            MSD_CORE_Last_Review_Date__c = System.today().addMonths(-1),
            MSD_CORE_Next_Review_Date__c = System.today().addDays(-5)
        );
        insert testEligibility;

        test.startTest();
            Map<String,String> result = MSD_CORE_RedirectController.getAccountLockStatus(UserInfo.getUserId());
		    System.assertEquals('Locked', result.get('accountStatus'));
        test.stopTest();
    }
    
    @isTest
    public static void testGetAccountStatusUnlocked(){
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c(
            MSD_CORE_Status__c = 'Approved',
            MSD_CORE_Email__c = 'test@example.com',
            MSD_CORE_Payor__c = UserInfo.getUserId(),
            MSD_CORE_Last_Review_Date__c = System.today().addMonths(-1),
            MSD_CORE_Next_Review_Date__c = System.today().addDays(5)
        );
        insert testEligibility;

        test.startTest();
            Map<String,String> result = MSD_CORE_RedirectController.getAccountLockStatus(UserInfo.getUserId());
		    System.assertEquals('Unlocked', result.get('accountStatus'));
        test.stopTest();
    }

  	@isTest
    static void testGetNextDate() {
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testone@merck.com',
            Username = 'testuserone@merckuser.com',
            Alias = 'TUser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = UserInfo.getProfileId()
        );
        insert testUser;
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c(
            MSD_CORE_Payor__c = testUser.Id,
            MSD_CORE_Last_Review_Date__c = Date.today(),
            MSD_CORE_Next_Review_Date__c = Date.today().addDays(30)
        );
        insert testEligibility;
        List<MSD_CORE_Eligibility__c> result = MSD_CORE_RedirectController.getNextDate(testUser.Id);
        System.assertEquals(1, result.size(), 'Expected one record');
        System.assertEquals(testEligibility.Id, result[0].Id, 'Unexpected record Id');
    }


    
    
    
}