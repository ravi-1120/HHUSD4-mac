/*
* CreateInteractionForRequestTestMVN
* Created By: Roman Lerman
* Created Date: 6/21/2013
* Description: This is a test class for CreateInteractionForRequestMVN
*/
@isTest
private class CreateInteractionForRequestTestMVN {
	static Case emailRequest;
	static{
		TestDataFactoryMVN.createSettings(true);
	}

	static testMethod void testCreateInteraction(){
		Test.startTest();
			System.debug('PAUL: ' + Service_Cloud_Settings_MVN__c.getInstance());
			emailRequest = TestDataFactoryMVN.createTestEmailRequest();
		Test.stopTest();

		Case request = [select ParentId from Case where Id = :emailRequest.Id];
		Case interaction = [select Id, Interaction_Notes_MVN__c from Case where Id = :request.ParentId];

		System.assertEquals(request.ParentId, interaction.Id);
		System.assertEquals(Label.Email_Subject+' Test\n\n'+Label.Email_Body+' Test', interaction.Interaction_Notes_MVN__c);
	}

	static testMethod void testExistingInteractionWithGroupIdentifier(){
		String interactionRecordTypeId = TestDataFactoryMVN.interactionRecordTypeId;

		Case existingInteraction = new Case(RecordTypeId = interactionRecordTypeId, Status='Open');
		existingInteraction.Medical_Inquiry_Group_Identifier_MVN__c = '1234';
		insert existingInteraction;

		Case testCase = new Case();
		Test.startTest();

	        testCase.Origin = 'Email';
	        testCase.RecordTypeId = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = :Service_Cloud_Settings_MVN__c.getInstance().Request_Record_Type_MVN__c].Id;
	        testCase.Subject = 'Test';
	        testCase.Description = 'Test';
	        testCase.Medical_Inquiry_Group_Identifier_MVN__c = '1234';
	        insert testCase;
		Test.stopTest();

		Case request = [select ParentId from Case where Id = :testCase.Id];
		List<Case> interactions = [select Id from Case where Id = :request.ParentId];

		System.assertEquals(1,interactions.size());
	}
}