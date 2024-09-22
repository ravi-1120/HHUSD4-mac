/*
* DocumentSearchControllerTestMVN
* Created By: Roman Lerman
* Created Date: 3/6/2013
* Description: This is the test class for the DocumentSearchControllerMVN
*/

@isTest
private class DocumentSearchControllerTestMVN {
    private static Product_vod__c product;

    // Setup the data
    static {        
        TestDataFactoryMVN.createSettings(true);
        product = TestDataFactoryMVN.createProduct();
        Test.setMock(HttpCalloutMock.class, new VaultMockWebServiceMVN.VaultUtilityMockNoRelatedDocs());
    }

    static Case request;
    static DocumentSearchControllerMVN documentSearchController;
    static Case_Document_MVN__c foundArticle;
    //***********
    // Scenario 1: Knowledge Articles should be searched by a search term
    static testMethod void knowledgeArticlesShouldBeSearchedByTerm(){
        customerAsksQuestion();
        hasSearchFields();
        enterASearchTerm();
        searchTheArticles();
        theArticlesReturnedShouldContainTerm();
    }

    // Given a customer asks a question
    static void customerAsksQuestion(){
        // Create a new request
        Case interaction = TestDataFactoryMVN.createTestCase();
        request = TestDataFactoryMVN.createTestRequest(interaction);

        ApexPages.currentPage().getParameters().put('caseId', request.Id);

        // Enter a search term
        ApexPages.standardController stdController = new ApexPages.standardController(request);
        documentSearchController = new DocumentSearchControllerMVN(stdController);
    }

    static void hasSearchFields(){
        System.assertNotEquals(null, documentSearchController.documentSearchFields);
    }

    // And I enter a search term
    static void enterASearchTerm(){
        documentSearchController.searchDocument.Document_Type_MVN__c = 'All';
        documentSearchController.searchDocument.Document_Language_MVN__c = 'en_US';
        documentSearchController.documentSearchText = 'Cholecap';
    }

    // When I search the articles
    static void searchTheArticles(){
        // Search the articles
        Test.startTest();
        documentSearchController.search();
        Test.stopTest();
    }

    // Then only articles that contain the search term of type FAQ which also contain the search term should be displayed
    static void theArticlesReturnedShouldContainTerm(){
        // Verify that the correct articles were returned
        System.debug('KnowledgeSearchList: '+documentSearchController.documentList);
        for(CaseDocumentMockMVN knowledgeResultArticle:documentSearchController.documentList){
            System.assert(knowledgeResultArticle.caseDocument.Document_Title_MVN__c.contains('Cholecap'));
            knowledgeResultArticle.getViewerURL();
            knowledgeResultArticle.getLinkURL();
            knowledgeResultArticle.getDownloadURL();
        }
    }
//***********
    // Scenario 2: Knowledge Articles should be filtered for quicker searching
    static testMethod void knowledgeArticlesShouldBeSearchedByTermAndType(){
        customerAsksQuestion();
        enterASearchTerm();
        filterForFAQs();
        searchTheArticles();
        theArticlesReturnedShouldBeFAQsAndContainTerm();
    }

    // And I filter for FAQs
    static void filterForFAQs(){
        // Specify a filter
        documentSearchController.searchDocument.Document_Type_MVN__c = 'FAQ';
    }

    // Then only articles that contain the search term of type FAQ which also contain the search term should be displayed
    static void theArticlesReturnedShouldBeFAQsAndContainTerm(){
        // Verify that the correct articles were returned
        for(CaseDocumentMockMVN knowledgeResultArticle:documentSearchController.documentList){
            System.assertEquals(documentSearchController.searchDocument.Document_Type_MVN__c, knowledgeResultArticle.caseDocument.Document_Type_MVN__c);
            System.assert(knowledgeResultArticle.caseDocument.Document_Title_MVN__c.contains('Cholecap'));
        }
    }
//*******************
    // Scenario 3:  Knowledge Articles should be attached once found
    static testMethod void knowledgeArticlesShouldBeAttachedOnceFound(){
        customerAsksQuestion();
        enterASearchTerm();
        searchTheArticles();
        findTheArticleImLookingFor();
        selectTheArticle();
        theArticleIsAttached();
    }
    // And I find the article I'm looking for
    static void findTheArticleImLookingFor(){
        foundArticle = documentSearchController.documentList[0].caseDocument;
    }
    // When select the article
    static void selectTheArticle(){
        documentSearchController.selectedDocumentId = foundArticle.Document_Id_MVN__c;
        documentSearchController.selectDocument();
        documentSearchController.processAttachedDocuments();
    }
    // The article is attached
    static void theArticleIsAttached(){
        List<Case_Document_MVN__c> attachedArticle = [select Id,Document_Id_MVN__c from Case_Document_MVN__c where Case_MVN__c = :request.Id];
        System.assertEquals(attachedArticle[0].Document_Id_MVN__c, foundArticle.Document_Id_MVN__c);
        System.assertEquals(1,[Select Id from Case_Document_MVN__c].size());
    }

//*******************
    // Scenario 4:  The article is selected twice
    static testMethod void knowledgeArticlesErrorsWhenSelectedTwice(){
        customerAsksQuestion();
        enterASearchTerm();
        searchTheArticles();
        findTheArticleImLookingFor();
        selectTheArticle();
        theArticleIsAttached();
        selectTheArticleAgainAndReceiveError();
    }
    static void selectTheArticleAgainAndReceiveError(){
        try{
            documentSearchController.selectDocument();
        }catch(Exception e){
            System.assert(e.getMessage().contains(Label.Document_Search_Article_Already_Attached));
        }
    }

//*******************
    // Scenario 5:  Search for an article without a product defined
    static testMethod void knowledgeArticlesNoProduct(){
        customerAsksQuestion();
        enterASearchTerm();
        documentSearchController.productId = 'test';
        searchTheArticles();
        theArticlesReturnedShouldContainTerm();
    }

//********************
    // Scenario 6:  Search for an article without a product defined
    static testMethod void knowledgeArticlesWithProduct(){
        customerAsksQuestionWithAProduct();

        searchTheArticles();
        theArticlesReturnedShouldContainProduct();
    }

    static void customerAsksQuestionWithAProduct(){
        // Create a new request
        Case interaction = TestDataFactoryMVN.createTestCase();        
        request = TestDataFactoryMVN.createTestRequest(interaction, product.Id);

        ApexPages.currentPage().getParameters().put('caseId', request.Id);

        System.debug('\tCase:\n' + request);

        // Enter a search term
        ApexPages.standardController stdController = new ApexPages.standardController(request);
        documentSearchController = new DocumentSearchControllerMVN(stdController);
        documentSearchController.documentSearchText = '';
    }

    // Then only articles that contain the search term of type FAQ which also contain the search term should be displayed
    static void theArticlesReturnedShouldContainProduct(){
        // Verify that the correct articles were returned
        System.debug('KnowledgeSearchList: '+documentSearchController.documentList);
        for(CaseDocumentMockMVN knowledgeResultArticle:documentSearchController.documentList){
            System.assert(knowledgeResultArticle.caseDocument.Document_Title_MVN__c.contains('Product'));
        }
    }

//********************
    static testMethod void testControllerMethods(){
        Case interaction = TestDataFactoryMVN.createTestCase();
        request = TestDataFactoryMVN.createTestRequest(interaction);

        ApexPages.currentPage().getParameters().put('caseId', request.Id);

        ApexPages.standardController stdController = new ApexPages.standardController(request);

        System.runAs(TestDataFactoryMVN.createTestUser()){
            documentSearchController = new DocumentSearchControllerMVN(stdController);
        }

        System.assertEquals(Case_Document_MVN__c.Document_Type_MVN__c.getDescribe().getPicklistValues().size() + 1, documentSearchController.documentTypes.size());
        System.assertEquals([SELECT count() FROM Product_vod__c WHERE IsDeleted = false] + 1, documentSearchController.products.size());    
    }
}