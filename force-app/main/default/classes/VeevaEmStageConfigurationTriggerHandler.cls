public without sharing class VeevaEmStageConfigurationTriggerHandler extends VeevaTriggerHandler{
	private List<EM_Stage_Configuration_vod__c > newEventStageConfigs = new List<EM_Stage_Configuration_vod__c >();
    private List<EM_Stage_Configuration_vod__c > oldEventStageConfigs = new List<EM_Stage_Configuration_vod__c >();
    private Map<ID, EM_Stage_Configuration_vod__c > newEventStageConfigsMap = new Map<ID, EM_Stage_Configuration_vod__c >();
    private Map<ID, EM_Stage_Configuration_vod__c > oldEventStageConfigsMap = new Map<ID, EM_Stage_Configuration_vod__c >();
    
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newEventStageConfigs = (List<EM_Stage_Configuration_vod__c>) triggerNew;
        this.oldEventStageConfigs = (List<EM_Stage_Configuration_vod__c>) triggerOld;
        this.newEventStageConfigsMap = (Map<ID, EM_Stage_Configuration_vod__c>) triggerNewMap;
        this.oldEventStageConfigsMap = (Map<ID, EM_Stage_Configuration_vod__c>) triggerOldMap;
    }
    
    protected override boolean doRecursionCheck() {
        return true;
    }
    
    protected override String sObjectType() {
        return 'EM_Stage_Configuration_vod__c';
    }
    
    protected override void beforeInsert() {
		beforeInsUpd();
    }
    
    protected override void beforeUpdate() {
		beforeInsUpd();
    }
    
    private void beforeInsUpd() {
        Set<String> eventRules = new Set<String>();
        Map<String, Set<String>> eventRuleToStageNames = new Map<String, Set<String>>();
        Map<String, Set<String>> eventRuleToStatusValues = new Map<String, Set<String>>();
        for (EM_Stage_Configuration_vod__c eventStage : newEventStageConfigs) {
            eventRules.add(eventStage.Event_Rule_vod__c);
        }
        populateEventRuleToStageSettings(eventRuleToStageNames, eventRuleToStatusValues, eventRules);
        checkStageName(eventRuleToStageNames);
        checkStatus(eventRuleToStatusValues);
    }
    
    private void populateEventRuleToStageSettings(Map<String, Set<String>> eventRuleToStageNames, Map<String, Set<String>> eventRuleToStatusValues, Set<String> eventRules) {
        for (EM_Stage_Configuration_vod__c existingStageConfig : [SELECT Id, Name, Stage_vod__c, Statuses_vod__c , Event_Rule_vod__c 
                                                          FROM EM_Stage_Configuration_vod__c
                                                          WHERE Event_Rule_vod__c IN :eventRules]) {
            if(!eventRuleToStageNames.containsKey(existingStageConfig.Event_Rule_vod__c)) {
                eventRuleToStageNames.put(existingStageConfig.Event_Rule_vod__c, new Set<String> ());
            }
            eventRuleToStageNames.get(existingStageConfig.Event_Rule_vod__c).add(existingStageConfig.Stage_vod__c);

            if(!eventRuleToStatusValues.containsKey(existingStageConfig.Event_Rule_vod__c)) {
                eventRuleToStatusValues.put(existingStageConfig.Event_Rule_vod__c, new Set<String> ());
            }
            for(String statusValue : existingStageConfig.Statuses_vod__c.split(',')) {
                eventRuleToStatusValues.get(existingStageConfig.Event_Rule_vod__c).add(statusValue.trim());
            }
        }
    }
    
    private void checkStageName(Map<String, Set<String>> eventRuleToStageNames) {
        for (EM_Stage_Configuration_vod__c eventStage : newEventStageConfigs) {
            Set<String> existingStageNames = eventRuleToStageNames.get(eventStage.Event_Rule_vod__c);
            if (existingStageNames != null && stageNameChanged(eventStage) && existingStageNames.contains(eventStage.Stage_vod__c)) {
                eventStage.addError('Duplicate Configuration: This stage already exists.');
            }
        }
    }
    
    private void checkStatus(Map<String, Set<String>> eventRuleToStatusValues) {
        for (EM_Stage_Configuration_vod__c eventStage : newEventStageConfigs) {
            if(statusChanged(eventStage)) {
                Set<String> existingStatusValues = eventRuleToStatusValues.get(eventStage.Event_Rule_vod__c);
                if(existingStatusValues != null) {
                    if(Trigger.isUpdate){
                        for(String oldStatusValue : oldEventStageConfigsMap.get(eventStage.Id).Statuses_vod__c.split(',')) {
                            existingStatusValues.remove(oldStatusValue.trim());
                        }
                    }
                    for(String newStatusValue : eventStage.Statuses_vod__c.split(',')) {
                        if (existingStatusValues.contains(newStatusValue.trim())) {
                            eventStage.addError('Duplicate Configuration: Event status is allowed in only one stage record.');
                        }
                        existingStatusValues.add(newStatusValue.trim());
                    }
                }
            }
        }
    }

    private boolean stageNameChanged(EM_Stage_Configuration_vod__c eventStage) {
        return Trigger.isInsert || (oldEventStageConfigsMap.get(eventStage.Id).Stage_vod__c != eventStage.Stage_vod__c);
    }

    private boolean statusChanged(EM_Stage_Configuration_vod__c eventStage) {
        return Trigger.isInsert || (oldEventStageConfigsMap.get(eventStage.Id).Statuses_vod__c != eventStage.Statuses_vod__c);
    }
}