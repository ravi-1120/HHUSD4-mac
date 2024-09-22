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
@RestResource(urlMapping='/veeva/distribution-record-management')
global with sharing class VeevaDistributionRecordManagement {
    private static final String STATUS_FAILURE = 'FAILURE';

    @HttpPost
    global static VeevaBaseResponse createMissingDistributionRecords() {
        VeevaBaseResponse distributionRecordResponse;
        RestResponse response = RestContext.response;
        RestRequest req = RestContext.request;
        try{
            String jsonBody = req.requestBody.toString();
            DistributionRecordRequest recordRequest = (DistributionRecordRequest) JSON.deserialize(jsonBody, DistributionRecordRequest.class);
            validateContentDocumentIds(recordRequest.contentDocumentIds);
            List<DistributionRecordResult> result = createDistributionRecords(recordRequest.contentDocumentIds, recordRequest.channel);
            distributionRecordResponse = new DistributionRecordResponse(result);
            response.statusCode = 200;
        } catch(Exception e) {
            distributionRecordResponse = new VeevaBaseResponse(STATUS_FAILURE, e.getMessage());
            response.statusCode = 500;
        }

        return distributionRecordResponse;
    }

    /**
     * Used by CRM Auto Publishing for Email Fragments to Publish Veeva Content to CDN
     * @param veevaContentWithFileMap:
     *      key = Veeva_Content_vod.Id;
     *      value = ContentDocument.Id (of the most recent linked file)
     */
    public static void createDistributionsForVeevaContent(Map<Id, PublishRequest> veevaContentWithFileMap) {
        // retrieve/ create veeva distribution linked to our veeva contents
        // key = Veeva_Content_vod.Id; value = Veeva_Distribution_vod
        Map<Id, Veeva_Distribution_vod__c> veevaContentDistributionMap = upsertVeevaDistributions(veevaContentWithFileMap);

        if(!veevaContentDistributionMap.isEmpty()) {
            List<Id> veevaDistributionIds = extractIds(veevaContentDistributionMap.values());
            // link/ re-link ContentDocument with VeevaDistribution
            refreshDocumentLinkWithVeevaDistributions(veevaContentWithFileMap, veevaContentDistributionMap, veevaDistributionIds);
            // update veeva distributions to trigger publishing process
            updateDistributionRecordStatus(veevaDistributionIds);
        }
    }

    private static List<Id> extractIds(List<Veeva_Distribution_vod__c> veevaDistributions) {
        List<Id> veevaDistributionIds = new List<Id>();
        for(Veeva_Distribution_vod__c veevaDistribution : veevaDistributions) {
            veevaDistributionIds.add(veevaDistribution.Id);
        }
        return veevaDistributionIds;
    }

    @TestVisible
    private static void refreshDocumentLinkWithVeevaDistributions(Map<Id, PublishRequest> veevaContentWithFileMap,
                                                                Map<Id, Veeva_Distribution_vod__c> veevaContentDistributionMap,
                                                                List<Id> veevaDistributionIds) {
        Map<String, ContentDocumentLink> existingContentDocumentLinks = getExistingDistributionFileLinks(veevaDistributionIds);
        List<ContentDocumentLink> toUpsert = new List<ContentDocumentLink>();
        for(Id veevaContentId : veevaContentDistributionMap.keySet()) {
            PublishRequest publishRequest = veevaContentWithFileMap.get(veevaContentId);
            Id fileId = publishRequest.fileId;
            Veeva_Distribution_vod__c veevaDistribution = veevaContentDistributionMap.get(veevaContentId);
            Id veevaDistributionId = veevaDistribution.Id;
            String comboKey = contentDocumentLinkComboKey(fileId, veevaDistributionId);
            ContentDocumentLink contentDocumentLink = existingContentDocumentLinks.get(comboKey);
            if(contentDocumentLink == null) {
                // create new ContentDocumentLink if one doesn't exist yet
                contentDocumentLink = buildContentDocumentLink(fileId, veevaDistributionId);
            }
            toUpsert.add(contentDocumentLink);
        }
        upsert toUpsert;
    }

    private static Map<String, ContentDocumentLink> getExistingDistributionFileLinks(List<Id> veevaDistributionIds) {
        Map<String, ContentDocumentLink> contentDocumentLinks = new Map<String, ContentDocumentLink>();
        for(ContentDocumentLink link : [SELECT Id, LinkedEntityId, ContentDocumentId
                                            FROM ContentDocumentLink
                                            WHERE LinkedEntityId IN: veevaDistributionIds]) {
            contentDocumentLinks.put(contentDocumentLinkComboKey(link), link);
        }
        return contentDocumentLinks;
    }

    private static String contentDocumentLinkComboKey(ContentDocumentLink contentDocumentLink) {
        return contentDocumentLinkComboKey(contentDocumentLink.ContentDocumentId, contentDocumentLink.LinkedEntityId);
    }

    private static String contentDocumentLinkComboKey(String contentDocumentId, String linkedEntityId) {
        return contentDocumentId + '_' + linkedEntityId;
    }

    /**
     * Try to find if there's existing Veeva Distribution record that has a lookup to the provided Veeva Contents
     *  1. If yes,
     *      a. Check if CDN Status is Published ----> Left Alone
     *      b. Otherwise, use for republishing with latest linked file
     *  2. If no,
     *      a. Create a new Veeva Distribution and set lookup to the Veeva Content
     * @return Map of
     *      key = Veeva_Content_vod.Id
     *      value = associated Veeva_Distribution_vod record (retrieved/ created)
     */
    @TestVisible
    private static Map<Id, Veeva_Distribution_vod__c> upsertVeevaDistributions(Map<Id, PublishRequest> veevaContentWithFileMap) {
        Set<Id> veevaContentIds = veevaContentWithFileMap.keySet();
        Set<Id> veevaContentsNeededVeevaDistribution = new Set<Id>(veevaContentIds);
        Set<Id> alreadyPublishedDistribution = new Set<Id>();

        // key = Veeva_Content_vod.Id; value = Veeva_Distribution_vod
        Map<Id, Veeva_Distribution_vod__c> veevaContentDistributionMap = new Map<Id, Veeva_Distribution_vod__c>();
        for(Veeva_Distribution_vod__c veevaDistribution : queryDistributionsForContent(veevaContentIds)) {
            Id veevaContentId = veevaDistribution.Veeva_Content_vod__c;

            // veeva distribution already exists for this veeva content, no need to create new veeva distribution record
            veevaContentsNeededVeevaDistribution.remove(veevaContentId);

            if(isPublished(veevaDistribution)) {
                // for published content, Veeva Distribution and related Approved Document record are left alone
                alreadyPublishedDistribution.add(veevaContentId);
                veevaContentDistributionMap.put(veevaContentId, veevaDistribution);
            } else if(!veevaContentDistributionMap.containsKey(veevaContentId) && !alreadyPublishedDistribution.contains(veevaContentId)) {
                // content may have been previously withdrawn, retry publishing
                veevaContentDistributionMap.put(veevaContentId, veevaDistribution);
            }
        }

        // for the contents with missing veeva distribution, build a veeva distribution record ready for creation
        veevaContentDistributionMap.putAll(buildVeevaDistributionWithContentIds(veevaContentsNeededVeevaDistribution));

        // set record type and distribution channel
        Id crmContentRecordTypeId = getVeevaDistributionCRMContentRtId();

        for(Id veevaContentId : veevaContentDistributionMap.keySet()) {
            Veeva_Distribution_vod__c veevaDistribution = veevaContentDistributionMap.get(veevaContentId);
            // update with AE publishing fields
            veevaDistribution.RecordTypeId = crmContentRecordTypeId;
            PublishRequest request = veevaContentWithFileMap.get(veevaContentId);
            veevaDistribution.Distribution_Channel_vod__c = String.join(request.channels, ';');
        }
        // upsert records
        upsert veevaContentDistributionMap.values();
        // do not return the ones that were already published (only want to update the distribution channels)
        for(Id alreadyPublished : alreadyPublishedDistribution) {
            veevaContentDistributionMap.remove(alreadyPublished);
        }
        return veevaContentDistributionMap;
    }

    public static boolean isPublished(Veeva_Distribution_vod__c veevaDistribution) {
        return veevaDistribution.CDN_Status_vod__c == 'Published_vod';
    }

    public static void withdrawVeevaDistributionForVeevaContents(Set<Id> veevaContentIds) {
        // query linked Veeva Distributions
        List<Veeva_Distribution_vod__c> veevaDistributions = queryDistributionsForContent(veevaContentIds);
        // withdraw content if needed
        if(!veevaDistributions.isEmpty()) {
            List<Veeva_Distribution_vod__c> toUpdate = new List<Veeva_Distribution_vod__c>();
            for(Veeva_Distribution_vod__c veevaDistribution : veevaDistributions) {
                if(VeevaDistributionRecordManagement.isPublished(veevaDistribution)) {
                    veevaDistribution.Processing_Status_vod__c = 'Ready_to_Withdraw_vod';
                    toUpdate.add(veevaDistribution);
                }
            }
            update toUpdate;
        }
    }

    public static List<Veeva_Distribution_vod__c> queryDistributionsForContent(Set<Id> veevaContentIds) {
        return [SELECT Id, Veeva_Content_vod__c, CDN_Status_vod__c
                    FROM Veeva_Distribution_vod__c
                    WHERE Veeva_Content_vod__c IN: veevaContentIds
                        AND Distribution_Channel_vod__c includes ('Approved_Email_vod', 'Published_Content_vod')];
    }

    private static Map<Id, Veeva_Distribution_vod__c> buildVeevaDistributionWithContentIds(Set<Id> aeVeevaContentIds) {
        Map<Id, Veeva_Distribution_vod__c> aeDistributions = new  Map<Id, Veeva_Distribution_vod__c>();
        if(!aeVeevaContentIds.isEmpty()) {
            // create Veeva
            for(Id aeVeevaContentId : aeVeevaContentIds) {
                aeDistributions.put(aeVeevaContentId, new Veeva_Distribution_vod__c(Veeva_Content_vod__c = aeVeevaContentId));
            }
        }
        return aeDistributions;
    }

    private static void validateContentDocumentIds(Set<String> contentDocumentIds) {
        for (String contentDocumentId : contentDocumentIds) {
            if (String.isBlank(contentDocumentId) || !VOD_Utils.matchesSfdcId(contentDocumentId)) {
                throw new IllegalArgumentException('Invalid Content Document Id: ' + contentDocumentId);
            }
        }
    }

    private static List<DistributionRecordResult> createDistributionRecords(Set<String> contentDocumentIds, String channel) {
        List<ContentDocumentLink> existingLinks = [SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink
                                                   WHERE ContentDocumentId IN :contentDocumentIds];
        Set<String> docsWithLink = new Set<String>();
        List<String> linkedEntityIds = new List<String>();
        for(ContentDocumentLink existingLink : existingLinks) {
            linkedEntityIds.add(existingLink.LinkedEntityId);
        }
        Set<Id> distributionIds = new Set<Id>(new Map<Id, Veeva_Distribution_vod__c>([SELECT Id FROM Veeva_Distribution_vod__c WHERE Id IN :linkedEntityIds]).keySet());
        for (Integer i = (existingLinks.size()-1) ; i>= 0 ; i--){
            if(!distributionIds.contains(existingLinks[i].LinkedEntityId)){
                existingLinks.remove(i);
            } else {
                docsWithLink.add(existingLinks[i].ContentDocumentId);
            }
        }
        contentDocumentIds.removeAll(docsWithLink);
        List<String> docsWithoutLink = new List<String>(contentDocumentIds);
        List<String> distributionRecordIds = createRecords(docsWithoutLink);
        createDocumentLinks(docsWithoutLink, distributionRecordIds, existingLinks);
        if (isValidDistributionChannel(channel)) {
            updateDistributionRecords(distributionRecordIds, channel);
        } else {
            updateDistributionRecordStatus(distributionRecordIds);
        }
        return buildResult(existingLinks);
    }

    @TestVisible
    private static boolean isValidDistributionChannel(String channel) {
        Schema.DescribeFieldResult channelField = Veeva_Distribution_vod__c.Distribution_Channel_vod__c.getDescribe();
        List<Schema.PicklistEntry> ple = channelField.getPicklistValues();
        for(Schema.PicklistEntry p : ple){
            if (p.getValue().equals(channel)) {
                return true;
            }
        }
        return false;
    }

    @TestVisible
    private static void updateDistributionRecords(List<String> distributionRecordIds, String channel) {
        List<Veeva_Distribution_vod__c> updateList = new List<Veeva_Distribution_vod__c>();
        for(String recordId : distributionRecordIds) {
            Veeva_Distribution_vod__c distributionRecord = new Veeva_Distribution_vod__c(Id=recordId, Processing_Status_vod__c='Ready_to_Publish_vod', Distribution_Channel_vod__c=channel);
            updateList.add(distributionRecord);
        }
        Database.update(updateList, true);
    }

    @TestVisible
    private static List<String> createRecords(List<String> docsWithoutLink) {
        List<String> distributionRecordIds = new List<String>();
        Id recordTypeId = getVeevaDistributionCRMContentRtId();
        List<Veeva_Distribution_vod__c> toCreate = new List<Veeva_Distribution_vod__c>();
        for(String contentDocumentId : docsWithoutLink) {
            Veeva_Distribution_vod__c distributionRecord = new Veeva_Distribution_vod__c(RecordTypeId=recordTypeId);
            toCreate.add(distributionRecord);
        }
        if(!toCreate.isEmpty()) {
            Database.SaveResult[] results = Database.insert(toCreate, true);
            for (Database.SaveResult result : results) {
                if (result.isSuccess()) {
                    distributionRecordIds.add(result.getId());
                }
            }
        }
        return distributionRecordIds;
    }

    private static Id getVeevaDistributionCRMContentRtId() {
        return Schema.SObjectType.Veeva_Distribution_vod__c.getRecordTypeInfosByDeveloperName()
                    .get('CRM_Content_vod').getRecordTypeId();
    }

    @TestVisible
    private static void createDocumentLinks(List<String> docsWithoutLink, List<String> distributionRecordIds, List<ContentDocumentLink> contentDocumentLinks) {
        List<ContentDocumentLink> toCreate = new List<ContentDocumentLink>();
        for(Integer i=0; i < distributionRecordIds.size(); i++) {
            ContentDocumentLink contentDocumentLink = buildContentDocumentLink(docsWithoutLink[i], distributionRecordIds[i]);
            toCreate.add(contentDocumentLink);
        }
        if(!toCreate.isEmpty()) {
            Database.SaveResult[] results = Database.insert(toCreate, true);
            for (Integer i=0; i< results.size(); i++) {
                if (results[i].isSuccess()) {
                    contentDocumentLinks.add(toCreate[i]);
                }
            }
        }
    }

    private static ContentDocumentLink buildContentDocumentLink(String contentDocumentId, String linkedEntityId) {
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentDocumentId;
        contentDocumentLink.LinkedEntityId = linkedEntityId;
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers';
        return contentDocumentLink;
    }

    @TestVisible
    private static void updateDistributionRecordStatus(List<String> distributionRecordIds) {
        List<Veeva_Distribution_vod__c> updateList = new List<Veeva_Distribution_vod__c>();
        for(String recordId : distributionRecordIds) {
            Veeva_Distribution_vod__c distributionRecord = new Veeva_Distribution_vod__c(Id=recordId, Processing_Status_vod__c='Ready_to_Publish_vod');
            updateList.add(distributionRecord);
        }
        Database.update(updateList, true);
    }

    @TestVisible
    private static List<DistributionRecordResult> buildResult(List<ContentDocumentLink> contentDocumentLinks) {
        List<DistributionRecordResult> result = new List<DistributionRecordResult>();
        for(ContentDocumentLink contentDocumentLink: contentDocumentLinks){
            DistributionRecordResult distributionResult = new DistributionRecordResult();
            distributionResult.contentDocumentId = contentDocumentLink.ContentDocumentId;
            distributionResult.veevaDistributionRecordId = contentDocumentLink.LinkedEntityId;
            result.add(distributionResult);
        }
        return result;
    }

    global class DistributionRecordResponse extends VeevaBaseResponse {
        public final List<DistributionRecordResult> data;
        public DistributionRecordResponse(List<DistributionRecordResult> distributionRecordResults) {
            this.data = distributionRecordResults;
        }
    }

    global class DistributionRecordResult{
        public String veevaDistributionRecordId;
        public String contentDocumentId;
    }

    global class DistributionRecordRequest {
        public Set<String> contentDocumentIds;
        public String channel;
    }

    public class PublishRequest {
        public Id fileId;
        public List<String> channels;
        public PublishRequest(Id fileId, List<String> channels) {
            this.fileId = fileId;
            this.channels = channels;
        }
    }
}