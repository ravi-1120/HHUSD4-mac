/*
 * SFAccountSearchUtilityMVN
 * Created by: Jennifer Wyher
 * Created Date: May 29, 2014
 * Description: This class implements the functionality to search for Customer and
 *              Business Accounts by different search parameters such as:
 *              First/Last Name, City, State, Country, Phone, Employee Number, 
 *              Customer Number, and Type
 *
 *              In order to facilitate the search this class looks across the following
 *              objects:  Account, Address_vod__c, Communication_Mechanism_MRK__c, and Child_Account_vod__c
 *
 * Change Log: KRB REL 10.0 - Added Logic for the Person Account Preferred first and last Names Searching
 *
 *
 */

public with sharing class SFAccountSearchUtilityMVN implements AccountSearchUtilityMVN.searchInterface {
    private static String acctPrefix = Schema.SObjectType.Account.getKeyPrefix();
    private static String addrPrefix = Schema.SObjectType.Address_vod__c.getKeyPrefix();
    private static String commPrefix = Schema.SObjectType.Communication_Mechanism_MRK__c.getKeyPrefix();
    private static List<String> validPersonTypes = new List<String>();
    private static List<Id> validPersonRecordTypeIds = new List<Id>(); 
    private static List<Id> validBusinessRecordTypeIds = new List<Id>();
    private static List<String> invalidPersonStatusReasons = new List<String>();
    private static List<String> invalidNonHCPStatuses = new List<String>();
    private static List<String> invalidBusinessStatuses = new List<String>();
    private static Set<Id> acctIdSet = new Set<Id>();

    // Account Fields
    private static Set<String> AccountOrderByFields = new Set<String>{
        'Preferred_Last_Name_MRK__c','Preferred_First_Name_MRK__c'    
    };

    // Search result ordering now handled by standard list sort 
    // given that AccountSearchResultMockMVN now implements the Comparable interface
    private static String AccountOrderByString = '';

    private static String AccountSelectFieldString = escapeAndJoin(UtilitiesMVN.accountSelectFields(), ',');

    private static Map<String, String> AccountPersonWhereFields = new Map<String, String>{
        'Preferred_Last_Name_MRK__c' => 'LIKE',
        'Preferred_First_Name_MRK__c' => 'LIKE',
        'Preferred_Middle_Name_MRK__c' => 'LIKE'
    };
    private static Map<String, String> EmployeeWhereFields = new Map<String, String>{
        'MSD_CORE_Merck_Employee_ID__c' => 'LIKE'
    };
    private static Map<String, String> AccountBusinessWhereFields = new Map<String, String>{
        'Preferred_Full_Name_MRK__c' => 'LIKE'
    };
    // Added for Merck_id_Search
    private static Map<String, String> MerckIdWhereFields = new Map<String, String>{
        'Merck_ID_MRK__c' => '='
    };
    // Code ends here
    // Address Fields
    private static String AddressRelationship = 'Address_vod';
    private static Set<String> AddressSelectFields = new Set<String>{
        'Id', 'External_ID_vod__c', 'Name', 'Address_line_2_vod__c', 'City_vod__c',
        'State_vod__c', 'Zip_vod__c', 'Country_vod__c'
    };
    private static String AddressSelectFieldString = escapeAndJoin(AddressSelectFields, ',');
    private static Map<String, String> AddressWhereFields = new Map<String,String>{
        'City_vod__c' => 'LIKE',
        'State_vod__c' => '=',
        'Zip_vod__c' => 'LIKE',
        'Country_vod__c' => '='
    };

    // Communication Fields
    private static String CommunicationRelationship = 'Communication_Mechanisms';
    private static Set<String> CommunicationSelectFields = new Set<String>{
        'Account_MRK__c', 'Phone_MRK__c'
    };
    private static String CommunicationSelectFieldString = escapeAndJoin(CommunicationSelectFields, ',');

    // Alternate ID Fields
    private static String AlternateIdRelationship = 'Alternate_Identifiers';
    private static Set<String> AlternateIDSelectFields = new Set<String>{
        'Alternate_Identifier_Value_MRK__c'
    };
    private static String AlternateIDSelectFieldString = escapeAndJoin(AlternateIDSelectFields, ',');

    private static Integer SEARCHLIMIT = (Integer) Service_Cloud_Settings_MVN__c.getInstance().Account_Search_Max_Results_MVN__c; // can never be greater than 200 due to sosl limits
    private static String SAP_ID_TYPE = Service_Cloud_Settings_MVN__c.getInstance().MSD_CORE_SAP_ID_Type__c;
    private static String HCP_TYPE = Service_Cloud_Settings_MVN__c.getInstance().MSD_CORE_HCP_Type__c;

    static {
        if(SEARCHLIMIT == null || SEARCHLIMIT < 1) {
            SEARCHLIMIT = 50;
        }
        SEARCHLIMIT=Math.min(SEARCHLIMIT, 200);

        setValidRecordTypeIds();
        setValidTypes();
        setStatusFilters();
    }

    // initialize the recordTypes
    private static void setValidRecordTypeIds() {
        validPersonRecordTypeIds = new List<Id>();
        validBusinessRecordTypeIds = new List<Id>();

        Map<String,RecordType> recordTypes = new Map<String,RecordType>();
        for(RecordType rt : [SELECT Id, Name, DeveloperName, IsActive, IsPersonType FROM RecordType WHERE sObjectType = 'Account' AND IsPersonType = TRUE and IsActive = TRUE]){
            validPersonRecordTypeIds.add(rt.Id);
        }

        for(RecordType rt : [SELECT Id, Name, DeveloperName, IsActive, IsPersonType FROM RecordType WHERE sObjectType = 'Account' AND IsPersonType = FALSE and IsActive = TRUE]){            
            validBusinessRecordTypeIds.add(rt.Id);
        }
    }

    private static void setValidTypes(){        
        validPersonTypes = UtilitiesMVN.splitCommaSeparatedString(Service_Cloud_Settings_MVN__c.getInstance().Person_Account_Search_Types_MVN__c);
    }

    private static void setStatusFilters(){
        invalidNonHCPStatuses = UtilitiesMVN.splitCommaSeparatedString(Service_Cloud_Settings_MVN__c.getInstance().MSD_CORE_Non_HCP_Status_Filter__c);
        invalidPersonStatusReasons = UtilitiesMVN.splitCommaSeparatedString(Service_Cloud_Settings_MVN__c.getInstance().MSD_CORE_Person_Status_Reason_Filter__c);
        invalidBusinessStatuses = UtilitiesMVN.splitCommaSeparatedString(Service_Cloud_Settings_MVN__c.getInstance().MSD_CORE_Business_Status_Filter__c);
    }

    public List<AccountSearchResultMockMVN> search(Account account, Address_vod__c address, String type, Boolean isPerson, String alternateId) {
        List<AccountSearchResultMockMVN> results = new List<AccountSearchResultMockMVN>();

        Boolean hasPhone = !String.isBlank(account.Phone);
        Boolean hasAddress = !(String.isBlank(address.City_vod__c) && String.isBlank(address.State_vod__c) && String.isBlank(address.Zip_vod__c));
        Boolean hasAccount = !(String.isBlank(account.Preferred_Last_Name_MRK__c) 
                                && String.isBlank(account.Preferred_First_Name_MRK__c) 
                                && String.isBlank(account.Preferred_Middle_Name_MRK__c)
                                && String.isBlank(account.Preferred_Full_Name_MRK__c));
        Boolean hasEmployeeId = isPerson && !(String.isBlank(account.MSD_CORE_Merck_Employee_ID__c));
        Boolean hasAlternateId = !isPerson && !(String.isBlank(alternateId));
        Boolean hasMerckId = !(String.isBlank(account.Merck_ID_MRK__c));  // Added for Merck_id_Search
		System.debug('isPerson:'+isPerson+'::'+'type:'+type);
        String baseWhereClause = getAccountBaseWhereClause(isPerson, type);

        if(hasAccount || hasAddress) {
            if(hasAddress){
                results = searchAccountsBySOQL(baseWhereClause + getAddressWhereClause(account, isPerson, address), 
                                account, address, type, alternateId);
            } else {
                results = searchAccountsBySOQL(baseWhereClause + getAccountWhereClause(account, isPerson), 
                                account, address, type, alternateId);
            }
        } else if (hasEmployeeId || hasAlternateId || hasMerckId) { // Added for Merck_id_Search the last XOR statement for MerKId check
            if(hasEmployeeId){
                results = searchAccountsBySOQL(baseWhereClause + getEmployeeWhereClause(account), 
                                account, address, type, alternateId);
            } else if(hasAlternateId){ // Added for Merck_id_Search
                results = searchAccountsBySOQL(baseWhereClause + getAlternateIdWhereClause(account, isPerson, alternateId), 
                                account, address, type, alternateId);
            } else{ // Added for Merck_id_Search
            	results = searchAccountsBySOQL(baseWhereClause + getMerckIdWhereClause(account), account, address, type, alternateId);
            }
        } else if(hasPhone) {
            results = searchAccountsBySOSL(account, address, type, isPerson, alternateId);
        } else {
            System.debug(LoggingLevel.ERROR, 'SFAccountSearchUtilityMVN.search parameters missing valid query');
        }

        return results;
    }

    public List<AccountSearchResultMockMVN> searchChildAccounts(Id accountId){
        List<AccountSearchResultMockMVN> results = new List<AccountSearchResultMockMVN>();

        if(accountId == null){
            System.debug(LoggingLevel.ERROR, 'accountId is null but is required');
            return results;
        }
        String whereClause = getChildAccountWhereClause('Child_Account_vod__c', 'Parent_Account_vod__c', accountId);
        results = searchAccountsBySOQL(whereClause, null, null, null, null);

        return results;
    }
    public List<AccountSearchResultMockMVN> searchParentAccounts(Id accountId){
        List<AccountSearchResultMockMVN> results = new List<AccountSearchResultMockMVN>();

        if(accountId == null){
            System.debug(LoggingLevel.ERROR, 'accountId is null but is required');
            return results;
        }

        String whereClause = getChildAccountWhereClause('Parent_Account_vod__c', 'Child_Account_vod__c', accountId);
        results = searchAccountsBySOQL(whereClause, null, null, null, null);

        return results;
    }

    private List<AccountSearchResultMockMVN> searchAccountsBySOQL(String whereClause, Account account, Address_vod__c address, String type, String alternateId){
        List<AccountSearchResultMockMVN> resultList = new List<AccountSearchResultMockMVN>();                

        String qString = 'SELECT ' + AccountSelectFieldString; 
        qString += ',(SELECT ' + AddressSelectFieldString + ' FROM '+ AddressRelationship +'__r WHERE IsDeleted = false'+getSObjectWhereClause(address, AddressWhereFields)+')';
        qString += ',(SELECT ' + AlternateIDSelectFieldString + ' FROM ' + AlternateIdRelationship + '__r WHERE Type_MRK__c = :SAP_ID_TYPE LIMIT 2)';
        qString += ' FROM Account ' +  whereClause + AccountOrderByString + ' LIMIT ' + SEARCHLIMIT;
        System.debug('validBusinessRecordTypeIds -->'+validBusinessRecordTypeIds);
        System.debug('invalidBusinessStatuses -->'+invalidBusinessStatuses);
        System.debug('type -->'+type);        
        System.debug('qString -->'+whereClause + AccountOrderByString + ' LIMIT ' + SEARCHLIMIT);
        System.debug(LoggingLevel.FINE, '\tSearchAccountsBySOQL Query:\n\n' + qString);

        List<Account> accountList = database.query(qString);
        for(Account accountResult : accountList ) {
            String sapIds = '';
            if(accountResult.Alternate_Identifiers__r.size() > 0){
                List<String> alternateIds = new List<String>();
                for(Alternate_Identifier_MRK__c alternateSAPId : accountResult.Alternate_Identifiers__r){
                    alternateIds.add(alternateSAPId.Alternate_Identifier_Value_MRK__c);
                }
                sapIds = String.join(alternateIds, ', ');
            }

            Boolean addressResultAdded = false;
            if(accountResult.Address_vod__r.size() > 0) {
                for(Address_vod__c addr : accountResult.Address_vod__r) {
                    if(address != null && String.isNotBlank(address.Country_vod__c) && address.Country_vod__c != addr.Country_vod__c){
                        continue;
                    }
                    resultList.add(new AccountSearchResultMockMVN(accountResult,addr, sapIds, this));
                    addressResultAdded = true;
                }
            }

            if ((address == null || accountResult.MSD_CORE_Country_Code__c == address.Country_vod__c || String.IsBlank(address.Country_vod__c)) && !addressResultAdded){
                resultList.add(new AccountSearchResultMockMVN(accountResult, new Address_vod__c(), sapIds, this));
            }

        }

        return resultList;
    }

    private String getAccountWhereClause(Account account, Boolean isPerson){
        String whereString = getSObjectWhereClause(account, isPerson ? AccountPersonWhereFields : AccountBusinessWhereFields);

        System.debug(LoggingLevel.FINE, '\tgetAccountWhereClause(account, address, isPerson)\n'+
            '\t\taccount=' + account + '\n\n\t\tisPerson' + isPerson +
            '\n\n\t\twhereString=' + whereString + '\n\n');

        return whereString;
    }

    private String getEmployeeWhereClause(Account account){
        String whereString = getSObjectWhereClause(account, EmployeeWhereFields);

        System.debug(LoggingLevel.FINE, '\tgetEmployeeWhereClause(account)\n'+
            '\t\taccount=' + account +
            '\n\n\t\twhereString=' + whereString + '\n\n');

        return whereString;
    }
//// Added for Merck_id_Search GetMerckIdWhereClause code snippet
    private String getMerckIdWhereClause(Account account){
        String whereString = getSObjectWhereClause(account, MerckIdWhereFields);

        System.debug(LoggingLevel.FINE, '\tgetMerckIdWhereClause(account)\n'+
            '\t\taccount=' + account +
            '\n\n\t\twhereString=' + whereString + '\n\n');

        return whereString;
    }
  // Code ends here
    
    private String getAddressWhereClause(Account account, Boolean isPerson, Address_vod__c address){
        String accountWhereClause = getSObjectWhereClause(account, isPerson ? AccountPersonWhereFields : AccountBusinessWhereFields); 
        
        String addressWhereClause = accountWhereClause.replace('Preferred_First_Name_MRK__c', 'Account_vod__r.Preferred_First_Name_MRK__c');
        addressWhereClause = addressWhereClause.replace('Preferred_Last_Name_MRK__c', 'Account_vod__r.Preferred_Last_Name_MRK__c');
        addressWhereClause = addressWhereClause.replace('Preferred_Full_Name_MRK__c', 'Account_vod__r.Preferred_Full_Name_MRK__c');

        //KRB REL 10 7/25/2017
        addressWhereClause = addressWhereClause.replace('FirstName', 'Account_vod__r.FirstName');
        addressWhereClause = addressWhereClause.replace('LastName', 'Account_vod__r.LastName');
        
        String addressQuery = 'SELECT Account_vod__c FROM Address_vod__c ' + getAddressBaseWhereClause(isPerson, account.Class_of_Trade_MRK__c) + addressWhereClause
                                  + getSObjectWhereClause(address, AddressWhereFields) 
                                  + ' LIMIT ' + SEARCHLIMIT;

        System.debug('Address Query: '+addressQuery);
        System.debug('KRB Rel 10: Address Query: '+addressQuery);
        List<Address_vod__c> addressList = Database.query(addressQuery);

        acctIdSet = new Set<Id>();
        for(Address_vod__c addr:addressList){
            if(!String.isBlank(addr.Account_vod__c)){
                acctIdSet.add(addr.Account_vod__c);
            }
        }

        String whereString = ' AND Id IN :acctIdSet';
        whereString += accountWhereClause;

        System.debug(LoggingLevel.FINE, '\tgetAddressWhereClause(account, address, isPerson)\n'+
            '\t\taccount=' + account + '\n\n\t\taddress=' + address + '\n\n\t\tisPerson' + isPerson +
            '\n\n\t\twhereString=' + whereString + '\n\n');

        return whereString;
    }

    private String getAlternateIdWhereClause(Account account, Boolean isPerson, String alternateId){
        String whereString = ' AND Id IN (SELECT Account_MRK__c FROM Alternate_Identifier_MRK__c WHERE Alternate_Identifier_Value_MRK__c = :alternateId)';
        whereString += getSObjectWhereClause(account, isPerson ? AccountPersonWhereFields : AccountBusinessWhereFields);

        System.debug(LoggingLevel.FINE, '\tgetAlternateIdWhereClause(account, isPerson, alternateId)\n'+
            '\t\taccount=' + account + '\n\n\t\tisPerson' + isPerson +
            '\n\n\t\twhereString=' + whereString + '\n\n');

        return whereString;
    }

    private String getChildAccountWhereClause(String relatedAccount, String subject, Id accountId){
        return 'WHERE Id IN (SELECT ' + relatedAccount 
            + ' FROM Child_Account_vod__c WHERE ' + subject + ' = \'' + accountId + '\') ';
    }

    private String getSObjectWhereClause(SObject theObject, Map<String,String> whereFields){
        String whereClause = '';
        if(theObject != null){
            for(String field : whereFields.keySet()){
                System.debug('Kevin 1: field: ' + field);
                String value = (String)theObject.get(field);
                System.debug('Kevin 2: value: ' + value);
                if(String.isNotBlank(value)){
                    
                    //KRB REL 10 - out
                    //String operator = whereFields.get(field);                
                    //whereClause += ' AND ' + field + ' ' + operator + ' \'' + value.replaceAll('\\*', '%') + '\'';
                    
                    //KRB REL 10 - in - special logic to search both Names and Preferred Names
                    if (field=='Preferred_First_Name_MRK__c'){
                       String operator = whereFields.get(field);                
                       whereClause += ' AND ';
                       whereClause += '(' ;
                       whereClause +=  '(' + field + ' ' + operator + ' \'' + value.replaceAll('\\*', '%') + '\'' + ')';
                       whereClause += ' or ';
                       whereClause +=  '( FirstName ' + operator + ' \'' + value.replaceAll('\\*', '%') + '\'' + ')';
                       whereClause += ')'; 
                    }else if (field=='Preferred_Last_Name_MRK__c'){
                       String operator = whereFields.get(field);                
                       whereClause += ' AND ';
                       whereClause += '(' ;
                       whereClause +=  '(' + field + ' ' + operator + ' \'' + value.replaceAll('\\*', '%') + '\'' + ')';
                       whereClause += ' or ';
                       whereClause +=  '( LastName ' + operator + ' \'' + value.replaceAll('\\*', '%') + '\'' + ')';
                       whereClause += ')'; 
                    }else {
                       String operator = whereFields.get(field);                
                       whereClause += ' AND ' + field + ' ' + operator + ' \'' + value.replaceAll('\\*', '%') + '\'';
                    }
                    
                    
                }
            }
        }
        
        System.Debug('Kevin 3: ' + whereClause);
        return whereClause;
    }

    private String getAccountBaseWhereClause(Boolean isPerson, String type){
        String whereString = ' WHERE IsDeleted = false';
        if(isPerson){
            whereString += ' AND (Class_of_Trade_MRK__c in :validPersonTypes)';
            whereString += ' AND (RecordTypeId in :validPersonRecordTypeIds)';
            whereString += ' AND (Status_MRK__c NOT in :invalidNonHCPStatuses OR Class_of_Trade_MRK__c = :HCP_TYPE)';
            whereString += ' AND (Status_Reason_MRK__c NOT in :invalidPersonStatusReasons)';
        } else {
            whereString += ' AND (RecordTypeId in :validBusinessRecordTypeIds)';
            whereString += ' AND Status_MRK__c NOT IN :invalidBusinessStatuses';
        }

        /*if(type != 'All') {
            whereString += ' AND (Class_of_Trade_MRK__c = :type)';
        }*/
        if(isPerson && type != 'All') {
            whereString += ' AND (Class_of_Trade_MRK__c = :type)';
        }
        return whereString;
    }

    private String getAddressBaseWhereClause(Boolean isPerson, String type){
        String whereString = ' WHERE IsDeleted = false';
        
        if(isPerson){
            whereString += ' AND (Account_vod__r.Class_of_Trade_MRK__c in :validPersonTypes)';
            whereString += ' AND (Account_vod__r.RecordTypeId in :validPersonRecordTypeIds)';
            whereString += ' AND (Account_vod__r.Status_MRK__c NOT in :invalidNonHCPStatuses OR Account_vod__r.Class_of_Trade_MRK__c = :HCP_TYPE)';
            whereString += ' AND (Account_vod__r.Status_Reason_MRK__c NOT in :invalidPersonStatusReasons)';
        } else {
            whereString += ' AND (Account_vod__r.RecordTypeId in :validBusinessRecordTypeIds)';
            whereString += ' AND Account_vod__r.Status_MRK__c NOT IN :invalidBusinessStatuses';
        }

        if(type != 'All' && !String.isBlank(type)) {
            whereString += ' AND (Account_vod__r.Class_of_Trade_MRK__c = \''+type+'\')';
        }
        return whereString;
    }

    private static String escapeAndJoin(Set<String> stringSet, String separator){
        return escapeAndJoin(new List<String>(stringSet), separator);
    }

    private static String escapeAndJoin(List<String> strings, String separator){
        return String.escapeSingleQuotes(String.join(strings, separator));
    }

    public List<AccountSearchResultMockMVN> searchAccountsBySOSL(Account account, Address_vod__c address, String type, Boolean isPerson, String alternateId) {

        Set<String> accountIdSet = new Set<String>();

        List<Communication_Mechanism_MRK__c> foundCommunicationMechanisms = new List<Communication_Mechanism_MRK__c>();
        List<Account> foundAccounts = new List<Account>();
        List<Address_vod__c> foundAddresses = new List<Address_vod__c>();

        //Do initial query
        String queryString = getSOSLQuery(account, address, type, isPerson, alternateId);
        if(queryString == null) {
            return null;
        }

        LIST<LIST<SObject>> searchResult;
        try {
            searchResult = search.query(queryString);
        } catch (exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, e.getMessage()));
            return null;
        }

        //Separate out what kind each list is
        for(List<SObject> oneKind : searchResult) {
            if(oneKind.size() > 0) {
                String typeId = oneKind[0].Id;
                if(typeId.startsWith(acctPrefix)) {
                    foundAccounts = (List<Account>) oneKind;
                } else if(typeId.startsWith(addrPrefix)) {
                    foundAddresses = (List<Address_vod__c>) oneKind;
                } else if(typeId.startsWith(commPrefix)) {
                    foundCommunicationMechanisms = (List<Communication_Mechanism_MRK__c>) oneKind;
                }
            }
        }

        for(Communication_Mechanism_MRK__c communicationMechanism : foundCommunicationMechanisms) {
            accountIdSet.add((String)communicationMechanism.Account_MRK__c);
        }

        for(Account foundAccount : foundAccounts) {
            accountIdSet.add((String)foundAccount.Id);
        }

        for(Address_vod__c foundAddress : foundAddresses) {
            accountIdSet.add((String)foundAddress.Account_vod__c);
        }

        String baseWhereClause = getAccountBaseWhereClause(isPerson, type);
        String accountIdInClause = ' AND Id IN (\'' + String.join(new List<String>(accountIdSet), '\',\'') + '\')';

        return searchAccountsBySOQL(baseWhereClause + accountIdInClause, 
                                account, address, type, alternateId);
    }

    public String getSOSLQuery(Account account, Address_vod__c address, String type, Boolean isPerson, String alternateId) {
        //Put together final query and error check it
        String qString = 'FIND \'';
        String findString = '';

        findString = account.Phone.replaceAll('[^0-9*]', '');
        if (findString.replaceAll('[^0-9]', '').length() < 2) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, System.Label.SOSL_Phone_Search_Min_Char + ' ' + String.escapeSingleQuotes(account.Phone)));
            return null;
        }

        qString += findString + '\' IN PHONE FIELDS RETURNING ';
        qString += ' Address_vod__c (Account_vod__c WHERE IsDeleted = false ';
        qString += getSObjectWhereClause(address, AddressWhereFields);
        qString += '), ';
        qString += ' Account (Id  WHERE IsDeleted = false ';
        qString += getSObjectWhereClause(account, isPerson ? AccountPersonWhereFields : AccountBusinessWhereFields);
        qString += '), ';
        qString += ' Communication_Mechanism_MRK__c (Account_MRK__c, Phone_MRK__c ';
        qString += 'WHERE IsDeleted = false AND Do_Not_Use_Inbound_Routing_MRK__c = false';
        qString += ')';
        return qString;
    }

    public AccountSearchResultMockMVN insertAccountDetails(AccountSearchResultMockMVN asr) {
        //Result was from Salesforce so no need to insert or do anything.
        return asr;
    }
}