public without sharing class CustomMetadataHelper {

    // Class to hold metadata settings
    public class MetadataSettings {
        public Id primaryExecutiveId;
        public Id medicalAEId;
        public Id oncologyAEId;
    }

    // Method to retrieve metadata settings
    public static MetadataSettings getMetadataSettings() {
        MetadataSettings settings = new MetadataSettings();
        try {
            // Query the custom metadata record
            MSD_CORE_Default_AE_Setting__mdt metadataRecord = [
                SELECT Primary_Executive__c, MSD_CORE_Medical_AE__c, MSD_CORE_Oncology_AE__c 
                FROM MSD_CORE_Default_AE_Setting__mdt 
                LIMIT 1
            ];

            // Ensure the metadata record is not null
            if (metadataRecord != null) {
                settings.primaryExecutiveId = metadataRecord.Primary_Executive__c;
                settings.medicalAEId = metadataRecord.MSD_CORE_Medical_AE__c;
                settings.oncologyAEId = metadataRecord.MSD_CORE_Oncology_AE__c;
            }
        } catch (Exception e) {
            // Handle any exceptions that occur during the query
            System.debug('Error retrieving metadata settings: ' + e.getMessage());
        }
        return settings;
    }
}