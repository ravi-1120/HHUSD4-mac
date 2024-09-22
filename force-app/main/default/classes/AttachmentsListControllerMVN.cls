/*
 * AttachmentsListControllerMVN
 * Created By:      Kai Amundsen
 * Created Date:    12/18/2013
 * Description:     Generic controller which provides the functionality necessary to replace the 
 *                  standard Notes and Attachments related list (namely displaying and deleting the
 *                  Attachments).
 *
 * *** NOTE: Currently not used for the Merck implementation. ***
 */

 public without sharing class AttachmentsListControllerMVN {

    public String selectedAttachment {get; set;}
    public List<Attachment> attachmentList {get; set;}
    public Boolean noAttachments {get {return attachmentList.isEmpty();}}
    public sObject parentRecord {get;set;}
    public Boolean userHasNoAccess {get;private set;}
    public Service_Cloud_Settings_MVN__c settings {get;set;}

    public AttachmentsListControllerMVN(ApexPages.StandardController std){
        settings = Service_Cloud_Settings_MVN__c.getInstance();
        this.parentRecord = (sObject)std.getRecord();

        userHasNoAccess = !parentRecord.getSObjectType().getDescribe().isUpdateable();
        loadData();
    }

    private void loadData(){
        attachmentList = [Select Id, Name, CreatedDate, CreatedById, CreatedBy.Name, OwnerId, Owner.Name from Attachment where Parentid = :parentRecord.Id];
    }

    public PageReference deleteAttachment(){
        if (selectedAttachment != null){
            List<Attachment> attachmentsToDelete = [Select Id From Attachment WHERE id = :selectedAttachment];

            if(attachmentsToDelete != null && !attachmentsToDelete.isEmpty()) {
                try{
                    delete attachmentsToDelete;
                } catch (Exception e) {
                    ApexPages.addMessages(e);
                    System.debug(LoggingLevel.Error,e.getMessage());
                }

                loadData();
            }
        }

        return null;
    }
}