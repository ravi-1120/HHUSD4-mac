/*
 * AttachmentsListControllerTestMVN
 * Created By:      Kai Amundsen
 * Created Date:    12/18/2013
 * Description:     Test for AttachmentsListControllerMVN class
 *                  Generic controller for making a VF page to replace the standard Notes and Attachments related list
 *                  Required to remove the notes functionality and to remove the delete and new attachment buttons.
 */

@isTest
private class AttachmentsListControllerTestMVN {

	static Service_Cloud_Settings_MVN__c settings;
	static Case interaction;
	static Fulfillment_MVN__c fulfillment;
	static AttachmentsListControllerMVN controller;

	static {
		TestDataFactoryMVN.createSettings(true);
		settings = Service_Cloud_Settings_MVN__c.getInstance();

		interaction = TestDataFactoryMVN.createTestCase();
		fulfillment = TestDataFactoryMVN.createTestFulfillment(interaction.AccountId, interaction.Id);
	}

	@isTest static void testLoadingPage() {
		addAttachmentsToFulfillment();

		Test.startTest();
		openFulfillmentPage();
		Test.stopTest();

		System.assertEquals(25,controller.attachmentList.size());
	}

	@isTest static void testDeletingAttachment() {
		addAttachmentsToFulfillment();

		Test.startTest();
		openFulfillmentPage();
		controller.selectedAttachment = controller.attachmentList[0].Id;
		controller.deleteAttachment();
		Test.stopTest();

		System.assertEquals(24,controller.attachmentList.size());

	}

	@isTest static void testNoAttachments() {
		Test.startTest();
		openFulfillmentPage();
		Test.stopTest();

		System.assert(controller.noAttachments);
	}

	@isTest static void testNoPermissionDeletingAttachment() {
		addAttachmentsToFulfillment();

		Test.setReadOnlyApplicationMode(true);
		Test.startTest();
		openFulfillmentPage();
		controller.selectedAttachment = controller.attachmentList[0].Id;
		controller.deleteAttachment();
		Test.stopTest();
		Test.setReadOnlyApplicationMode(false);

		System.assertEquals(25,controller.attachmentList.size());

	}

	static void addAttachmentsToFulfillment() {
		List<Attachment> attachments = new List<Attachment>();
		for(Integer i=0;i<25;i++) {
			Attachment a = new Attachment();
			a.ParentId = fulfillment.Id;
			a.Name = 'MyAttachment' + i;
			a.Body = Blob.valueOf(a.Name);
			attachments.add(a);
		}
		insert attachments;
	}

	static void openFulfillmentPage() {
		Test.setCurrentPage(new PageReference('/apex/FulfillmentAttachmentsListMVN?Id='+fulfillment.Id));
        ApexPages.standardController stdController = new ApexPages.standardController(fulfillment);
        controller = new AttachmentsListControllerMVN(stdController);
	}

}