public inherited sharing virtual class VeevaMyAccountsFieldDefn {

    private static Map<String, Schema.SObjectType> objectTypeMap = new Map<String, Schema.SObjectType>{
        'account' => Account.getSObjectType(),
        'address_vod__c' => Address_vod__c.getSObjectType(),
        'tsf_vod__c' => TSF_vod__c.getSObjectType(),
        'product_metrics_vod__c' => Product_Metrics_vod__c.getSObjectType(),
        'dynamic_attribute_configuration_vod__c' => Dynamic_Attribute_Configuration_vod__c.getSObjectType()
    };

    public static final Map<Schema.SObjectType, VeevaBaseObject> BASE_OBJECT_MAP = new Map<Schema.SObjectType, VeevaBaseObject>{
        Account.getSObjectType() => VeevaBaseObject.create(Account.getSObjectType()),
        Address_vod__c.getSObjectType() => VeevaBaseObject.create(Address_vod__c.getSObjectType()),
        TSF_vod__c.getSObjectType() => VeevaBaseObject.create(TSF_vod__c.getSObjectType()),
        Product_Metrics_vod__c.getSObjectType() => VeevaBaseObject.create(Product_Metrics_vod__c.getSObjectType()),
        Dynamic_Attribute_Configuration_vod__c.getSObjectType() => VeevaBaseObject.create(Dynamic_Attribute_Configuration_vod__c.getSObjectType())
    };

    @AuraEnabled
    public String objectName { get; protected set; }

    @AuraEnabled
    public String name { get; protected set; }

    @AuraEnabled
    public String label { get; protected set; }

    @AuraEnabled
    public List<String> qualifiers { get; private set; }

    @AuraEnabled
    public boolean hasError { get; protected set; }

    @AuraEnabled
    public String fieldType { get; protected set; }

    @AuraEnabled
    public String referenceNameField { get; private set; }

    @AuraEnabled
    public String referenceToObject { get; private set; }

    @AuraEnabled
    public boolean isHtmlFormatted { get; private set; }

    @AuraEnabled
    public Integer scale { get; private set; }

    @AuraEnabled
    public List<String> picklistValues { get; protected set; }

    public Schema.SObjectType objectType { get; private set; }

    public VeevaMyAccountsFieldDefn(String objectAndFieldString) {
        List<String> parts = objectAndFieldString?.split('\\.');
        if (parts?.size() > 1) {
            this.objectName = getObjectName(parts);
            this.objectType = getSObjectType(this.objectName);
            this.name = getFieldName(parts);
            this.qualifiers = getQualifiers(parts);

            VeevaBaseObject baseObject = getVeevaBaseObject(this.objectType);
            Schema.SObjectField field = baseObject?.getField(this.name);

            this.fieldType = field?.getDescribe().getType().name().toLowerCase();
            this.isHtmlFormatted = field?.getDescribe().isHtmlFormatted();
            this.scale = field?.getDescribe().getScale();
            this.referenceNameField = field?.getDescribe().getType() == Schema.DisplayType.REFERENCE ? getReferenceNameField(field) : null;
            this.referenceToObject = field?.getDescribe().getType() == Schema.DisplayType.REFERENCE ? getReferenceToObject(field) : null;
            this.hasError = hasError(baseObject, field, this.objectName, this.name);
            this.label = getLabel(field);
        } else {
            this.hasError = true;
            this.objectName = objectAndFieldString;
            this.name = objectAndFieldString;
            this.objectType = null;
            this.label = objectAndFieldString;
        }
    }

    public virtual Set<Id> getReferenceIds() {
        return new Set<Id>();
    }

    public void updateLabel(Map<Id, String> referenceIdLabels) {
        Set<Id> referenceIds = getReferenceIds();
        for (Id referenceId : referenceIds) {
            String label = referenceIdLabels.get(referenceId);
            if (label != null) {
                this.label = this.label.replace(referenceId, label);
            }
        }
    }

    /**
     * Child classes can override this method to define how we should update using reference id's type
     *
     * VeevaMyAccountsFieldDefn does not determine field type using recordType
     */
    public virtual void updateFieldType(String recordType) {
        // does nothing in base class
    }

    protected virtual String getObjectName(List<String> objectAndFieldParts) {
        return objectAndFieldParts.get(0);
    }

    protected virtual String getFieldName(List<String> objectAndFieldParts) {
        return objectAndFieldParts.get(1);
    }

    /**
     * Updates Picklist Values based on Record Type
     *
     * VeevaMyAccountsFieldDefn does not update picklist values using recordType
     */
    public virtual void setPicklistValues(String recordType, List<String> picklistValues) {
        // does nothing in base class
    }

    protected virtual String getLabel(Schema.SObjectField field) {
        return hasError || field == null ?  objectName + '.' + name : field.getDescribe().getLabel();
    }

    protected virtual boolean hasError(VeevaBaseObject baseObject, Schema.SObjectField field, String objectName, String fieldName) {
        return baseObject == null || field == null || !field.getDescribe().isAccessible();
    }

    protected virtual List<String> getQualifiers(List<String> parts) {
        List<String> qualifiers = new List<String>();
        if (parts.size() > 2) {
            for (Integer i = 2; i < parts.size(); i++) {
                qualifiers.add(parts.get(i));
            }
        }
        return qualifiers;
    }

    private static String getReferenceNameField(Schema.SObjectField field) {
        return field.getDescribe().getRelationshipName() + '.Name';
    }

    private static String getReferenceToObject(Schema.SObjectField field) {
        // We will always use the first reference to object
        return field.getDescribe().getReferenceTo()?.get(0).getDescribe().getName();
    }

    private static VeevaBaseObject getVeevaBaseObject(Schema.SObjectType objectType) {
        if (objectType == null) {
            return null;
        }

        VeevaBaseObject baseObject = BASE_OBJECT_MAP.get(objectType);
        if (baseObject == null) {
            baseObject = VeevaBaseObject.create(objectType);
            BASE_OBJECT_MAP.put(objectType, baseObject);
        }
        return baseObject;
    }

    private static Schema.SObjectType getSObjectType(String objectName) {
        if (objectName == null) {
            return null;
        }

        Schema.SObjectType objectType = objectTypeMap.get(objectName.toLowerCase());
        if (objectType == null) {
            Type typeOfObject = Type.forName(objectName);
            if (typeOfObject != null) {
                objectType = ((SObject) typeOfObject.newInstance()).getSObjectType();
            }
        }
        return objectType;
    }
}