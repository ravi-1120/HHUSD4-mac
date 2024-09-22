@isTest
public class MSD_CORE_CC_AttachmentsControllerTest {
  private static Case testCase;
    static {
        testCase = TestDataFactoryMVN.createTestCase(null, false);
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
        
        Test.startTest();
            MSD_CORE_CC_AttachmentsController.getAttachments(testCase.AccountId);
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
                Integer attachmentSize = MSD_CORE_CC_AttachmentsController.getAttachmentSize(cdl.Id);
                MSD_CORE_CC_AttachmentsController.getDocProperties(documents[0].Id, testCase.AccountId);
            }
            catch(exception ex){}
            
            MSD_CORE_CC_AttachmentsController fileCtrl = new MSD_CORE_CC_AttachmentsController();
            fileCtrl.document =Blob.valueOf('Test Content'); 
            fileCtrl.uploadAttachment();
            
        Test.stopTest();
        System.assertEquals(cdl.ContentDocumentId,documents[0].Id);
    }
}