trigger VeevaEmEventStageConfigurationTrigger on EM_Stage_Configuration_vod__c (before insert, before update) {
    VeevaTriggerHandler handler = new VeevaEmStageConfigurationTriggerHandler();
    handler.handleTrigger();
}