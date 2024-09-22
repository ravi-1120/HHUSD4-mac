public with sharing class VeevaGASFilterField {
    @AuraEnabled
    public String objectApiName { get; private set; }
    @AuraEnabled
    public String fieldApiName { get; private set; }
    public Schema.SObjectType sObjectType { get; private set; }
    public Schema.SObjectField field { get; private set; }

    public VeevaGASFilterField(String objectApiName, String fieldApiName) {
        this.objectApiName = objectApiName;
        this.fieldApiName = fieldApiName;
        this.sObjectType = getSObjectType(objectApiName);
        this.field = getSObjectField(fieldApiName, this.sObjectType);
    }

    private static Schema.SObjectType getSObjectType(String objectName) {
        Type typeOfObject = Type.forName(objectName);
        Schema.SObjectType objectType = null;
        if (typeOfObject != null) {
            objectType = ((SObject) typeOfObject.newInstance()).getSObjectType();
        }
        return objectType;
    }

    private static Schema.SObjectField getSObjectField(String fieldName, Schema.SObjectType objectType) {
        Schema.SObjectField field = null;
        if (objectType != null && String.isNotBlank(fieldName)) {
            Map<String, Schema.SObjectField> fields = objectType.getDescribe().fields.getMap();
            field = fields.get(fieldName);
        }
        return field;
    }
}