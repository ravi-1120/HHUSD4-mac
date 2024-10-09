public class MSD_CORE_HEQ_DesignMetadataHandler {
    public static void onAfterUpdate(Map<Id, MSD_CORE_HEQ_Design_Metadata__c> oldMap, Map<Id, MSD_CORE_HEQ_Design_Metadata__c> newMap) {
        Set<Id> setOfDesignMetadataExpired = new Set<Id>();
        for(MSD_CORE_HEQ_Design_Metadata__c rec : newMap.Values()) {
            if(oldMap.get(rec.Id).MSD_CORE_Status__c != rec.MSD_CORE_Status__c && rec.MSD_CORE_Status__c == 'EXPIRED' ) {
                setOfDesignMetadataExpired.add(rec.Id);
            }
        }
        List<MSD_CORE_HEQ_Template_File_Metadata__c> lstOfTempFileMetadataToBeUpdated = new List<MSD_CORE_HEQ_Template_File_Metadata__c>();
        lstOfTempFileMetadataToBeUpdated = [SELECT Id, MSD_CORE_Parent_Template__r.MSD_CORE_HEQ_Design_Metadata__c, MSD_CORE_HEQ_Design_Metadata__c, MSD_CORE_Status__c, MSD_CORE_HEQ_Type__c  
                                            FROM MSD_CORE_HEQ_Template_File_Metadata__c 
                                            WHERE MSD_CORE_Parent_Template__r.MSD_CORE_HEQ_Design_Metadata__c IN : setOfDesignMetadataExpired OR 
                                            (MSD_CORE_HEQ_Design_Metadata__c IN:setOfDesignMetadataExpired AND MSD_CORE_HEQ_Type__c = 'MASTER')];
        
        for(MSD_CORE_HEQ_Template_File_Metadata__c rec : lstOfTempFileMetadataToBeUpdated) {
            rec.MSD_CORE_Status__c = 'EXPIRED';
        }
        
        if(lstOfTempFileMetadataToBeUpdated.size()>0) {
            UPDATE lstOfTempFileMetadataToBeUpdated;
        }
            
        List<ContentVersion> lstOfResourcesToBeExpired = new List<ContentVersion>();
        lstOfResourcesToBeExpired = [SELECT Id, MSD_CORE_HEQ_Associated_Template__c, MSD_CORE_Status__c
                                    FROM ContentVersion 
                                    WHERE MSD_CORE_HEQ_Associated_Template__r.MSD_CORE_HEQ_Design_Metadata__c IN:setOfDesignMetadataExpired];
        
        for(ContentVersion rec : lstOfResourcesToBeExpired) {
            rec.MSD_CORE_Status__c = 'Expired';
        }
        
        if(lstOfResourcesToBeExpired.size()>0) {
            UPDATE lstOfResourcesToBeExpired;
        }
    }
}