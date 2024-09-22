//This is a test class.
@isTest
private class RecordTypeControllerTest {
    
    public static Case testCase{set;get;}
    public static Case testCase2{set;get;}
    public static Id testCaseId;
    
    static{
        TestDataFactoryMVN.createSettings(false);
        testCase = new case();
        testCase2 = new case();
        testCase = TestDataFactoryMVN.createTestCase(null, false);
        testCase2 = TestDataFactoryMVN.createTestCase(); 
    }
    
    @isTest static void testupdateCaseDesc() {
        Test.startTest();
        RecordTypeController.updateCaseDesc(testCase2.Id, 'updateDesc');
        Test.stopTest(); 
    } 
    
    @isTest static void testgetCaseRecord() {
        Test.startTest();
        list<case> testCaseList = RecordTypeController.getCaseRecord(testCase.Id);
        Test.stopTest(); 
    }
    
    @isTest static void testreadOnlyCheck() {
        Test.startTest();
        RecordTypeController.readOnlyCheck();
        Test.stopTest(); 
    }
    
    @isTest static void testgetDescInfo() {
        Test.startTest();
        RecordTypeController.DescWrapper resultdeswrap = new RecordTypeController.DescWrapper();
        resultdeswrap = RecordTypeController.getDescInfo();
        Test.stopTest(); 
    }
    
    @isTest static void testDescWrapper() {
        Test.startTest();
        RecordTypeController.DescWrapper resultdeswrap = new RecordTypeController.DescWrapper();
        Test.stopTest(); 
    }
    
}