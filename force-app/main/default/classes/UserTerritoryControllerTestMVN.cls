/*
 * UserTerritoryControllerTestMVN
 * Modified by: Kai Amundsen
 * Last Modified Date: June 9, 2014
 * Description: This is a test class for the UserTerritoryControllerMVN class.
 *				There is an issue where you cannot assign a user to a territory 
 *				in unit tests limiting the amount that this can be tested.
 */
@isTest
private class UserTerritoryControllerTestMVN {

	@isTest static void testGetUserTerritories() {

		Account testAccount = TestDataFactoryMVN.createTestHCP();

		User testUser = TestDataFactoryMVN.createTestUser();

		Territory testTerritory = new Territory();

		testTerritory.Name = 'Test Territory';
		testTerritory.Description = 'Territory for Unit Test';

		System.runAs(testUser){
			insert testTerritory;

			UserTerritory userTerr = new UserTerritory();

			userTerr.UserId = testUser.Id;
			userTerr.TerritoryId = testTerritory.Id;

			//insert userTerr;
		}

		ApexPages.StandardController controller = new ApexPages.StandardController(testAccount);
    	UserTerritoryControllerMVN extension = new UserTerritoryControllerMVN(controller);
    	
    	Test.startTest();
    		extension.getUserTerritories();
    	Test.stopTest();

    	System.assertEquals(0,extension.userTerritories.size());
	}
}