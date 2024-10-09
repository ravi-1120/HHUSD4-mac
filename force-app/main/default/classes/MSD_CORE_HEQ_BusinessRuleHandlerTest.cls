@isTest
public class MSD_CORE_HEQ_BusinessRuleHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@merck.com',
            Username = 'testuser@test.com.hhusd4',
            CommunityNickname = 'testuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create a Public Group
        Group publicGroup = new Group(
            Name = 'TestPublicGroup',
            DeveloperName = 'TestPublicGroup',
            Type = 'Regular'
        );
        insert publicGroup;
        
        // Add the user to the public group
        GroupMember groupMember = new GroupMember(
            GroupId = publicGroup.Id,
            UserOrGroupId = testUser.Id
        );
        insert groupMember;
    }
    
    @isTest
    static void testGetOptions() {
        // Get the test user ID
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@merck.com' LIMIT 1];
        
        // Call the method to be tested
        List<String> options = MSD_CORE_HEQ_BusinessRuleHandler.getOptions(testUser.Id, 'Static');
        
        // Assert that the correct options are returned
        System.assert(options.contains('Add To Collection'), 'Option "Add To Collection" should be returned');
        System.assert(options.contains('Customize'), 'Option "Customize" should be returned');
        System.assert(options.contains('Download'), 'Option "Download" should be returned');
        System.assert(!options.contains('Email To Customer'), 'Option "Email To Customer" should not be returned');
        System.assert(options.contains('Open'), 'Option "Open" should be returned');
        System.assert(!options.contains('Preview and Details'), 'Option "Preview and Details" should not be returned');
        System.assert(options.contains('Print to Customer'), 'Option "Print to Customer" should be returned');
    }
}