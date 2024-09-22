public inherited sharing class VeevaMyAccountsChildAccountFieldDefn extends VeevaMyAccountsFieldDefn {
    private static final Set<String> VALID_ACCOUNT_RELATIONSHIP_FIELDS = new Set<String>{ 
        'Child_Account_vod__r',
        'Parent_Account_vod__r'
    };

    @AuraEnabled
    public String accountRelationship { get; private set; }

    public VeevaMyAccountsChildAccountFieldDefn(String fieldString) {
        super('Child_Account_vod__c.' + fieldString);
        List<String> parts = fieldString.split('\\.');
        parts.add(0, 'Child_Account_vod__c');
        this.accountRelationship = getAccountRelationship(parts);
    }

    protected override List<String> getQualifiers(List<String> objectAndFieldParts) {
        return new List<String>();
    }

    protected override String getFieldName(List<String> objectAndFieldParts) {
        String objectName = getObjectName(objectAndFieldParts);
        if ('Child_Account_vod__c'.equalsIgnoreCase(objectName) && objectAndFieldParts.size() > 1) {
            return objectAndFieldParts.get(1);
        } else if ('Account'.equalsIgnoreCase(objectName) && objectAndFieldParts.size() > 2) {
            if ('Name'.equalsIgnoreCase(objectAndFieldParts.get(2))) {
                return new VeevaMyAccountsAccountNameField(String.join(objectAndFieldParts, '.')).name;
            }
            return objectAndFieldParts.get(2);
        } else if ('Address_vod__c'.equalsIgnoreCase(objectName) && objectAndFieldParts.size() > 3) {
            return objectAndFieldParts.get(3);
        }

        return null;
    }

    protected override String getLabel(Schema.SObjectField field) {
        if ('Account'.equalsIgnoreCase(this.objectName) && 'Formatted_Name_vod__c'.equalsIgnoreCase(field?.getDescribe().getName())) {
            return Account.Name.getDescribe().getLabel();
        }
        return super.getLabel(field);
    }

    protected override String getObjectName(List<String> objectAndFieldParts) {
        if (objectAndFieldParts.size() == 2) {
            return 'Child_Account_vod__c';
        }

        // We currently only support Account as a relationship field from a child account
        String accountRelationshipField = getAccountRelationship(objectAndFieldParts);
        boolean isAddressField = isAddressField(objectAndFieldParts);
        String objectName = isAddressField ? 'Address_vod__c' : 'Account';
        return accountRelationshipField != null ? objectName : null;
    }

    private boolean isAddressField(List<String> objectAndFieldParts) {
        return objectAndFieldParts.size() > 2 && 'Address_vod__r'.equalsIgnoreCase(objectAndFieldParts.get(2));
    }

    private String getAccountRelationship(List<String> objectAndFieldNameParts) {
        String accountRelationship = objectAndFieldNameParts.get(1);
        return VALID_ACCOUNT_RELATIONSHIP_FIELDS.contains(accountRelationship) ? accountRelationship : null;
    }
}