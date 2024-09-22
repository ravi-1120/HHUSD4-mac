public inherited sharing class VeevaMyAccountsFieldDefnFactory {
    public static VeevaMyAccountsFieldDefn create(String objectAndFieldString, String source) {
        String trimmedObjectAndFieldString = objectAndFieldString?.trim();
        List<String> objectAndFieldParts = trimmedObjectAndFieldString?.split('\\.');
        String objectName = objectAndFieldParts?.get(0);

        if (Dynamic_Attribute_Configuration_vod__c.getSObjectType().getDescribe().getName().equalsIgnoreCase(objectName)) {
            return new VeevaMyAccountsDynamicAttributeDefn(trimmedObjectAndFieldString);
        } else if (Product_Metrics_vod__c.getSObjectType().getDescribe().getName().equalsIgnoreCase(objectName)) {
            return new VeevaMyAccountsProductMetricsDefn(trimmedObjectAndFieldString, source);
        } else if (Account.getSObjectType().getDescribe().getName().equalsIgnoreCase(objectName) && objectAndFieldParts?.size() == 2 && 'Name'.equalsIgnoreCase(objectAndFieldParts?.get(1))) {
            return new VeevaMyAccountsAccountNameField(trimmedObjectAndFieldString);
        } else if (isChildAccountFieldOrChildAccountRelation(source, objectAndFieldParts, objectName)) {
            return new VeevaMyAccountsChildAccountFieldDefn(trimmedObjectAndFieldString);
        } else {
            return new VeevaMyAccountsFieldDefn(trimmedObjectAndFieldString);
        }
    }

    private static Boolean isChildAccountFieldOrChildAccountRelation(String source, List<String> objectAndFieldParts, String objectName) {
        return 'LOCATION'.equalsIgnoreCase(source) && (objectAndFieldParts.size() == 1 || VeevaBaseObject.create(objectName) == null);
    }
}