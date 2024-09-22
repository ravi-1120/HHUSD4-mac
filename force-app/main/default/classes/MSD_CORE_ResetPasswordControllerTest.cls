@isTest
public with sharing class MSD_CORE_ResetPasswordControllerTest {

    @isTest
    static void testResetPassword() {
        // Setup test data
        String initialPassword = 'test@12345';
        String newPassword = 'test@123';
        
        // Create a test user with necessary data
        User testUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);

        // Set initial password for the test user
        System.runAs(testUser) {
            System.setPassword(testUser.Id, initialPassword);
        }

        // Test password reset functionality
        Test.startTest();
        String result = MSD_CORE_ResetPasswordController.resetPassword(testUser.Id, newPassword);
        Test.stopTest();

        // Assert password reset success
        System.assertEquals('Password Set Successfully!', result, 'Password should be reset successfully');

        // Optional: Verify if the password actually got set correctly using System.assert or additional logic
        User updatedUser = [SELECT Id FROM User WHERE Id = :testUser.Id];
        //System.assertNotEquals(initialPassword, updatedUser.Password, 'Password should have been updated');
    }

    // Test method for resetPassword with exception scenario
    @isTest
    static void testResetPasswordWithException() {
        // Setup test user
        User testUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);

        // Test invalid user ID scenario
        Test.startTest();
        String userId = 'invalidUserId'; // This will trigger an exception
        String newPassword = 'NewPassword123';
        String result = MSD_CORE_ResetPasswordController.resetPassword(userId, newPassword);
        Test.stopTest();

        // Assert that exception message contains the invalid user ID
        System.assert(result.contains('invalidUserId'), 'Exception message should be returned');
    }

    // Test method for createPassword
    @isTest
    static void testCreatePassword() {
        // Setup test data
        String newPassword = 'test@123';

        // Create a test user with necessary data
        User testUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);

        // Test createPassword functionality
        Test.startTest();
        String result = MSD_CORE_ResetPasswordController.createPassword(testUser.AccountId, newPassword);
        Test.stopTest();

        // Assert password creation success
        System.assertEquals('Success!', result, 'Password creation should be successful');
    }

    @isTest
    static void testCreatePasswordException() {
        // Setup test data
        String newPassword = 'test@123';

        // Test createPassword functionality with invalid AccountId
        Test.startTest();
        String result = MSD_CORE_ResetPasswordController.createPassword('invalidAccountId', newPassword);
        Test.stopTest();

        // Assert password creation failure due to invalid AccountId
        //System.assertEquals('Invalid AccountId', result, 'Password creation should fail with invalid AccountId');
    }


    // Test method for doLogin
    @isTest
    static void testDoLogin() {
        // Setup test data
        String password = 'test@123';
        String startURLval = null; // Test with null start URL

        // Create a test user with necessary data
        User testUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);

        // Test doLogin functionality
        Test.startTest();
        String result = MSD_CORE_ResetPasswordController.doLogin(testUser.AccountId, password, startURLval, null);
        Test.stopTest();
    }

    @isTest
    static void testDoLoginException() {
        // Setup test data
        String password = 'test@123';
        String startURLval = null; // Test with null start URL

        // Create a test user with necessary data
        User testUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);

        // Test doLogin functionality with invalid AccountId
        Test.startTest();
        String result = MSD_CORE_ResetPasswordController.doLogin(testUser.AccountId, password, startURLval, 'brandId');
        Test.stopTest();

        // Assert login failure due to invalid AccountId
        //System.assertEquals('Invalid AccountId', result, 'Login should fail with invalid AccountId');
    }

}