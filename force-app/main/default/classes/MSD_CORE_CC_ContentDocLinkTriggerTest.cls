@isTest
public class MSD_CORE_CC_ContentDocLinkTriggerTest {

    @isTest
    public static void testdoclink(){
        string before = 'Testing base 64 encode';            
         Blob beforeblob = Blob.valueOf(before);
        
          
           
         //Insert contentdocument data
         ContentVersion cv = new ContentVersion();
         cv.title = 'test content trigger';      
         cv.PathOnClient ='test';           
         cv.VersionData =beforeblob; 
         
         insert cv;         
                                                
         ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
  		Knowledge__kav kRecord = new Knowledge__kav();
        kRecord.Title = 'Testing the Knowledge';
        kRecord.UrlName = 'Testing-the-Knowledge';
        kRecord.MSD_CORE_Audience__c = 'CONSUMER';
        kRecord.MSD_CORE_KnwlArtCat__c = 'NSC';
        
        insert kRecord;
        System.debug(kRecord.Id);
         
//insert new ContentDocumentLink
        ContentDocumentLink newFileShare = new ContentDocumentLink();
        newFileShare.contentdocumentid = testcontent.contentdocumentid;
        newFileShare.LinkedEntityId = kRecord.Id;
        newFileShare.ShareType= 'I';
        insert newFileShare;
        
    }
    
}