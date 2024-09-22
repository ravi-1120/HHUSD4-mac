public with sharing class VeevaCustomSettingsService {

    private static final String VEEVA_SETTINGS_OBJECT_NAME = 'Veeva_Settings_vod__c';

    private static final String VEEVA_SETTINGS_ENABLE_CRM_DESKTOP_FIELD_NAME ='Enable_CRM_Desktop_vod__c';
    private static final String USER_ENABLE_CRM_DESKTOP_OVERRIDE_FIELD_NAME ='Enable_CRM_Desktop_Override_vod__c';


    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getVeevaSettings(List<String> settingFieldNames){
        return getCustomSettings(VEEVA_SETTINGS_OBJECT_NAME, settingFieldNames);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCustomSettings(String customSettingObjectName, List<String> settingFieldNames) {
        Schema.SObjectType settingsType = getSObjectType(customSettingObjectName);
        if (settingsType == null) {
            throw new AuraHandledException('Invalid Custom Setting Name Provided: "' + customSettingObjectName + '".');
        }
        Map<String, Object> settingsMapResult = new Map<String, Object>();

        List<String> filteredSettings = getFilteredSettingFields(settingsType, settingFieldNames);
        if (filteredSettings == null || filteredSettings.isEmpty()) {
            return settingsMapResult;
        }
        String orgId = UserInfo.getOrganizationId();
        String currentUserProfileId = UserInfo.getProfileId();
        String currentUserId = UserInfo.getUserId();

        String queryStmt = 'SELECT ' + String.join(filteredSettings, ', ') + ', SetupOwnerId FROM ' + customSettingObjectName +
        ' WHERE SetupOwnerId in (:currentUserProfileId, :currentUserId, :orgId)';
        List<SObject> settingsSetList = Database.query(queryStmt);

        //Re-orgnize all Approved_Email_Settings record as Map<'SetupOwnerId', Setting Record Map<'Field', Value> >
        Map<String, Map<String, Object>> allSettings = new Map<String, Map<String, Object>>();
        Map<String, Object> settings;
        for (SObject settingsSet : settingsSetList) {
            settings = (Map<String, Object>) settingsSet.getPopulatedFieldsAsMap();
            allSettings.put((String)settings.get('SetupOwnerId'), settings);
        }

        //use user level setting first, then profile level, use default org level setting if user level and profile level both do not exist
        Map<String, Object> matchedSettings;
        if(allSettings.containsKey(currentUserId)) {
            matchedSettings = allSettings.get(currentUserId);
        } else if (allSettings.containsKey(currentUserProfileId)) {
            matchedSettings =  allSettings.get(currentUserProfileId);
        } else {
            matchedSettings = allSettings.get(orgId);
        }

        if (matchedSettings != null && matchedSettings.keySet().size() > 0) {
            for (String s : filteredSettings) {
                Object fieldValue = getVeevaSettingsFromMessage(matchedSettings.get(s));
                settingsMapResult.put(s, fieldValue);
            }
        }
        return adjustCustomSettings(customSettingObjectName, settingsMapResult);
    }

    private static Map<String, Object> adjustCustomSettings(String customSettingObjectName, Map<String, Object> customSettings) {
        if( VEEVA_SETTINGS_OBJECT_NAME.equals(customSettingObjectName) ) {
            // CRM-321721 Unsupported feature: Allow setting override for Enable_CRM_Desktop in an optional field of the User object
            if( customSettings.containsKey(VEEVA_SETTINGS_ENABLE_CRM_DESKTOP_FIELD_NAME) ) {
                adjustEnableCrmDesktopSetting(customSettings);
            }
        }
        return customSettings;
    }

    private static void adjustEnableCrmDesktopSetting(Map<String, Object> customSettings) {
        VeevaBaseObject user = VeevaBaseObject.create('User');
        if( user != null ) {
            SObjectField crmDesktopOverrideField = user.getField(USER_ENABLE_CRM_DESKTOP_OVERRIDE_FIELD_NAME);
            if( crmDesktopOverrideField != null ) {
                Id userId = UserInfo.getUserId();
                String userQuery = 'SELECT ' + USER_ENABLE_CRM_DESKTOP_OVERRIDE_FIELD_NAME + ' FROM User WHERE Id = :userId';
                SObject currentUser = Database.query(userQuery);
                String crmDesktopOverride = (String) currentUser?.get(USER_ENABLE_CRM_DESKTOP_OVERRIDE_FIELD_NAME);
                if( !String.isBlank(crmDesktopOverride) ) {
                    customSettings.put(VEEVA_SETTINGS_ENABLE_CRM_DESKTOP_FIELD_NAME, crmDesktopOverride);
                }
            }
        }
    }

    private static List<String> getFilteredSettingFields(Schema.SObjectType settingsType, List<String> fieldNames) {
        List<String> fields = new List<String>();
        Map<String, SObjectField> fieldMap = settingsType.getDescribe().fields.getMap();
        for (String name : fieldNames) {
            SObjectField field = fieldMap.get(name);
            if (field != null) {
                fields.add(name);
            }
        }
        return fields;
    }

    private static Schema.SObjectType getSObjectType(String objectName) {
        Type typeOfObject = Type.forName(objectName);
        Schema.SObjectType objectType = null;
        if (typeOfObject != null) {
            objectType = ((SObject) typeOfObject.newInstance()).getSObjectType();
        }
        return objectType;
    }

    private static Object getVeevaSettingsFromMessage(Object settingValue) {
        if (settingValue == null) {
            return '';
        } else if (!(settingValue instanceof String)) {
            return settingValue;
        }

        // split values with ;;
        List<String> splitString = settingValue.toString().trim().split(';;');

        // check if setting points to valid VeevaMessage
        if (splitString.size() == 2) {
            String key = splitString.get(0).trim();
            String category = splitString.get(1).trim();
            String messageValue = VeevaMessageController.getMsgWithDefault(key, category, '');

            // if a non-blank message was returned, return it as the VeevaSetting value
            if (!String.isBlank(messageValue)) {
                return messageValue.trim();
            }
        }

        return settingValue;
    }

}