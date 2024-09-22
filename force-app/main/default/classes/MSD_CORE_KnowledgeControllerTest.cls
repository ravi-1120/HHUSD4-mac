@isTest
public class MSD_CORE_KnowledgeControllerTest {
    public static Knowledge__kav know = new Knowledge__kav();
    
    List<Knowledge__kav> KRecordlist  = new List<Knowledge__kav>();
    public static Knowledge__kav kRecord = new Knowledge__kav();
    static{
        
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
        insert kRecord;
    }
    
   
    
    
    @isTest static void testGetKnowledgeList(){
        Test.startTest();
        MSD_CORE_KnowledgeController knowCon = new MSD_CORE_KnowledgeController();
        knowCon.getKnowledgeList();
        Test.stopTest();  
    }
    @isTest static void testGetKnowledgeExpirationList(){
        Test.startTest();
        MSD_CORE_KnowledgeController knowCon = new MSD_CORE_KnowledgeController();
        knowCon.getKnowledgeExpirationList();
        Test.stopTest();  
    }
    @isTest static void testGetKnowledgeArticleId(){
        Test.startTest();
        try{
        MSD_CORE_KnowledgeController.getKnowledgeArticleId('test');
        }catch(exception e){}
        Test.stopTest();  
    }
   /* @isTest static void testGetRedirectingURLForPrintArticles(){
        Test.startTest();
        try{
        MSD_CORE_KnowledgeController.getRedirectingURLForPrintArticles('test');
             }catch(exception e){}
        Test.stopTest();  
    }*/
    /*@isTest static void testApproveKnowledgeWithChanges(){
        Test.startTest();
        try{
        MSD_CORE_KnowledgeController.approveKnowledgeWithChanges('test', 'test', 'test');
        }catch(exception e){}
        Test.stopTest();  
    }*/
    @isTest static void testArticleActions(){
        Test.startTest();
        MSD_CORE_KnowledgeController.articleActions(kRecord.Id);
        MSD_CORE_KnowledgeController.articleActions(know.Id);
        Test.stopTest();  
    }
    @isTest static void testPublishArticle(){
        Test.startTest();
        Knowledge__kav kav = new Knowledge__kav();
        MSD_CORE_KnowledgeController.publishArticle(know.Id);
        Test.stopTest();  
    }
    @isTest static void testGetWorkItemId(){
        Test.startTest();
        MSD_CORE_KnowledgeController.getWorkItemId(know.Id); 
        Test.stopTest();  
    }
    
    @isTest static void testGetWorkItemIdWithoutCurrentUser(){
        Test.startTest();
        MSD_CORE_KnowledgeController.getWorkItemIdWithoutCurrentUser(know.Id); 
        Test.stopTest();  
    }
    @isTest static void testGetStatus(){
        Test.startTest();
            MSD_CORE_KnowledgeController knowCon = new MSD_CORE_KnowledgeController();
            //Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            //Approval.ProcessResult result = Approval.process(req1);
            knowCon.getStatus();
        Test.stopTest();  

    }
    @isTest static void testGetKnowledgeRecord(){
        Test.startTest();
        MSD_CORE_KnowledgeController knowCon = new MSD_CORE_KnowledgeController();
        knowCon.getKnowledgeRecord(kRecord.Id);
        Test.stopTest();  
    }
    @isTest static void testApproveArtiles(){
        Test.startTest();
        MSD_CORE_KnowledgeController knowCon = new MSD_CORE_KnowledgeController();
        MSD_CORE_KnowledgeController.approveArtiles(kRecord.Id);
        MSD_CORE_KnowledgeController.approveArtiles(know.Id);
        MSD_CORE_KnowledgeController.publishArticle(kRecord.Id);
       // MSD_CORE_KnowledgeController.articleActions(kRecord.Id);

        Test.stopTest();  
    }
    @isTest static void testCheckProcessInstance(){
        Test.startTest();
            MSD_CORE_KnowledgeController.checkProcessInstance(know.Id);
            MSD_CORE_KnowledgeController.checkProcessInstance(kRecord.Id);
        Test.stopTest();  

    }
  
    @isTest static void testApproveKnowledgeWithChanges(){
           try{
            Test.startTest();
            MSD_CORE_KnowledgeController.approveKnowledgeWithChanges(know.Id,'test','Rejected');
            MSD_CORE_KnowledgeController.approveKnowledgeWithChanges(kRecord.Id,'test','Rejected');
          Test.stopTest(); 
       }catch(exception e){}
    }
    @isTest static void testApproveKnowledgeWithChangesApproved(){
    Test.startTest();
    try{
            MSD_CORE_KnowledgeController.approveKnowledgeWithChanges(know.Id,'test','Approved');
            MSD_CORE_KnowledgeController.approveKnowledgeWithChanges(kRecord.Id,'test','Approved');
            }catch(exception e){}
           Test.stopTest(); 
           
           }
    @isTest static void testApproveKnowledgeWithChangesPending(){
        Test.startTest();
        try{
            MSD_CORE_KnowledgeController.approveKnowledgeWithChanges(know.Id,'test','Pending');
            MSD_CORE_KnowledgeController.approveKnowledgeWithChanges(kRecord.Id,'test','Pending');
            }catch(exception e){}
           Test.stopTest(); 
           
           }
}