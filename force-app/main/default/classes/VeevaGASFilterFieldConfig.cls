public with sharing class VeevaGASFilterFieldConfig {
    private static Set<Schema.DisplayType> SUPPORTED_FILTER_FIELD_TYPES = new Set<Schema.DisplayType>{
        Schema.DisplayType.STRING,
        Schema.DisplayType.PICKLIST,
        Schema.DisplayType.MULTIPICKLIST,
        Schema.DisplayType.BOOLEAN,
        Schema.DisplayType.REFERENCE,
        Schema.DisplayType.DOUBLE,
        Schema.DisplayType.CURRENCY,
        Schema.DisplayType.PERCENT
    };

    private static List<VeevaGASFilterField> DEFAULT_IMPLICIT_FILTER_FIELDS = new List<VeevaGASFilterField>{
        new VeevaGASFilterField('Account', 'RecordTypeId')
    };

    private static List<VeevaGASFilterField> DEFAULT_USER_FILTER_FIELDS = new List<VeevaGASFilterField>{
        new VeevaGASFilterField('Account', 'Specialty_1_vod__c'),
        new VeevaGASFilterField('Account', 'Credentials_vod__c')
    };

    private static Set<String> SUPPORTED_OBJECT_NAMES = new Set<String>{
        Account.getSObjectType().getDescribe().getName(),
        Address_vod__c.getSObjectType().getDescribe().getName()
    };
    
    public List<VeevaGASFilterField> getImplicitFilterFields() {
        List<VeevaGASFilterField> implicitFilterFields = getFilterFields('GAS_Implicit_Filters_vod__c');
        if (implicitFilterFields.isEmpty()) {
            implicitFilterFields.addAll(DEFAULT_IMPLICIT_FILTER_FIELDS);
        }
        List<VeevaGASFilterField> userAccessibleImplicitFilterFields = getUserAccessible(implicitFilterFields);
        return getSupportedFilterFields(userAccessibleImplicitFilterFields, SUPPORTED_FILTER_FIELD_TYPES);
    }

    public List<VeevaGASFilterField> getUserFilterFields() {
        List<VeevaGASFilterField> userFilterFields = getFilterFields('GAS_User_Filters_vod__c');
        if (userFilterFields.isEmpty()) {
            userFilterFields.addAll(DEFAULT_USER_FILTER_FIELDS);
        }
        List<VeevaGASFilterField> userAccessibleUserFilterFields = getUserAccessible(userFilterFields);
        return getSupportedFilterFields(userAccessibleUserFilterFields, SUPPORTED_FILTER_FIELD_TYPES);
    }

    private static List<VeevaGASFilterField> getSupportedFilterFields(List<VeevaGASFilterField> filterFields, Set<Schema.DisplayType> supportedFieldTypes) {
        List<VeevaGASFilterField> supportedFilterFields = new List<VeevaGASFilterField>();
        for (VeevaGASFilterField filterField : filterFields) {
            if (supportedFieldTypes.contains(filterField.field.getDescribe().getType()) && !isLongOrRichTextArea(filterField.field)) {
                supportedFilterFields.add(filterField);
            }
        }
        return supportedFilterFields;
    }

    private static boolean isLongOrRichTextArea(Schema.SObjectField field) {
        return field.getDescribe().getType() == Schema.DisplayType.TEXTAREA && field.getDescribe().getLength() > 255;
    }

    private static List<VeevaGASFilterField> getFilterFields(String fieldApiName) {
        String settingFieldValue = getFieldValue(fieldApiName);
        List<String> doubleSemiColonSeparatedValues = removeBlankStrings(settingFieldValue.split(';;'));
        List<VeevaGASFilterField> filterFields;
        if (doubleSemiColonSeparatedValues.size() == 2) {
            filterFields = getFilterFieldsFromVeevaMessage(doubleSemiColonSeparatedValues.get(0), doubleSemiColonSeparatedValues.get(1));
        } else {
            List<String> singleSemiColonSeparatedValues = removeBlankStrings(getObjectFields(settingFieldValue));
            filterFields = getFilterFieldsFromValues(singleSemiColonSeparatedValues);
        }
        return filterFields;
    }

    private static List<VeevaGASFilterField> getUserAccessible(List<VeevaGASFilterField> filterFields) {
        List<VeevaGASFilterField> userAccessibleFilterFields = new List<VeevaGASFilterField>();
        for (VeevaGASFilterField filterField : filterFields) {
            if (hasAccessToFilterField(filterField)) {
                userAccessibleFilterFields.add(filterField);
            }
        }
        return userAccessibleFilterFields;
    }

    private static boolean hasAccessToFilterField(VeevaGASFilterField filterField) {
        boolean hasAccessToFilterField = false;
        if (filterField.sObjectType != null && filterField.sObjectType.getDescribe().isAccessible()) {
            if (filterField.field != null && filterField.field.getDescribe().isAccessible()) {
                hasAccessToFilterField = true;
            }
        }
        return hasAccessToFilterField;
    }

    private static String getFieldValue(String fieldApiName) {
        Global_Account_Search_Settings_vod__c gasSettings = Global_Account_Search_Settings_vod__c.getInstance();
        Object value = gasSettings.get(fieldApiName);
        return value != null ? value.toString() : '';
    }

    private static List<VeevaGASFilterField> getFilterFieldsFromVeevaMessage(String messageName, String category) {
        String messageValue = VeevaMessageController.getMsgWithDefault(messageName, category, '');
        List<VeevaGASFilterField> filterFieldsFromVeevaMessage;
        if (String.isBlank(messageValue)) {
            filterFieldsFromVeevaMessage = new List<VeevaGASFilterField>();
        } else {
            List<String> separatedValues = removeBlankStrings(getObjectFields(messageValue));
            filterFieldsFromVeevaMessage = getFilterFieldsFromValues(separatedValues);
        }
        return filterFieldsFromVeevaMessage;
    }

    private static List<VeevaGASFilterField> getFilterFieldsFromValues(List<String> values) {
        List<VeevaGASFilterField> filterFields = new List<VeevaGASFilterField>();
        Set<String> addedValue = new Set<String>();
        for (String value : values) {
            List<String> objectAndFieldName = value.split('\\.');
            if (objectAndFieldName.size() == 2 && !addedValue.contains(value) && SUPPORTED_OBJECT_NAMES.contains(objectAndFieldName.get(0))) {
                filterFields.add(new VeevaGASFilterField(objectAndFieldName.get(0), objectAndFieldName.get(1)));
                addedValue.add(value);
            }
        }
        return filterFields;
    }

    private static List<String> removeBlankStrings(List<String> strings) {
        List<String> nonBlankStrings = new List<String>();
        for (String value : strings) {
            if (String.isNotBlank(value)) {
                nonBlankStrings.add(value);
            }
        }
        return nonBlankStrings;
    }

    private static List<String> getObjectFields(String objectFieldsString) {
        return trim(objectFieldsString.split(';'));
    }

    private static List<String> trim(List<String> strings) {
        List<String> trimmedStrings = new List<String>();
        for (String value : strings) {
            if (value != null) {
                trimmedStrings.add(value.trim());
            }
        }
        return trimmedStrings;
    }
}