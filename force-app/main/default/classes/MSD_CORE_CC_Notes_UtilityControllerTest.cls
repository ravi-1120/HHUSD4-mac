@isTest
public class MSD_CORE_CC_Notes_UtilityControllerTest {
    public static MSD_CORE_Note__c objNote = new MSD_CORE_Note__c();
    Public static Case c = new Case();
    
    static{
        c = TestDataFactoryMVN.createTestCase(null, false);
        
        objNote.MSD_CORE_Case__c = c.Id;
        objNote.MSD_CORE_Note__c =  'test';
        
    }
    
    @isTest static void testGetNotes(){
        Test.startTest();
        MSD_CORE_CC_Notes_UtilityController.getNotes(c.Id);
        Test.stopTest();  
    }
    @isTest static void testGetCaseRT(){
        Test.startTest();
        MSD_CORE_CC_Notes_UtilityController.getCaseRT(c.Id);
        Test.stopTest();  
    }
    @isTest static void testGetCaseInfo(){
        Test.startTest();
        try{
        MSD_CORE_CC_Notes_UtilityController.getCaseInfo(c.Id);
        }catch(exception e){}
        Test.stopTest();  
    }
    @isTest static void testSaveCaseNote(){
        Test.startTest();
        try{
        MSD_CORE_CC_Notes_UtilityController.saveCaseNote(c.Id, objNote.MSD_CORE_Note__c);
        }catch(exception e){}
        Test.stopTest();  
    }
}