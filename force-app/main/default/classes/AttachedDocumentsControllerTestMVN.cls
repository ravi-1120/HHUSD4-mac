/*
 * AttachedDocumentsControllerTestMVN
 * Created By:      Roman Lerman
 * Created Date:    5/1/2013
 * Description:     Test class for the AttachedDocumentsControllerMVN
 */
@isTest
private class AttachedDocumentsControllerTestMVN {
    static Case request;
    static AttachedDocumentsControllerMVN attachedDocumentsController;
    static Case_Document_MVN__c foundDocument;
    static List<Id> documentIds;

    // Setup the data
    static {
        TestDataFactoryMVN.createSettings(true);
    }

    //********************
    // Scenario 1:  Component lists attached documents when viewed
    @isTest static void knowledgeDocumentsListed() {
        caseIsCreatedWithAttachedDocument();
        repViewsCase();
        allDocumentsDisplayed();
    }

    static void caseIsCreatedWithAttachedDocument() {
        // Create a new request
        Case interaction = TestDataFactoryMVN.createTestCase();
        request = TestDataFactoryMVN.createTestRequest(interaction);

        foundDocument = new Case_Document_MVN__c();
        foundDocument.Case_MVN__c = request.Id;
        foundDocument.Document_Major_Version_MVN__c = '1';
        foundDocument.Document_Minor_Version_MVN__c = '0';
        foundDocument.Document_ID_MVN__c = 'MYID1234';

        insert foundDocument;
    }

    static void repViewsCase() {
    	ApexPages.currentPage().getParameters().put('id', request.id);
        attachedDocumentsController = new attachedDocumentsControllerMVN();
    }

    static void allDocumentsDisplayed() {
        System.assertEquals(1,attachedDocumentsController.getAttachedDocumentList().size());

    }

    //********************
    // Scenario 2:  Knowledge Documents should be removed
    @isTest static void knowledgeDocumentsCanBeRemoved(){
        caseIsCreatedWithAttachedDocument();
        repViewsCase();
        removeTheDocument();
        repViewsCase();
        theDocumentIsRemoved();
    }
    // And I remove the document
    static void removeTheDocument(){
        attachedDocumentsController = new attachedDocumentsControllerMVN();
        attachedDocumentsController.getAttachedDocumentList();
        attachedDocumentsController.attachedDocumentId = foundDocument.Id;
        attachedDocumentsController.removeDocument();
    }
    // The document is removed
    static void theDocumentIsRemoved(){
        System.assertEquals(0, attachedDocumentsController.getAttachedDocumentList().size());
    }

    //********************
    // Scenario 3:  Error while removing document
    @isTest static void errorDetectedWhenRemovingKnowledgeDocument(){
        caseIsCreatedWithAttachedDocument();
        repViewsCase();

        Test.setReadOnlyApplicationMode(true);
        removeTheDocument();
        Test.setReadOnlyApplicationMode(false);

        anErrorIsDetected();
    }

    static void anErrorIsDetected(){
        System.assert(ApexPages.getMessages().size() > 0);
    }
}