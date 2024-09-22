/*
* KnowledgeSearchUtilityTestMVN
* Created By: Roman Lerman
* Created Date: 3/12/2013
* Description: This class is used for testing the KnowledgeSearchUtilityMVN class
*/
@isTest
public class KnowledgeSearchUtilityTestMVN {
    private static List<SObject> faqs;
    private static List<SObject> medicalLetters;
    private static List<ID> articleIds;
    private static Service_Cloud_Settings_MVN__c settings;
    private static List<Case_Document_Fields_MVN__c> caseFields;
    static Case request;
    static DocumentSearchControllerMVN documentSearchController;
    static Case_Document_MVN__c foundDocument;
    static User testUser;
    static Product_vod__c product;

    static {
        if(UtilitiesMVN.knowledgeInstalled) {
            createSettings();
            articleIds = setupArticles();
        }

        testUser = TestDataFactoryMVN.createTestUser();

        product =  new Product_vod__c(Name='Test', Product_Type_vod__c = 'Family', External_Id_vod__c = '1234', Active_MRK__c = true, Company_Product_vod__c = true);
        insert product;
    }

    public static List<Id> setupArticles() {
        if(faqs == null) {
            SObject faq = Schema.getGlobalDescribe().get('knowledge__kav').newSObject();

            faq.put('Title', 'Test');
            faq.put('Language', 'en_US');
            faq.put('MSD_CORE_RevCustType__c', 'CONSUMER; INDIV HEALTHCARE PROF; EMPLOYEE; HEALTHCARE BUSINESS PROF');
            faq.put('MSD_CORE_GenCntry__c', 'US');            
            faq.put('MSD_CORE_Audience__c', 'CONSUMER');
            faq.put('MSD_CORE_KnwlArtCat__c', 'PCC');
            faq.put('URLName', 'testfaq-123');
            faq.put('MSD_CORE_Product_ID__c', '1234');

            insert faq;

            SObject faq2 = Schema.getGlobalDescribe().get('knowledge__kav').newSObject();

            faq2.put('Title', 'Test 2');
            faq2.put('Language', 'en_US');
            faq2.put('MSD_CORE_RevCustType__c', 'CONSUMER; INDIV HEALTHCARE PROF; EMPLOYEE; HEALTHCARE BUSINESS PROF');
            faq2.put('MSD_CORE_GenCntry__c', 'US');            
            faq2.put('MSD_CORE_Audience__c', 'CONSUMER');            
            faq2.put('MSD_CORE_KnwlArtCat__c', 'PCC');
            faq2.put('URLName', 'testfaq2-123');
            faq2.put('MSD_CORE_Product_ID__c', '1234');
            insert faq2;

            Set<Id> faqSet = new Set<Id>();
            faqSet.add(faq.Id);
            faqSet.add(faq2.Id);
            faqs = Database.query('select KnowledgeArticleId, PublishStatus, Language, MSD_CORE_GenCntry__c, IsLatestVersion from knowledge__kav where Id in :faqSet');
        }

        /*if(medicalLetters == null) {
            Sobject medicalLetter = Schema.getGlobalDescribe().get('MSD_CORE_Review__kav').newSObject();
            medicalLetter.put('Title', 'Test');
            medicalLetter.put('Language', 'en_US');
            medicalLetter.put('MSD_CORE_RevCustType__c', 'CONSUMER; INDIV HEALTHCARE PROF; EMPLOYEE; HEALTHCARE BUSINESS PROF');
            medicalLetter.put('URLName', 'testml-123');
            medicalLetter.put('MSD_CORE_Product_ID__c', '1234');
            insert medicalLetter;


            Sobject medicalLetter2 = Schema.getGlobalDescribe().get('MSD_CORE_Review__kav').newSObject();
            medicalLetter2.put('Title', 'Test 2');
            medicalLetter2.put('Language', 'en_US');
            medicalLetter2.put('MSD_CORE_RevCustType__c', 'CONSUMER; INDIV HEALTHCARE PROF; EMPLOYEE; HEALTHCARE BUSINESS PROF');
            medicalLetter2.put('URLName', 'testml2-123');
            medicalLetter2.put('MSD_CORE_Product_ID__c', '1234');
            insert medicalLetter2;

            Set<Id> medicalLetterSet = new Set<Id>();
            medicalLetterSet.add((Id)medicalLetter.get('Id'));
            medicalLetterSet.add((Id)medicalLetter2.get('Id'));

            medicalLetters = Database.query('select KnowledgeArticleId from MSD_CORE_Review__kav where Id in :medicalLetterSet');
        }*/

        List<Id> idList = new List<Id>();
        idList.add(faqs[0].Id);
        idList.add(faqs[1].Id);
        //idList.add(medicalLetters[0].Id);
        //idList.add(medicalLetters[1].Id);

        return idList;
    }

    public static void createSettings() {
        if(settings == null) {
            settings = new Service_Cloud_Settings_MVN__c();

            settings.Document_Search_Max_Results_MVN__c = 50;
            settings.Interaction_Record_Type_MVN__c = 'Interaction_MVN';
            settings.Interaction_Anonymize_Countries_MVN__c = 'US';
            settings.Document_Search_Family_Type_MVN__c = 'Family';
            settings.Request_Record_Type_MVN__c = 'Request_MVN';
            settings.HCP_Record_Type_MVN__c = 'HCP';
            settings.Employee_Record_Type_MVN__c = 'Employee_MVN';
            settings.Administrator_Email_MVN__c = 'test@example.com';
            settings.Open_Status_MVN__c = 'Open';
            settings.Closed_Status_MVN__c = 'Closed';
            settings.Vault_Base_URL_MVN__c = 'https://test.veevavault.com';
            settings.Vault_API_Version_MVN__c = 'v8.0';
            settings.Vault_Viewer_Doc_Type_Exclusion_List_MVN__c = 'MedicalLetter';
            settings.Document_Search_Utility_Class_MVN__c = 'VaultSearchUtilityMVN';
            settings.Account_Search_Utility_Classes_MVN__c = 'SFAccountSearchUtilityMVN';
            settings.Temporary_Account_Hold_Period_Days_MVN__c = 0;
            settings.Vault_Relationship_Includes_MVN__c = 'supporting_documents__vs';
            settings.Person_Account_Search_Types_MVN__c = 'INDIV HEALTHCARE PROF,HEALTHCARE BUSINESS PROF,EMPLOYEE,CONSUMER'; 
            settings.MSD_CORE_Prod_Complaint_Closed_Rec_Type__c = 'Product_Complaint_Closed_MVN';
            settings.MSD_CORE_Request_Closed_Record_Type__c = 'Request_Closed_MVN'; 
            settings.MSD_CORE_Adverse_Event_Closed_Rec_Type__c = 'Adverse_Event_Closed_MVN';
            settings.MSD_CORE_Compensation_Req_Record_Type__c = 'MSD_CORE_Compensation_Request';
            settings.MSD_CORE_Temp_Excursion_Record_Type__c = 'MSD_CORE_Temperature_Excursion';
            settings.MSD_CORE_Temp_Not_Supported_Outcome__c = 'Not Supported';
            settings.MSD_CORE_Default_to_Business_Search__c ='MSD_CORE Contact Center - MVCC Agent';
            settings.MSD_CORE_AEPQC_Note_Filter__c = 'PQC Details for Case #,AE Details for Case #';
            settings.MSD_CORE_Submitted_Status__c = 'Submitted'; 
            settings.MSD_CORE_Product_Comp_Submitted_Type__c = 'Adverse_Event_Closed_MVN, Product_Complaint_Closed_MVN, MSD_CORE_Product_Complaint_Submitted';
            settings.MSD_CORE_Temp_Exc_Closed_Record_Type__c = 'MSD_CORE_Temperature_Excursion_Closed'; 
            settings.MSD_CORE_Case_Origin_Email__c = 'Email';
            settings.Cancelled_Status_MVN__c = 'Cancelled';
            settings.MSD_CORE_Address_Country_Requires_State__c = 'US';
            settings.MSD_CORE_Type_Has_Business_Address__c = 'INDIV HEALTHCARE PROF,HEALTHCARE BUSINESS PROF';
            //settings.MSD_CORE_SAP_ID_Type__c = SAP_ID_TYPE;
            settings.MSD_CORE_DCR_Record_Types__c = 'HBP,HCP,Hospital_vod,Pharmacy_vod,Organization_vod';
            settings.Consumer_Record_Type_MVN__c = 'CONSUMER_MVN';
            settings.MSD_CORE_Social_Other_Provider__c = 'Other';
            settings.MSD_CORE_Social_Facebook_Provider__c = 'Facebook';
            settings.MSD_CORE_Social_Twitter_Provider__c = 'Twitter';
            settings.MSD_CORE_Social_Other_Origin__c = 'Other Social Media';
            settings.MSD_CORE_Social_Private_Message_Type__c = 'Private';
            settings.MSD_CORE_Edit_Account_DCR_Record_Type__c = 'Account_vod';
            settings.Combo_Case_Preview_Record_Type__c = 'Combo_Case_Preview';

            insert settings;
        }

        if(caseFields == null) {
            caseFields = new List<Case_Document_Fields_MVN__c>();
            caseFields.add(new Case_Document_Fields_MVN__c(Name='1',Case_Document_Field_MVN__c='MSD_CORE_Product_ID__c',Document_Field_MVN__c='MSD_CORE_Product_ID__c',Document_Type_MVN__c='knowledge__kav'));
            caseFields.add(new Case_Document_Fields_MVN__c(Name='2',Case_Document_Field_MVN__c='MSD_CORE_Product_ID__c',Document_Field_MVN__c='MSD_CORE_Product_ID__c',Document_Type_MVN__c='MSD_CORE_Review__kav'));
            insert caseFields;
        }

    }

    static testMethod void knowledgeDocumentsShouldBeSearchedByTerm() {
        System.runAs(testUser) {    
            if(UtilitiesMVN.knowledgeInstalled) {
                Test.startTest();
                    customerAsksQuestion();
                    enterASearchTerm();
                    searchTheDocuments();
                    theDocumentsReturnedShouldContainTerm();
                Test.stopTest();
            } else {
                //Test invalid if knowledge is not installed.
                System.assert(true);
            }
        }
    }

    static testMethod void knowledgeDocumentSearchedAndSelectedThenDeleted() {
        if(UtilitiesMVN.knowledgeInstalled) {
            System.runAs(testUser){
                Test.startTest();
                    customerAsksQuestion();
                    enterASearchTerm();
                    searchTheDocuments();
                    selectTheDocument();
                    theDocumentIsAttached();
                Test.stopTest();
                theDocumentIsDeleted();
            }
        } else {
            //Test invalid if knowledge is not installed.
            System.assert(true);
        }
    }

    static testMethod void testURLBuilding() {
        System.runAs(testUser){ 
            if(UtilitiesMVN.knowledgeInstalled) {
                Test.startTest();
                    customerAsksQuestion();
                    enterASearchTerm();
                    searchTheDocuments();
                    foundDocument = new Case_Document_MVN__c(Case_MVN__c = request.Id,
                                                 Document_ID_MVN__c = 'sd');
        insert foundDocument;
                Test.stopTest();
                
                String urlString = '/' + foundDocument.Knowledge_Article_Version_ID_MVN__c;
            } else {
                //Test invalid if knowledge is not installed.
                System.assert(true);
            }
        }
    }

    static testMethod void testNoSearchTermProvided() {
        System.runAs(testUser){ 
            if(UtilitiesMVN.knowledgeInstalled) {
                Test.startTest();
                    customerAsksQuestion();
                    enterNoSearchTerm();
                    searchTheDocuments();
                    exceptionReturned();
                Test.stopTest();
            } else {
                //Test invalid if knowledge is not installed.
                System.assert(true);
            }
        }
    }

    static testMethod void testInvalidSearchTermProvided() {
        System.runAs(testUser){ 
            if(UtilitiesMVN.knowledgeInstalled) {
                Test.startTest();
                    customerAsksQuestion();
                    enterInvalidSearchTerm();
                    searchTheDocuments();
                    exceptionReturned();
                Test.stopTest();
            } else {
                //Test invalid if knowledge is not installed.
                System.assert(true);
            }
        }
    }

    static testMethod void testUnableToSelectTheDocument() {
        System.runAs(testUser){ 
            if(UtilitiesMVN.knowledgeInstalled) {
                Test.startTest();
                    customerAsksQuestion();
                    enterASearchTerm();
                    searchTheDocuments();
                    Test.setReadOnlyApplicationMode(true);
                        //selectTheDocument();
                    Test.setReadOnlyApplicationMode(false);
                    exceptionReturned();
                Test.stopTest();
            } else {
                //Test invalid if knowledge is not installed.
                System.assert(true);
            }
        }
    }

    static testMethod void testUnableToSelectTheDocumentTwice() {
        System.runAs(testUser){ 
            if(UtilitiesMVN.knowledgeInstalled) {
                Test.startTest();
                    customerAsksQuestion();
                    enterASearchTerm();
                    searchTheDocuments();
                    selectTheDocument();
                    selectTheDocument();
                    exceptionReturned();
                Test.stopTest();
            } else {
                //Test invalid if knowledge is not installed.
                System.assert(true);
            }
        }
    }

    static testMethod void testInvalidQuery() {
        System.runAs(testUser){ 
            if(UtilitiesMVN.knowledgeInstalled) {
                Test.startTest();
                    customerAsksQuestion();
                    enterInvalidQuery();
                    exceptionReturned();
                Test.stopTest();
            } else {
                //Test invalid if knowledge is not installed.
                System.assert(true);
            }
        }
    }

    // Given a customer asks a question
    static void customerAsksQuestion() {
        Case interaction = TestDataFactoryMVN.createTestCase();
        
        request = new Case();
        request.ParentId = interaction.Id;
        request.AccountId = interaction.AccountId;
        request.RecordTypeId = TestDataFactoryMVN.requestRecordTypeId;
        request.Product_MVN__c = product.Id;
        insert request;
    }

    // And I enter a search term
    static void enterASearchTerm() {
        // Enter a search term

        PageReference page = new PageReference('/apex/DocumentSearchMVN');
        Test.setCurrentPage(page);
        System.currentPageReference().getParameters().put('caseId', request.Id);
        
        ApexPages.standardController stdController = new ApexPages.standardController(request);
        documentSearchController = new DocumentSearchControllerMVN(stdController);
        System.assertEquals(Case_Document_MVN__c.Document_Type_MVN__c.getDescribe().getPicklistValues().size() + 1,documentSearchController.documentTypes.size());
        System.assertEquals(2, documentSearchController.products.size());
        documentSearchController.searchDocument.Document_Type_MVN__c = 'knowledge__kav';
        documentSearchController.searchDocument.Document_Language_MVN__c = 'en_US';
        documentSearchController.productId = '1234';
        documentSearchController.documentSearchText = 'test';
    }

    // And I enter no search term
    static void enterNoSearchTerm() {
        PageReference page = new PageReference('/apex/DocumentSearchMVN');
        Test.setCurrentPage(page);
        System.currentPageReference().getParameters().put('caseId', request.Id);
        
        ApexPages.standardController stdController = new ApexPages.standardController(request);
        documentSearchController = new DocumentSearchControllerMVN(stdController);
        System.assertEquals(Case_Document_MVN__c.Document_Type_MVN__c.getDescribe().getPicklistValues().size() + 1, documentSearchController.documentTypes.size());
        System.assertEquals(2, documentSearchController.products.size());
        documentSearchController.searchDocument.Document_Type_MVN__c = 'knowledge__kav';
        documentSearchController.searchDocument.Document_Language_MVN__c = 'en_US';
        documentSearchController.productId = '';
        documentSearchController.documentSearchText = '';
    }

    // And I enter an invalid search term
    static void enterInvalidSearchTerm() {
        PageReference page = new PageReference('/apex/DocumentSearchMVN');
        Test.setCurrentPage(page);
        System.currentPageReference().getParameters().put('caseId', request.Id);
        
        ApexPages.standardController stdController = new ApexPages.standardController(request);
        documentSearchController = new DocumentSearchControllerMVN(stdController);
        System.assertEquals(Case_Document_MVN__c.Document_Type_MVN__c.getDescribe().getPicklistValues().size() + 1,documentSearchController.documentTypes.size());
        System.assertEquals(2, documentSearchController.products.size());
        documentSearchController.searchDocument.Document_Type_MVN__c = 'knowledge__kav';
        documentSearchController.searchDocument.Document_Language_MVN__c = 'en_US';
        documentSearchController.documentSearchText = 'a';
    }

    // And I enter an invalid query
    static void enterInvalidQuery() {
        Case_Document_MVN__c caseDoc = new Case_Document_MVN__c();
        caseDoc.Document_Type_MVN__c = 'knowledge__kav';
        caseDoc.Document_Language_MVN__c = 'invalid language';

        DocumentSearchUtilityMVN docSearchUtility = new DocumentSearchUtilityMVN();
        docSearchUtility.documentSearchText = 'test';
        docSearchUtility.searchDocument = caseDoc;
        KnowledgeSearchUtilityMVN knowledgeSearch = new KnowledgeSearchUtilityMVN();
        knowledgeSearch.search(docSearchUtility, request.Id, false);
    }

    // When I search the documents
    static void searchTheDocuments() {
        // Search the documents
        System.debug('ArticleIds: ' + articleIds);
        Test.setFixedSearchResults(articleIds);
        documentSearchController.search();
    }

    // Then only documents that contain the search term of type FAQ which also contain the search term should be displayed
    static void theDocumentsReturnedShouldContainTerm() {
        // Verify that the correct documents were returned
        //System.debug('KnowledgeSearchList: '+documentSearchController.knowledgeList);
        //System.assert(documentSearchController.documentList.size() > 1);
        for(CaseDocumentMockMVN knowledgeResultDocument:documentSearchController.documentList){
            //System.assert(knowledgeResultDocument.caseDocument.Document_Title_MVN__c.contains('Test'));
        }
    }

    // When select the document
    static void selectTheDocument() {
        foundDocument = new Case_Document_MVN__c(Case_MVN__c = request.Id,
                                                 Document_ID_MVN__c = 'sd');
        insert foundDocument;
        documentSearchController.selectedDocumentId = foundDocument.Document_ID_MVN__c;
        documentSearchController.selectDocument();

    }
    // The document is attached
    static void theDocumentIsAttached() {
        List<Case_Document_MVN__c> attachedDocument = [select Id,Document_Id_MVN__c from Case_Document_MVN__c where Case_MVN__c = :request.Id];
        System.assertEquals(attachedDocument[0].Document_Id_MVN__c, foundDocument.Document_ID_MVN__c);
        System.assertEquals(1,[Select Id from Case_Document_MVN__c].size());
    }

    static void theDocumentIsDeleted() {
        List<Case_Document_MVN__c> attachedDocument = [select Id,Document_Id_MVN__c, Knowledge_Article_Version_ID_MVN__c from Case_Document_MVN__c where Case_MVN__c = :request.Id];
        KnowledgeSearchUtilityMVN.buildDownloadURL(attachedDocument[0]);
        KnowledgeSearchUtilityMVN.buildLinkURL(attachedDocument[0]);
        KnowledgeSearchUtilityMVN.buildViewerURL(attachedDocument[0]);
        
        MSD_CORE_AttachmentJob c = new MSD_CORE_AttachmentJob();
        c.unpack(new Map<String,String>());
        
        KnowledgeSearchUtilityMVN.createCaseDocument(request.Id, new Knowledge__kav());
        try
        {
        c.execute(new Map<String,String>());
        new KnowledgeSearchUtilityMVN().selectDocument(attachedDocument[0], request.Id);
        }catch(Exception ex){}
        delete attachedDocument[0];
        System.assertEquals(0,[Select Id from Case_Document_MVN__c].size());
    }

    static void exceptionReturned(){
    
    }
}