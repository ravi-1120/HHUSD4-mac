@isTest
public class PDS_MyRequestsControllerTest {
    public static User createUser(){
        Profile p = [Select Id from Profile Limit 1];
        User usr= new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'user1@merck.com',
            Username = 'user1@merck.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert usr;
        return usr;
    }
    @isTest
    static void testFilterRequests(){
        User usr = createUser();
        Test.startTest();
        List<PDS_Donation_Request__c> reqTest = PDS_MyRequestsController.filterRequests(usr.Id, 'M-0100','al','Annual Allotment');
        Test.stopTest();     
    }
}