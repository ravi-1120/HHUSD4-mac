/*
 * MSD_CORE_AddBusinessAddressController
 * Created by: Roman Lerman
 * Created Date: October 13, 2015
 * Description: Test class for the MSD_CORE_AddBusinessAddressController class
 */
@isTest
private class MSD_CORE_AddBusinessAddrControllerTest {
	private static Account businessAccount;
	private static MSD_CORE_AddBusinessAddressController controller;

	static{
		TestDataFactoryMVN.createSettings(true);

		businessAccount = TestDataFactoryMVN.createBusiness();

		businessAccount.Status_MRK__c = 'ACTIVE';
		businessAccount.Merck_Id_MRK__c = '1234567890';
		update businessAccount;

		ApexPages.currentPage().getParameters().put('id', businessAccount.Id);
		controller = new MSD_CORE_AddBusinessAddressController();
	}

	@isTest static void testBusinessAddressCreation() {		
		controller.newAddress.Name = '123 Main St';
		controller.newAddress.Address_Line_2_vod__c = 'Unit 5C';
		controller.newAddress.City_vod__c = 'Chicago';
		controller.newAddress.State_vod__c = 'IL';
		controller.newAddress.Country_vod__c = 'US';

		Test.startTest();
			controller.createAddress();
		Test.stopTest();

		List<Address_vod__c> addresses = [select Id, Name, Address_Line_2_vod__c, 
											City_vod__c, State_vod__c, Country_vod__c,
											Inactive_vod__c, Physical_Address_MRK__c, 
											Mailing_vod__c from Address_vod__c];

		System.assertEquals(true, controller.saveSuccess);
		System.assertEquals(1, addresses.size());
		System.assertEquals('123 Main St', addresses[0].Name);
		System.assertEquals('Unit 5C', addresses[0].Address_Line_2_vod__c);
		System.assertEquals('Chicago', addresses[0].City_vod__c);
		System.assertEquals('IL', addresses[0].State_vod__c);
		System.assertEquals('US', addresses[0].Country_vod__c);
		System.assertEquals(true, addresses[0].Physical_Address_MRK__c);
		System.assertEquals(false, addresses[0].Mailing_vod__c);
		System.assertEquals(true, addresses[0].Inactive_vod__c);
	}

	@isTest static void testIfStateIsRequired() {
		controller.newAddress.Country_vod__c = 'US';

		Boolean requireState;

		Test.startTest();
			requireState = controller.getRequireState();
		Test.stopTest();

		System.assertEquals(true, requireState);
	}

	@isTest static void testSaveErrors() {
		Test.setReadOnlyApplicationMode(true);
		Test.startTest();
			controller.createAddress();
		Test.stopTest();
		Test.setReadOnlyApplicationMode(false);

		System.assertEquals(false, controller.saveSuccess);
	}
}