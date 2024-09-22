public inherited sharing class VeevaGASSearchCondition {

    private static final Set<Schema.DisplayType> VALUE_AS_STRING_LITERAL = new Set<Schema.DisplayType>{
        Schema.DisplayType.ID,
        Schema.DisplayType.STRING,
        Schema.DisplayType.REFERENCE,
        Schema.DisplayType.PICKLIST,
        Schema.DisplayType.MULTIPICKLIST
    };

    private final Schema.SObjectType objectType;
    private final Schema.DescribeFieldResult field;
    private final VeevaGASSearchConditionOperator operator;
    private final String value;
    private final Boolean isImplicitFilter;

    public VeevaGASSearchCondition(Implicit_Filter_Condition_vod__c filterCondition, Implicit_Filter_vod__c filter) {
        this.objectType = getObjectType(filterCondition.Object_Name_vod__c);
        this.field = getSObjectField(filterCondition.Field_Name_vod__c, this.objectType);
        this.operator = getOperatorForField(this.field, filter.Inclusion_vod__c);
        this.value = filterCondition.Criteria_vod__c;
        this.isImplicitFilter = true;
    }

    public VeevaGASSearchCondition(String objectApiName, String fieldApiName, String selectedOption) {
        this.objectType = getObjectType(objectApiName);
        this.field = getSObjectField(fieldApiName, this.objectType);
        this.operator = getOperatorForField(this.field, true);
        this.value = selectedOption;
        this.isImplicitFilter = false;
    }

    public Schema.SObjectType getObject() {
        return objectType;
    }

    public String getObjectName() {
        return objectType.getDescribe().getName();
    }

    public Schema.DescribeFieldResult getField() {
        return field;
    }

    public String getFieldName() {
        return field.getName();
    }

    public VeevaGASSearchConditionOperator getOperator() {
        return operator;
    }

    public VeevaGASSearchExpressionKey getExpressionKey() {
        return new VeevaGASSearchExpressionKey(getObjectName(), getFieldName(), isImplicitFilter, operator);
    }

    public String getValue() {
        if (VALUE_AS_STRING_LITERAL.contains(field.getType())) {
            return '\'' + value + '\'';
        }
        return value;
    }

    private static Schema.SObjectType getObjectType(String objectName) {
        Type typeOfObject = Type.forName(objectName);
        Schema.SObjectType objectType = ((SObject) typeOfObject.newInstance()).getSObjectType();
        return objectType;
    }

    private static Schema.DescribeFieldResult getSObjectField(String fieldName, Schema.SObjectType objectType) {
        Schema.DescribeSObjectResult objectDescribeResult = objectType.getDescribe();
        return objectDescribeResult.fields.getMap().get(fieldName).getDescribe();
    }

    private static VeevaGASSearchConditionOperator getOperatorForField(Schema.DescribeFieldResult field, boolean inclusive) {
        if (Schema.DisplayType.MULTIPICKLIST == field.getType()) {
            return inclusive ? VeevaGASSearchConditionOperator.INCLUDES : VeevaGASSearchConditionOperator.EXCLUDES;
        } else {
            return inclusive ? VeevaGASSearchConditionOperator.EQUALS : VeevaGASSearchConditionOperator.NOT_EQUALS;
        }
    }
}