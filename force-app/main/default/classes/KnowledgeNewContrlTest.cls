@isTest
public class KnowledgeNewContrlTest {
    public static List<Schema.RecordTypeInfo> recordtypes = new List<Schema.RecordTypeInfo>();
    public static List<Knowledge__kav> kRecordlist = new List<Knowledge__kav>();
    static{
        Knowledge__kav kRecord = new Knowledge__kav();
        kRecord.Title = 'Testing the Knowledge Comment and Conversation flow.';
        kRecord.UrlName = 'Testing-the-Knowledge-Comment-and-Conversation-flow';
        kRecord.MSD_CORE_Audience__c = 'CONSUMER';
        kRecord.MSD_CORE_KnwlArtCat__c = 'NSC';
        kRecord.MSD_CORE_General_Cmnt__c = 'This is  a Generic comment used for testing.';        
        kRecord.MSD_CORE_After_Call_Work_Cmnt__c = 'This is a After Call Work comment used for testing.';
        kRecord.MSD_CORE_Information_Cmnt__c = 'This is a Information comment used for testing.';
        kRecord.MSD_CORE_Instruction_Comment__c = 'This is a Instruction comment used for testing.';
        kRecord.MSD_CORE_Preview_Cmnt__c = 'This is a Preview comment used for testing.';
        kRecord.MSD_CORE_Questions_Comment__c = 'This is a Questions comment used for testing.';
        kRecordlist.add(kRecord);
        insert kRecordlist;
    }
    @isTest static void testFetchRecordTypeValues(){
        Test.startTest();
        try{
            KnowledgeNewContrl.fetchRecordTypeValues('test');
        }catch(exception e){}
        Test.stopTest();
        
    }
    @isTest static void testGetTemplateValues(){
        Test.startTest();
        try{
            KnowledgeNewContrl.getTemplateValues('test');
        }catch(exception e){}
        Test.stopTest();
        
    }
    @isTest static void testGetFieldsToClone(){
        Test.startTest();
        try{
            KnowledgeNewContrl.getFieldsToClone();
        }catch(exception e){}
        Test.stopTest();
        
    }
    @isTest static void testGetProfileNamee(){
        Test.startTest();
        try{
            KnowledgeNewContrl.getProfileName();
        }catch(exception e){}
        Test.stopTest();
        
    }
    
}