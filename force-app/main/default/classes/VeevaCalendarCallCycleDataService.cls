public with sharing class VeevaCalendarCallCycleDataService {
    public static final Set<String> REQUIRED_FIELDS = new Set<String>{'Account_vod__c', 'Day_of_Week_vod__c', 'Duration_vod__c', 'Start_Time_vod__c', 'Week_vod__c'};
    
    public static Map<String, Map<String, Map<String, Object>>> getCallCycleEntryInfo() {
        Map<String, Map<String, Map<String, Object>>> callCycleRes = new Map<String, Map<String, Map<String, Object>>>();
        
        // check permissions
        VeevaBaseObject callCycleObj = VeevaBaseObject.create('Call_Cycle_Entry_vod__c');
        if (callCycleObj.getAccessibleFields(REQUIRED_FIELDS).size() != REQUIRED_FIELDS.size()) {
            return callCycleRes;
        }
        // query user's call cycle entries
        List<Call_Cycle_Entry_vod__c> callCycleEntries = [SELECT Account_vod__r.Formatted_Name_vod__c, Day_Title_vod__c, Day_of_Week_vod__c, toLabel(Day_of_Week_vod__c) dayLabel, Duration_vod__c, Start_Time_vod__c, Week_vod__c FROM Call_Cycle_Entry_vod__c WHERE OwnerId = :UserInfo.getUserId() AND IsDeleted != True AND Account_vod__r.Formatted_Name_vod__c != null];

        // format response to look like: {<call cycle number> : {<weekday name> : { entries: [<obj1 info>, <obj2 info>, ...], title: <weekday title>, label: <translated weekday label> }, ... }, ... }
        for (Call_Cycle_Entry_vod__c entry : callCycleEntries) {
            Map<String, Map<String, Object>> entryWeek = callCycleRes.get(String.valueOf(entry.Week_vod__c));
            if (entryWeek == null) {
                entryWeek = new Map<String, Map<String, Object>>();
                callCycleRes.put(String.valueOf(entry.Week_vod__c), entryWeek);
            }

            Map<String, Object> entryDay = entryWeek.get(entry.Day_of_Week_vod__c);
            if (entryDay == null) {
                entryDay = new Map<String, Object>();
                entryDay.put('entries', new List<Call_Cycle_Entry_vod__c>());
                entryDay.put('title', entry.Day_Title_vod__c);
                entryDay.put('label', entry.get('dayLabel'));

                entryWeek.put(entry.Day_of_Week_vod__c, entryDay);
            }
            List<Call_Cycle_Entry_vod__c> dayEntries = (List<Call_Cycle_Entry_vod__c>) entryDay.get('entries');
            dayEntries.add(entry);
        }
        return callCycleRes;
    }
}