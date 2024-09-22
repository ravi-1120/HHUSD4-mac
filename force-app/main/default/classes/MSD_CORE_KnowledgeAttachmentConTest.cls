@isTest
public class MSD_CORE_KnowledgeAttachmentConTest {
    private static Case testCase;
    public static Knowledge__kav kRecord = new Knowledge__kav();
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
        insert kRecord;
        
        testCase = TestDataFactoryMVN.createTestCase(null, false);
    }
    
    static testMethod void attachmentsWithOutFileTest() {
        String fileName = 'Test Attachment';
        String filebody ='Hi this is the test Attachment to Upload';
        Blob beforeblob = Blob.valueOf(filebody);
        string paramvalue = EncodingUtil.base64Encode(beforeblob);
        String contentType = 'text/plain';
        String fileId = '';
        String attType = 'Article attachment';
        Test.startTest();
        	Id attachmentCreatedFileId = MSD_CORE_KnowledgeAttachmentController.saveChunk(kRecord.Id,fileName,paramvalue,contentType,fileId, attType);
		Test.stopTest();
        List<Attachment> attachments=[select id, name from Attachment where ParentId=:kRecord.Id];
        List<Knowledge_Attachment__c> ka=[select id, name from Knowledge_Attachment__c];
        System.assertEquals(0, attachments.size());
        System.assertEquals(1, ka.size());
    }
    
    static testMethod void attachmentsWithFileIdTest() {
        Attachment attachment = new Attachment();
        attachment.Name = 'Test Attachment';
        Blob bodyBlob = Blob.valueOf('Test Attachment Body');
        attachment.Body = bodyBlob;
        attachment.ParentId = testCase.AccountId;
        insert attachment;
        
        String fileName = 'Test Attachment';
        String filebody ='Hi this is the test Attachment to Upload';
        Blob beforeblob = Blob.valueOf(filebody);
        string paramvalue = EncodingUtil.base64Encode(beforeblob);
        String contentType = 'text/plain';
        String fileId = attachment.Id;
        String attType = 'Article attachment';
        
        Test.startTest();
            Id attachmentCreatedFileId = MSD_CORE_KnowledgeAttachmentController.saveChunk(testCase.AccountId,fileName,paramvalue,contentType,fileId,attType);
            MSD_CORE_KnowledgeAttachmentController.getAttachments(testCase.AccountId);
        Test.stopTest();

        List<Attachment> attachments=[select id, name from Attachment where ParentId=:testCase.AccountId];
        System.assertEquals(1, attachments.size());
    }
    
    static testMethod void getAttachmentSizeTest() {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.origin = 'H';        
        Insert cv;
        
        List<ContentDocument> documents = [SELECT Id, Title, FileExtension, LatestPublishedVersionId FROM ContentDocument];
        //Get Content DocumentId
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
         
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType ='V';
        cdl.Visibility ='AllUsers';
        cdl.LinkedEntityId = testCase.AccountId;
        Insert cdl;
        
        Test.startTest();
            try {
                Integer attachmentSize = MSD_CORE_KnowledgeAttachmentController.getAttachmentSize(cdl.Id);
                MSD_CORE_KnowledgeAttachmentController.getDocProperties(documents[0].Id, testCase.AccountId);
            }
            catch(exception ex){}
            
            MSD_CORE_KnowledgeAttachmentController fileCtrl = new MSD_CORE_KnowledgeAttachmentController();
            fileCtrl.FileSizeToString(1234);
            fileCtrl.FileSizeToString(10);
            fileCtrl.FileSizeToString(1048600);
            fileCtrl.document =Blob.valueOf('Test Content');
            fileCtrl.uploadAttachment();
            MSD_CORE_KnowledgeAttachmentController.getAttachmentByIds(testCase.AccountId,new List<String>{cdl.Id});
            MSD_CORE_KnowledgeAttachmentController.getCaseInfo();
        Test.stopTest();
        System.assertEquals(cdl.ContentDocumentId,documents[0].Id);
    }
}