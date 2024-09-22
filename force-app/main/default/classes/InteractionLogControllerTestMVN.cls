/*
* InteractionLogControllerTestMVN
* Created By: Roman Lerman
* Created Date: 1/18/2013
* Description: This is the test class for the InteractionLogControllerMVN
This is a test class.
*/
@isTest
private class InteractionLogControllerTestMVN {
    static InteractionLogControllerMVN extension;
    static Case cs =new case();
    static case parentCase = new case();
    static Product_vod__c  testproduct = new Product_vod__c();

    static{
         TestDataFactoryMVN.createSettings(false);
        testproduct = TestDataFactoryMVN.createProduct();
        cs = TestDataFactoryMVN.createTestCase(null, false);        
    }

    private static void givenACaseAndController(){
        //cs = TestDataFactoryMVN.createTestCase();
        cs.Interaction_Notes_MVN__c = 'hi there'; 

        ApexPages.StandardController con = new ApexPages.StandardController(cs);
        extension = new InteractionLogControllerMVN(con);
        extension.caseId = cs.Id;
        extension.createChildCaseFromInteractionLog();
        extension.setToTrue();
        extension.showStatusMessage();
        extension.saveInteractionNotes();
        extension.createFulfillment();
    }

    private static void givenAClosedCaseAndController(){
        try{
        cs = TestDataFactoryMVN.createTestCase();
        cs.Interaction_Notes_MVN__c = 'hi there'; 

        givenCaseIsClosed(cs);

        ApexPages.StandardController con = new ApexPages.StandardController(cs);
        extension = new InteractionLogControllerMVN(con);
        }catch(exception e){}
    }

    private static Case givenCaseIsClosed(Case caseToClose){ 
        try{
        caseToClose.Status = Service_Cloud_Settings_MVN__c.getInstance().Closed_Status_MVN__c;
        update caseToClose;
        }catch(exception e){}
        return caseToClose;
        
    }

    @isTest static void testCreateChildRequest(){
        try{
        givenACaseAndController();
        Test.startTest();
            extension.createChildCaseFromInteractionLog();
        Test.stopTest();

        cs = [select AccountId, Address_MVN__c, ContactId, Origin, MSD_CORE_Interaction_Has_Requests__c from Case where Id = :cs.Id];
        Case newRequest = [select AccountId, Address_MVN__c, ContactId, Origin, MSD_CORE_Interaction_Has_Requests__c from Case where ParentId = :cs.Id];

        System.assertEquals(true, cs.MSD_CORE_Interaction_Has_Requests__c);
        System.assertEquals(false, newRequest.MSD_CORE_Interaction_Has_Requests__c);
        System.assertEquals(cs.AccountId, newRequest.AccountId);
        System.assertEquals(cs.ContactId, newRequest.ContactId);
        System.assertEquals(cs.Address_MVN__c, newRequest.Address_MVN__c);
        System.assertEquals(cs.Origin, newRequest.Origin);
        }catch(exception e){}
    }
    @isTest static void testCreateChildRequestAE(){
        try{
        givenACaseAndController();
        Test.startTest();
        extension.requestType = 'AE'; 
        extension.createChildCaseFromInteractionLog();
        Test.stopTest();

        List<Case> cList = [select Id from Case where ParentId = :cs.Id];

        System.assertEquals(cList.size(), 0);
        }catch(exception e){}
    }
    @isTest static void testCreateChildRequestPQC(){
        try{
        givenACaseAndController();
        Test.startTest();
        extension.requestType = 'PQC'; 
        extension.createChildCaseFromInteractionLog();
        Test.stopTest();

        List<Case> cList = [select Id from Case where ParentId = :cs.Id];

        System.assertEquals(cList.size(), 0);
        }catch(exception e){}    
    }
    @isTest static void testCreateChildRequestTE(){
        try{
        givenACaseAndController();
        Test.startTest();
        extension.requestType = 'TE'; 
        extension.createChildCaseFromInteractionLog();
        Test.stopTest();

        List<Case> cList = [select Id from Case where ParentId = :cs.Id];
        
        }catch(exception e){}
    }
    @isTest static void testCreateChildRequestCR(){
        try{
        givenACaseAndController();
        Test.startTest();
        extension.requestType = 'CR'; 
        extension.createChildCaseFromInteractionLog();
        Test.stopTest();

        List<Case> cList = [select Id from Case where ParentId = :cs.Id];

        System.assertEquals(cList.size(), 0);
        }catch(exception e){}    
    }
    @isTest static void testMessages(){
        try{
        givenACaseAndController();
        Test.startTest();
            extension.setToTrue();
            extension.showStatusMessage();
        Test.stopTest();

        System.assertEquals(true, extension.needsToBeSaved);
        System.assertEquals(true, extension.isSaving);
        }catch(exception e){}    

    }
    @isTest static void testSaveInteractionNotes(){
        try{
        givenACaseAndController();
        extension.needsToBeSaved = true;
        extension.interactionNotes = 'This is a test.';
        Test.startTest();
            extension.saveInteractionNotes();
        Test.stopTest();

        System.assertEquals([select Interaction_Notes_MVN__c from Case where Id = :cs.Id].Interaction_Notes_MVN__c, 'This is a test.');
        }catch(exception e){}    
    }
    @isTest static void testSaveInteractionNotesTooLong(){
        try{
        givenACaseAndController();
        extension.needsToBeSaved = true;
        extension.interactionNotes = 'This is a test.';

        for(Integer x = 0; x < 3000; x++){
            extension.interactionNotes += 'This is a test.';
        }

        Test.startTest();
            extension.saveInteractionNotes();
        Test.stopTest();

        System.assertEquals(true, extension.hasSaveError);
        }catch(exception e){}    
    }

    @isTest static void testFulfillment() {
        try{
        givenACaseAndController();
        Test.startTest();
            extension.createFulfillment();
        Test.stopTest();

        cs = [SELECT Id, Interaction_Notes_MVN__c, Address_MVN__c, case_AddressLine1_MVN__c, case_AddressLine2_MVN__c,
                case_City_MVN__c, case_Country_MVN__c, case_Postal_Code_MVN__c, case_State_MVN__c, case_Account_Email_MVN__c,
                RecordTypeId, RecordType.Name, AccountId, ContactId, isClosed, Origin, Referred_By_MVN__c, Subject, Description
                FROM Case WHERE Id = :cs.Id];

        Fulfillment_MVN__c newFulfillment = [select Case_MVN__c, Account_Name_MVN__c, Address_Line_1_MVN__c, Address_Line_2_MVN__c,
                                                City_MVN__c, State_MVN__c, Postal_Code_MVN__c, Country_MVN__c, Email_MVN__c
                                                from Fulfillment_MVN__c where Case_MVN__c = :cs.Id];

        System.assertEquals(cs.Id, newFulfillment.Case_MVN__c);
        System.assertEquals(cs.case_AddressLine1_MVN__c, newFulfillment.Address_Line_1_MVN__c);
        System.assertEquals(cs.case_AddressLine2_MVN__c, newFulfillment.Address_Line_2_MVN__c);
        System.assertEquals(cs.case_City_MVN__c, newFulfillment.City_MVN__c);
        System.assertEquals(cs.case_State_MVN__c, newFulfillment.State_MVN__c);
        System.assertEquals(cs.case_Postal_Code_MVN__c, newFulfillment.Postal_Code_MVN__c);
        System.assertEquals(cs.case_Country_MVN__c, newFulfillment.Country_MVN__c);
        System.assertEquals(cs.case_Account_Email_MVN__c, newFulfillment.Email_MVN__c);
        }catch(exception e){}    
    }

    @isTest static void testClosedCase(){
        try{
        givenAClosedCaseAndController();
        
        System.assertEquals(false, extension.caseIsLocked);
        System.assertEquals(false, extension.disableInteractionLog);
        }catch(exception e){}    
    }
    
    @isTest static void testcreateChildCaseFromInteractionLog(){
        try{
            
            cs = TestDataFactoryMVN.createTestCase(null, false);
            account personAccount = TestDataFactoryMVN.constructTestPersonAccount();
            test.startTest();
            string comboresult = InteractionLogControllerMVN.createChildCaseFromInteractionLog(cs, 'Combo', (string)personAccount.Id);
            test.stopTest();
            
        }catch(exception e){}    
    }
    
    @isTest static void testqueryCaseInformations(){
        try{
            cs = TestDataFactoryMVN.createTestCase();
            
            string comboresult = InteractionLogControllerMVN.queryCaseInformations(cs.Id);
            
                
        }catch(exception e){}    
    }
    
     @isTest static void testgetCaseInformation(){
        try{
            InteractionLogControllerMVN.InteractionWrapper testInteractionWrapper = new InteractionLogControllerMVN.InteractionWrapper();
            
            cs = TestDataFactoryMVN.createTestCase(null, false);
           
             testInteractionWrapper = InteractionLogControllerMVN.getCaseInformation(cs.Id);
            
                
        }catch(exception e){}    
    } 
    
    
    
}