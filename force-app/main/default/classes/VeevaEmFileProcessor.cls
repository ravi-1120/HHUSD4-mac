public inherited sharing class VeevaEmFileProcessor extends VeevaFileObjectProcessorFactory.BaseProcessor {
    public static final Set<String> lockedEventStatusSet = new Set<String>{ 'Canceled_vod', 'Closed_vod' };

    public VeevaEmFileProcessor() {
        super(
            new Set<String>{
                'EM_Event_vod__c',
                'EM_Attendee_vod__c',
                'EM_Event_Budget_vod__c',
                'EM_Event_Speaker_vod__c',
                'EM_Event_Session_vod__c',
                'EM_Event_Session_Attendee_vod__c',
                'EM_Expense_Estimate_vod__c',
                'Expense_Header_vod__c',
                'Expense_Line_vod__c',
                'EM_Event_Team_Member_vod__c',
                'EM_Event_Material_vod__c'
            }
        );
    }

    protected override void process(
        Set<Id> entityIds,
        Map<Id, SObject> entitiesToFileObj,
        boolean skipEditPermissions,
        String objectName,
        Set<Id> filterEntityIds,
        boolean isDelete
    ) {
        if (skipEditPermissions || sObjUpdateable(objectName)) {
            Id entityId;
            String errorMessage = VeevaMessageController.getMsgWithDefault(
                'NOT_ALLOWED_TO_EDIT',
                'Common',
                'You do not have permission to edit this record.'
            );
            String errorDeleteMessage = VeevaMessageController.getMsgWithDefault(
                'NOT_ALLOWED_TO_DELETE',
                'Common',
                'You do not have permission to delete this record.'
            );
            String selectQuery = generateSelectQueryString(objectName);
            String query = selectQuery + ' FROM ' + objectName + ' WHERE Id in :entityIds';
            List<SObject> sObjs = Database.query(query);
            Set<Id> integrationDocuments = getIntegrationDocuments(entitiesToFileObj, isDelete);
            Set<Id> contentNotes = getContentNotes(entitiesToFileObj);

            for (SObject sObj : sObjs) {
                entityId = sObj.Id;
                boolean locked = isEventLocked(sObj, objectName);
                if (locked && entitiesToFileObj.containsKey(entityId)) {
                    SObject fileObj = entitiesToFileObj.get(entityId);
                    if (contentNotes.contains(fileObj.Id)) {
                        continue;
                    }
                    if (isDelete) {
                        if (!integrationDocuments.contains(fileObj.Id)) {
                            fileObj.addError(errorDeleteMessage);
                        }
                    } else {
                        fileObj.addError(errorMessage);
                    }
                }
            }
        }
    }

    private String generateSelectQueryString(String objectName) {
        String selectQueryStr;
        if ('EM_Event_vod__c' == objectName) {
            selectQueryStr = 'SELECT Lock_vod__c, Status_vod__c ';
        } else if ('EM_Event_Session_Attendee_vod__c' == objectName) {
            selectQueryStr = 'SELECT Event_Session_vod__r.Event_vod__r.Lock_vod__c, Event_Session_vod__r.Event_vod__r.Status_vod__c ';
        } else {
            selectQueryStr = 'SELECT Event_vod__r.Lock_vod__c, Event_vod__r.Status_vod__c ';
        }
        return selectQueryStr;
    }

    private boolean isEventLocked(SObject sObj, String objectName) {
        boolean isLocked = false;
        if ('EM_Event_vod__c' == objectName) {
            isLocked = (boolean) sObj.get('Lock_vod__c') || lockedEventStatusSet.contains((String) sObj.get('Status_vod__c'));
        } else if (
            'EM_Event_Session_Attendee_vod__c' == objectName &&
            sObj.getSobject('Event_Session_vod__r') != null &&
            sObj.getSobject('Event_Session_vod__r').getSobject('Event_vod__r') != null
        ) {
            isLocked =
                (boolean) sObj.getSobject('Event_Session_vod__r').getSobject('Event_vod__r').get('Lock_vod__c') ||
                lockedEventStatusSet.contains((String) sObj.getSobject('Event_Session_vod__r').getSobject('Event_vod__r').get('Status_vod__c'));
        } else if (sObj.getSobject('Event_vod__r') != null) {
            isLocked =
                (boolean) sObj.getSobject('Event_vod__r').get('Lock_vod__c') ||
                lockedEventStatusSet.contains((String) sObj.getSobject('Event_vod__r').get('Status_vod__c'));
        }
        return isLocked;
    }

    private Set<Id> getIntegrationDocuments(Map<Id, SObject> entitiesToFileObj, boolean isDelete) {
        Set<Id> integrationDocuments = new Set<Id>();
        if (isDelete) {
            Map<Id, Id> docIdTofileObjIdMap = new Map<Id, Id>();
            for (SObject fileObj : entitiesToFileObj.values()) {
                if (fileObj instanceof ContentDocument) {
                    docIdTofileObjIdMap.put(fileObj.Id, fileObj.Id);
                } else if (fileObj instanceof ContentDocumentLink) {
                    docIdTofileObjIdMap.put(((ContentDocumentLink) fileObj).ContentDocumentId, fileObj.Id);
                }
            }
            for (ContentVersion version : [
                SELECT ContentDocumentId, TagCsv
                FROM ContentVersion
                WHERE IsLatest = true AND ContentDocumentId IN :docIdTofileObjIdMap.keySet()
            ]) {
                if (version.TagCsv == 'EM_VAULT_INT') {
                    integrationDocuments.add(docIdTofileObjIdMap.get(version.ContentDocumentId));
                }
            }
        }
        return integrationDocuments;
    }

    private Set<Id> getContentNotes(Map<Id, SObject> entitiesToFileObj) {
        Set<Id> contentNotes = new Set<Id>();
        Map<Id, Id> docIdToLinkId = new Map<Id, Id>();
        for (SObject fileObj : entitiesToFileObj.values()) {
            if (fileObj instanceof ContentDocument && 'SNOTE'.equals(((ContentDocument) fileObj).FileType)) {
                contentNotes.add(fileObj.Id);
            } else if (fileObj instanceof ContentDocumentLink) {
                docIdToLinkId.put(((ContentDocumentLink) fileObj).ContentDocumentId, fileObj.Id);
            }
        }
        if (!docIdToLinkId.isEmpty()) {
            for (ContentDocument doc : [SELECT Id FROM ContentDocument WHERE Id IN :docIdToLinkId.keySet() AND FileType = 'SNOTE']) {
                contentNotes.add(docIdToLinkId.get(doc.Id));
            }
        }
        return contentNotes;
    }
}