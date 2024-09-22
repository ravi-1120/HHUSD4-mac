public with sharing class S4LCallSearchController {

    private static final String CALL_QUERY =
        'SELECT Id ' +
        'FROM Call2_vod__c ' +
        'WHERE OwnerId =: userId AND Is_Parent_Call_vod__c = 1 AND Status_vod__c != \'Submitted_vod\' {0} ' +
        'ORDER BY Call_Date_vod__c DESC NULLS LAST, Call_Datetime_vod__c DESC NULLS LAST, Name DESC NULLS LAST ' +
        'LIMIT {1}';

    private static final String TODAY_ONLY_WHERE_CLAUSE = 
        'AND (Call_Date_vod__c =: today OR (Call_Datetime_vod__c >=: todayDatetime AND Call_Datetime_vod__c <: tomorrowDatetime))';

    @AuraEnabled
    public static List<Id> getUnsubmittedCallIdsForUser(Boolean todayOnly) {
        List<Id> callIds = new List<Id>();
        List<Call2_vod__c> calls = getAllCallIds(todayOnly);
        if(calls != null) {
            for(Call2_vod__c call : calls) {
                callIds.add(call.Id);
            }
        }
        return callIds;
    }

    @AuraEnabled
    public static List<Id> getAttendeeChildCallIds(Id callId){
        List<Id> childCallIds = new List<Id>();
        Call2_vod__c call = [
            SELECT Id, Account_vod__c, Account_vod__r.IsPersonAccount, Location_Name_vod__c, Location_Id_vod__c, (SELECT Id, Account_vod__c FROM Call2_vod__r WHERE Account_vod__c != NULL)
            FROM Call2_vod__c WHERE Id =: callId];
        if (call != null) {
            Boolean isPersonAccountCall = (Boolean) MCAConvertToCallController.get(call, 'Account_vod__r', 'IsPersonAccount');
            if (isPersonAccountCall == null) {
                isPersonAccountCall = false;
            }
            String callLocationId = extractCallLocationId(call);
            Boolean checkLocation = isPersonAccountCall && callLocationId != null;
            // loop through child calls and extract ids
            List<Call2_vod__c> childCalls = call.Call2_vod__r;
            if(childCalls != null && childCalls.size() > 0) {
                for(Call2_vod__c childCall : call.Call2_vod__r) {
                    // skip location child call
                    if(!checkLocation || childCall.Account_vod__c != callLocationId) {
                        childCallIds.add(childCall.Id);
                    }
                }
            }
        }
        return childCallIds;
    }

    private static String extractCallLocationId (Call2_vod__c call) {
        String locationId = (String) MCAConvertToCallController.get(call, 'Location_Name_vod__c');
        if(locationId == null) {
            locationId = (String) MCAConvertToCallController.get(call, 'Location_Id_vod__c');
        }
        return locationId;
    }

    private static List<Call2_vod__c> getAllCallIds(Boolean todayOnly) {
        String userId = UserInfo.getUserId();
        List<Call2_vod__c> calls = new List<Call2_vod__c>();
        Date today = Date.today();
        Datetime todayDatetime = Datetime.newInstance(today.year(), today.month(), today.day(), 0, 0, 0);
        Datetime tomorrowDatetime = todayDatetime.addDays(1);
        Integer numOfRowsAllowed = Limits.getLimitQueryRows();
        return Database.query(getCallQuery(todayOnly, numOfRowsAllowed));
    }

    private static String getCallQuery(Boolean todayOnly, Integer rowLimit) {
        String additionalWhere = todayOnly == true? TODAY_ONLY_WHERE_CLAUSE : '';
        return CALL_QUERY.replace('{0}', additionalWhere)
            .replace('{1}', String.valueOf(rowLimit));
    }

    @AuraEnabled
    public static List<Call2_vod__c> queryChildCallAccountAndSignatureDate(Id callId) {
        return [SELECT Id, Account_vod__r.Id, Account_vod__r.Formatted_Name_vod__c, Signature_Date_vod__c FROM Call2_vod__c WHERE Parent_Call_vod__c =: callId];
    }
}