public without sharing class VeevaEmCatalogTriggerUtil {

    public static void withdrawVeevaDistribution(List<EM_Catalog_vod__c> newCatalogs) {
        if(Schema.sObjectType.Veeva_Distribution_vod__c.isUpdateable() && Schema.sObjectType.Veeva_Distribution_vod__c.fields.Processing_Status_vod__c.isUpdateable()) {
            Set<Id> expiredCatalogIds = new Set<Id>();
            for(EM_Catalog_vod__c catalog : newCatalogs) {
                if('Expired_vod' == catalog.Status_vod__c) {
                    expiredCatalogIds.add(catalog.Id);
                }
            }
            if(!expiredCatalogIds.isEmpty()) {
                withdrawVeevaDistributionSync(expiredCatalogIds);
            }
        }
    }

    private static void withdrawVeevaDistributionSync(Set<Id> catalogIds) {
        Set<Id> docIds = getContentDocumentIdsFromCatalog(catalogIds);
        Set<Id> linkEntityIds = getLinkEntityIdsFromDocs(docIds);
        linkEntityIds.removeAll(catalogIds);
        updateDistributionRecords(linkEntityIds);
    }

    @TestVisible
    private static void updateDistributionRecords(Set<Id> linkEntityIds) {
        if(!linkEntityIds.isEmpty()) {
            List<Veeva_Distribution_vod__c> distributionRecords = [SELECT Id FROM Veeva_Distribution_vod__c WHERE Id IN :linkEntityIds];
            for(Veeva_Distribution_vod__c record : distributionRecords) {
                record.Processing_Status_vod__c = 'Ready_to_Withdraw_vod';
            }
            update distributionRecords;
        }
    }

    @TestVisible
    private static Set<Id> getLinkEntityIdsFromDocs(Set<Id> docIds) {
        Set<Id> linkEntityIds = new Set<Id>();
        if(!docIds.isEmpty()) {
            List<ContentDocumentLink> links = [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :docIds];
        	for(ContentDocumentLink link : links) {
            	linkEntityIds.add(link.LinkedEntityId);
        	}
        }
        return linkEntityIds;
    }

    private static Set<Id> getContentDocumentIdsFromCatalog(Set<Id> catalogIds) {
        Set<Id> docIds = new Set<Id>();
        List<ContentDocumentLink> docs = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :catalogIds];
        for(ContentDocumentLink link : docs) {
            docIds.add(link.ContentDocumentId);
        }
        return docIds;
    }
}