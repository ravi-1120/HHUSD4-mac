public inherited sharing class VeevaMyAccountsAccountNameField extends VeevaMyAccountsFieldDefn {
    public VeevaMyAccountsAccountNameField(String objectAndFieldString) {
        super(objectAndFieldString);
        this.name = getFieldName();
    }

    private String getFieldName() {
        VeevaBaseObject accountBaseObject = VeevaMyAccountsFieldDefn.BASE_OBJECT_MAP.get(Account.getSObjectType());
        boolean formatedNameFieldAccessible = accountBaseObject.getAccessibleField('Formatted_Name_vod__c', false, false) != null;
        String fieldName;
        if (formatedNameFieldAccessible) {
            fieldName = 'Formatted_Name_vod__c';
        } else {
            fieldName = 'Name';
        }
        return fieldName;
    }
}