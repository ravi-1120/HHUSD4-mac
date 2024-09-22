public with sharing class EmEventController {
    @AuraEnabled
    public static List<EM_Event_Configuration_Country_vod__c> getEventCountryConfigs(
        List<String> recordTypeDeveloperNames
    ) {
        try {
            Date currentDate = System.now().dateGmt();
            List<EM_Event_Configuration_Country_vod__c> result = new List<EM_Event_Configuration_Country_vod__c>();

            // Using Dynamic SOQL, as inline SOQL gives error due to aliasing lookup field
            String soqlQuery =
                'SELECT Id, Country_vod__c, Country_vod__r.Alpha_2_Code_vod__c, toLabel(Country_vod__r.Country_Name_vod__c) LabelAlias, ' +
                    'Event_Configuration_vod__c, External_ID_vod__c ' +
                'FROM EM_Event_Configuration_Country_vod__c ' +
                getWhereClause() +
                'ORDER BY Country_vod__r.Country_Name_vod__c ASC';

            return Database.query(soqlQuery);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<String> getRecordTypesWithEventCountryConfigs(
        List<String> recordTypeDeveloperNames
    ) {
        try {
            List<String> result = new List<String>();
            Date currentDate = System.now().dateGmt();

            String soqlQuery =
                'SELECT Event_Configuration_vod__r.Event_Type_vod__c ' +
                'FROM EM_Event_Configuration_Country_vod__c ' +
                getWhereClause() +
                'GROUP BY Event_Configuration_vod__r.Event_Type_vod__c';

            List<AggregateResult> ars = Database.query(soqlQuery);

            for (AggregateResult ar : ars) {
                result.add((String) ar.get('Event_Type_vod__c'));
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getUserPreferenceCountryConfig() {
        try {
            Id currentUserId = UserInfo.getUserId();
            List<Preferences_vod__c> userPreferenceList = [
                SELECT Id, Event_Country_Config_vod__c
                FROM Preferences_vod__c
                WHERE User_vod__c = :currentUserId
                AND Event_Country_Config_vod__c != ''
                LIMIT 1
            ];
            return !userPreferenceList.isEmpty()
                ? userPreferenceList[0].Event_Country_Config_vod__c
                : '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    static String getWhereClause() {
        return
        'WHERE ' +
            'Country_vod__c != null ' +
            'AND Event_Configuration_vod__r.Event_Type_vod__c IN :recordTypeDeveloperNames ' +
            'AND Event_Configuration_vod__r.Start_Date_vod__c <=: currentDate ' +
            'AND Event_Configuration_vod__r.End_Date_vod__c >=: currentDate ';
    }

    @AuraEnabled(cacheable=true)
    public static String getTeamMemberGroupLabel(String groupDevName) {
        try {
            String result = groupDevName;
            Group publicGroup = [SELECT Name, DeveloperName FROM Group WHERE DeveloperName = :groupDevName AND Type IN ('Queue', 'Regular') LIMIT 1];
            if (publicGroup != null) {
                result = publicGroup.Name;
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static VMobile_Object_Configuration_vod__c getEngageVMOC(){
        return [SELECT Id FROM VMobile_Object_Configuration_vod__c WHERE Device_vod__c = 'CRM_Engage_vod' and Active_vod__c = true LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasEngageWebinarEditAccess(){
        Schema.RecordTypeInfo recordType = Schema.SObjectType.Remote_Meeting_vod__c.getRecordTypeInfosByDeveloperName().get('Webinar_vod');
        Map<String,Schema.SObjectField > eventFieldMap = Schema.SObjectType.EM_Event_vod__c.fields.getmap();
        Map<String,Schema.SObjectField > eventSpeakerFieldMap = Schema.SObjectType.EM_Event_Speaker_vod__c.fields.getmap();
        Map<String,Schema.SObjectField > eventAttendeeFieldMap = Schema.SObjectType.EM_Attendee_vod__c.fields.getmap();
        Map<String,Schema.SObjectField > remoteMeetingFieldMap = Schema.SObjectType.Remote_Meeting_vod__c.fields.getmap();
        Set<String> eventFields = new Set<String>{'Engage_Webinar_vod__c', 'Webinar_Status_vod__c',
                                                'Assigned_Host_vod__c', 'Webinar_Error_Message_vod__c', 'Webinar_Error_DateTime_vod__c'};
        Set<String> remoteMeetingFields = new Set<String>{'Meeting_Id_vod__c', 'Scheduled_vod__c', 'Scheduled_DateTime_vod__c', 'Assigned_Host_vod__c'};
        Boolean hasEngageEditAccess = recordType.isActive()
                                        && eventSpeakerFieldMap.get('Webinar_Panelist_URL_vod__c').getDescribe().isUpdateable()
                                        && eventAttendeeFieldMap.get('Webinar_Participant_URL_vod__c').getDescribe().isUpdateable();
        hasEngageEditAccess = checkEngageWebinarEditAccess(hasEngageEditAccess, eventFieldMap, eventFields);
        hasEngageEditAccess = checkEngageWebinarEditAccess(hasEngageEditAccess, remoteMeetingFieldMap, remoteMeetingFields);
        return hasEngageEditAccess;
    }

    private static Boolean checkEngageWebinarEditAccess(Boolean hasEngageEditAccess, Map<String,Schema.SObjectField > fieldMap, Set<String> fields) {
        Boolean isUpdateable = hasEngageEditAccess;
        for(String field : fields) {
            if(!isUpdateable) {
                break;
            }
            isUpdateable = isUpdateable && fieldMap.get(field).getDescribe().isUpdateable();
        }
        return isUpdateable;
    }
}