public class VeevaEMCatalogUtil {

    public VeevaEMCatalogUtil() {}

    private static void generatePreview(Set<String> catalogIds) {

        String commaSeparatedCatalogIds = String.join((Iterable<String>)catalogIds, ',');
        if(commaSeparatedCatalogIds.length() > 0) {
            String auth = VOD_EMBED_CONTROLLER.getSfdcAuth();
            String sfEndpoint = VOD_EMBED_CONTROLLER.getSfEndpoint();
            VEEVA_PREVIEW_GENERATION_PROCESS.generatePreview(auth, sfEndpoint, commaSeparatedCatalogIds);
        }
    }

    public static void setEMCatalogIds (List<ContentDocumentLink> cdls) {
        Set<String> catalogIds = new Set<String>();
        Set<Id> linkedEntityIds = new Set<Id>();
        
        for (ContentDocumentLink cdl : cdls) {
            linkedEntityIds.add(cdl.LinkedEntityId);
        }
        
        List<EM_Catalog_vod__c> catalogs = [SELECT Id, RecordType.DeveloperName FROM EM_Catalog_vod__c WHERE Id IN :linkedEntityIds];
        for (EM_Catalog_vod__c catalog : catalogs) {
            if (catalog.RecordType.DeveloperName == 'Print_Invitation_Template_vod' || catalog.RecordType.DeveloperName == 'Print_Sign_In_Template_vod') {
                catalogIds.add(catalog.Id);
            }
        }

        generatePreview(catalogIds);
    }
}