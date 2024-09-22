public class ChannelMetricsTriggerHandler extends VeevaTriggerHandler{
	private List<Channel_Metrics_vod__c> newRecords = new List<Channel_Metrics_vod__c>();
    private List<Channel_Metrics_vod__c> oldRecords = new List<Channel_Metrics_vod__c>();
    private Map<Id, Channel_Metrics_vod__c> newRecordsMap = new Map<Id, Channel_Metrics_vod__c>();
    private Map<Id, Channel_Metrics_vod__c> oldRecordsMap = new Map<Id, Channel_Metrics_vod__c>();
   
    @testVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.newRecords = (List<Channel_Metrics_vod__c>) triggerNew;
        this.oldRecords = (List<Channel_Metrics_vod__c>) triggerOld;
        this.newRecordsMap = (Map<Id, Channel_Metrics_vod__c>) triggerNewMap;
        this.oldRecordsMap = (Map<Id, Channel_Metrics_vod__c>) triggerOldMap;
    }

    
    protected override String sObjectType() {
        return 'Channel_Metrics_vod__c';
    }
    
    protected override void beforeInsert() {
        handleUpsert();
    }
    
    protected override void beforeUpdate() {
        handleUpsert();
    }
    
    public void handleUpsert(){
        for(Channel_Metrics_vod__c curr : newRecords ){
            curr.External_ID_vod__c = curr.Account_vod__c + '_' + curr.RecordTypeId + '_' + curr.Channel_Value_vod__c;
        }
    }
}