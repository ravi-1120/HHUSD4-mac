trigger VOD_EM_EVENT_RULE_AFTER_INSERT_UPDATE on EM_Event_Rule_vod__c (after insert, after update) {
    VeevaTriggerHandler handler = new VeevaEmEventRuleTriggerHandler();
    handler.handleTrigger();
}