/*
* CreateLineItemsTriggerTestMVN
* Created By: Kai Amundsen
* Created Date: June 12, 2014
* Description: This is a test class for the CreateLineItemsTriggerMVN class
*/
@isTest
private class CreateLineItemsTriggerTestMVN {
	private static Service_Cloud_Settings_MVN__c settings;
	private static Case interaction;
	private static List<Case> requests;

	static {
		TestDataFactoryMVN.createSettings(true);
		settings = Service_Cloud_Settings_MVN__c.getInstance();

		Test.startTest();
			interaction = TestDataFactoryMVN.createTestCase();
			requests = new List<Case>();
			requests.add(TestDataFactoryMVN.createTestRequest(interaction));
			requests.add(TestDataFactoryMVN.createTestRequest(interaction));
		Test.stopTest();
	}

	@isTest static void testLineItemsCreated() {
		Fulfillment_MVN__c ful = TestDataFactoryMVN.createTestFulfillment(interaction.AccountId,interaction.Id);

		List<Fulfillment_Line_Item_MVN__c> lineItems = [select Id,Fulfillment_MVN__c,Case_MVN__c from Fulfillment_Line_Item_MVN__c where Fulfillment_MVN__c = :ful.Id];
		System.assertEquals(2, lineItems.size());
	}

	@isTest static void testMultipleFulfillmentsPerInteraction() {
		List<Fulfillment_MVN__c> fulfillments = new List<Fulfillment_MVN__c>();
		for(Integer i = 0; i<5 ; i++) {
			Fulfillment_MVN__c fulfillment = new Fulfillment_MVN__c();
	        fulfillment.Account_Name_MVN__c = interaction.AccountId;
	        fulfillment.Case_MVN__c = interaction.Id;
	        fulfillments.add(fulfillment);
		}

		insert fulfillments;

		List<Fulfillment_Line_Item_MVN__c> lineItems = [select Id,Fulfillment_MVN__c,Case_MVN__c from Fulfillment_Line_Item_MVN__c where Fulfillment_MVN__c in :fulfillments];
		System.assertEquals(10, lineItems.size());
	}
}