public inherited sharing class VeevaMyAccountsDynamicAttributeDefn extends VeevaMyAccountsFieldDefn {
    private static Schema.DescribeSObjectResult DYNAMIC_ATTRIBUTE_CONFIGURATION_DESCRIBE = Dynamic_Attribute_Configuration_vod__c.getSObjectType().getDescribe();

    public static Map<String, String> DYNAMIC_ATTRIBUTE_RECORD_TYPE_TO_FIELD_TYPE_MAP = new Map<String, String>{
        'Text_vod' => Schema.DisplayType.STRING.name().toLowerCase(),
        'Text_Area_vod' => Schema.DisplayType.TEXTAREA.name().toLowerCase(),
        'Picklist_vod' => Schema.DisplayType.PICKLIST.name().toLowerCase(),
        'Checkbox_vod' => Schema.DisplayType.BOOLEAN.name().toLowerCase(),
        'Date_vod' => Schema.DisplayType.DATE.name().toLowerCase(),
        'Datetime_vod' => Schema.DisplayType.DATETIME.name().toLowerCase(),
        'Number_vod' => Schema.DisplayType.DOUBLE.name().toLowerCase(),
        'Multi_Select_Picklist_vod' => Schema.DisplayType.MULTIPICKLIST.name().toLowerCase()
    };

    public VeevaMyAccountsDynamicAttributeDefn(String objectAndFieldString) {
        super(objectAndFieldString);
    }

    public override Set<Id> getReferenceIds() {
        return new Set<Id>{this.name};
    }

    protected override String getLabel(Schema.SObjectField field) {
        return name;
    }

    protected override boolean hasError(VeevaBaseObject baseObject, Schema.SObjectField field, String objectName, String fieldName) {
        return !fieldName.startsWith(DYNAMIC_ATTRIBUTE_CONFIGURATION_DESCRIBE.getKeyPrefix());
    }

    /**
     * We will take a look at our look at our reference id and update our field type using the reference id's type
     */
    public override void updateFieldType(String recordType) {
        String fieldType = DYNAMIC_ATTRIBUTE_RECORD_TYPE_TO_FIELD_TYPE_MAP.get(recordType);
        if (fieldType != null) {
            this.fieldType = fieldType;
        }
    }

    /**
     * Updates Picklist Values based on Record Type
     */
    public override void setPicklistValues(String recordType, List<String> picklistValues) {
        if ('Multi_Select_Picklist_vod'.equalsIgnoreCase(recordType)) {
            this.picklistValues = picklistValues;
        }
    }
}