public with sharing class S4LRecordTypeSelectorController {

    public class RecordTypeOption {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;

        public RecordTypeOption(Schema.RecordTypeInfo recordTypeInfo) {
            this.id = recordTypeInfo.getRecordTypeId();
            this.name = recordTypeInfo.getName();
        }
    }

    // check if the user can select the Call record type

    @AuraEnabled
    public static Boolean canSelectClmCallRecordType(){
        Multichannel_Settings_vod__c mcSettings = Multichannel_Settings_vod__c.getInstance();
        return mcSettings != null && mcSettings.SELECT_CLM_CALL_RECORD_TYPE_vod__c;
    }

    @AuraEnabled
    public static Map<String, Object> getEditableSelectorConfig(Id accountId) {
        Account account = queryAccount(accountId);
        String accountRecordType = account.RecordType.Name;

        // Base map + default record type
        List<Schema.RecordTypeInfo> allRecordTypeInfos = filterEventRecordType(getAllAvailableCallRecordTypeForAccount(accountRecordType));
        Map<String, Object> result = getDefaultRecordType(accountId, allRecordTypeInfos);
        List<RecordTypeOption> options = new List<RecordTypeOption>();
        for(Schema.RecordTypeInfo rtInfo : allRecordTypeInfos) {
            options.add(new RecordTypeOption(rtInfo));
        }
        result.put('recordTypes', options);
        return result;
    }

    public static List<Schema.RecordTypeInfo> getAllAvailableCallRecordTypeForAccount(String accountRecordType) {
        // retrieve all Call record types
        DescribeSobjectResult callDescribe = Call2_vod__c.getSObjectType().getDescribe();
        List<Schema.RecordTypeInfo> allRecordTypes = getAllCallRecordTypes(callDescribe);

        // query account and retrieve account's allowed call types
        Map<String, Set<String>> allowedCallRecordTypeSettings = getAllowedCallRecordTypesSetting();
        if(allowedCallRecordTypeSettings.containsKey(accountRecordType)) {
            Set<String> accountAllowedRecordTypes = allowedCallRecordTypeSettings.get(accountRecordType);
            allRecordTypes = getFilteredCallRecordTypes(allRecordTypes, accountAllowedRecordTypes);
        }
        return allRecordTypes;
    }

    private static Account queryAccount(Id accountId) {
        return [SELECT Id, RecordType.Name FROM Account WHERE Id =: accountId];
    }

    private static List<RecordType> queryAllCallRecordTypes() {
        return [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Call2_vod__c'];
    }

    private static Map<Id, String> mapRecordTypeIdToName(List<RecordType> recordTypes) {
        Map<Id, String> rtMap = new Map<Id, String>();
        for (RecordType rt : recordTypes) {
            rtMap.put(rt.Id, rt.Name);
        }
        return rtMap;
    }

    public static Map<String, Set<String>> getAllowedCallRecordTypesSetting() {
        Map<String, Object> settingsMap = VeevaCustomSettingsService.getCustomSettings('Veeva_Settings_vod__c', new List<String>{'ALLOWED_CALL_RECORD_TYPES_vod__c'});
        String veevaAllowedCallRecordTypeSettings = (String) settingsMap.get('ALLOWED_CALL_RECORD_TYPES_vod__c');
        return parseVeevaSettingsForAccountType(veevaAllowedCallRecordTypeSettings, true);
    }

    public static Map<String, Set<String>> getDefaultCallRecordTypesSetting() {
        Map<String, Object> settingsMap = VeevaCustomSettingsService.getCustomSettings('Veeva_Settings_vod__c', new List<String>{'DEFAULT_CALL_RECORD_TYPE_vod__c'});
        String veevaDefaultCallRecordTypeSettings = (String) settingsMap.get('DEFAULT_CALL_RECORD_TYPE_vod__c'); 
        return parseVeevaSettingsForAccountType(veevaDefaultCallRecordTypeSettings, false);
    }

    // settingValue format: <account_type1>,<val_1>,<val_2>;;<account_type2>,<val_1>,<val_2>;;...
    // allowedMultiple: flag to determine if <val_2> is expected per account type entry
    public static Map<String, Set<String>> parseVeevaSettingsForAccountType(String settingValue, Boolean allowedMultiple) {
        Map<String, Set<String>> result = new Map<String, Set<String>>();
        if(String.isNotBlank(settingValue)) {
            for(String perAccountType : settingValue.split(';;')) {
                Set<String> values = new Set<String>();
                String[] split = perAccountType.split(',');
                String accountTypeName = split[0].trim();
                for(Integer i = 1; i < split.size(); i++) {
                    String val = split[i].trim();
                    if(allowedMultiple || values.isEmpty()) {
                        values.add(val);
                    }
                }
                result.put(accountTypeName, values);
            }
        }
        return result;
    }

    private static List<Schema.RecordTypeInfo> filterEventRecordType(List<Schema.RecordTypeInfo> allRecordTypes) {
        Schema.RecordTypeInfo eventCallRecordTypeInfo = Call2_vod__c.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('Event_vod');
        Integer eventIndex = allRecordTypes.indexOf(eventCallRecordTypeInfo);
        if (eventIndex != -1) {
            allRecordTypes.remove(eventIndex);
        }
        return allRecordTypes;
    }

    @AuraEnabled
    public static Map<String, Object> getDefaultRecordType(Id accountId) {
        return getDefaultRecordType(accountId, null);
    }

    private static Map<String, Object> getDefaultRecordType(Id accountId, List<Schema.RecordTypeInfo> allRecordTypes) {
        Account account = queryAccount(accountId);
        String accountRecordType = account.RecordType.Name;
        if (allRecordTypes == null) {
            allRecordTypes = filterEventRecordType(getAllAvailableCallRecordTypeForAccount(accountRecordType));
        }

        // query all call record types and store into a map
        List<RecordType> callRecordTypes = queryAllCallRecordTypes();
        Map<Id, String> callRecordTypeMap = mapRecordTypeIdToName(callRecordTypes);

        Schema.RecordTypeInfo defaultRt = null;
        if(allRecordTypes != null && !allRecordTypes.isEmpty()) {
            // get default call record type setting for account
            Map<String, Set<String>> defaultRecordTypesMap = getDefaultCallRecordTypesSetting();
            if(defaultRecordTypesMap.containsKey(accountRecordType)) {
                Set<String> defaultRecordTypes = defaultRecordTypesMap.get(accountRecordType);
                if(!defaultRecordTypes.isEmpty()) {
                    String defaultRecordType = defaultRecordTypes.iterator().next();
                    for(Schema.RecordTypeInfo recordType : allRecordTypes) {
                        Id recordTypeId = recordType.getRecordTypeId();
                        String rtName = callRecordTypeMap.get(recordTypeId);
                        if(rtName == defaultRecordType) {
                            defaultRt = recordType;
                            break;
                        }
                    }
                }
            }
            // get default call record type from object setting
            if(defaultRt == null) {
                defaultRt = allRecordTypes.get(0);
                for(Schema.RecordTypeInfo rts : allRecordTypes) {
                    if(rts.isDefaultRecordTypeMapping()) {
                        defaultRt = rts;
                    }
                }
            }
        }

        Map<String, Object> result = getBaseResultMap();
        if(defaultRt != null) {
            result.put('recordType', new RecordTypeOption(defaultRt));
        }
        return result;
    }

    private static Map<String, Object> getBaseResultMap() {
        Map<String, Object> result = new Map<String, Object> ();
        result.put('label', RecordType.getSObjectType().getDescribe().getLabel());
        return result;
    }

    private static List<Schema.RecordTypeInfo> getFilteredCallRecordTypes (List<Schema.RecordTypeInfo> allRecordTypes, Set<String> accountAllowedRecordTypes) {
        // query all call record types and store into a map
        List<RecordType> callRecordTypes = queryAllCallRecordTypes();
        Map<Id, String> callRecordTypeMap = mapRecordTypeIdToName(callRecordTypes);

        List<Schema.RecordTypeInfo> filtered = new List<Schema.RecordTypeInfo>();
        for(Schema.RecordTypeInfo callRecordType : allRecordTypes) {
            Id callRecordTypeId = callRecordType.getRecordTypeId();
            String rtName = callRecordTypeMap.get(callRecordTypeId);
            if(accountAllowedRecordTypes.contains(rtName)) {
                filtered.add(callRecordType);
            }
        }
        return filtered;
    }

    private static List<Schema.RecordTypeInfo> getAllCallRecordTypes(DescribeSobjectResult callDescribe) {
        List<Schema.RecordTypeInfo> recordTypeInfos = callDescribe.getRecordTypeInfos();
        List<Schema.RecordTypeInfo> result = new List<Schema.RecordTypeInfo>();
        if(recordTypeInfos != null) {
            for(Schema.RecordTypeInfo info : recordTypeInfos) {
                if(canIncludeRecordType(info)) {
                    result.add(info);
                }
            }
        }
        return result;
    }

    private static Boolean canIncludeRecordType(Schema.RecordTypeInfo rt) {
        return rt != null 
            // skip Master record type
            && !rt.isMaster() 
            // include Active record type
            && rt.isActive() 
            // include record type that is available to user
            && rt.isAvailable();
    }

}