@isTest(SeeAllData=true)
public class CaseRecordTypeControllerMVNTest {
    
    private static Case testCase = new Case();
   
    static{
      testCase = TestDataFactoryMVN.createTestCase(null, false);
    }
    
    @isTest static private void testsetDisclaimer(){
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        CaseRecordTypeControllerMVN testCaseRecordTypeControllerMVN = new CaseRecordTypeControllerMVN(sc);
        testCaseRecordTypeControllerMVN.setDisclaimer(testCase);
        Test.stopTest();
    }
    
    @isTest static private void testupdateRecordType(){
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        CaseRecordTypeControllerMVN testCaseRecordTypeControllerMVN = new CaseRecordTypeControllerMVN(sc);
        testCaseRecordTypeControllerMVN.caseRecordTypeName = 'Combo Case';
        testCaseRecordTypeControllerMVN.updateRecordType();
        Test.stopTest();
    }
    
    @isTest static private void testsaveCase(){
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        CaseRecordTypeControllerMVN testCaseRecordTypeControllerMVN = new CaseRecordTypeControllerMVN(sc);
        testCaseRecordTypeControllerMVN.saveCase();
        string result  = CaseRecordTypeControllerMVN.saveCase(testCase.Id, 'General');
        Test.stopTest();
    }
    
    @isTest static private void testsetDisclaimerCaseDataWrapperMVN(){
        Test.startTest();
        CaseDataWrapperMVN testCaseDataWrapperMVN = new CaseDataWrapperMVN(testCase, 'General', true);
        testCaseDataWrapperMVN = CaseRecordTypeControllerMVN.setDisclaimer(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static private void testgetAEFieldsData(){
        Test.startTest();
        case resultcase = new case();
        resultcase = CaseRecordTypeControllerMVN.getAEFieldsData(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static private void testmarkDisclaimerRead(){
        Test.startTest();
        string result  = CaseRecordTypeControllerMVN.markDisclaimerRead(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static private void testsaveCase2(){
        Test.startTest();
        string result  = CaseRecordTypeControllerMVN.saveCase(testCase.Id, 'General');
        Test.stopTest();
    }
    
    @isTest static private void testupdateRecordType2(){
        Test.startTest();
        string result  = CaseRecordTypeControllerMVN.updateRecordType(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static private void testqueryAERequiredFields(){
        Test.startTest();
        CaseRecordTypeControllerMVN.FieldWrapper testFieldWrapper = new CaseRecordTypeControllerMVN.FieldWrapper('name', 'name', true, false, 'string');
        List<CaseRecordTypeControllerMVN.FieldWrapper> testFieldWrapperList = new List<CaseRecordTypeControllerMVN.FieldWrapper>();
        CaseRecordTypeControllerMVN.CaseAERequiredFieldWrapper testCaseAERequiredFieldWrapper = new CaseRecordTypeControllerMVN.CaseAERequiredFieldWrapper('General', testFieldWrapperList);
        testFieldWrapperList.add(testFieldWrapper);
        list<CaseRecordTypeControllerMVN.CaseAERequiredFieldWrapper> resultAERequiredFieldWrapperList = new list<CaseRecordTypeControllerMVN.CaseAERequiredFieldWrapper>();
        resultAERequiredFieldWrapperList  = CaseRecordTypeControllerMVN.queryAERequiredFields(testCase.Id);
        Test.stopTest();
    }
    
    @isTest static private void testgetCaseInfo(){
        Test.startTest();
        CaseRecordTypeControllerMVN.InteractionWrapper testInteractionWrapper = new CaseRecordTypeControllerMVN.InteractionWrapper();
        testInteractionWrapper  = CaseRecordTypeControllerMVN.getCaseInfo(testCase.Id);
        Test.stopTest();
    }
    
    
}