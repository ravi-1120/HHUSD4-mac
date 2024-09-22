/*
    Copied from Call Report's AttendeeService
    TODO: to be refactored with the original AttendeeService when it is merged to DVP.
*/
public with sharing class S4LAttendeeService {

    public class S4LAttendeeWrapper implements Comparable {
        public S4LAttendeeWrapper(Account account) {
            this.data = account;
            this.type = 'Account_vod__c';
        }

        @AuraEnabled
        public SObject data {
            get; set;
        }

        @AuraEnabled
        public String type { get; set; }

        public String LastName {
            get {
                if (this.data.isSet('LastName')) {
                    return (String)this.data.get('LastName');
                } else {
                    return (String)this.data.get('Formatted_Name_vod__c');
                }
            }
        }

        public Integer compareTo(Object compareTo) {
            S4LAttendeeWrapper wrapped = (S4LAttendeeWrapper) compareTo;

            Integer returnValue = 0;

            if (this.LastName < wrapped.LastName) {
                return -1;
            } else if (this.LastName > wrapped.LastName) {
                return 1;
            } else {
                return 0;
            }
        }
    }

    static final Integer TABLE_MAX_ROWS = 50;

    @AuraEnabled
    public static Map<Id, Address_vod__c> getAddresses(List<String> accountIds, String territory) {
		List<String> fieldNames = new List<String>{'Id','Name','Account_vod__c', 'Address_Line_2_vod__c', 'Primary_vod__c', 'City_vod__c', 'State_vod__c', 'Zip_vod__c', 'Country_vod__c'};
        Map<Id, Address_vod__c> addressMap = VeevaAddress.getPrimaryAddresses(accountIds, territory, fieldNames, false);

        // exception for attendee-specific preferred addresses
        VeevaBaseObject address = VeevaBaseObject.create('Address_vod__c');
        Set<String> addressAccessibleFields = address.getAccessibleFields(new Set<String>(fieldNames), true, false);

        Set<String> tsfQueryFields = new Set<String>{'Id','Name','Territory_vod__c'};
        VeevaBaseObject tsf = VeevaBaseObject.create('TSF_vod__c');
        Set<String> tsfAccessibleFields = tsf.getAccessibleFields(tsfQueryFields, false, false);

        Set<Id> acctIds = addressMap.keySet();
        Map<Id, String> acctTerrMap = getAcctTerritories(acctIds);
        List<String> acctTerrs = acctTerrMap.values();

        String statement = 'SELECT ';
        if(addressAccessibleFields.size() > 0){
            statement += String.join(new List<String>(addressAccessibleFields), ',');
        }
        if(tsfAccessibleFields.size() > 0){
            if(addressAccessibleFields.size() > 0){
                statement += ', ';
            }
            statement += '(SELECT ' + String.join(new List<String>(tsfAccessibleFields), ',') + ' FROM TSF_vod__r WHERE Territory_vod__c IN :acctTerrs)';
        }
        statement += ' FROM Address_vod__c WHERE Account_vod__c IN :acctIds AND Inactive_vod__c = false ORDER BY Account_vod__c, LastModifiedDate DESC';

        List<Address_vod__c> addresses = Database.query(statement);
        List<Id> seen = new List<Id>();
        for (Address_vod__c addr : addresses) {
            Id accId = addr.Account_vod__c;
            if(addr.TSF_vod__r.size() > 0 && !seen.contains(accId)) {
                addressMap.put(accId, addr);
                seen.add(accId);
            }
        }
        return addressMap;
    }

    private static Map<Id, String> getAcctTerritories(Set<Id> accountIds) {
        List<ObjectTerritory2Association> result =
            [SELECT Id, Territory2.Name, ObjectId
                FROM ObjectTerritory2Association
                WHERE ObjectId IN :accountIds AND
                    Territory2Id IN (SELECT Territory2Id FROM UserTerritory2Association WHERE UserId = :UserInfo.getUserId())];
        
        Map<Id, String> acctTerrs = new Map<Id, String>();
        for (ObjectTerritory2Association acctTerr : result) {
            Id acctId = acctTerr.ObjectId;
            if (!acctTerrs.containsKey(acctId)) {
                acctTerrs.put(acctId, acctTerr.Territory2.Name);
            }
        }
        return acctTerrs;
    }

    @AuraEnabled
    public static List<S4LAttendeeWrapper> getSuggestedAttendees(String accountId, List<String> params, String skipAccountId, String atfTerritory) {
        List<S4LAttendeeWrapper> allSuggested = new List<S4LAttendeeWrapper>();
        List<S4LAttendeeWrapper> truncatedList = new List<S4LAttendeeWrapper>();
        try {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            String stmt;
            Set<String> accountFields = new Set<String>{ 'Formatted_Name_vod__c', 'Account_Identifier_vod__c', 'Primary_Parent_vod__c' };
            accountFields.addAll(params);
            Set<Id> accountSet = new Set<Id>();
            SObjectType affiliationObj = schemaMap.get('Affiliation_vod__c');
            List<String> accessibleFields = getAccessibleFields(schemaMap.get('Account'), accountFields);
            Boolean myTargetFieldAvailable = false;
            if (!String.isBlank(atfTerritory)) {
                VeevaBaseObject tsf = VeevaBaseObject.create('TSF_vod__c');
                String tsfAccessibleFields = tsf.getAccessibleField('My_Target_vod__c', false, false);
                myTargetFieldAvailable = tsfAccessibleFields != null;
            }
            if (affiliationObj.getDescribe().isAccessible()) {
                List<Affiliation_vod__c> affiliations = [
                    SELECT To_Account_vod__c
                    FROM Affiliation_vod__c
                    WHERE From_Account_vod__c = :accountId AND To_Account_vod__r.IsPersonAccount = true
                ];
                if (affiliations.size() > 0) {
                    List<Id> toAccounts = new List<Id>();
                    for (Affiliation_vod__c aff : affiliations) {
                        toAccounts.add(aff.To_Account_vod__c);
                    }
                    List<Account> affiliationAccounts = queryForAccounts(accessibleFields, true, toAccounts, null, skipAccountId, atfTerritory, myTargetFieldAvailable);
                    for (Account account : affiliationAccounts) {
                        accountSet.add(account.Id);
                        allSuggested.add(new S4LAttendeeWrapper(account));
                    }
                }
            }
            SObjectType childAccountObject = schemaMap.get('Child_Account_vod__c');
            if (childAccountObject.getDescribe().isAccessible()) {
                List<Account> memberOfAccounts = queryForAccounts(accessibleFields, false, null, accountId, skipAccountId, atfTerritory, myTargetFieldAvailable);
                for (Account account : memberOfAccounts) {
                    if (!accountSet.contains(account.Id)) {
                        allSuggested.add(new S4LAttendeeWrapper(account));
                    }
                }
            }
            /*if (String.isBlank(atfTerritory)) {
                SObjectType contactObject = schemaMap.get('Contact');
                if (contactObject.getDescribe().isAccessible()) {
                    stmt = 'SELECT Name, FirstName, LastName FROM Contact WHERE AccountId = :accountId ORDER BY LastName ASC LIMIT ' + TABLE_MAX_ROWS;
                    List<Contact> contacts = Database.query(stmt);
                    for (Contact contact : contacts) {
                        allSuggested.add(new S4LAttendeeWrapper(contact));
                    }
                }
            }*/
            allSuggested.sort();
            for(Integer i = 0; i < TABLE_MAX_ROWS && i < allSuggested.size(); i++){
                truncatedList.add(allSuggested[i]);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return truncatedList;
    }

    private static List<Account> queryForAccounts(List<String> accessibleFields, Boolean isAffiliations, List<Id> toAccounts, String accountId,
                                                    String skipAccountId, String atfTerritory, Boolean myTargetFieldAvailable) {
        String stmt = 'SELECT RecordType.DeveloperName, toLabel(RecordType.Name) toLabel_RecordType';
        if (accessibleFields.size() > 0) {
            stmt += ', ' + String.join(accessibleFields, ', ');
        }
        stmt += ' FROM Account WHERE Do_Not_Call_vod__c != \'Yes_vod\' AND Id IN ';
        if (isAffiliations) {
            stmt += ':toAccounts';
        } else {
            stmt += '(SELECT Child_Account_vod__c From Child_Account_vod__c WHERE Parent_Account_vod__c = :accountId) AND IsPersonAccount=true ';
        }
        if (!String.isBlank(skipAccountId)) {
            stmt += ' AND Id != :skipAccountId';
        }
        if (!String.isBlank(atfTerritory) && myTargetFieldAvailable) {
            stmt += ' AND Id IN (SELECT Account_vod__c FROM TSF_vod__c WHERE My_Target_vod__c = true AND Territory_vod__c = :atfTerritory)';
        }
        stmt += ' ORDER BY Formatted_Name_vod__c ASC LIMIT ' + TABLE_MAX_ROWS;
        return Database.query(stmt);
    }

    private static List<String> getAccessibleFields(Schema.SObjectType schemaObj, Set<String> fields) {
        Map<String, Schema.SObjectField> fieldMap = schemaObj.getDescribe().fields.getMap();
        List<String> accessibleFields = new List<String>();
        for (String field : fields) {
            SObjectField addField = fieldMap.get(field);
            List<String> fieldNameInfo = field.split('\\.');
            if (addField != null && addField.getDescribe().isAccessible()) {
                Schema.DescribeFieldResult fldDesc = addField.getDescribe();
                if (fldDesc.getType() == Schema.DisplayType.REFERENCE && !String.isEmpty(fldDesc.getRelationshipName())) {
                    String queryField = (fieldNameInfo.size() > 1)
                        ? (fldDesc.getRelationshipName() + '.' + fieldNameInfo[1])
                        : fldDesc.getRelationshipName() + '.Name';
                    accessibleFields.add(queryField);
                } else if (fldDesc.getType() == Schema.DisplayType.PICKLIST) {
                    accessibleFields.add('toLabel(' + field + ') toLabel_' + field);
                } else {
                    accessibleFields.add(field);
                }
            }
        }
        return accessibleFields;
    }

    @AuraEnabled
    public static List<S4LAttendeeWrapper> searchAccounts(String searchText, String skipAccountId) {
        List<S4LAttendeeWrapper> searchResults = new List<S4LAttendeeWrapper>();
        List<S4LAttendeeWrapper> truncatedList = new List<S4LAttendeeWrapper>();
        try {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Set<String> accountFields = new Set<String>{ 'Formatted_Name_vod__c', 'Account_Identifier_vod__c' };
            List<String> accessibleFields = getAccessibleFields(schemaMap.get('Account'), accountFields);
            List<String> searchTextInfo = searchText.split('\\s+');
            String toSearch = formatSearchString(searchTextInfo);
            String searchQuery =
                'FIND {' +
                toSearch +
                '} in Name fields RETURNING Account(Id,Name,IsPersonAccount,FirstName,LastName,RecordType.Name,toLabel(RecordType.Name) toLabel_RecordType,Do_Not_Call_vod__c, RecordType.DeveloperName';
            if (accessibleFields.size() > 0) {
                searchQuery += ', ' + String.join(accessibleFields, ', ');
            }
            searchQuery += ' WHERE IsPersonAccount=true';
            if (!String.isBlank(skipAccountId)) {
                searchQuery += ' AND Id != :skipAccountId';
            }
            searchQuery += ' LIMIT ' + TABLE_MAX_ROWS + ')';
            List<List<Object>> results = search.query(searchQuery);
            if (results.size() > 0) {
                for (Object accountResult : results.get(0)) {
                    searchResults.add(new S4LAttendeeWrapper((Account)accountResult));
                }
                /*for (Object contactResult : results.get(1)) {
                    searchResults.add(new S4LAttendeeWrapper((Contact)contactResult));
                }*/
                searchResults.sort();
                for(Integer i = 0; i < TABLE_MAX_ROWS && i < searchResults.size(); i++){
                    truncatedList.add(searchResults[i]);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return truncatedList;
    }

    private static String formatSearchString(List<String> searchTextInfo) {
        SOSLQueryHelper helper = new SOSLQueryHelper();
        String searchString = '';
        for (String searchWord : searchTextInfo) {
            if (searchString.length() > 0) {
                searchString += ' AND ';
            }
            searchString += helper.escapeSpecialCharacters(searchWord) + '*';
        }
        return searchString;
    }
}