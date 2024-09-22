public inherited sharing class VeevaSNCustomDisplayService {

    private static Set<String> ALLOWED_CUSTOM_DISPLAY_OBJECTS = new Set<String>{'Account', 'Address_vod__c'};
    private static Set<Schema.DisplayType> ALLOWED_CUSTOM_DISPLAY_FIELD_TYPES = new Set<Schema.DisplayType>{
        Schema.DisplayType.STRING, Schema.DisplayType.BOOLEAN, Schema.DisplayType.DATE, 
        Schema.DisplayType.DATETIME, Schema.DisplayType.DOUBLE, Schema.DisplayType.INTEGER, Schema.DisplayType.LONG, 
        Schema.DisplayType.PICKLIST, Schema.DisplayType.MULTIPICKLIST, Schema.DisplayType.REFERENCE, 
        Schema.DisplayType.PERCENT, Schema.DisplayType.PHONE, Schema.DisplayType.EMAIL, Schema.DisplayType.URL
    };
    private static Set<Schema.DisplayType> ALLOWED_CUSTOM_IDENTIFIER_FIELD_TYPES = new Set<Schema.DisplayType>{
        Schema.DisplayType.STRING, Schema.DisplayType.DOUBLE, Schema.DisplayType.INTEGER, Schema.DisplayType.LONG, 
        Schema.DisplayType.PICKLIST, Schema.DisplayType.PHONE, Schema.DisplayType.EMAIL
    };
    private static Set<Schema.DisplayType> ALLOWED_ADDITIONAL_AFFILIATION_FIELD_TYPES = new Set<Schema.DisplayType>{
        Schema.DisplayType.PICKLIST,  Schema.DisplayType.MULTIPICKLIST
    };
    private static Set<String> CUSTOM_DISPLAY_FIELDS_TO_SKIP = new Set<String>{
        'Account.RecordTypeId'
    };  
    private static String DEFAULT_DISPLAY_FIELDS_MESSAGE = 'PersonAccount;Account.PersonEmail;Account.Phone;Account.Specialty_1_vod__c;Account.Specialty_2_vod__c;Account.Group_Specialty_1_vod__c;Account.Group_Specialty_2_vod__c;;BusinessAccount;Account.Phone;Account.Specialty_1_vod__c;Account.Specialty_2_vod__c;Account.Group_Specialty_1_vod__c;Account.Group_Specialty_2_vod__c;';
    private static String DEFAULT_PERSON_ACCOUNT_DISPLAY_FIELDS = 'Account.PersonEmail;Account.Phone;Account.Specialty_1_vod__c;Account.Specialty_2_vod__c;Account.Group_Specialty_1_vod__c;Account.Group_Specialty_2_vod__c';
    private static String DEFAULT_BUSINESS_ACCOUNT_DISPLAY_FIELDS = 'Account.Phone;Account.Specialty_1_vod__c;Account.Specialty_2_vod__c;Account.Group_Specialty_1_vod__c;Account.Group_Specialty_2_vod__c';
    private static String DEFAULT_IDENTIFIERS_SETTING = VeevaMedicalIdentifierHandler.getIdentifierString();
    private static Integer MAX_DISPLAY_FIELD_COUNT = 10;

    public static VeevaSNCustomDisplayOverrides getDisplayFieldOverrides() {

        VeevaSNCustomDisplayOverrides response = new VeevaSNCustomDisplayOverrides();

        // base objects to validate fields with
        Map<String, VeevaBaseObject> objectToBaseObject = new Map<String, VeevaBaseObject>();
        objectToBaseObject.put('Account', VeevaBaseObject.create('Account'));
        objectToBaseObject.put('Address_vod__c', VeevaBaseObject.create('Address_vod__c'));
        objectToBaseObject.put('Affiliation_vod__c', VeevaBaseObject.create('Affiliation_vod__c'));

        // first we get the person/business account display fields
        Map<String, List<String>> fieldOverrides = retrieveAccountDisplayFieldsOrDefault(objectToBaseObject);
        response.personAccountDisplayFields = fieldOverrides.get('person');
        response.businessAccountDisplayFields = fieldOverrides.get('business');

        // then we get the account identifiers
        Map<String, String> identifierOverrides = retrieveAccountIdentifiersOrDefault(objectToBaseObject);
        response.accountIdentifiers = identifierOverrides;

        // lastly we get the zvod affiliation fields
        List<String> customAffiliationPicklistFields = retrieveCustomAffiliationPicklistFields(objectToBaseObject);
        response.customAffiliationPicklistFields = customAffiliationPicklistFields;

        return response;
    }

    private static Map<String, List<String>> retrieveAccountDisplayFieldsOrDefault(Map<String, VeevaBaseObject> objectToBaseObject) {

        Object value = Veeva_Settings_vod__c.getInstance()?.get('SN_ACCOUNT_FIELDS_OVERRIDE_vod__c');
        String settingValue = value != null ? String.valueOf(value) : null;
        if (settingValue == null) {
            return parseAccountDisplayFields(DEFAULT_DISPLAY_FIELDS_MESSAGE, objectToBaseObject);
        }

        String[] settingKeyAndCategory = settingValue.split(';;');
        if (settingKeyAndCategory.size() != 2) {
            return parseAccountDisplayFields(DEFAULT_DISPLAY_FIELDS_MESSAGE, objectToBaseObject);
        }

        String fieldOverrideMessage = VeevaMessageController.getMsgWithDefault(settingKeyAndCategory[0], settingKeyAndCategory[1], null);
        if (fieldOverrideMessage == null || String.isEmpty(fieldOverrideMessage)) {
            return parseAccountDisplayFields(DEFAULT_DISPLAY_FIELDS_MESSAGE, objectToBaseObject);
        }

        return parseAccountDisplayFields(fieldOverrideMessage, objectToBaseObject);
    }

    @TestVisible 
    private static Map<String, List<String>> parseAccountDisplayFields(String messageValue, Map<String, VeevaBaseObject> objectToBaseObject) {

        Map<String, List<String>> res = new Map<String, List<String>>();
        String personAccountDisplayString = null;
        String businessAccountDisplayString = null;

        for (String messageSplitBySection : messageValue.split(';;')) {
            String[] sectionList = messageSplitBySection.split(';');
            if (sectionList.size() == 0) {
                continue;
            } else if (sectionList[0] == 'PersonAccount') {
                personAccountDisplayString = messageSplitBySection;
            } else if (sectionList[0] == 'BusinessAccount') {
                businessAccountDisplayString = messageSplitBySection;
            }
        }

        if (personAccountDisplayString == null) {
            List<String> personAccountFields = filterFieldDisplayList(DEFAULT_PERSON_ACCOUNT_DISPLAY_FIELDS, objectToBaseObject); 
            res.put('person', personAccountFields);
        } else {
            List<String> personAccountFields = filterFieldDisplayList(personAccountDisplayString, objectToBaseObject);  
            res.put('person', personAccountFields);
        }

        if (businessAccountDisplayString == null) {
            List<String> businessAccountFields = filterFieldDisplayList(DEFAULT_BUSINESS_ACCOUNT_DISPLAY_FIELDS, objectToBaseObject); 
            res.put('business', businessAccountFields);
        } else {
            List<String> businessAccountFields = filterFieldDisplayList(businessAccountDisplayString, objectToBaseObject);
            res.put('business', businessAccountFields);
        }

        return res;
    }

    private static List<String> filterFieldDisplayList(String accountDisplayString,  Map<String, VeevaBaseObject> objectToBaseObject) {

        List<String> res = new List<String>();

        for (String accountDisplayField : accountDisplayString.split(';')) {
            if (CUSTOM_DISPLAY_FIELDS_TO_SKIP.contains(accountDisplayField)) {
                continue;
            }

            List<String> accountFieldSplit = accountDisplayField.split('\\.');
            if (accountFieldSplit.size() != 2) {
                continue;
            }
            String objectName = accountFieldSplit[0];
            String fieldName = accountFieldSplit[1];

            if (!ALLOWED_CUSTOM_DISPLAY_OBJECTS.contains(objectName)) {
                continue;
            }

            if (objectToBaseObject.get(objectName).getAccessibleField(fieldName, false, false) == null) {
                continue;
            }

            Schema.DisplayType fieldDataType = objectToBaseObject.get(objectName).getFieldDescribe(fieldName).getType();
            if (!ALLOWED_CUSTOM_DISPLAY_FIELD_TYPES.contains(fieldDataType)) {
                continue;
            }

            res.add(accountDisplayField);
            if (res.size() == MAX_DISPLAY_FIELD_COUNT) {
                break;
            }
        }

        return res;
    }

    private static Map<String, String> retrieveAccountIdentifiersOrDefault(Map<String, VeevaBaseObject> objectToBaseObject) {

        Object value = Veeva_Settings_vod__c.getInstance()?.get('SN_ACCOUNT_IDENTIFIER_OVERRIDE_vod__c');
        String settingValue = value != null ? String.valueOf(value) : null;
        if (settingValue == null || String.isEmpty(settingValue)) {
            return parseAccountIdentifiers(DEFAULT_IDENTIFIERS_SETTING, objectToBaseObject);
        }

        return parseAccountIdentifiers(settingValue, objectToBaseObject);
    }

    @TestVisible 
    private static Map<String, String> parseAccountIdentifiers(String settingValue, Map<String, VeevaBaseObject> objectToBaseObject) {
        List<String> unfilteredIdentifiers = settingValue.split(';');
        List<String> filteredIdentifiers = new List<String>();

        for (String unfilteredIdentifier : unfilteredIdentifiers) {
            if (objectToBaseObject.get('Account').getAccessibleField(unfilteredIdentifier, false, false) == null) {
                continue;
            }

            Schema.DisplayType fieldDataType = objectToBaseObject.get('Account').getFieldDescribe(unfilteredIdentifier).getType();
            if (!ALLOWED_CUSTOM_IDENTIFIER_FIELD_TYPES.contains(fieldDataType)) {
                continue;
            }

            filteredIdentifiers.add(unfilteredIdentifier);
            if (filteredIdentifiers.size() == 2) {
                break;
            }
        }

        Map<String, String> identifiers = new Map<String, String>();
        if (filteredIdentifiers.size() == 0) {
            identifiers.put('secondary', null);
            identifiers.put('tertiary', null);
        } else if (filteredIdentifiers.size() == 1) {
            identifiers.put('secondary', filteredIdentifiers.get(0));
            identifiers.put('tertiary', null);
        } else if (filteredIdentifiers.size() == 2) {
            identifiers.put('secondary', filteredIdentifiers.get(0));
            identifiers.put('tertiary', filteredIdentifiers.get(1));
        }

        return identifiers;
    }

    @TestVisible
    private static List<String> retrieveCustomAffiliationPicklistFields(Map<String, VeevaBaseObject> objectToBaseObject) {

        if (objectToBaseObject.get('Affiliation_vod__c') == null) {
            return new List<String>();
        }

        Object value = Veeva_Settings_vod__c.getInstance()?.get('ENABLE_CUSTOM_RELATIONSHIP_FIELDS_vod__c');
        Integer settingValue = value != null ? Integer.valueOf(value) : null;

        if (settingValue == null || settingValue == 0) {
            return new List<String>();
        }

        // find the default record type, otherwise defer to the first in the list
        List<Schema.RecordTypeInfo> recordTypes = objectToBaseObject.get('Affiliation_vod__c').getDescribe().getRecordTypeInfos();
        List<Schema.RecordTypeInfo> availableRecordTypes = new List<Schema.RecordTypeInfo>();
        Id defaultRecordTypeId = null;

        for (Schema.RecordTypeInfo recordType : recordTypes) {
            if (recordType.isActive() && recordType.isAvailable()) {
                availableRecordTypes.add(recordType);
            }
        }

        for (Schema.RecordTypeInfo availableRecordType : availableRecordTypes) {
            if (availableRecordType.isDefaultRecordTypeMapping()) {
                defaultRecordTypeId = availableRecordType.getRecordTypeId();
                break;
            }
        }

        if (defaultRecordTypeId == null) {
            if (availableRecordTypes.isEmpty()) {
                return new List<String>();
            } else {
                defaultRecordTypeId = availableRecordTypes.get(0).getRecordTypeId();
            }
        }

        List<String> unfilteredFieldsOnLayout = VeevaLayoutService.retrieveFieldsFromLayout('Affiliation_vod__c', defaultRecordTypeId, 'View');
        return parseFieldsFoundOnAffiliationLayout(unfilteredFieldsOnLayout, objectToBaseObject.get('Affiliation_vod__c'));
    }

    @TestVisible
    private static List<String> parseFieldsFoundOnAffiliationLayout(List<String> unfilteredFieldsOnLayout, VeevaBaseObject affiliationBaseObject) {
        List<String> fiteredFieldsOnLayout = new List<String>();

        for (String unfilteredFieldOnLayout : unfilteredFieldsOnLayout) {
            if (!unfilteredFieldOnLayout.startsWith('zvod_')) {
                continue;
            }

            if (affiliationBaseObject.getAccessibleField(unfilteredFieldOnLayout, false, false) == null) {
                continue;
            }

            Schema.DisplayType fieldDataType = affiliationBaseObject.getFieldDescribe(unfilteredFieldOnLayout).getType();
            if (!ALLOWED_ADDITIONAL_AFFILIATION_FIELD_TYPES.contains(fieldDataType)) {
                continue;
            } 

            fiteredFieldsOnLayout.add(unfilteredFieldOnLayout);
        }

        return fiteredFieldsOnLayout;
    } 
}