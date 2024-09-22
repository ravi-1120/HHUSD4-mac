public inherited sharing class VeevaContentDocumentTriggerHandler extends VeevaTriggerHandler {

    private List<SObject> oldDocs = new List<SObject>();
    private Map<Id, SObject> oldDocsMap = new Map<Id, SObject>();
    private List<SObject> newDocs = new List<SObject>();
    
    private static final String BULK_PROCESS_RECORD_TITLE_PREFIX = 'CLM Content';
    private static final String REFERENCE_DOCUMENT_PREFIX = 'CLM Reference';
    private static final String ENGAGE_PROFILE_PREFIX = 'Engage Profile';
    
    // Static ContentDocumentLink List preserves records in After Delete Context
    private static List<ContentDocumentLink> docLinksBeforeDeletion = new List<ContentDocumentLink>();

    @TestVisible
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.oldDocs = triggerOld;
        this.oldDocsMap = triggerOldMap;
        this.newDocs = triggerNew;
    }
    
    @TestVisible 
    protected override void filterRecordsToProcess(System.TriggerOperation context, List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        super.filterRecordsToProcess(context, triggerNew, triggerOld, triggerNewMap, triggerOldMap);
        
        //Filter records starting with 'CLM Content' or 'Engage Profile' for Bulk processing.
        for(SObject record: triggerOld) {
            ContentDocument doc = (ContentDocument)record;
            if(doc.Title.startsWithIgnoreCase(BULK_PROCESS_RECORD_TITLE_PREFIX) || doc.Title.startsWithIgnoreCase(ENGAGE_PROFILE_PREFIX) || doc.Title.startsWithIgnoreCase(REFERENCE_DOCUMENT_PREFIX)) {
            	Id oldDocId = doc.Id;
                
                filterRecord(oldDocId, oldRecordsMapToProcess, triggerOldMap, oldRecordsToProcess);
                filterRecord(oldDocId, newRecordsMapToProcess, triggerNewMap, newRecordsToProcess);
            }
        }
    }
    
    private void filterRecord(Id docIdTobeRemoved, Map<ID, SObject> recordsMapToProcess, Map<ID, SObject> triggerMap, List<SObject> recordsToProcess) {
        recordsMapToProcess.remove(docIdTobeRemoved);
        SObject docToBeRemoved = triggerMap!=null?triggerMap.get(docIdTobeRemoved):null;
        if(docToBeRemoved != null) {
            Integer recIndex = recordsToProcess.indexOf(docToBeRemoved);
            if(recIndex != -1) {
                recordsToProcess.remove(recIndex);
            }
        }
    }

    protected override String sObjectType() {
        return 'ContentDocument';
    }

    @TestVisible
    protected override void beforeUpdate() {
        Map<Id, ContentDocument> newVersionDocs = new Map<Id, ContentDocument>();
        Map<Id, ContentDocument> docs = new Map<Id, ContentDocument>();

        for (Integer i=0; i<newDocs.size(); i++) {
            ContentDocument oldDoc = (ContentDocument)oldDocs.get(i);
            ContentDocument newDoc = (ContentDocument)newDocs.get(i);
            docs.put(newDoc.Id, newDoc);
            if (oldDoc.LatestPublishedVersionId != newDoc.LatestPublishedVersionId) {
                //changed VersionId means Upload New Version
                newVersionDocs.put(newDoc.Id, newDoc);
            }
        }
        processContentDocuments(docs, newVersionDocs, false, false);
    }

    @TestVisible
    protected override void beforeDelete() {
        processContentDocuments(this.oldDocsMap, this.oldDocsMap, true, false);
    }

    @TestVisible
    protected override void afterDelete() {
        VeevaEmMaterialProcessor emMaterialProcessor = new VeevaEmMaterialContentDocProcessor(docLinksBeforeDeletion);
        emMaterialProcessor.updateHasAttachmentFlagForDelete();
    }

    private static void processContentDocuments(Map<Id, SObject> docsMap, Map<Id, SObject> newVersionDocsMap, boolean isBeforeDelete, boolean skipEditPermissions) {
        List<ContentDocumentLink> docLinks = getContentDocumentLinks(docsMap.keySet());
        List<ContentDocumentLink> newVersionDocLinks = getContentDocumentLinks(newVersionDocsMap.keySet());
        if (isBeforeDelete == true) {
            docLinksBeforeDeletion.addAll(docLinks);
        }
        Map<Id, SObject> entityIdToDoc = getEntityIdToDocsMap(docLinks, docsMap);
        Map<Id, SObject> newVersionEntityIdToDoc = getEntityIdToDocsMap(newVersionDocLinks, docsMap);
        VeevaFileObjectProcessorFactory.processFileObjectsValidation(docLinks, entityIdToDoc, skipEditPermissions, newVersionEntityIdToDoc.keySet(), isBeforeDelete);
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(Set<Id> docIds) {
        if(docIds.isEmpty()) {
            return new List<ContentDocumentLink>();
        }
        return [
            SELECT Id, ContentDocumentId, LinkedEntityId, LinkedEntity.Name
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds
        ];
    }

    private static Map<Id, SObject> getEntityIdToDocsMap(List<ContentDocumentLink> docLinks, Map<Id, SObject> docsMap) {
        Map<Id, SObject> entityIdToDoc = new Map<Id, SObject>();
        for (ContentDocumentLink link : docLinks) {
            entityIdToDoc.put(link.LinkedEntityId, docsMap.get(link.ContentDocumentId));
        }
        return entityIdToDoc;
    }
}