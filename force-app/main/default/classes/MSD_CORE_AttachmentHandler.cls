/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MSD_CORE_AttachmentHandler.cls
* @description - processing logic for the Attachment object
* @createdate - Apr 14th, 2015
*
*/

public class MSD_CORE_AttachmentHandler implements MSD_CORE_ITrigger {

    public MSD_CORE_AttachmentHandler() {}
    public void bulkAfter() {}
    public void beforeInsert(SObject so) {}
    public void beforeUpdate(SObject oldSo, SObject so) {}
    public void beforeDelete(SObject so) {}
    
    public void afterInsert(SObject so) {
        Attachment att = (Attachment)so;
        String objectTypeName = ((Id)att.parentId).getSObjectType().getDescribe().getName();

        if (objectTypeName == 'MSD_CORE_List_Attachment__c') {
            Map<String,String> opts = new Map<String,String>();
            opts.put('attachmentId', att.Id + '');
            opts.put('listAttachmentId', att.parentId + '');
            MSD_CORE_ListServices.handleListAttachmentTriggerOperation(opts);
        }

    }
    
    public void bulkBefore() {
        if(trigger.isInsert)
        {
            List<Attachment> attList = (List<Attachment>) trigger.new;
        
            for(Attachment a : attList)
            {
                String parentId = a.ParentId;
                
                if(parentId.startsWith('500'))
                {
                    integer ind = a.Name.lastIndexOf('.');
                    String dtString = System.now().format('MM-dd-yyyy');
                    a.Name = a.Name.substring(0, ind) + '-' + dtString + '.' + a.Name.substring((ind+1), a.Name.length());
                }
            }
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so) {}
    public void afterDelete(SObject so) {}
    public void andFinally() {}

}