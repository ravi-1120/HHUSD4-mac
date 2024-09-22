@isTest
public class MSD_CORE_MHEESitePageConfigurationTest {
    // @isTest
    // public static void testSiteAPINames(){
    //     String librAPIN = MSD_CORE_MHEESitePageConfiguration.getSiteAPIName('Library');
    //     System.Assert((MSD_CORE_MHEESitePageConfiguration.appendS && librAPIN.contains('/library')) || (!MSD_CORE_MHEESitePageConfiguration.appendS && librAPIN.contains('/library')));
    // }
    @isTest
    public static void getAllSiteNameAndAPINames(){
        Map<String,Object> results = MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames();
       System.Assert(results!=null && results.keySet().size()>0);
    }
    @isTest
    public static void testgetSiteNameAndAPIName(){
       Map<String,String> results = MSD_CORE_MHEESitePageConfiguration.getSiteNameAndAPIName('Pipeline');
       System.Assert(results!=null && results.keySet().size()==2); 
    }
    @isTest
    public static void testgetAllSiteNameAndAPINames(){
       Map<String,Object> results = MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames();
       System.Assert(results!=null && results.keySet().size()>0); 
    }
    private static User createUser() {
      String uniqueUserName = 'user' + DateTime.now().getTime() + 'user@merck.com';
      Profile firstProfile = [SELECT Id FROM Profile WHERE Name='MRK_Payor_Exec'];
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
}