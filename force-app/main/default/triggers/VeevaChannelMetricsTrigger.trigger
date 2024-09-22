trigger VeevaChannelMetricsTrigger on Channel_Metrics_vod__c (before insert, before update) {
	VeevaTriggerHandler handler = new ChannelMetricsTriggerHandler();
    handler.handleTrigger();
}