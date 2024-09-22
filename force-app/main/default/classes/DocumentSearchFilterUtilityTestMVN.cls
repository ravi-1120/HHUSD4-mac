/**
 *  DocumentSearchFilterUtilityTestMVN
 *  Created By: Brian Aggen
 *  Created: July 21, 2014
 *  Description: Test class for DocumentSearchFilterUtilityMVN.
 **/
 @isTest
private class DocumentSearchFilterUtilityTestMVN {
    static Map<Id,String> acctRTMap {
        get {
            if(acctRTMap == null) {
                acctRTMap = new Map<Id,String>();
                // get all person account RTs
                for(RecordType rt : [select Id, DeveloperName from RecordType where SobjectType = 'Account' and IsPersonType = true]) {
                    acctRTMap.put(rt.Id,rt.DeveloperName);
                }
            }
            return acctRTMap;
        } set;
    }

    @isTest static void utilityReturnsCaseFieldNoCustomLogic() {
        TestDataFactoryMVN.createSettings(true);
        Boolean caseFieldReturned = false;
        Account testAcct = createTestAccount();
        Case testCase = createTestCase(testAcct);
        Case_Document_MVN__c searchDocument = new Case_Document_MVN__c();
        setupCustomSettingsNoCustomLogic(testAcct);

        test.startTest();
            DocumentSearchFilterUtilityMVN dsfu = new DocumentSearchFilterUtilityMVN();
            List<DocumentSearchFilterUtilityMVN.DocumentSearchFilterWrapperMVN> additionalQueryParams = dsfu.getAdditionalDocumentSearchParams(searchDocument, testCase.Id);
            Set<String> filteredFieldSet = dsfu.fieldsFilteredByCaseAcctRT(testCase.Id);
        test.stopTest();

        for(DocumentSearchFilterUtilityMVN.DocumentSearchFilterWrapperMVN dsfw : additionalQueryParams) {
            if(dsfw.caseDocumentField == 'Document_Subtype_MVN__c' && dsfw.isCustomFilter == false) {
                caseFieldReturned = true;
            }
        }
        System.assert(caseFieldReturned);
        System.assert(filteredFieldSet.size() > 0);
    }

    @isTest static void utilityReturnsCaseFieldWithCustomLogic() {
        TestDataFactoryMVN.createSettings(true);
        Boolean caseFieldReturned = false;
        Account testAcct = createTestAccount();
        Case testCase = createTestCase(testAcct);
        Case_Document_MVN__c searchDocument = new Case_Document_MVN__c();
        searchDocument.Document_Subtype_MVN__c = 'Non-Medical';
        setupCustomSettingsWithCustomLogic(testAcct);

        test.startTest();
            DocumentSearchFilterUtilityMVN dsfu = new DocumentSearchFilterUtilityMVN();
            List<DocumentSearchFilterUtilityMVN.DocumentSearchFilterWrapperMVN> additionalQueryParams = dsfu.getAdditionalDocumentSearchParams(searchDocument, testCase.Id);
            Set<String> filteredFieldSet = dsfu.fieldsFilteredByCaseAcctRT(testCase.Id);
        test.stopTest();

        for(DocumentSearchFilterUtilityMVN.DocumentSearchFilterWrapperMVN dsfw : additionalQueryParams) {
            if(dsfw.caseDocumentField == 'Document_Subtype_MVN__c' && dsfw.isCustomFilter == true) {
                caseFieldReturned = true;
            }
        }
        System.assert(caseFieldReturned);
        System.assert(filteredFieldSet.size() > 0);
    }

    static Account createTestAccount() {
        Id acctRTID = new List<Id>(acctRTMap.keySet())[0];
        Account testAcct = new Account(LastName='Test', RecordTypeId=acctRTID);
        insert testAcct;
        return testAcct;
    }

    static Case createTestCase(Account testAcct) {
        Case testCase = new Case();
        testCase.AccountId = testAcct.Id;
        testCase.Status ='Open';
        insert testCase;
        return testCase;
    }

    static void setupCustomSettingsNoCustomLogic(Account testAcct) {
        Account_Type_Document_Filters_MVN__c newATDF = new Account_Type_Document_Filters_MVN__c();
        newATDF.Name                       = testAcct.Id;
        newATDF.Account_Record_Type_MVN__c = acctRTMap.get(testAcct.RecordTypeId);
        newATDF.Case_Document_Field_MVN__c = 'Document_Subtype_MVN__c';
        //newATDF.Custom_Filter_Logic_MVN__c = 'NO TEST LOGIC';
        newATDF.Search_Filter_Value_MVN__c = 'Non-Medical';

        insert newATDF;

        Case_Document_Fields_MVN__c newCDF = new Case_Document_Fields_MVN__c();
        newCDF.Name                        = testAcct.Id;
        newCDF.Case_Document_Field_MVN__c  = 'Document_Subtype_MVN__c';
        newCDF.Document_Field_MVN__c       = 'MSD_CORE_Subtype__c';

        insert newCDF;
    }

    static void setupCustomSettingsWithCustomLogic(Account testAcct) {
        Account_Type_Document_Filters_MVN__c newATDF = new Account_Type_Document_Filters_MVN__c();
        newATDF.Name                       = testAcct.Id;
        newATDF.Account_Record_Type_MVN__c = acctRTMap.get(testAcct.RecordTypeId);
        newATDF.Case_Document_Field_MVN__c = 'Document_Subtype_MVN__c';
        newATDF.Custom_Filter_Logic_MVN__c = '=';
        newATDF.Search_Filter_Value_MVN__c = 'Non-Medical';

        insert newATDF;

        Case_Document_Fields_MVN__c newCDF = new Case_Document_Fields_MVN__c();
        newCDF.Name                        = testAcct.Id;
        newCDF.Case_Document_Field_MVN__c  = 'Document_Subtype_MVN__c';
        newCDF.Document_Field_MVN__c       = 'MSD_CORE_Subtype__c';

        insert newCDF;
    }

}