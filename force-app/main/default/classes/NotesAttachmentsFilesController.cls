public with sharing class NotesAttachmentsFilesController {
    @AuraEnabled
    public static List<NoteAttachmentFileWrapper> fetchNotesAttachmentsFiles(
        String recordId,
        Integer maxNum,
        String sortBy,
        String sortDirection
    ) {
        if (maxNum == null || maxNum < 0) {
            maxNum = 2500;
        }
        if (String.isBlank(sortBy)) {
            sortBy = 'LastModifiedDate';
        }
        if (String.isBlank(sortDirection)) {
            sortDirection = 'DESC';
        }

        List<ContentDocument> files = queryFiles(recordId, new List<String>(), sortBy, sortDirection, maxNum, false);
        List<NoteAndAttachment> attachments = queryNotesAndAttachments(recordId, sortBy, sortDirection, maxNum);

        return mergeLists(files, attachments, sortBy, sortDirection, maxNum);
    }

    @AuraEnabled
    public static List<ContentDocument> fetchFiles(String recordId, List<String> contentDocIds, Integer maxNum, String sortBy, String sortDirection) {
        if (maxNum == null || maxNum < 0) {
            maxNum = 2500;
        }
        if (String.isBlank(sortBy)) {
            sortBy = 'LastModifiedDate';
        }
        if (String.isBlank(sortDirection)) {
            sortDirection = 'DESC';
        }
        return queryFiles(recordId, contentDocIds, sortBy, sortDirection, maxNum, true);
    }

    @AuraEnabled
    public static List<Map<String, Object>> fetchNotes(String recordId, String sortBy, String sortDirection) {
        if (String.isBlank(sortBy)) {
            sortBy = 'LastModifiedDate';
        }
        if (String.isBlank(sortDirection)) {
            sortDirection = 'DESC';
        }
        return queryContentNotes(recordId, sortBy, sortDirection);
    }

    private static List<ContentDocument> queryFiles(
        String recordId,
        List<String> contentDocIds,
        String sortBy,
        String sortDirection,
        Integer maxNum,
        Boolean formatLastModified
    ) {
        Set<String> contentDocIdsSet = new Set<String>();
        if (contentDocIds != null) {
            contentDocIdsSet.addAll(contentDocIds);
        }

        if (!String.isBlank(recordId)) {
            for (ContentDocumentLink link : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
                contentDocIdsSet.add(link.ContentDocumentId);
            }
        }

        String query = 'SELECT Id, Title, ContentSize, FileExtension, CreatedBy.Name, Owner.Name, (SELECT Id, ContentBodyId from ContentVersions WHERE IsLatest = true)';
        if (formatLastModified == true) {
            query += ', FORMAT(LastModifiedDate)';
        } else {
            query += ', LastModifiedDate';
        }
        query += ' FROM ContentDocument WHERE Id IN :contentDocIdsSet AND FileType != \'SNOTE\'';
        if (String.isNotBlank(sortBy)) {
            query += ' ORDER BY ' + sortBy;
            if (String.isNotBlank(sortDirection)) {
                query += ' ' + sortDirection;
            }
        }
        if (maxNum != null && maxNum >= 0) {
            query += ' LIMIT :maxNum';
        }
        return Database.query(query);
    }

    private static List<NoteAndAttachment> queryNotesAndAttachments(
        String recordId,
        String sortBy,
        String sortDirection,
        Integer maxNum
    ) {
        Id parentRecordId = Id.valueOf(recordId);
        String parentObjectApiName = parentRecordId.getSObjectType().getDescribe().getName();
        String query = 'SELECT Id, (SELECT Id, IsNote, Title, LastModifiedDate, CreatedBy.Name, Owner.Name';
        query += ' FROM NotesAndAttachments';
        if (String.isNotBlank(sortBy)) {
            query += ' ORDER BY ' + sortBy;
            if (String.isNotBlank(sortDirection)) {
                query += ' ' + sortDirection;
            }
        }
        if (maxNum != null && maxNum >= 0) {
            query += ' LIMIT :maxNum';
        }
        query += ') FROM ' + parentObjectApiName + ' WHERE Id = :recordId';
        SObject result = Database.query(query);
        return result.getSObjects('NotesAndAttachments');
    }

    private static List<Map<String, Object>> queryContentNotes(String recordId, String sortBy, String sortDirection) {
        Map<Id, Id> contentDocToContentDocLinkMap = new Map<Id,Id>();

        for (ContentDocumentLink link : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
            contentDocToContentDocLinkMap.put(link.ContentDocumentId, link.Id);
        }

        Set<Id> contentDocIds = contentDocToContentDocLinkMap.keySet();

        String query = 'SELECT Id, Title, TextPreview, CreatedBy.Name, FORMAT(LastModifiedDate), LastModifiedBy.Name';
        query += ' FROM ContentNote WHERE Id IN :contentDocIds';
        if (String.isNotBlank(sortBy)) {
            query += ' ORDER BY ' + sortBy;
            if (String.isNotBlank(sortDirection)) {
                query += ' ' + sortDirection;
            }
        }
        query += ' LIMIT 2500';
        List<SObject> contentNotes = Database.query(query);
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (SObject note : contentNotes) {
            Map<String, Object> noteMap = note.getPopulatedFieldsAsMap().clone();
            noteMap.put('contentDocumentLinkId', contentDocToContentDocLinkMap.get(note.Id));
            results.add(noteMap);
        }
        return results;
    }

    /**
     * merges a sorted list of ContentDocuments and a sorted list of NotesAndAttachments
     * returns sorted list of NoteAttachmentFileWrapper
     */
    @TestVisible
    private static List<NoteAttachmentFileWrapper> mergeLists(
        List<ContentDocument> files,
        List<NoteAndAttachment> attachments,
        String sortBy,
        String sortDirection,
        Integer maxNum
    ) {
        List<NoteAttachmentFileWrapper> result = new List<NoteAttachmentFileWrapper>();
        Integer fileIdx = 0;
        Integer fileLength = files != null ? files.size() : 0;
        Integer attachmentIdx = 0;
        Integer attachmentLength = attachments != null ? attachments.size() : 0;
        if (maxNum == null) {
            maxNum = 2500;
        }
        while (fileIdx < fileLength && attachmentIdx < attachmentLength && fileIdx + attachmentIdx < maxNum) {
            if (compareField(files.get(fileIdx), attachments.get(attachmentIdx), sortBy, sortDirection)) {
                result.add(new NoteAttachmentFileWrapper(files.get(fileIdx)));
                fileIdx++;
            } else {
                result.add(new NoteAttachmentFileWrapper(attachments.get(attachmentIdx)));
                attachmentIdx++;
            }
        }
        while (fileIdx < fileLength && fileIdx + attachmentIdx < maxNum) {
            result.add(new NoteAttachmentFileWrapper(files.get(fileIdx)));
            fileIdx++;
        }
        while (attachmentIdx < attachmentLength && fileIdx + attachmentIdx < maxNum) {
            result.add(new NoteAttachmentFileWrapper(attachments.get(attachmentIdx)));
            attachmentIdx++;
        }
        return result;
    }

    /**
     * compare a ContentDocument to a NoteAndAttachment
     * returns true if the file should appear before the note/attachment
     */
    private static Boolean compareField(ContentDocument file, NoteAndAttachment attachment, String fieldName, String sortDirection) {
        Boolean sortAscending = 'ASC'.equalsIgnoreCase(sortDirection);
        if ('Title'.equalsIgnoreCase(fieldName)) {
            return (file.Title > attachment.Title) ^ sortAscending;
        }
        if ('LastModifiedDate'.equalsIgnoreCase(fieldName)) {
            return (file.LastModifiedDate > attachment.LastModifiedDate) ^ sortAscending;
        }
        if ('CreatedBy.Name'.equalsIgnoreCase(fieldName)) {
            return (file.CreatedBy.Name > attachment.CreatedBy.Name) ^ sortAscending;
        }
        if ('Owner.Name'.equalsIgnoreCase(fieldName)) {
            return (file.Owner.Name > attachment.Owner.Name) ^ sortAscending;
        }
        throw new AuraHandledException('invalid sort column');
    }
}