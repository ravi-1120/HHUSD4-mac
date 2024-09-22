/*
 * VaultSearchUtilityTestMVN
 * Created by: Samuel Rosen
 * Created on: Oct 2013
 * Description: This class tests the Vault Seach Utility. 
 * 				It primarily focuses on the parsing and error handling of the web callout.
 *
 * *** NOTE: Currently not used for the Merck implementation. ***
 */

@isTest
private class VaultSearchUtilityTestMVN {
	static {
		TestDataFactoryMVN.createSettings(true);
	}

	static Case request;
	static DocumentSearchControllerMVN documentSearchController;
	static Case_Document_MVN__c foundDocument;

	static testMethod void documentsShouldBeSearchedByTerm() {
		customerAsksQuestion();
		enterASearchTerm();
		searchTheDocuments();
		theDocumentsReturnedShouldContainTerm();
	}

	static testMethod void documentSearchedAndSelectedWithRelationships() {
		customerAsksQuestion();
		enterASearchTerm();
		searchTheDocumentsWithRelationships();
		selectTheDocument();
		theDocumentIsAttachedWithRelated();
	}

	static testMethod void documentSearchedAndSelectedTwoDocuments() {
		customerAsksQuestion();
		enterASearchTerm();
		searchTheDocumentsWithRelationships();
		selectTheDocument();
		theDocumentIsAttachedWithRelated();
		selectTheDocument2();
		theDocumentsAreAttachedWithNoDuplicates();
	}

	static testMethod void documentSearchedAndSelected() {
		customerAsksQuestion();
		enterASearchTerm();
		searchTheDocuments();
		selectTheDocument();
		theDocumentIsAttached();
	}

	static testMethod void errorTestInactiveUser() {
		customerAsksQuestion();
		enterASearchTerm();
		searchInactiveUser();
	}

	static testMethod void errorTestLockedOutUser() {
		customerAsksQuestion();
		enterASearchTerm();
		searchLockedOutUser();
	}

	static testMethod void errorTestSessionID() {
		customerAsksQuestion();
		enterASearchTerm();
		searchInvalidSessionUser();
	}

	static testMethod void errorTestAccess() {
		customerAsksQuestion();
		enterASearchTerm();
		searchInsufficientAcccess();
	}

	static testMethod void errorOther() {
		customerAsksQuestion();
		enterASearchTerm();
		searchOtherError();
	}

	static testMethod void testURLBuilding() {
		customerAsksQuestion();
		enterASearchTerm();
		searchTheDocuments();
		foundDocument = documentSearchController.documentList.get(0).caseDocument;

		System.debug('Download URL: ' + VaultSearchUtilityMVN.buildDownloadURL(foundDocument));
		System.debug('Link URL: ' + VaultSearchUtilityMVN.buildLinkURL(foundDocument));
		System.debug('Viewer URL: ' + VaultSearchUtilityMVN.buildViewerURL(foundDocument));
		System.assert(VaultSearchUtilityMVN.buildDownloadURL(foundDocument).contains('api/v8.0'));
		System.assert(VaultSearchUtilityMVN.buildLinkURL(foundDocument).contains('#doc_info'));
		System.assert(VaultSearchUtilityMVN.buildViewerURL(foundDocument).contains('&ext_url='));
	}

	static testMethod void testUnableToSelectADocument() {
		customerAsksQuestion();
		enterASearchTerm();
		searchTheDocuments();

		Test.setReadOnlyApplicationMode(true);
			unableToSelectDocument();
		Test.setReadOnlyApplicationMode(false);
	}

	// Given a customer asks a question
	static void customerAsksQuestion(){
		// Create a new request
		Case interaction = TestDataFactoryMVN.createTestCase();
		request = TestDataFactoryMVN.createTestRequest(interaction);
	}

	// And I enter a search term
	static void enterASearchTerm(){
		// Enter a search term

		PageReference page = new PageReference('/apex/DocumentSearchMVN?caseId=' + request.Id);
		Test.setCurrentPage(page);
		ApexPages.standardController stdController = new ApexPages.standardController(request);
		documentSearchController = new DocumentSearchControllerMVN(stdController);
        System.assertEquals(Case_Document_MVN__c.Document_Type_MVN__c.getDescribe().getPicklistValues().size() + 1,documentSearchController.documentTypes.size());
        System.assertEquals(1,documentSearchController.products.size());
		documentSearchController.searchDocument.Document_Type_MVN__c = 'FAQ';
		documentSearchController.searchDocument.Document_Language_MVN__c = 'en_US';
		documentSearchController.productId = '1359657466295';
		documentSearchController.searchDocument.Country_MVN__c = 'US';
		documentSearchController.documentSearchText = 'Cholecap';
	}

	// When I search the documents
	static void searchTheDocuments(){
		// Search the documents
		Test.setMock(HttpCalloutMock.class, new VaultMockWebServiceMVN.VaultUtilityMockNoRelatedDocs());
		test.startTest();
		documentSearchController.search();
		test.stopTest();
	}

	// When I search the documents
	static void searchTheDocumentsWithRelationships(){
		// Search the documents
		Test.setMock(HttpCalloutMock.class, new VaultMockWebServiceMVN.VaultUtilityMockProperService());
		test.startTest();
		documentSearchController.search();
		test.stopTest();
	}

	// Then only documents that contain the search term of type FAQ which also contain the search term should be displayed
	static void theDocumentsReturnedShouldContainTerm(){
		// Verify that the correct documents were returned
		for(CaseDocumentMockMVN resultDocument:documentSearchController.documentList){
			System.assert(resultDocument.caseDocument.Document_Title_MVN__c.contains('Cholecap'));
		}
	}

	// When select the document
	static void selectTheDocument(){
		documentSearchController.selectedDocumentId = '10';
		documentSearchController.selectDocument();
		List<Case_Document_MVN__c> selectedDocs =  [select Id,Document_Id_MVN__c from Case_Document_MVN__c where Document_Id_MVN__c = '10'];
		System.debug('Selected Documents: ' + selectedDocs);
		System.assertEquals(1,selectedDocs.size());
		foundDocument = selectedDocs[0];
	}

	static void unableToSelectDocument(){
		documentSearchController.selectedDocumentId = '10';
		documentSearchController.selectDocument();
		System.assert(ApexPages.getMessages().size() == 1);
	}

	// When select the document
	static void selectTheDocument2(){
		documentSearchController.selectedDocumentId = '5';
		documentSearchController.selectDocument();
		List<Case_Document_MVN__c> selectedDocs =  [select Id,Document_Id_MVN__c from Case_Document_MVN__c where Document_Id_MVN__c = '5'];
		System.debug('Selected Documents: ' + selectedDocs);
		System.assertEquals(1,selectedDocs.size());
		foundDocument = selectedDocs[0];
	}
	// The document is attached
	static void theDocumentIsAttached(){
		List<Case_Document_MVN__c> attachedDocument = [select Id,Document_Id_MVN__c from Case_Document_MVN__c where Case_MVN__c = :request.Id];
		System.assertEquals(attachedDocument[0].Document_Id_MVN__c, foundDocument.Document_ID_MVN__c);
		System.assertEquals(1,[Select Id from Case_Document_MVN__c].size());
	}

	// The document is attached
	static void theDocumentIsAttachedWithRelated(){
		List<Case_Document_MVN__c> attachedDocument = [select Id,Document_Id_MVN__c from Case_Document_MVN__c where Case_MVN__c = :request.Id];
		Set<String> attachedIds = new Set<String>();
		for(Case_Document_MVN__c cd : attachedDocument) {
			attachedIds.add(cd.Document_ID_MVN__c);
		}
		System.assert(attachedIds.contains(foundDocument.Document_ID_MVN__c));
		System.assertEquals(4,[Select Id from Case_Document_MVN__c].size());
	}

	// The document is attached
	static void theDocumentsAreAttachedWithNoDuplicates(){
		List<Case_Document_MVN__c> attachedDocument = [select Id,Document_Id_MVN__c from Case_Document_MVN__c where Case_MVN__c = :request.Id];
		Set<String> attachedIds = new Set<String>();
		for(Case_Document_MVN__c cd : attachedDocument) {
			attachedIds.add(cd.Document_ID_MVN__c);
		}
		System.assertEquals(attachedIds.size(),attachedDocument.size());
		System.assertEquals(4,[Select Id from Case_Document_MVN__c].size());
	}

	static void theDocumentIsDeleted(){
		delete foundDocument;
		System.assertEquals(0,[Select Id from Case_Document_MVN__c].size());
	}

	static void searchInactiveUser(){
		Test.setMock(HttpCalloutMock.class, new VaultMockWebServiceMVN.VaultUtilityMockInactiveService());
		test.startTest();
		documentSearchController.search();
		test.stopTest();
		List<ApexPages.Message> errors = ApexPages.getMessages();
		System.assert(errors.get(0).getSummary().contains('Inactive'));
	}

	static void searchLockedOutUser(){
		Test.setMock(HttpCalloutMock.class, new VaultMockWebServiceMVN.VaultUtilityMockUserLockedOut());
		test.startTest();
		documentSearchController.search();
		test.stopTest();
		List<ApexPages.Message> errors = ApexPages.getMessages();
		System.assert(errors.get(0).getSummary().contains('locked'));
	}

	static void searchInvalidSessionUser(){
		Test.setMock(HttpCalloutMock.class, new VaultMockWebServiceMVN.VaultUtilityMockInvalidSession());
		test.startTest();
		documentSearchController.search();
		test.stopTest();
		List<ApexPages.Message> errors = ApexPages.getMessages();
		System.assert(errors.get(0).getSummary().contains('Session'));
	}

	static void searchInsufficientAcccess(){
		Test.setMock(HttpCalloutMock.class, new VaultMockWebServiceMVN.VaultUtilityMockInsufficientAccess());
		test.startTest();
		documentSearchController.search();
		test.stopTest();
		List<ApexPages.Message> errors = ApexPages.getMessages();
		System.assert(errors.get(0).getSummary().contains('Insufficient'));
	}

	static void searchOtherError(){
		Test.setMock(HttpCalloutMock.class, new VaultMockWebServiceMVN.VaultUtilityMockOther());
		test.startTest();
		documentSearchController.search();
		test.stopTest();
		List<ApexPages.Message> errors = ApexPages.getMessages();
		System.assert(errors.get(0).getSummary().contains('Connecting'));
	}
}