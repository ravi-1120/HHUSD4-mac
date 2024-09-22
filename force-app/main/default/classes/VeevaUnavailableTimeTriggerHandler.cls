public without sharing class VeevaUnavailableTimeTriggerHandler extends VeevaTriggerHandler {
    private final String STARTS_ENDS_NOT_NULL_KEY = 'Common;;STARTS_AND_ENDS_CANNOT_BE_NULL';
    private final String STARTS_BEFORE_ENDS_KEY = 'OfficeBestTimes;;BEST_TIMES_START_END_ERROR';
    private final String STARTS_ENDS_NOT_NULL_DEFAULT = 'Start and End Date Times cannot be null.';
    private final String STARTS_BEFORE_ENDS_DEFAULT = 'Start time must be earlier than end time';

    private List<Unavailable_Time_vod__c> newUnavailableTimes;
    private Map<ID, Unavailable_Time_vod__c> newUnavailableTimesMap;
    
    private Map<String, String> messageMap;
    
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newUnavailableTimes = (List<Unavailable_Time_vod__c>) triggerNew;
    }
    
    protected override String sObjectType() {
        return 'Unavailable_Time_vod__c';
    }
    
    protected override void beforeInsert() {
        loadVeevaMessages();
        validateFieldValues();
    }
    
    protected override void beforeUpdate() {
        loadVeevaMessages();
        validateFieldValues();
    }
    
    private void loadVeevaMessages() {
        this.messageMap = VOD_VEEVA_MESSAGE.getVeevaMessages(new List<String>{STARTS_ENDS_NOT_NULL_KEY, STARTS_BEFORE_ENDS_KEY});
    }
    
    private void validateFieldValues() {
        for (Unavailable_Time_vod__c unavailableTime : this.newUnavailableTimes) {
            if (unavailableTime.Start_Datetime_vod__c == null || unavailableTime.End_Datetime_vod__c == null) {
                String startEndCannotBeNullMsg = 
                    this.messageMap.get(STARTS_ENDS_NOT_NULL_KEY) != null 
                    ? this.messageMap.get(STARTS_ENDS_NOT_NULL_KEY) : STARTS_ENDS_NOT_NULL_DEFAULT;
                unavailableTime.addError(startEndCannotBeNullMsg);
            } else if (unavailableTime.Start_Datetime_vod__c >= unavailableTime.End_Datetime_vod__c) {
                String startNotBeforeEndDatetimeMsg = 
                    this.messageMap.get(STARTS_BEFORE_ENDS_KEY) != null 
                    ? this.messageMap.get(STARTS_BEFORE_ENDS_KEY) : STARTS_BEFORE_ENDS_DEFAULT;
                unavailableTime.addError(startNotBeforeEndDatetimeMsg);
            }
        }
    }
}