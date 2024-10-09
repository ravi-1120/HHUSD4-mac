/**
* @File Name : MSD_CORE_HEQ_DownloadHistory.cls
* @Description : This class handles saving user download history for tracking
* @Author : Gopi Chintamaneni
* @Last Modified By : Gopi Chintamaneni
* @Last Modified On : September 22, 2024
**/

public without sharing class MSD_CORE_HEQ_DownloadHistory {

	@AuraEnabled
    public static void saveDownloadHistory(Id resourceId, Id cid) {
        if (resourceId == null) {
            throw new AuraHandledException('Invalid parameters');
        }

        try {
            // ContentVersion contentVersion = [
            //     SELECT ContentDocumentId
            //     FROM ContentVersion
            //     WHERE Id = :resourceId
            //     LIMIT 1
            // ];

            // ContentDocumentLink documentLink = [
            //     SELECT LinkedEntityId, LinkedEntity.Id
            //     FROM ContentDocumentLink
            //     WHERE ContentDocumentId = :contentVersion.ContentDocumentId
            //     AND LinkedEntityId IN (SELECT Id FROM MSD_CORE_HEQ_Collection__c)
            //     LIMIT 1
            // ];

            if (resourceId != null && cid != null) {
                insert new MSD_CORE_HEQ_Download_History__c(
                    MSD_CORE_Resource_Id__c = resourceId,
                    MSD_CORE_User__c = UserInfo.getUserId(),
                    MSD_CORE_Downloaded_Date__c = Datetime.now(),
                    MSD_CORE_Collection_Name__c = cid
                );
            }

        } catch (Exception ex) {
            throw new AuraHandledException('Error creating resource record: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<DownloadHistoryWrapper> getDownloadHistory(Id userId) {
        if (userId == null) {
            throw new AuraHandledException('Invalid parameters');
        }

        try {
            List<MSD_CORE_HEQ_Download_History__c> historyRecords = [
                SELECT MSD_CORE_Resource_Id__c,
                    MSD_CORE_User__c,
                    MSD_CORE_Downloaded_Date__c,
                    MSD_CORE_Collection_Name__c
                FROM MSD_CORE_HEQ_Download_History__c
                WHERE MSD_CORE_User__c = :userId
            ];

            Set<Id> resourceIds = new Set<Id>();
            Set<Id> collectionIds = new Set<Id>();
            for (MSD_CORE_HEQ_Download_History__c record : historyRecords) {
                resourceIds.add(record.MSD_CORE_Resource_Id__c);
                collectionIds.add(record.MSD_CORE_Collection_Name__c);
            }

            Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>(
                [SELECT Id, Title, MSD_CORE_Expiration_Date__c, ContentDocumentId
                FROM ContentVersion
                WHERE Id IN :resourceIds]
            );

            Map<Id, MSD_CORE_HEQ_Collection__c> collectionMap = new Map<Id, MSD_CORE_HEQ_Collection__c>(
                [SELECT Id, Name, MSD_CORE_Collection_Name__c
                FROM MSD_CORE_HEQ_Collection__c
                WHERE Id IN :collectionIds]
            );

            List<DownloadHistoryWrapper> historyWrapperList = new List<DownloadHistoryWrapper>();

            for (MSD_CORE_HEQ_Download_History__c record : historyRecords) {
                ContentVersion contentVersion = contentVersionMap.get(record.MSD_CORE_Resource_Id__c);
                DateTime expirationDate = contentVersion != null ? contentVersion.MSD_CORE_Expiration_Date__c : null;
                String formattedDate = (record.MSD_CORE_Downloaded_Date__c != null) ? record.MSD_CORE_Downloaded_Date__c.format('MM/dd/yyyy hh:mm:ss a') : '';
                Boolean isExpired = expirationDate != null && expirationDate < Date.today();
                String collectionName = collectionMap.containsKey(record.MSD_CORE_Collection_Name__c) ?
                    collectionMap.get(record.MSD_CORE_Collection_Name__c).MSD_CORE_Collection_Name__c : null;
                String collectionId = collectionMap.containsKey(record.MSD_CORE_Collection_Name__c) ? collectionMap.get(record.MSD_CORE_Collection_Name__c).Id : null;

                historyWrapperList.add(new DownloadHistoryWrapper(
                    contentVersion.Id,
                    contentVersion.Title,
                    formattedDate,
                    collectionName,
                    expirationDate,
                    contentVersion.ContentDocumentId,
                    isExpired,
                    collectionId
                ));
            }

            return historyWrapperList;

        } catch (Exception ex) {
            throw new AuraHandledException('Error retrieving download history: ' + ex.getMessage());
        }
    }


    public class DownloadHistoryWrapper {
        @AuraEnabled
        public String resourceId;
        @AuraEnabled
        public String resourceTitle;
        @AuraEnabled
        public String downloadedDate;
        @AuraEnabled
        public String collectionName;
        @AuraEnabled
        public DateTime expirationDate;
        @AuraEnabled
        public String documentId;
        @AuraEnabled
        public Boolean isExpired;
        @AuraEnabled
        public String collectionId;

        public DownloadHistoryWrapper(String resourceId, String resourceTitle, String formattedDate, String collectionName, DateTime expirationDate, String documentId, Boolean isExpired, String collectionId) {
            this.resourceId = resourceId;
            this.resourceTitle = resourceTitle;
            this.downloadedDate = formattedDate;
            this.collectionName = collectionName;
            this.expirationDate = expirationDate;
            this.documentId = documentId;
            this.isExpired = isExpired;
            this.collectionId = collectionId;
        }
    }

}