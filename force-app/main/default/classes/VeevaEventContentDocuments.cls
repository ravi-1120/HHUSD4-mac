/******************************************************************************
 *
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems, Inc.
 *
 * Copyright (c) 2023 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/
@RestResource(urlMapping='/veeva/events-management/event/content-documents')
global with sharing class VeevaEventContentDocuments {
    global class EventContentDocumentResponse extends VeevaBaseResponse {
        public final List<ContentDocumentResult> data;

        public EventContentDocumentResponse(List<ContentDocumentResult> contentDocumentResults) {
            this.data = contentDocumentResults;
        }
    }

    global class ContentDocumentResult{
        public String fileExtension;
        public String fileName;
        public String description;
        public Datetime lastModifiedDate;
        public Id contentVersionId;
        public Id contentDocumentId;
    }

    private static final String STATUS_FAILURE = 'FAILURE';
    private static final Integer SOQL_CHILD_TYPE_LIMIT = 20;

    @HttpGet
    global static VeevaBaseResponse getEventContentDocuments() {
        VeevaBaseResponse eventContentDocumentsResponse;
        RestResponse response = RestContext.response;
        try {
            String eventId = RestContext.request.params.get('eventId');
            if(isValidId(eventId)){
                Set<Id> relatedRecordsIds = getRelatedRecordsIds(eventId);
                List<ContentDocumentLink> contentDocumentLink = getContentDocumentLinks(relatedRecordsIds);
                List<ContentDocumentResult> contentDocumentResults = populateContentDocumentResult(contentDocumentLink);
                eventContentDocumentsResponse = new EventContentDocumentResponse(contentDocumentResults);
                response.statusCode = 200;
            } else {
                eventContentDocumentsResponse = new VeevaBaseResponse(STATUS_FAILURE, 'Invalid Event Id');
            	response.statusCode = 400;
            }
        } catch (Exception ex) {
            eventContentDocumentsResponse = new VeevaBaseResponse(STATUS_FAILURE, 'Unable to get files');
            response.statusCode = 500;
        }
        return eventContentDocumentsResponse;
    }

    private static Boolean isValidId(String candidate) {
        return String.isNotBlank(candidate)
            && VOD_Utils.matchesSfdcId(candidate);
    }

    private static Set<Id> getRelatedRecordsIds(String eventId) {
        Set<Id> relatedRecordsIds = new Set<Id>();
        if(Schema.sObjectType.EM_Event_Material_vod__c.fields.Approved_vod__c.isAccessible()){
           relatedRecordsIds = (new Map<Id, EM_Event_Material_vod__c>([SELECT Id FROM EM_Event_Material_vod__c WHERE Approved_vod__c = 'yes_vod' AND Event_vod__c = :eventId])).keySet();
        }
        return relatedRecordsIds;
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(Set<Id> relatedObjectIdSet) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        if(!relatedObjectIdSet.isEmpty()) {
            contentDocumentLinks = [SELECT ContentDocument.FileExtension, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.Description, ContentDocument.ContentModifiedDate, ContentDocumentId
                                    FROM ContentDocumentLink WHERE LinkedEntityId IN :relatedObjectIdSet];
        }
        return contentDocumentLinks;
    }

    private static List<ContentDocumentResult> populateContentDocumentResult(List<ContentDocumentLink> contentDocLinks) {
        Set<Id> docIdsSeen = new Set<Id>();
        List<ContentDocumentResult> contentDocumentResults = new List<ContentDocumentResult>();
        for (ContentDocumentLink docLink : contentDocLinks) {
            if (!docIdsSeen.contains(docLink.ContentDocumentId)) {
                ContentDocumentResult contentDocumentResult = new ContentDocumentResult();
                contentDocumentResult.fileExtension = docLink.ContentDocument.FileExtension;
                contentDocumentResult.fileName = docLink.ContentDocument.Title;
                contentDocumentResult.description = docLink.ContentDocument.Description;
                contentDocumentResult.lastModifiedDate = docLink.ContentDocument.ContentModifiedDate;
                contentDocumentResult.contentVersionId = docLink.ContentDocument.LatestPublishedVersionId;
                contentDocumentResult.contentDocumentId = docLink.ContentDocumentId;
                contentDocumentResults.add(contentDocumentResult);
                docIdsSeen.add(docLink.ContentDocumentId);
            }
        }
        return contentDocumentResults;
    }
}