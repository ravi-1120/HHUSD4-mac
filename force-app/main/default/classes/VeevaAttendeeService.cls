global inherited sharing class VeevaAttendeeService {

    private final String PREFIX_AND = ' AND ';
    private final String BASE_QUERY = 'SELECT Parent_Child_Name_vod__c, Parent_Account_vod__c, Child_Account_vod__c, Child_Account_vod__r.Name, Child_Account_vod__r.Formatted_Name_vod__c, Id';

    public List<SearchResult> searchChildAccounts(boolean isCJK, String name, String configuredField, String city, String state, string zip, string configuredFieldName, string searchOutsideTerrRecordTypes, string searchOutsideTerrCountries) {
        List<Child_Account_vod__c> childAccountQueryResults = queryChildAccounts(isCJK, name, configuredField, city, state, zip, configuredFieldName, searchOutsideTerrRecordTypes, searchOutsideTerrCountries);

        // Create a set of parent IDs
        Set<Id> parentAccountIds = new Set<Id>();
        for (Child_Account_vod__c childAccount : childAccountQueryResults) {
            parentAccountIds.add(childAccount.Parent_Account_vod__c);
        }

        // Query Addresses for each parent
        Map<Id, Address_vod__c> addressMap = getParentAccountAddresses(parentAccountIds);

        // Set Search Results
        List<SearchResult> searchResults = new List<SearchResult>();
        for (Child_Account_vod__c childAccount : childAccountQueryResults) {
            Address_vod__c addr = addressMap.get(childAccount.Parent_Account_vod__c);
            searchResults.add(buildSearchResult(childAccount, addr, configuredFieldName));
        }

        return searchResults;
    }

    private List<Child_Account_vod__c> queryChildAccounts(boolean isCJK, String name, String configuredField, String city, String state, string zip, string configuredFieldName, string searchOutsideTerrRecordTypes, string searchOutsideTerrCountries) {
        String query = BASE_QUERY;
        boolean hasConfiguredField = String.isNotBlank(configuredField);
        boolean hasName = String.isNotBlank(name);
        boolean hasCity = String.isNotBlank(city);
        boolean hasState = String.isNotBlank(state);
        boolean hasZip = String.isNotBlank(zip);
        boolean isConfiguredPicklist = false;
        boolean hasRTFilter = String.isNotBlank(searchOutsideTerrRecordTypes);
        boolean hasCountryFilter = String.isNotBlank(searchOutsideTerrCountries);

        if (String.isNotBlank(configuredFieldName)) {
            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
            DescribeFieldResult configuredSObjectField = fieldMap.get(configuredFieldName).getDescribe();
            isConfiguredPicklist = configuredSObjectField.getType() == Schema.DisplayType.PICKLIST;
            if (isConfiguredPicklist) {
                query += ', toLabel(' + 'Child_Account_vod__r.' + String.escapeSingleQuotes(configuredFieldName) + ')';
            } else {
                query += ', Child_Account_vod__r.' + String.escapeSingleQuotes(configuredFieldName);
            }
        }

        query += ' FROM Child_Account_vod__c WHERE (Child_Account_vod__c != null AND Parent_Account_vod__c != null)';

        if (hasName) {
            query = appendPredicate(query, handleNamePredicate(name, isCJK));
        }

        if (hasConfiguredField) {
            query = appendPredicate(query, handleConfiguredFieldPredicate(configuredField, configuredFieldName, isConfiguredPicklist));
        }

        if (hasCity || hasState || hasZip) {
            query = appendPredicate(query, handleLocationPredicate(city, state, zip));
        }

        if (hasRTFilter) {
            String[] recordTypeNames = searchOutsideTerrRecordTypes.split(';');
            List<Id> recordTypeIds = new List<Id>();
            for (RecordType rt: [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName IN :recordTypeNames]){
                recordTypeIds.add(rt.id);
            }
            query = appendPredicate(query, ' ((Parent_Account_vod__r.RecordTypeId IN :recordTypeIds) OR (Child_Account_vod__r.RecordTypeId IN :recordTypeIds)) ');
        }

        if (hasCountryFilter) {
            String[] countryCodes = searchOutsideTerrCountries.split(';');
            List<Id> countryIds = new List<Id>();
            for (Country_vod__c c: [SELECT Id FROM Country_vod__c WHERE Alpha_2_Code_vod__c IN :countryCodes]){
                countryIds.add(c.id);
            }
            query = appendPredicate(query, ' ((Parent_Account_vod__r.Country_vod__c IN :countryIds) OR (Child_Account_vod__r.Country_vod__c IN :countryIds)) ');
        }
        query += ' LIMIT 50';

        List<Child_Account_vod__c> childAccountQueryResults = Database.query(query);
        return childAccountQueryResults;
    }

    private String appendPredicate(String query, String predicate) {
        return query + PREFIX_AND + predicate;
    }

    private String handleNamePredicate(String name, boolean isCJK) {
        String predicate = '';
        name = String.escapeSingleQuotes(name);

        predicate += '(Parent_Account_vod__r.Name LIKE\'' + name + '%\' OR ';

        List<String> nameList = name.split(' ');
        if (nameList.size() == 1) {
            String singleName = nameList.get(0);
            predicate += '(Child_Account_vod__r.lastName LIKE \'' + singleName + '%\' OR Child_Account_vod__r.firstName Like \'' + singleName + '%\' OR Child_Account_vod__r.Name LIKE \'' + singleName +'%\')';
        } else {
            String firstName = isCJK ? nameList.get(1) : nameList.get(0);
            String lastName = isCJK ? nameList.get(0) : nameList.get(1);

            predicate += '((Child_Account_vod__r.lastName LIKE \'' + lastName + '%\' AND Child_Account_vod__r.firstName Like \'' + firstName + '%\') OR ' +
                                        '(Child_Account_vod__r.lastName LIKE \'' + name + '%\' OR Child_Account_vod__r.firstName Like \'' + name + '%\') OR ' +
                                        'Child_Account_vod__r.Name LIKE \'' + name +'%\')';
        }

        predicate += ')';
        return predicate;
    }

    private String handleConfiguredFieldPredicate(String configuredField, String configuredFieldName, Boolean isConfiguredPicklist) {
        String predicate = '';
        configuredField = String.escapeSingleQuotes(configuredField);
        configuredFieldName = String.escapeSingleQuotes(configuredFieldName);
        if (isConfiguredPicklist) {
            predicate += 'Child_Account_vod__r.' + configuredFieldName + ' = \'' + configuredField + '\'';
        } else {
            predicate += 'Child_Account_vod__r.' + configuredFieldName + ' LIKE \'%' + configuredField + '%\'';
        }
        return predicate;
    }

    private String handleLocationPredicate(String city, String state, String zip) {
        String predicate = '';
        predicate += 'Parent_Account_vod__c IN (Select Account_vod__c FROM Address_vod__c WHERE Inactive_vod__c = false';

        if (String.isNotBlank(city)) {
            city = String.escapeSingleQuotes(city);
            predicate += ' AND City_vod__c LIKE\'' + city + '%\'';
        }
        if (String.isNotBlank(zip)) {
            zip = String.escapeSingleQuotes(zip);
            predicate += ' AND (Zip_vod__c LIKE\'' + zip + '%\' OR Zip_4_vod__c LIKE \'' + zip + '%\')';
        }
        if (String.isNotBlank(state)) {
            state = String.escapeSingleQuotes(state);
            predicate += ' AND State_vod__c = \'' + state + '\'';
        }

        predicate += ')';
        return predicate;
    }

    private Map<Id, Address_vod__c> getParentAccountAddresses(Set<Id> parentAccountIds) {
        Map<Id, Address_vod__c> addressMap = new Map<Id, Address_vod__c>();
        for (Address_vod__c address : [SELECT Account_vod__c, Name, City_vod__c, State_vod__c, Zip_vod__c, Address_line_2_vod__c, toLabel(Country_vod__c) FROM Address_vod__c WHERE Account_vod__c IN :parentAccountIds AND Inactive_vod__c = false ORDER BY Primary_vod__c DESC]) {
            if (!addressMap.containsKey(address.Account_vod__c)) {
                addressMap.put(address.Account_vod__c, address);
            }
        }
        return addressMap;
    }

    private SearchResult buildSearchResult(Child_Account_vod__c childAccount, Address_vod__c address, String configuredFieldName) {
        SearchResult sr = new SearchResult();
        sr.id = childAccount.Id;
        sr.name = childAccount.Parent_Child_Name_vod__c;
        if (String.isNotBlank(configuredFieldName)) {
            sr.identifier = (String)childAccount.getSObject('Child_Account_vod__r').get(configuredFieldName);
        }
        sr.childId = childAccount.Child_Account_vod__c;
        sr.childFormattedName = (String)childAccount.getSObject('Child_Account_vod__r').get('Formatted_Name_vod__c');
        sr.parentId = childAccount.Parent_Account_vod__c;
        sr.address = getAddressFromRow(address);
        return sr;
    }

    private String getAddressFromRow(SObject addressRow) {
        String addressString = '';
        if (addressRow != null) {
            String addressLine1 = (String)addressRow.get('Name');
            String addressLine2 = (String)addressRow.get('Address_line_2_vod__c');
            String cityString = (String)addressRow.get('City_vod__c');
            String stateString = (String)addressRow.get('State_vod__c');
            String zipString = (String)addressRow.get('Zip_vod__c');
            String countryString = (String)addressRow.get('Country_vod__c');
            if (String.isNotBlank(addressLine1)) {
                addressString += addressLine1;
            }
            if (String.isNotBlank(addressLine2)) {
                addressString += ',' + addressLine2;
            }
            if (String.isNotBlank(cityString)) {
                addressString += ',' + cityString;
            }
            if (String.isNotBlank(stateString)) {
                addressString += ',' + stateString;
            }
            if (String.isNotBlank(zipString)) {
                addressString += ',' + zipString;
            }
            if (String.isNotBlank(countryString)) {
                addressString += ',' + countryString;
            }
        }
        return addressString;
    }

    global class SearchResult {
        @TestVisible String id;
        String name;
        @TestVisible String address;
        String identifier;
        String parentId;
        String childId;
        String childFormattedName;
    }
}