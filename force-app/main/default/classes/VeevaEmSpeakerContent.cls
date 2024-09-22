@RestResource(urlMapping='/veeva/events-management/speakers/content')
global with sharing class VeevaEmSpeakerContent {
    private static final String CONTENT_DOCUMENT_ID = 'ContentDocumentId';
    private static final String CRM_CONTENT_TYPE_VOD_C = 'CRM_Content_Type_vod__c';
    private static final String LINKED_ENTITY_ID = 'LinkedEntityId';
    private static final String FILE_EXTENSION = 'FileExtension';
    private static final String VERSION_DATA = 'VersionData';
    private static final Set<String> CONTENT_DOCUMENT_LINK_FIELDS = new Set<String>{ CONTENT_DOCUMENT_ID, LINKED_ENTITY_ID };
    private static final Set<String> CONTENT_VERSION_FIELDS = new Set<String>{
        CONTENT_DOCUMENT_ID,
        CRM_CONTENT_TYPE_VOD_C,
        FILE_EXTENSION,
        VERSION_DATA
    };
    private static final Integer MAX_SPEAKER_IDS_FOR_CONTENT = 20;
    private static final Integer CONTENT_DOCUMENT_LINK_LIMIT = 900;
    private static final Integer MAX_FILE_SIZE_BYTES = 51200;
    private static final String[] VALID_FILE_TYPES = new List<String>{ 'jpg', 'jpeg', 'png', 'gif' };

    @TestVisible
    private class SpeakerContent {
        public String speakerId;
        public String contentType;
        public String fileExtension;
        public Blob versionData;

        public SpeakerContent(String speakerId, String contentType, String fileExtension, Blob versionData) {
            this.speakerId = speakerId;
            this.contentType = contentType;
            this.fileExtension = fileExtension;
            this.versionData = versionData;
        }
    }

    @TestVisible
    private class SpeakerContentResponse extends VeevaBaseResponse {
        public final List<SpeakerContent> data;

        public SpeakerContentResponse(List<SpeakerContent> content) {
            data = content;
        }
    }

    @HttpGet
    global static VeevaBaseResponse getSpeakerContent() {
        Map<String, String> queryParams = RestContext.request.params;
        String speakerIds = queryParams.get('speakerIds');
        String contentTypes = queryParams.get('contentTypes');

        VeevaBaseResponse contentResponse;
        RestResponse response = RestContext.response;
        response.statusCode = 200;

        if (String.isEmpty(speakerIds)) {
            contentResponse = new VeevaBaseResponse('FAILURE', 'speakerIds parameter must be populated');
            response.statusCode = 400;
        } else if (String.isEmpty(contentTypes)) {
            contentResponse = new VeevaBaseResponse('FAILURE', 'contentTypes parameter must be populated');
            response.statusCode = 400;
        } else {
            List<Id> speakerIdList = new List<Id>();
            for (String speakerIdString : speakerIds.split(',')) {
                Id speakerId = VODDatabaseApiUtils.getValidId(speakerIdString);
                if (speakerId != null) {
                    speakerIdList.add(speakerId);
                }
            }
            List<String> contentTypeList = String.escapeSingleQuotes(contentTypes).split(',');
            if (speakerIdList.isEmpty() || speakerIdList.size() > MAX_SPEAKER_IDS_FOR_CONTENT) {
                contentResponse = new VeevaBaseResponse(
                    'FAILURE',
                    'No valid speaker ids or more than ' +
                    MAX_SPEAKER_IDS_FOR_CONTENT +
                    ' speaker ids to process'
                );
                response.statusCode = 400;
            } else if (!checkQueryAccess(ContentDocumentLink.sObjectType, CONTENT_DOCUMENT_LINK_FIELDS)) {
                contentResponse = new VeevaBaseResponse('FAILURE', 'Missing FLS to ContentDocumentId, LinkedEntityId on ContentDocumentLink object');
                response.statusCode = 400;
            } else if (!checkQueryAccess(ContentVersion.sObjectType, CONTENT_VERSION_FIELDS)) {
                contentResponse = new VeevaBaseResponse(
                    'FAILURE',
                    'Missing FLS to ContentDocumentId, CRM_Content_Type_vod, FileExtension, VersionData on ContentVersion object'
                );
                response.statusCode = 400;
            } else {
                try {
                    List<SpeakerContent> data = getSpeakerContentData(speakerIdList, contentTypeList);
                    contentResponse = new SpeakerContentResponse(data);
                } catch (Exception e) {
                    contentResponse = new VeevaBaseResponse('FAILURE', e.getMessage());
                    response.statusCode = 400;
                }
            }
        }
        return contentResponse;
    }

    private static List<SpeakerContent> getSpeakerContentData(Id[] speakerIds, String[] contentTypes) {
        Map<Id, Set<String>> speakerToContentTypesMap = new Map<Id, Set<String>>();
        Map<Id, Id> contentVersionToSpeakerMap = new Map<Id, Id>();
        for (ContentDocumentLink contentDocLink : [
            SELECT LinkedEntityId, ContentDocument.LatestPublishedVersion.Id, ContentDocument.LatestPublishedVersion.CRM_Content_Type_vod__c
            FROM ContentDocumentLink
            WHERE
                LinkedEntityId IN :speakerIds
                AND ContentDocument.LatestPublishedVersion.ContentSize < :MAX_FILE_SIZE_BYTES
                AND ContentDocument.LatestPublishedVersion.CRM_Content_Type_vod__c IN :contentTypes
                AND ContentDocument.LatestPublishedVersion.FileExtension IN :VALID_FILE_TYPES
            ORDER BY ContentDocument.LatestPublishedVersion.LastModifiedDate DESC
            LIMIT :CONTENT_DOCUMENT_LINK_LIMIT
        ]) {
            if (speakerToContentTypesMap.get(contentDocLink.LinkedEntityId) == null) {
                speakerToContentTypesMap.put(contentDocLink.LinkedEntityId, new Set<String>());
            }
            Set<String> contentTypesSet = speakerToContentTypesMap.get(contentDocLink.LinkedEntityId);
            ContentVersion contentVersion = (ContentVersion) contentDocLink.getSObject('ContentDocument').getSObject('LatestPublishedVersion');
            if (!contentTypesSet.contains(contentVersion.CRM_Content_Type_vod__c)) {
                contentTypesSet.add(contentVersion.CRM_Content_Type_vod__c);
                contentVersionToSpeakerMap.put(contentVersion.Id, contentDocLink.LinkedEntityId);
            }
        }
        List<SpeakerContent> data = new List<SpeakerContent>();
        for (ContentVersion contentVersion : [
            SELECT VersionData, FileExtension, CRM_Content_Type_vod__c
            FROM ContentVersion
            WHERE Id IN :contentVersionToSpeakerMap.keySet()
        ]) {
            data.add(
                new SpeakerContent(
                    contentVersionToSpeakerMap.get(contentVersion.Id),
                    contentVersion.CRM_Content_Type_vod__c,
                    contentVersion.FileExtension,
                    contentVersion.VersionData
                )
            );
        }
        return data;
    }

    private static Boolean checkQueryAccess(SObjectType objectType, Set<String> fields) {
        VeevaBaseObject obj = VeevaBaseObject.create(objectType);
        if (obj == null) {
            return false;
        }
        Set<String> accessibleFields = obj.getAccessibleFields(fields);
        return accessibleFields.size() == fields.size();
    }
}