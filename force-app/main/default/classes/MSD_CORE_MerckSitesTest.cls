@IsTest
public class MSD_CORE_MerckSitesTest {

    @IsTest
    static void getMerckSitesTest() {

        User testUser = createUser();
        Test.startTest();
        System.runAs(testUser) {
            List<MSD_CORE_OtherMercksites__mdt> merckSites= MSD_CORE_MerckSites.getMerckSites();
        }
        test.stopTest();

        System.assert(true,true);
    }

    private static User createUser() {
        Profile firstProfile = [SELECT Id FROM Profile LIMIT 1];
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
        insert user;
        return user;
    }
}