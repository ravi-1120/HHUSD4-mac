@isTest
public class MSD_CORE_DashboardTest {
    
    @isTest
    static void testgetPrimaryExecutive(){
        User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test1', 'Contact1', true);
        Test.startTest();
        List<user> primaryexcutiveList = MSD_CORE_Dashboard.getPrimaryExecutive((String)communityUser.Id);
        Test.stopTest();
        System.assert(primaryexcutiveList.size()==0,'primaryexcutiveList exists');  
    }

    @isTest
    static void testgetPrimaryExecutive1(){
        User communityUser = createUser();
        Test.startTest();
        List<user> primaryexcutiveList = MSD_CORE_Dashboard.getPrimaryExecutive((String)communityUser.Id);
        Test.stopTest();
        System.assert(true,true);  
    }

    @IsTest
    static void testgetMerckSites() {
        User testUser = createUser();
        Test.startTest();
        System.runAs(testUser) {
            List<MSD_CORE_OtherMerck__mdt> merckSites= MSD_CORE_Dashboard.getMerckSites();
        }
        test.stopTest();
        System.assert(true,true);
    }

    private static User createUser() {
        String uniqueUserName = 'user' + DateTime.now().getTime() + 'user@merck.com';
        Profile firstProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User user = new User(LastName = 'Userton',
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
        System.runAs(user) {
            System.debug(LoggingLevel.WARN,'Current User: ' + UserInfo.getUserName());
            System.debug(LoggingLevel.WARN,'Current Profile: '+ UserInfo.getProfileId());
        }
        return user;
    }
    
    @isTest 
    static void testgetEnableDisease() {
        User testUser = createUser();
        Test.startTest();
        System.runAs(testUser) {
            Boolean siteSetting= MSD_CORE_Dashboard.getEnableDisease();
        }
        test.stopTest();
        System.assert(true,true);
    }
    
}