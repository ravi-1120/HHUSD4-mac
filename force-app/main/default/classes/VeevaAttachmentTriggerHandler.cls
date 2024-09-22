public with sharing class VeevaAttachmentTriggerHandler extends VeevaTriggerHandler {

    private List<Attachment> oldAtts = new List<Attachment>();
    private List<Attachment> newAtts = new List<Attachment>();

    @TestVisible
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.oldAtts = (List<Attachment>)triggerOld;
        this.newAtts = (List<Attachment>)triggerNew;
    }
    protected override String sObjectType() {
        return 'Attachment';
    }

    @TestVisible
    protected override void beforeDelete() {
        Map<Id, SObject> entityIdToDoc = getEntityIdToAttsMap(oldAtts);
        VeevaFileObjectProcessorFactory.processFileObjectsValidation(oldAtts, entityIdToDoc, true);
    }

    @TestVisible
    protected override void beforeUpdate() {
        Map<Id, SObject> entityIdToDoc = getEntityIdToAttsMap(newAtts);
        VeevaFileObjectProcessorFactory.processFileObjectsValidation(newAtts, entityIdToDoc);
    }

    private static Map<Id, SObject> getEntityIdToAttsMap(List<Attachment> attachments) {
        Map<Id, SObject> entityIdToAtt = new Map<Id, SObject>();
        for (Attachment attachment : attachments) {
            entityIdToAtt.put(attachment.ParentId, attachment);
        }
        return entityIdToAtt;
    }
}