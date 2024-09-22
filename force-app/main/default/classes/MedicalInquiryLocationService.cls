public without sharing class MedicalInquiryLocationService {

    private static String FURIGANA = 'Furigana_vod__c';

    private static Set<String> ACCOUNT_QUERY_FIELDS = new Set<String> {
        'Id', 'Name',  'Account_Identifier_vod__c', FURIGANA
    };

    private static Set<String> ADDRESS_QUERY_FIELDS = new Set<String> {
        'Id', 'Name', 'Address_Line_2_vod__c', 'City_vod__c', 'toLabel(State_vod__c)', 'Zip_vod__c', 'LastModifiedDate'
    };

    @AuraEnabled(cacheable=true)
    public static String getPrimaryParentId(String accountId) {
        List<Child_Account_vod__c> primaryParent = [SELECT Parent_Account_vod__c FROM Child_Account_vod__c WHERE Child_Account_vod__c =: accountId AND Primary_vod__c =: Label.Common_Yes_vod];
        return primaryParent.isEmpty() ? null : primaryParent[0].Parent_Account_vod__c;
    } 


    
    @AuraEnabled(cacheable=true)
    public static List<Account> getParentAccounts(String accountId) {
        List<String> parentAccountIds = getParentAccountIds(accountId);
        List<Account> parentAccounts = new List<Account>();

        if (parentAccountIds.size() > 0) {
            Schema.DescribeSObjectResult accountDescribe = Account.getSObjectType().getDescribe();
            List<String> userAccessibleAccountFields = new List<String>(getUserAccessiblQueryFields(accountDescribe, ACCOUNT_QUERY_FIELDS));

            Schema.DescribeSObjectResult addressDescribe = Address_vod__c.getSObjectType().getDescribe();
            List<String> userAccessibleAddressFields = new List<String>(getUserAccessiblQueryFields(addressDescribe, ADDRESS_QUERY_FIELDS));
            if (userAccessibleAddressFields.size() > 0) {
                userAccessibleAccountFields.add(String.format(
                    '(SELECT {0} FROM Address_vod__r ORDER BY Primary_vod__c DESC, LastModifiedDate DESC LIMIT 1)',
                    new List<Object>{ String.join(userAccessibleAddressFields, ', ') }
                ));
            }

            if (userAccessibleAccountFields.size() > 0) {
                parentAccounts = Database.query(
                String.format(
                    'SELECT {0} FROM Account WHERE Id IN :parentAccountIds ORDER BY {1} Name',
                    new List<Object> { String.join(userAccessibleAccountFields, ', '), userAccessibleAccountFields.contains(FURIGANA) ? 'Furigana_vod__c NULLS LAST, ' : '' }
                    ),
                    AccessLevel.USER_MODE
                );
            }
        }

        return parentAccounts;
    }

    private static List<String> getParentAccountIds(String accountId) {
        List<Child_Account_vod__c> relatedChildAccountRecords = [SELECT Parent_Account_vod__c FROM Child_Account_vod__c WHERE Child_Account_vod__c = :accountId];

        List<String> parentAccountIds = new List<String>();
        for (Child_Account_vod__c childRelationship : relatedChildAccountRecords) {
            parentAccountIds.add(childRelationship.Parent_Account_vod__c);
        }

        return parentAccountIds;
    }

    private static Set<String> getUserAccessiblQueryFields(Schema.DescribeSObjectResult describe, Set<String> fields) {
        Set<String> userAccessibleFields = new Set<String>();
        if (describe.isAccessible() && describe.isQueryable()) {
            Map<String, Schema.SObjectField> fieldDefinitions = describe.fields.getMap();
            for (String field : fields) {
                String strippedFieldName = field.startsWith('toLabel') ? field.substringBetween('(', ')') : field;
                Schema.SObjectField fieldDefinition = fieldDefinitions.get(strippedFieldName);
                if (fieldDefinition != null && fieldDefinition.getDescribe().isAccessible()) {
                    userAccessibleFields.add(field);
                }
            }
        }
        return userAccessibleFields;        
    }
}