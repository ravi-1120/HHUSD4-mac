//This is a test class.
@isTest
public class MSD_CORE_KnowledgeTriggerHandlerTest {
    Public static Case c = new Case();
    public static Knowledge__kav kRecord = new Knowledge__kav();
    public static List<Knowledge__kav> KRecordlist  = new List<Knowledge__kav>(); 
    public static Map<Id, Knowledge__kav> oldoppmap = new Map<Id, Knowledge__kav>();
    
    static
    {  
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
    
    @isTest static void testupdateOwner(){
        Test.startTest();
        MSD_CORE_KnowledgeTriggerHandler.updateOwner(KRecordlist);
        Test.stopTest();
        
    } 
    @isTest static void testCreateComments(){
        Test.startTest();
        MSD_CORE_KnowledgeTriggerHandler.createComments(kRecordlist);
        Test.stopTest();
        
    } 
    @isTest static void testAlertTemplateChange(){
        Test.startTest();
        MSD_CORE_KnowledgeTriggerHandler.alertTemplateChange(kRecordlist, oldoppmap);
        Test.stopTest();
        
    } 
    @isTest static void testUpdateAssignedTo(){
        Test.startTest();
        try{
        MSD_CORE_KnowledgeTriggerHandler.updateAssignedTo(kRecordlist, oldoppmap);
        }catch(exception e){}
        Test.stopTest();
        
    } 
    @isTest static void testAssingOldVersionToCase(){
        Test.startTest();
        try{
            MSD_CORE_KnowledgeTriggerHandler.assingOldVersionToCase(kRecordlist);
        }catch(exception e){}
        Test.stopTest();
        
    } 
    @isTest static void testCopyFromTemplate(){
        Test.startTest();
        MSD_CORE_KnowledgeTriggerHandler.copyFromTemplate(kRecordlist);
        Test.stopTest();
        
    } 
    
}