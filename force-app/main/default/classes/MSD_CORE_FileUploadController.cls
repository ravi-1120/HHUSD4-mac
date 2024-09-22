public class MSD_CORE_FileUploadController {
    @AuraEnabled
    public static Id saveChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        // check if fileId id ''(Always blank in first chunk), then call the saveTheFile method,
        //  which is save the check data and return the attachemnt Id after insert, 
        //  next time (in else) we are call the appentTOFile() method
        //   for update the attachment with reamins chunks   
        if (fileId == '') {
            fileId = saveTheFile(parentId, fileName, base64Data, contentType);
        } else {
            appendToFile(fileId, base64Data);
        }
 
        return Id.valueOf(fileId);
    }
 
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
 
        Attachment oAttachment = new Attachment();
        oAttachment.parentId = parentId;
 
        oAttachment.Body = EncodingUtil.base64Decode(base64Data);
        oAttachment.Name = fileName;
        oAttachment.ContentType = contentType;
 
        try
        { 
            insert oAttachment;
        }
        catch(Exception ex){
            String error = ex.getMessage();
            if(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, '))
                error = error.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1].replace(': []', '');
                
            AuraHandledException e = new AuraHandledException(error);
            e.setMessage(error);
            throw e;
        }
        
        return oAttachment.Id;
    }
 
    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
 
        Attachment a = [
            SELECT Id, Body
            FROM Attachment
            WHERE Id =: fileId
        ];
 
        String existingBody = EncodingUtil.base64Encode(a.Body);
 
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data);
        
        try
        {
            UtilitiesMVN.isAnonymizing = true; 
            update a;
        }
        catch(Exception ex){
            UtilitiesMVN.isAnonymizing = true; 
            delete a;
            
            String error = ex.getMessage();
            if(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, '))
                error = error.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1].replace(': []', '');
                
            AuraHandledException e = new AuraHandledException(error);
            e.setMessage(error);
            throw e;
        }
    }
    
    @AuraEnabled
    public static integer getAttachmentSize(String recordId){
        return [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId=:recordId];
    }
    
    @AuraEnabled
    public static AttachmentWrapper getAttachments(String recordId){
        AttachmentWrapper aw = new AttachmentWrapper([SELECT Id, ContentDocumentId, ContentDocument.Title,ContentDocument.ContentSize, ContentDocument.FileExtension, ContentDocument.CreatedDate 
                                                      FROM ContentDocumentLink 
                                                      WHERE LinkedEntityId =: recordId
                                                      Order By ContentDocument.CreatedDate desc],
                                                     [SELECT Id, Name, ContentType, BodyLength, CreatedDate 
                                                      FROM Attachment 
                                                      WHERE ParentId =: recordId
                                                      Order By CreatedDate desc]);
           
        return aw;
    }
    public String FileSizeToString(Long Value)
        {
            /* string representation if a file's size, such as 2 KB, 4.1 MB, etc */
            if (Value < 1024)
              return string.valueOf(Value) + ' Bytes';
            else
            if (Value >= 1024 && Value < (1024*1024))
            {
              //KB
              Decimal kb = Decimal.valueOf(Value);
              kb = kb.divide(1024,2);
              return string.valueOf(kb) + ' KB';
            }
            else
                
            {
              //MB
              Decimal mb = Decimal.valueOf(Value);
              mb = mb.divide((1024*1024),2);
              return string.valueOf(mb) + ' MB';
            }   
        }
    
    @AuraEnabled
    public static AttachmentWrapper getAttachmentByIds(String recordId, List<String> attIds){
        AttachmentWrapper aw = new AttachmentWrapper([SELECT Id, ContentDocumentId, ContentDocument.Title,ContentDocument.ContentSize, ContentDocument.FileExtension, ContentDocument.CreatedDate 
                                                      FROM ContentDocumentLink 
                                                      WHERE LinkedEntityId =: recordId
                                                      AND id in : attIds
                                                      Order By ContentDocument.CreatedDate desc],
                                                     [SELECT Id, Name, ContentType,BodyLength, CreatedDate 
                                                      FROM Attachment 
                                                      WHERE ParentId =: recordId
                                                      AND id in : attIds
                                                      Order By CreatedDate desc]);
        
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
    
    
    @AuraEnabled
    public static InteractionWrapper getCaseInfo(){
        InteractionWrapper wrap = new InteractionWrapper();
        wrap.userProfile = [SELECT Profile.Name FROM User WHERE Id =: UserInfo.getUserId()].Profile.Name;
        return wrap;
    }
    
     public class InteractionWrapper{
        @AuraEnabled
        public String userProfile;
    }
    
    @AuraEnabled
    public static void deleteAttachmentAura(String attachmentId){
        try
        {
            List<Attachment> attList = [select id, Name from Attachment where id =: attachmentId];
            if(attList.size() > 0)
                delete attList;
        }
        catch(Exception ex){
            String error = ex.getMessage();
            if(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, '))
                error = error.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1].replace(': []', '');
                
            AuraHandledException e = new AuraHandledException(error);
            e.setMessage(error);
            throw e;
        }
    }
    
    @AuraEnabled
    public static void deleteFiles(List<String> attachmentIds, String recordId){
        try
        {
            List<ContentDocumentLink> attList = [select id from ContentDocumentLink 
                                                 where ContentDocumentId in: attachmentIds
                                                 and LinkedEntityId =: recordId];
            if(attList.size() > 0)
                delete attList;
        }
        catch(Exception ex){
            String error = ex.getMessage();
            if(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, '))
                error = error.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1].replace(': []', '');
                
            AuraHandledException e = new AuraHandledException(error);
            e.setMessage(error);
            throw e;
        }
    }
    
    @AuraEnabled
    public static String getVFHostURL() {
        String hostname = Url.getSalesforceBaseUrl().getHost();
        System.debug('hostname-- '+ hostname);
        String myDomain = hostname.split('\\.')[0];
        String sbName = hostname.split('\\.')[1];
        Boolean isSandbox = sbName.left(2).equalsignorecase('cs');
        System.debug('myDomain-- '+ myDomain);
        String pod = [SELECT InstanceName FROM Organization].InstanceName.toLowerCase();
        //https://msdlogin--hhusd1--c.cs63.visual.force.com --D1 sandbox
        //https://msdlogin--c.na37.visual.force.com -- prod
        if(isSandbox){
            myDomain = myDomain.toLowerCase() +'--c.'+pod.toLowerCase();
            return 'https://' + myDomain +'.visual.force.com';
        }
        if(myDomain.containsIgnoreCase('--c'))
            return 'https://' + myDomain.toLowerCase() +'.'+ pod.toLowerCase() + '.visual.force.com';
        else
       		return 'https://' + myDomain.toLowerCase() + '--c.' + pod.toLowerCase() + '.visual.force.com';
       
    }
    
}