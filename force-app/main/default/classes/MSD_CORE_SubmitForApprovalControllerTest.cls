@isTest
Public class MSD_CORE_SubmitForApprovalControllerTest {
    
    private static Case testCase;
    public static Knowledge__kav kRecord = new Knowledge__kav();
    public static Knowledge__kav kRecord2 = new Knowledge__kav();
    public static List<Knowledge__kav> kRecordlist = new List<Knowledge__kav>();
    private static Id testId;
    private static ApexPages.StandardSetController stdController;
    
    static {
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
        kRecord.MSD_CORE_ApprStatus__c = 'Pending Submission';
        
        kRecord2.Title = 'Testing the Knowledge Comment and Conversation flow.';
        kRecord2.UrlName = 'Testing-the-Knowledge-Comment-and-Conversation-flow';
        kRecord2.MSD_CORE_Audience__c = 'CONSUMER';
        kRecord2.MSD_CORE_KnwlArtCat__c = 'NSC';
        kRecord2.MSD_CORE_General_Cmnt__c = 'This is  a Generic comment used for testing.';        
        kRecord2.MSD_CORE_After_Call_Work_Cmnt__c = 'This is a After Call Work comment used for testing.';
        kRecord2.MSD_CORE_Information_Cmnt__c = 'This is a Information comment used for testing.';
        kRecord2.MSD_CORE_Instruction_Comment__c = 'This is a Instruction comment used for testing.';
        kRecord2.MSD_CORE_Preview_Cmnt__c = 'This is a Preview comment used for testing.';
        kRecord2.MSD_CORE_Questions_Comment__c = 'This is a Questions comment used for testing.';
        kRecord2.MSD_CORE_ApprStatus__c = 'Approved';
        try{
            insert kRecord;
            insert kRecord2;
            kRecordlist.add(kRecord);
            //insert kRecordlist;
            
        }catch(exception e){}
           
        testCase = TestDataFactoryMVN.createTestCase(null, false);
        testId = testcase.Id;
		ApexPages.currentPage().getParameters().put('id', kRecord.Id);
        stdController = new  ApexPages.StandardSetController(kRecordlist);
       	stdController.setSelected(kRecordlist);
    }
    
    @isTest private static void testSubmitForApproval() {
         system.debug('kRecord '+ kRecord.Id);
         system.debug('kRecord2  '  + kRecord2.Id);
        system.debug('kRecord KnowledgeArticleId   '  + kRecord.KnowledgeArticleId);
        system.debug('kRecord2 KnowledgeArticleId   '  + kRecord2.KnowledgeArticleId); 
        test.startTest();
        ApexPages.StandardSetController stdController = new  ApexPages.StandardSetController(kRecordlist);
        stdController.setSelected(kRecordlist);
        ApexPages.currentPage().getParameters().put('id', kRecord.Id);
        MSD_CORE_SubmitForApprovalController testSubmitApp = new MSD_CORE_SubmitForApprovalController(stdController);
        testSubmitApp.comment = 'testComment';
        test.stopTest();
    }
    
    public MSD_CORE_SubmitForApprovalControllerTest () {
       
        test.startTest();
        ApexPages.StandardSetController stdController = new  ApexPages.StandardSetController(kRecordlist);
        stdController.setSelected(kRecordlist);
        ApexPages.currentPage().getParameters().put('id', kRecord.Id);
        
        Id testId = testcase.Id;
		ApexPages.currentPage().getParameters().put('id', testId);
        
        MSD_CORE_SubmitForApprovalController testSubmitApp = new MSD_CORE_SubmitForApprovalController(stdController);
        test.stopTest();
    }
    
    @isTest private static void testqueryUser() {
        test.startTest();
        ApexPages.StandardSetController stdController = new  ApexPages.StandardSetController(kRecordlist);
        MSD_CORE_SubmitForApprovalController testSubmitApp = new MSD_CORE_SubmitForApprovalController(stdController);
        stdController.setSelected(kRecordlist);
        ApexPages.currentPage().getParameters().put('id', kRecord.Id);
        
        testSubmitApp.queryUser();
        test.stopTest();
    }
    
    @isTest private static void testrecallApprval() {
        test.startTest();
        kRecordlist.clear();
        kRecordlist.add(kRecord2);
        ApexPages.StandardSetController stdController = new  ApexPages.StandardSetController(kRecordlist);
        MSD_CORE_SubmitForApprovalController testSubmitApp = new MSD_CORE_SubmitForApprovalController(stdController);
        stdController.setSelected(kRecordlist);
        
        testSubmitApp.comment = 'testComment';
		testSubmitApp.queryUser();
        
        ApexPages.currentPage().getParameters().put('id', kRecord2.Id);
        system.debug('kRecord  ' + kRecord );
        system.debug('kRecord2  '  + kRecord2);
        system.debug('kRecord2 KnowledgeArticleId   '  + kRecord2.KnowledgeArticleId);
        system.debug('kRecord KnowledgeArticleId   '  + kRecord.KnowledgeArticleId);
        
        knowledge__kav obj1 = [SELECT Id,Title FROM knowledge__kav WHERE id =: kRecord2.Id];
         system.debug('obj1   '  + obj1);
		KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
        testSubmitApp.recallApprval();
        test.stopTest();
    }
    
    
    
}

/*
Public static Knowledge__kav kav = new Knowledge__kav();
Public static Knowledge__kav kav2 = new Knowledge__kav();
public static List<Schema.RecordTypeInfo> recordtypes = new List<Schema.RecordTypeInfo>();
public static List<Knowledge__kav> kRecordlist = new List<Knowledge__kav>();
public static MSD_CORE_Comments__c comment = new MSD_CORE_Comments__c();
public static ProcessInstance testpiwi = new ProcessInstance ();
public static PageReference pageRef = new PageReference('/apex/MSD_CORE_SubmitForApproval');

//public static Account acc1 = new Account(Name='acc1');


static{

kav.MSD_CORE_Questions__c = 'test';
kav.MSD_CORE_Audience__c = 'CONSUMER';
kav.MSD_CORE_KnwlArtCat__c = 'NSC';
kav.Title = 'test';
kav.UrlName = '53jk';
kav.MSD_CORE_ApprStatus__c = 'Approved';
insert kav; 

kav2.MSD_CORE_Questions__c = 'test';
kav2.MSD_CORE_Audience__c = 'CONSUMER';
kav2.MSD_CORE_KnwlArtCat__c = 'NSC';
kav2.Title = 'test';
kav2.UrlName = '53jkk';
kav2.MSD_CORE_ApprStatus__c = 'Pending Submission';
insert kav2; 

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

kRecordlist.add(kav);
kRecordlist.add(kav2);
update kRecordlist;

//insert acc1;
ApexPages.StandardSetController stdController = new  ApexPages.StandardSetController(kRecordlist);
stdController.setSelected(kRecordlist);
MSD_CORE_SubmitForApprovalController testSubmitApp = new MSD_CORE_SubmitForApprovalController(stdController);
PageReference pageRef = new PageReference('/apex/MSD_CORE_SubmitForApproval');
Test.setCurrentPage(pageRef);

ProcessInstance proc = new ProcessInstance();
proc.LastActorId = userinfo.getuserid();
proc.TargetObjectId = kav.id;
insert proc;

ProcessInstanceWorkitem pworkItem = new ProcessInstanceWorkitem();
pworkItem.ActorId = userinfo.getuserId();
pworkItem.OriginalActorId = userinfo.getuserId();
pworkItem.ProcessInstanceId = proc.id;
insert pworkItem;

//MSD_CORE_SubmitForApprovalController.RecallApprovalWrapper testrecallApp= new  MSD_CORE_SubmitForApprovalController.RecallApprovalWrapper(true, kav);
//comment = new MSD_CORE_Comments__c(MSD_CORE_Knowledge__c = kRecord.Id, MSD_CORE_Comment__c = 'testcomment', MSD_CORE_Type__c = 'Recall' );
//PageReference pageRef = new PageReference('/apex/MSD_CORE_SubmitForApproval');
//Test.setCurrentPage(pageRef);



}  */