public class MSD_CORE_HEQ_BATCHAPEX_CreateShadowCD implements Database.Batchable<sObject>{
    
    public Boolean dailySync = true;
    public MSD_CORE_HEQ_BATCHAPEX_CreateShadowCD(Boolean fullSync) {
        if(fullSync) {
            dailySync = false;
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, LatestPublishedVersionId FROM ContentDocument';
        if(dailySync) {
            query = 'SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE LastModifieddate =: TODAY';
        }        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<ContentDocument> lstOfContentDocs ){
        //ReportingDataModelHelper.upsertShadowContentDocument(lstOfContentDocs);
        system.debug('### lstOfContentDocs '+lstOfContentDocs);
    }
    
    public void finish(Database.BatchableContext BC)
    {
        
    }
}