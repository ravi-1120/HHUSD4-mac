public class MSD_CORE_AttachmentUploadController {

    public MSD_CORE_AttachmentUploadController(ApexPages.StandardController controller) {

    }


    public Attachment attachment {
        get {
            if (attachment == null)
                attachment = new Attachment();
            return attachment;
        }
        set;
    }

    public PageReference upload() {
    
        attachment.OwnerId = UserInfo.getUserId();
        attachment.ParentId = ApexPages.currentPage().getParameters().get('id');
        
        try {
            insert attachment;
        } catch (Exception e) {
            String err = e.getMessage();
            if(err.contains('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION'))
                err = err.split('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION')[1];
            
            //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, err));
            return null;
        } finally {
            attachment = new Attachment(); 
        }
    
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Attachment uploaded successfully.'));
        return null;
    }
}