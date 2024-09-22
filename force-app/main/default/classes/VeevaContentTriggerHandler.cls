public with sharing class VeevaContentTriggerHandler extends VeevaTriggerHandler{
    private List<Veeva_Content_vod__c> newRecords = new List<Veeva_Content_vod__c>();
    private List<Veeva_Content_vod__c> oldRecords = new List<Veeva_Content_vod__c>();
    private Map<Id, Veeva_Content_vod__c> newRecordsMap = new Map<Id, Veeva_Content_vod__c>();
    private Map<Id, Veeva_Content_vod__c> oldRecordsMap = new Map<Id, Veeva_Content_vod__c>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld,
                                        Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.newRecords = (List<Veeva_Content_vod__c>) triggerNew;
        this.oldRecords = (List<Veeva_Content_vod__c>) triggerOld;
        this.newRecordsMap = (Map<Id, Veeva_Content_vod__c>) triggerNewMap;
        this.oldRecordsMap = (Map<Id, Veeva_Content_vod__c>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'Veeva_Content_vod__c';
    }

    protected override void beforeInsert() {
        // runs validations
        handleBeforeInsert();
    }

    protected override void beforeUpdate() {
        // runs validations
        handleBeforeUpdate();
    }

    protected override void afterUpdate() {
        // runs publishing/ withdrawal
        handleAfterUpdate();
    }

    protected override void beforeDelete() {
        // runs validations
        handleBeforeDelete();
    }

    private void handleBeforeInsert() {
        String aeContentRequiredProductMsg = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('PUBLISH_FOR_AE_REQUIRES_PRODUCT', 'ApprovedEmail',
            'Product is required to publish for Approved Email');
        String noContentToPublishErrorMsg = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('VEEVA_CONTENT_NO_CONTENT_TO_PUBLISH', 'Multichannel',
            'No content to publish. Please add a file to the record and save again.');

        for(Veeva_Content_vod__c toInsert : newRecords) {
            if(isMarkedPublishForApprovedEmail(toInsert) && toInsert.Product_vod__c == NULL) {
                toInsert.addError(aeContentRequiredProductMsg);
            } else if(isPublished(toInsert)) {
                // record will have no attachments upon creation
                toInsert.addError(noContentToPublishErrorMsg);
            }
            // also nothing to withdraw for new records
        }
    }

    private void handleBeforeUpdate() {
        Map<Id, Veeva_Content_vod__c> publishGroup = new Map<Id, Veeva_Content_vod__c>();
        Map<Id, Veeva_Content_vod__c> withdrawGroup = new Map<Id, Veeva_Content_vod__c>();

        String aeContentRequiredProductMsg = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('PUBLISH_FOR_AE_REQUIRES_PRODUCT', 'ApprovedEmail',
            'Product is required to publish for Approved Email');
        List<Veeva_Content_vod__c> toBeGrouped = new List<Veeva_Content_vod__c>();
        for(Veeva_Content_vod__c toUpdate : newRecords) {
            if(isMarkedPublishForApprovedEmail(toUpdate) && toUpdate.Product_vod__c == NULL) {
                toUpdate.addError(aeContentRequiredProductMsg);
            } else {
                toBeGrouped.add(toUpdate);
            }
        }

        groupNewRecords(toBeGrouped, publishGroup, withdrawGroup);

        if(!publishGroup.isEmpty()) {
            Map<Id, Id> mostRecentAssociatedFiles = getMostRecentAssociatedFile(publishGroup.keySet());
            validatePublishGroup(publishGroup, mostRecentAssociatedFiles);
        }
    }

    private void handleAfterUpdate() {
        Map<Id, Veeva_Content_vod__c> publishGroup = new Map<Id, Veeva_Content_vod__c>();
        Map<Id, Veeva_Content_vod__c> withdrawGroup = new Map<Id, Veeva_Content_vod__c>();
        groupNewRecords(newRecords, publishGroup, withdrawGroup);

        if(!publishGroup.isEmpty()) {
            Map<Id, Id> mostRecentAssociatedFiles = getMostRecentAssociatedFile(publishGroup.keySet());
            processPublishGroup(publishGroup, mostRecentAssociatedFiles);
        }

        if(!withdrawGroup.isEmpty()) {
            processWithdrawGroup(withdrawGroup);
        }
    }

    private void groupNewRecords(List<Veeva_Content_vod__c> toBeGrouped, Map<Id, Veeva_Content_vod__c> publishGroup, Map<Id, Veeva_Content_vod__c> withdrawGroup) {
        List<String> fieldsToCheck = getVeevaContentFieldsToCheck();
        for(Veeva_Content_vod__c newContent : toBeGrouped) {
            Id veevaContentId = newContent.Id;
            Veeva_Content_vod__c oldContent = oldRecordsMap.get(veevaContentId);
            if(!isJustUpdatingStatusDetail(fieldsToCheck, newContent, oldContent)) {
                if(isPublished(newContent)) {
                    // if content is in published state
                    publishGroup.put(veevaContentId, newContent);
                } else if (!isPublished(newContent) && isPublished(oldContent)) {
                    // if content was in published state, but is just made ready to be withdrawn
                    withdrawGroup.put(veevaContentId, newContent);
                }
            }
        }
    }

    @TestVisible
    private static List<String> getVeevaContentFieldsToCheck() {
        List<String> fieldsToCheck = new List<String>();
        for(SObjectField field : Schema.SObjectType.Veeva_Content_vod__c.fields.getMap().values()){
            Schema.describeFieldResult fldDesc = field.getDescribe();
            String fieldName = fldDesc.getName();
            // include all custom fields excluding status detail and Name field
            if ((fldDesc.isCustom() && !'Status_Details_vod__c'.equals(fieldName)) || 'Name'.equals(fieldName)){
                fieldsToCheck.add(fieldName);
            }
        }
        return fieldsToCheck;
    }

    @TestVisible
    private static Boolean isJustUpdatingStatusDetail(List<String> fieldsToCheck, Veeva_Content_vod__c newContent, Veeva_Content_vod__c oldContent) {
        // ensure all other custome fields + Name are not updated
        for(String fieldToCheck : fieldsToCheck) {
            if(newContent.get(fieldToCheck) != oldContent.get(fieldToCheck)) {
                return false;
            }
        }
        return newContent.Status_Details_vod__c != oldContent.Status_Details_vod__c;
    }

    private void handleBeforeDelete() {
        String cannotDeletePublishedContentErrorMsg = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('ERROR_DELETING_VEEVA_CONTENT', 'Multichannel',
            'Please expire the content or remove publishing channels before deleting.');
        for(Veeva_Content_vod__c toDelete : oldRecords) {
            if(isPublished(toDelete)) {
                // prevent user from deleting published content
                toDelete.addError(cannotDeletePublishedContentErrorMsg);
            }
        }
    }

    private Boolean isPublished(Veeva_Content_vod__c veevaContent) {
        return isContentApproved(veevaContent) &&
            (isMarkedPublishForApprovedEmail(veevaContent) || isMarkedPublishForDistribution(veevaContent));
    }

    private Boolean isContentApproved(Veeva_Content_vod__c veevaContent) {
        return veevaContent.Content_Status_vod__c == 'Approved_vod';
    }

    private Boolean isMarkedPublishForApprovedEmail(Veeva_Content_vod__c veevaContent) {
        return veevaContent.Publish_for_Approved_Email_vod__c == true;
    }

    private Boolean isMarkedPublishForDistribution(Veeva_Content_vod__c veevaContent) {
        return veevaContent.Publish_for_Distribution_vod__c == true;
    }

    private Map<Id, Id> getMostRecentAssociatedFile(Set<Id> veevaContentIds) {
        Map<Id, Id> mostRecentFiles = new Map<Id, Id>();
        // find all content documents linked to the provided veeva content ids
        for(ContentDocumentLink link: [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN: veevaContentIds ORDER BY SystemModstamp DESC]) {
            // to get most recent, only save the first one matching each veeva content
            Id veevaContentId = link.LinkedEntityId;
            if(!mostRecentFiles.containsKey(veevaContentId)) {
                mostRecentFiles.put(veevaContentId, link.ContentDocumentId);
            }
        }
        return mostRecentFiles;
    }

    private void validatePublishGroup(Map<Id, Veeva_Content_vod__c> publishGroup, Map<Id, Id> mostRecentAssociatedFiles) {
        String noContentToPublishErrorMsg = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('VEEVA_CONTENT_NO_CONTENT_TO_PUBLISH', 'Multichannel',
            'No content to publish. Please add a file to the record and save again.');
        Map<Id, Id> veevaContentsToPublish = new Map<Id, Id>();
        for(Id veevaContentId : publishGroup.keySet()) {
            Veeva_Content_vod__c toPublish = publishGroup.get(veevaContentId);
            Id fileId = mostRecentAssociatedFiles.get(veevaContentId);
            if(fileId == NULL) {
                toPublish.addError(noContentToPublishErrorMsg);
            }
        }
    }

    private void processPublishGroup(Map<Id, Veeva_Content_vod__c> publishGroup, Map<Id, Id> mostRecentAssociatedFiles) {
        String noContentToPublishErrorMsg = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('VEEVA_CONTENT_NO_CONTENT_TO_PUBLISH', 'Multichannel',
            'No content to publish. Please add a file to the record and save again.');

        Map<Id, VeevaDistributionRecordManagement.PublishRequest> veevaContentsToPublish = new Map<Id, VeevaDistributionRecordManagement.PublishRequest>();
        Map<Id, Id> aeContents = new Map<Id, Id>();
        Set<Id> contentsToExpireAppDoc = new Set<Id>();
        for(Id veevaContentId : publishGroup.keySet()) {
            Veeva_Content_vod__c toPublish = publishGroup.get(veevaContentId);
            Id fileId = mostRecentAssociatedFiles.get(veevaContentId);
            if(fileId == NULL) {
                toPublish.addError(noContentToPublishErrorMsg);
            } else {
                Veeva_Content_vod__c toPublishOld = oldRecordsMap.get(veevaContentId);
                List<String> channels = new List<String>();
                if(isMarkedPublishForApprovedEmail(toPublish)) {
                    channels.add('Approved_Email_vod');
                    aeContents.put(veevaContentId, fileId);
                } else if(toPublishOld != null && isMarkedPublishForApprovedEmail(toPublishOld)) {
                    // was previously published for AE, but no longer is
                    contentsToExpireAppDoc.add(veevaContentId);
                }
                if(isMarkedPublishForDistribution(toPublish)) {
                    channels.add('Published_Content_vod');
                }
                VeevaDistributionRecordManagement.PublishRequest publishRequest = new VeevaDistributionRecordManagement.PublishRequest(fileId, channels);
                veevaContentsToPublish.put(veevaContentId, publishRequest);
            }
        }

        if(!veevaContentsToPublish.isEmpty()) {
            // publish content veeva distirbution
            VeevaDistributionRecordManagement.createDistributionsForVeevaContent(veevaContentsToPublish);
            // create approved document email fragments
            activateApprovedDocumentFragments(aeContents);
            // expire Approved Documents that no longer have Publish_for_Approved_Email_vod__c = true
            expireApprovedDocuments(contentsToExpireAppDoc);
        }
    }

    private void activateApprovedDocumentFragments(Map<Id, Id> mostRecentAssociatedFiles) {
        // find existing approved document
        Set<Id> veevaContentIds = mostRecentAssociatedFiles.keySet();
        Set<Id> newFragmentsNeeded = new Set<Id>(veevaContentIds);
        List<Approved_Document_vod__c> existingApprovedDocuments = getAllLinkedApprovedDocumentFragments(veevaContentIds);
        // activate existing approved documents
        if(!existingApprovedDocuments.isEmpty()) {
            for(Approved_Document_vod__c existingFragment : existingApprovedDocuments) {
                newFragmentsNeeded.remove(existingFragment.Veeva_Content_vod__c);
                existingFragment.Status_vod__c = 'Approved_vod';
            }
            update existingApprovedDocuments;
        }
        // create new approved document fragments
        if(!newFragmentsNeeded.isEmpty()) {
            VeevaContentApprovedDocumentService.createApprovedDocumentFragments(newFragmentsNeeded, mostRecentAssociatedFiles);
        }
    }

    private void processWithdrawGroup(Map<Id, Veeva_Content_vod__c> withdrawGroup) {
        Set<Id> veevaContentIds = withdrawGroup.keySet();
        VeevaDistributionRecordManagement.withdrawVeevaDistributionForVeevaContents(veevaContentIds);
        expireApprovedDocuments(veevaContentIds);
    }

    private static void expireApprovedDocuments(Set<Id> veevaContentIds) {
        // query linked Approved Document Email Fragments
        List<Approved_Document_vod__c> fragments = getAllLinkedApprovedDocumentFragments(veevaContentIds);
        // update Status to expired
        if(!fragments.isEmpty()) {
            for(Approved_Document_vod__c fragment : fragments) {
                fragment.Status_vod__c = 'Expired_vod';
            }
            update fragments;
        }
    }

    private static List<Approved_Document_vod__c> getAllLinkedApprovedDocumentFragments(Set<Id> veevaContentIds) {
        return [SELECT Id, Veeva_Content_vod__c FROM Approved_Document_vod__c
                WHERE Veeva_Content_vod__c IN: veevaContentIds
                    AND RecordType.DeveloperName = 'Email_Fragment_vod'];
    }

}