public class MSD_CORE_CC_AttachmentsController {
    @AuraEnabled
    public static integer getAttachmentSize(String recordId){
        return [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId=:recordId];
    }
    
    @AuraEnabled
    public static AttachmentWrapper getAttachments(String recordId){
        AttachmentWrapper aw = new AttachmentWrapper([SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.CreatedDate 
                                                      FROM ContentDocumentLink 
                                                      WHERE LinkedEntityId =: recordId
                                                      Order By ContentDocument.CreatedDate desc
                                                      limit 3],
                                                     [SELECT Id, Name, ContentType, CreatedDate 
                                                      FROM Attachment 
                                                      WHERE ParentId =: recordId
                                                      Order By CreatedDate desc
                                                      limit 3]);
        
        return aw;
    }
    
    public class AttachmentWrapper 
    {
        @AuraEnabled public List<ContentDocumentLink> cdocList {get;set;}
        @AuraEnabled public List<Attachment> attachList {get;set;}
        
        public AttachmentWrapper(List<ContentDocumentLink> cdocList,
                                 List<Attachment> attachList)
        {
            this.cdocList = cdocList;
            this.attachList = attachList;
        }
    }
    
    @AuraEnabled
    public static void getDocProperties(String documentId, String recordId){
        List<ContentDocumentLink> cdl = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:recordId];  
        ContentDocument cd = [select Id, ContentSize, FileExtension from ContentDocument where Id=:documentId];
        System.debug(cdl+'::'+cdl.size());
        System.debug(cd);
        if(cdl.size() == 1){
            if(cd.FileExtension != 'zip'){
                System.debug(cdl);
                delete cdl;
                System.debug(cdl);
                String err = 'Do not attach a zip file to a case.  To proceed, attach each document in the zip file OR This case contains a zip file - Do not remove it.  To proceed, open a new case and cross reference this case.';
                /*AuraHandledException e = new AuraHandledException(System.Label.MSD_CORE_Attachment_Type_Warning);
                e.setMessage(System.Label.MSD_CORE_Attachment_Type_Warning);
                throw e;*/
                AuraHandledException e = new AuraHandledException(err);
                e.setMessage(err);
                throw e;
            }
        }
        else{
            if(cd.FileExtension == 'zip'){
                delete cd;
                
                AuraHandledException e = new AuraHandledException(System.Label.Too_Many_Results);
                e.setMessage(System.Label.Too_Many_Results);
                throw e;
            }
        }        
    }
    
    public transient Blob document {get; set;}
    public String contentType {get; set;}
    public String fileName {get; set;}

    public void uploadAttachment() {
        system.debug('document :::::' + document);
        if(document != null){
            Attachment attach = new Attachment(ContentType = contentType, Body = document, ParentID = ApexPages.currentPage().getParameters().get('id'), Name = filename);
            try {
                insert attach;
                document = null;
                contentType = null;
                filename = null;
            } catch(Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }
        }
    }
}


// comment added again
// comment 2