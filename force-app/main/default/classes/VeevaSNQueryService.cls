public without sharing class VeevaSNQueryService {
    public static List<Child_Account_vod__c> getParentChildRelationshipsFromChild(List<Id> ids) {
        return [
            SELECT Parent_Account_vod__c, Child_Account_vod__c, Primary_vod__c, Parent_Account_vod__r.Formatted_Name_vod__c, 
                Child_Account_vod__r.Primary_Parent_vod__c, Child_Account_vod__r.RecordType.IsPersonType
            FROM Child_Account_vod__c 
            WHERE Child_Account_vod__c in :ids
        ];
    }

    public static Map<Id, Account> getAccounts(Set<Id> ids){
        return new Map<Id, Account>([
            SELECT Id, Formatted_Name_vod__c, RecordType.DeveloperName, RecordType.IsPersonType,
                toLabel(RecordType.Name), Specialty_1_vod__c, Group_Specialty_1_vod__c, Specialty_2_vod__c,
                Group_Specialty_2_vod__c, Account_Identifier_vod__c, PersonEmail, Phone, Primary_Parent_vod__c
            FROM Account
            WHERE Id IN :ids
        ]);
    }

    public static List<Affiliation_vod__c> getAffiliations(Set<Id> ids){
        return [
            SELECT From_Account_vod__c, To_Account_vod__c, Influence_vod__c, Relationship_Strength_vod__c, 
                   Role_vod__c, Therapeutic_Area_vod__c, Comments_vod__c
            FROM Affiliation_vod__c 
            WHERE From_Account_vod__c IN :ids
        ];
    }

    public static ID getAccountIdOfAccountPlan(Id rootId) {
        List<Account_Plan_vod__c> accountPlan = [
            SELECT Account_vod__c
            FROM Account_Plan_vod__c
            WHERE Id = :rootId
            LIMIT 1
        ];
        Id accountPlanId;
        if (accountPlan.size() > 0) {
            accountPlanId = accountPlan[0].Account_vod__c;
        }
        return accountPlanId;
    }

    public static ID getParentId(Id rootId) {
        List<Child_Account_vod__c> childAccounts = [
            SELECT Parent_Account_vod__c
            FROM Child_Account_vod__c
            WHERE Child_Account_vod__c = :rootId
            LIMIT 1
        ];
        if (childAccounts.size() > 0) {
            return childAccounts[0].Parent_Account_vod__c;
        }
        return null;
    }

    public static List<Id> getKeyStakeholders(Id accountPlanId) {
        List<Id> keyStakeholders = new List<Id>();
        for (Key_Stakeholder_vod__c s: [
            SELECT Key_Stakeholder_vod__c
            FROM Key_Stakeholder_vod__c
            WHERE Account_Plan_vod__c = :accountPlanId
        ]) {
            keyStakeholders.add(s.Key_Stakeholder_vod__c);
        }

        return keyStakeholders;
    }

    public static Map<String, String> getStakeholderNavigatorVeevaMessages() {
        String userLang = UserInfo.getLanguage();
        Map<String, String> veevaMessages = new Map<String, String>();

        veevaMessages = getVeevaMessagesByCategory('STAKEHOLDER_NAVIGATOR');
        veevaMessages.putAll(getVeevaMessages('COMMON', new List<String>{'ALL', 'RECORD_TYPE_LABEL', 'OK', 'CANCEL', 'YES', 'NO', 'EDIT', 'DELETE', 'SAVE', 'NONE', 'VIEW', 'CLOSE', 'SEARCH', 'NONE_NO_DASH', 'BACK'}));
        veevaMessages.putAll(getVeevaMessages('Global Account Search', 
            new List<String>{'GAS_SELECT_TERRITORIES', 'GAS_ASSIGNMENT_SUCCESSFUL', 'GAS_ASSIGNMENT_ERROR', 'GAS_ADD_TO_TERRITORY', 'GAS_NO_TERRITORY_ALIGNED_ERROR'}));
        veevaMessages.putAll(getVeevaMessages('NETWORK', new List<String>{'CONFIRM_ADD_ACCOUNT'}));
        veevaMessages.putAll(getVeevaMessages('TABLET', new List<String>{'FILTER'}));
        veevaMessages.putAll(getVeevaMessages('MobileCRMApp', new List<String>{'SETTINGS'}));
        veevaMessages.putAll(getVeevaMessages('SphereOfInfluence', new List<String>{'ACCT_TYPE_LABEL', 'NO_SEARCH_RESULTS'}));
 
        return veevaMessages;
    }

    public static Map<String, String> getVeevaMessagesByCategory(String category) {
        String userLang = UserInfo.getLanguage();
        Map<String, String> veevaMessages = new Map<String, String>();
        for (Message_vod__c message : [
            SELECT Name, Text_vod__c
            FROM Message_vod__c
            WHERE Active_vod__c = true 
                AND Language_vod__c = :userLang
                AND Category_vod__c = :category
        ]) {
            veevaMessages.put(message.Name, message.Text_vod__c);
        }

        return veevaMessages;
    }

    public static Map<String, String> getVeevaMessages(String category, List<String> messageNames) {
        String userLang = UserInfo.getLanguage();
        Map<String, String> veevaMessages = new Map<String, String>();
        for (Message_vod__c message : [
            SELECT Name, Text_vod__c
            FROM Message_vod__c
            WHERE Active_vod__c = true 
                AND Language_vod__c = :userLang
                AND Category_vod__c = :category
                AND Name in :messageNames
        ]) {
            veevaMessages.put(message.Name, message.Text_vod__c);
        }

        return veevaMessages;
    }

    public static Boolean hasAccountAccess(Id id) {
        List<Account> acc = [SELECT Id, Formatted_Name_vod__c FROM Account WHERE Id = :id];
        return acc.size() == 1;
    }

    public static String getSNVeevaMessageWithDefault(String messageName, String defaultString) {
        String userLang = UserInfo.getLanguage();
        String veevaMessage = defaultString;

        for (Message_vod__c message: [
            SELECT Text_vod__c
            FROM Message_vod__c
            WHERE Category_vod__c = 'STAKEHOLDER_NAVIGATOR' AND 
                  Language_vod__c = :userLang AND
                  Name = :messageName AND
                  Active_vod__c = true
            LIMIT 1
        ]) {
            veevaMessage = message.Text_vod__c;
        }

        return veevaMessage;
    }

    public static Map<Id, Set<String>> getAccountToTerritoryMap(Set<Id> accountIds) {
        Map<Id, Set<Id>> acctToTerrMap = new Map<Id, Set<Id>>();
        Set<Id> allTerritoryIds = new Set<Id>();
        for (ObjectTerritory2Association t : [
            SELECT Id, ObjectId, Territory2Id
            FROM ObjectTerritory2Association
            WHERE ObjectId in :accountIds
        ]) {
            allTerritoryIds.add(t.Territory2Id);
            Set<Id> terrForAcct = acctToTerrMap.get(t.ObjectId);
            if (terrForAcct == null) {
                acctToTerrMap.put(t.ObjectId, new Set<Id>{t.Territory2Id});
            } else {
                terrForAcct.add(t.Territory2Id);
            }
        }
        TerritoryManagement2 tm = new TerritoryManagement2();
        Map<Id, Map<String, String>> territories = tm.getTerritories(allTerritoryIds);
        Map<Id, Set<String>> acctToTerrNameMap = new Map<Id, Set<String>>();
        for (Id accountId : acctToTerrMap.keySet()) {
            Set<String> terrNames = new Set<String>();
            for (Id terrId : acctToTerrMap.get(accountId)) {
                Map<String, String> terrValues = territories.get(terrId);
                if (terrValues != null) {
                    terrNames.add(terrValues.get('Name'));
                }
            }
            if (terrNames != null) {
                acctToTerrNameMap.put(accountId, terrNames);
            }
        }

        return acctToTerrNameMap;
    }

    public static Map<Id, VeevaSNAccount> queryAccountObjects(Set<Id> accountIdsToQuery, List<String> requestedAccountFields) {

        // first we need to create our query string
        VeevaBaseObject accountBaseObject = VeevaBaseObject.create('Account');
        List<String> requestedAccountFieldsWithFormats = new List<String>(accountBaseObject.getAccessibleFields(new Set<String>(requestedAccountFields), true, true));

        String fieldsToQuery = 'Id,RecordType.DeveloperName,RecordType.IsPersonType,toLabel(RecordType.Name)'; // required
        if (requestedAccountFieldsWithFormats.size() > 0) {
            fieldsToQuery += ',';
            fieldsToQuery += String.join(requestedAccountFieldsWithFormats, ',');
        }

        String queryString = String.format('Select {0} From Account Where Id in :accountIdsToQuery', new List<Object>{
            fieldsToQuery, '\'' + String.join(new List<Id>(accountIdsToQuery), '\',\'') + '\''
        });

        // now let's query and convert our results into our expected format
        Map<Id, VeevaSNAccount> snAccounts = new Map<Id, VeevaSNAccount>();
        for (Account account : Database.query(queryString)) {

            VeevaSNAccount snAccount = new VeevaSNAccount();
            snAccount.id = account.Id;
            snAccount.recordType = account.RecordType;
            snAccount.fields = extractFormattedFieldsFromQueryResult(account, 'Account', requestedAccountFields);
            snAccounts.put(account.Id, snAccount);
        }

        return snAccounts;
    }

    public static Map<String, Map<String, Object>> extractFormattedFieldsFromQueryResult(SObject queryResult, String objectName, List<String> requestedFields) {

        if (queryResult == null) {
            return new Map<String, Map<String, Object>>();
        }

        VeevaBaseObject baseObject = VeevaBaseObject.create(objectName);
        List<String> accessibleRequestedFields = new List<String>(baseObject.getAccessibleFields(new Set<String>(requestedFields), false, false));

        List<Schema.DescribeFieldResult> requestedFieldDescribes = new List<Schema.DescribeFieldResult>();
        for (String accessibleRequestedField : accessibleRequestedFields) {
            requestedFieldDescribes.add(baseObject.getFieldDescribe(accessibleRequestedField));
        }

        Set<String> percentFields = findPercentFormattingFields(requestedFieldDescribes);
        Set<String> localeFormattedFields = findLocaleFormattingFields(requestedFieldDescribes);
        Map<String, String> referenceToRelationshipMap = findReferenceFormattingFields(requestedFieldDescribes);        

        Map<String, Map<String, Object>> res = new Map<String, Map<String, Object>>();
        for (String requestedField : accessibleRequestedFields) {
            Object value = null;
            Object displayValue = null;

            if (localeFormattedFields.contains(requestedField) && percentFields.contains(requestedField)) {
                value = queryResult.get(requestedField);
                displayValue = queryResult.get('toFormat_' + requestedField.replace('.','_')) + '%';
            } else if (localeFormattedFields.contains(requestedField)) {
                value = queryResult.get(requestedField);
                displayValue = queryResult.get('toFormat_' + requestedField.replace('.','_'));
            } else if (referenceToRelationshipMap.containsKey(requestedField)) {
                value = queryResult.get(requestedField);
                SObject lookup = queryResult.getsObject(referenceToRelationshipMap.get(requestedField));
                if (lookup != null) {
                    displayValue = lookup.get('Name');
                }
            } else {
                value = queryResult.get(requestedField);
            }
            
            Map<String, Object> fieldResult = new Map<String, Object>();
            fieldResult.put('value', value);
            fieldResult.put('displayValue', displayValue);
            res.put(requestedField, fieldResult);
        }
        return res;
    }

    private static Set<String> findPercentFormattingFields(List<Schema.DescribeFieldResult> requestFieldDescribes) {
        Set<String> percentFormattedFields = new Set<String>();
        for (Schema.DescribeFieldResult requestFieldDescribe : requestFieldDescribes) {
            if (requestFieldDescribe.getType() == Schema.DisplayType.PERCENT) {
                percentFormattedFields.add(requestFieldDescribe.getName());
            }
        }
        return percentFormattedFields;
    }

    private static Set<String> findLocaleFormattingFields(List<Schema.DescribeFieldResult> requestFieldDescribes) {
        Set<String> localeFormattedFields = new Set<String>();
        for (Schema.DescribeFieldResult requestFieldDescribe : requestFieldDescribes) {
            if (
                requestFieldDescribe.getType() == Schema.DisplayType.DATE ||
                requestFieldDescribe.getType() == Schema.DisplayType.DATETIME ||
                isNumericalField(requestFieldDescribe.getType())
            ) {
                localeFormattedFields.add(requestFieldDescribe.getName());
            }
        }
        return localeFormattedFields;
    }

    private static boolean isNumericalField(DisplayType fieldType) {
        return (fieldType == DisplayType.DOUBLE) || (fieldType == DisplayType.INTEGER)
            || (fieldType == DisplayType.LONG) || (fieldType == DisplayType.PERCENT);
    }

    private static Map<String, String> findReferenceFormattingFields(List<Schema.DescribeFieldResult> requestFieldDescribes) {
        Map<String, String> referenceToRelationshipMap = new Map<String, String>();
        for (Schema.DescribeFieldResult requestFieldDescribe : requestFieldDescribes) {
            if (requestFieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                referenceToRelationshipMap.put(requestFieldDescribe.getName(), requestFieldDescribe.getRelationshipName());
            }
        }
        return referenceToRelationshipMap;
    }
}