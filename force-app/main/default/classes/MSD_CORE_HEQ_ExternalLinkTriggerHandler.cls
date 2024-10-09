public class MSD_CORE_HEQ_ExternalLinkTriggerHandler {
    public Static List<Id> lstOfExternalLinksDeleted = new List<Id>();
    public static void upsertContentVersion(Map<Id, MSD_CORE_HEQ_External_Link__c> newMap, Map<Id, MSD_CORE_HEQ_External_Link__c> oldmap) {
        List<ContentVersion> lstofContentVersionToBeCreated = new List<ContentVersion>();
        List<ContentVersion> lstofContentVersionToBeUpdated = new List<ContentVersion>();
        Map<Id, MSD_CORE_HEQ_External_Link__c> mapOfRecordsUpdated = new Map<Id, MSD_CORE_HEQ_External_Link__c>();
        for(MSD_CORE_HEQ_External_Link__c rec : newMap.values()) {
            if(oldMap == NULL) {
                Blob bodyBlob=Blob.valueOf(rec.MSD_CORE_HEQ_Description__c!=NULL?rec.MSD_CORE_HEQ_Description__c:'Test');
                ContentVersion cvRecToBeCreated = new ContentVersion(
                    Title=rec.Name, 
                    PathOnClient =rec.Name,
                    VersionData = bodyBlob, 
                    Description = rec.MSD_CORE_HEQ_Description__c,
                    MSD_CORE_HEQ_URL__c = rec.MSD_CORE_HEQ_URL__c,
                    MSD_CORE_HEQ_External_Link_Id__c = rec.id,
                    MSD_CORE_HEQ_Resource_Type__c = 'External Link',
                    origin = 'H'
                );
                lstofContentVersionToBeCreated.add(cvRecToBeCreated);
            } else if(oldMap != NULL && (rec.Name != oldMap.get(rec.Id).Name || rec.MSD_CORE_HEQ_Description__c != oldMap.get(rec.Id).MSD_CORE_HEQ_Description__c || rec.MSD_CORE_HEQ_URL__c != oldMap.get(rec.Id).MSD_CORE_HEQ_URL__c )) {
                mapOfRecordsUpdated.put(rec.Id, rec);
            }
        }
        if(lstofContentVersionToBeCreated.size()>0) {
            INSERT lstofContentVersionToBeCreated;
        }
        for(ContentVersion rec : [SELECT Id, Description, Title,  MSD_CORE_HEQ_URL__c, MSD_CORE_HEQ_External_Link_Id__c 
                                  FROM CONTENTVERSION
                                  WHERE MSD_CORE_HEQ_External_Link_Id__c in: mapOfRecordsUpdated.keySet()]) {
                                      rec.Title=mapOfRecordsUpdated.get(rec.MSD_CORE_HEQ_External_Link_Id__c).Name;
                                      rec.Description = mapOfRecordsUpdated.get(rec.MSD_CORE_HEQ_External_Link_Id__c).MSD_CORE_HEQ_Description__c;
                                      rec.MSD_CORE_HEQ_URL__c = mapOfRecordsUpdated.get(rec.MSD_CORE_HEQ_External_Link_Id__c).MSD_CORE_HEQ_URL__c;
                                      lstofContentVersionToBeUpdated.add(rec);
                                  }
        System.debug('### lstofContentVersionToBeUpdated '+lstofContentVersionToBeUpdated);
        if(lstofContentVersionToBeUpdated.size()>0) {
            UPDATE lstofContentVersionToBeUpdated;
        }
    }
    
    public static void collectDeletedIds(Map<Id, MSD_CORE_HEQ_External_Link__c> oldMap) {
        lstOfExternalLinksDeleted.addAll(oldMap.keySet());
    }
    
    public static void updateContentVersion() {
        List<ContentVersion> lstofContentVersionToBeUpdated = new List<ContentVersion>();
        for(ContentVersion rec : [SELECT Id, MSD_CORE_HEQ_External_Link_Id__c 
                                  FROM CONTENTVERSION
                                  WHERE MSD_CORE_HEQ_External_Link_Id__c in: lstOfExternalLinksDeleted]) {
                                      rec.MSD_CORE_HEQ_External_Link_Id__c='';
                                      lstofContentVersionToBeUpdated.add(rec);
                                  }
        if(lstofContentVersionToBeUpdated.size()>0) {
            UPDATE lstofContentVersionToBeUpdated;
        }
    }
}