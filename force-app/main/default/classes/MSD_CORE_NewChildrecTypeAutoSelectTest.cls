//This is a test class.
@isTest
public class MSD_CORE_NewChildrecTypeAutoSelectTest {
    
    public static Account testAccount =  new Account();
    public static Case testCase = new Case();
    public static List<Case> testCaseList = new List<Case>();
    
    static {
        TestDataFactoryMVN.createSettings(true);
        testAccount = TestDataFactoryMVN.createTestHCP();
        testCase = TestDataFactoryMVN.createTestCase(null, false);
    }
    
    @isTest
    static void urlTest(){
        test.startTest();
        ApexPages.StandardController stdController = new  ApexPages.StandardController(testCase);
        MSD_CORE_SuspectedProductsController testNewChildRT = new MSD_CORE_SuspectedProductsController(stdController);
        try{
            PageReference resultPr = testNewChildRT.url();
        }catch(exception e){}
        test.stopTest();
    }
    
    @isTest
    static void SuspectedProduct(){
        test.startTest();
        ApexPages.StandardController stdController = new  ApexPages.StandardController(testCase);
        MSD_CORE_SuspectedProductsController testNewChildRT = new MSD_CORE_SuspectedProductsController(stdController);
        string result = testNewChildRT.getRecordTypeName(testCase.Id);
        test.stopTest();
    }
    
    @isTest
    static void getChildRecordTypeTest(){
        test.startTest();
        ApexPages.StandardController stdController = new  ApexPages.StandardController(testCase);
        MSD_CORE_SuspectedProductsController testNewChildRT = new MSD_CORE_SuspectedProductsController(stdController);
        try{
            Id resultId = testNewChildRT.getChildRecordTypeId(testCase.Id);
        }catch(exception e){}
        test.stopTest();
    }
    
    @isTest
    static void getParentSObjectIdTest(){
        test.startTest();
        ApexPages.StandardController stdController = new  ApexPages.StandardController(testCase);
        MSD_CORE_SuspectedProductsController testNewChildRT = new MSD_CORE_SuspectedProductsController(stdController);
        Map<String, String> testMap = new Map<String, String>();
        testMap.put('_lkid', 'First item');
        try{
            Id resultId = testNewChildRT.getParentSObjectId(testMap);
        }catch(exception e){}
        test.stopTest();
    }
    
    
}