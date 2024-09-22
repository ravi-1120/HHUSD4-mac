public with sharing class S4LAccountValidator {

    @AuraEnabled
    public static Map<Id, S4LAccountValidationResult> validateAccountsOnCall(Id mcaId, List<Id> callIds){
        Boolean isChildAccountEnabled = MCAConvertToCallController.isChildAccountEnabled();
        Set<String> queryFields = new Set<String>(new String[]{'Id', 'Account_vod__c', 'Child_Account_vod__r.Parent_Child_Name_vod__c', 'Child_Account_Id_vod__c'});
        VeevaBaseObject callObj = VeevaBaseObject.create('Call2_vod__c');
        callObj.mapRelationships(new List<String>(queryFields));
        queryFields = callObj.getAccessibleFields(queryFields);
        List<Call2_vod__c> calls = Database.query(
            'SELECT ' + String.escapeSingleQuotes(String.join(new List<String>(queryFields), ',') +
            ' FROM Call2_vod__c WHERE Id IN: callIds'));
        List<Id> accountIds = new List<Id>();
        Map<Id, Call2_vod__c> accountIdToCallMap = new Map<Id, Call2_vod__c>();
        Map<String, Id> childAccountIdToAccountIdMap = new Map<String, Id>();
        if(calls != null && calls.size() > 0) {
            for(Call2_vod__c call : calls) {
                Id callAccountId = call.Account_vod__c;
                if(callAccountId != null) {
                    accountIds.add(callAccountId);
                    accountIdToCallMap.put(callAccountId, call);
                    String caId = (String) MCAConvertToCallController.get(call, 'Child_Account_Id_vod__c');
                    if(caId != null) {
                        childAccountIdToAccountIdMap.put(caId, callAccountId);
                    }
                }
            }
        }
        Map<Id, S4LAccountValidationResult> validationResult = new Map<Id, S4LAccountValidationResult>();
        if (!accountIds.isEmpty()) {
            validationResult = validateAccounts(mcaId, accountIds);
        }
        if(isChildAccountEnabled) {
            Map<Id, String> accountIdToParentChildNameMap = getAccountIdToParentChildNameMap(childAccountIdToAccountIdMap);
            useParentChildNameInValidationResult(validationResult, accountIdToCallMap, accountIdToParentChildNameMap);
        }
        return validationResult;
    }

    private static Map<Id, String> getAccountIdToParentChildNameMap(Map<String, Id> childAccountIdToAccountIdMap) {
        VeevaBaseObject childAccountObj = VeevaBaseObject.create('Child_Account_vod__c');
        SObjectField parentChildNameFld = childAccountObj.getField('Parent_Child_Name_vod__c');
        Map<Id, String> accountIdToParentChildNameMap = new Map<Id, String>();
        if(parentChildNameFld != null && !childAccountIdToAccountIdMap.isEmpty()) {
            List<Child_Account_vod__c> childAccounts = [SELECT Id, Parent_Child_Name_vod__c FROM Child_Account_vod__c WHERE Id IN: childAccountIdToAccountIdMap.keySet()];
            for(Child_Account_vod__c childAccount : childAccounts) {
                String caId = childAccount.Id;
                Id accountId = childAccountIdToAccountIdMap.get(caId);
                accountIdToParentChildNameMap.put(accountId, childAccount.Parent_Child_Name_vod__c);
            }
        }
        return accountIdToParentChildNameMap;
    }

    private static void useParentChildNameInValidationResult(Map<Id, S4LAccountValidationResult> validationResult, Map<Id, Call2_vod__c> accountIdToCallMap, Map<Id, String> accountIdToParentChildNameMap) {
        if(validationResult != null && accountIdToCallMap != null) {
            for(Id accountId : validationResult.keySet()) {
                S4LAccountValidationResult accountValidationResult = validationResult.get(accountId);
                Call2_vod__c call = accountIdToCallMap.get(accountId);
                String backupValue = accountIdToParentChildNameMap.get(accountId);
                replaceAccountNameWithParentChildName(accountValidationResult, call, backupValue);
            }
        }
    }

    private static void replaceAccountNameWithParentChildName(S4LAccountValidationResult result, Call2_vod__c call, String backupValue) {
        if(result != null && call != null) {
            String parentChildName = (String) MCAConvertToCallController.get(call, 'Child_Account_vod__r', 'Parent_Child_Name_vod__c');
            if(parentChildName == null) {
                parentChildName = backupValue;
            }
            if(parentChildName != null && parentChildName.length() > 0) {
                result.accountFormattedName = parentChildName;
            }
        }
    }

    @AuraEnabled
    public static S4LAccountValidationResult validateAccount(Id mcaId, Id accountId) {
        List<Id> singleton = new List<Id>();
        singleton.add(accountId);
        return validateAccounts(mcaId, singleton).get(accountId);
    }

    private static final List<String> MCAL_FIELDS = new List<String>(
        new String[]{'Segment_vod__c', 'Product_vod__r.Name', 'CLM_Presentation_vod__r.Name'});

    @AuraEnabled
    public static Map<Id, S4LAccountValidationResult> validateAccounts(Id mcaId, List<Id> accountIds) {
        Map<Id, S4LAccountValidationResult> result = new Map<Id, S4LAccountValidationResult>();
        Set<String> accountAccessibleFields = VeevaBaseObject.create('Account').getAccessibleFields(new Set<String>{'Do_Not_Call_vod__c', 'Restricted_Products_vod__c', 'Segmentations_vod__c'});
        Set<String> territoryAccessibleFields = VeevaBaseObject.create('TSF_vod__c').getAccessibleFields(new Set<String>{'Allowed_Products_vod__c'});
        
        // query Multichannel Activity Lines and extract all the Products/ Segments
        List<Multichannel_Activity_Line_vod__c> mcals = MCAConvertToCallController.queryMCALs(mcaId, MCAL_FIELDS);
        Set<String> mcalProductNames = new Set<String>();
        Set<String> mcalSegments = new Set<String>();
        Map<String, String> mcalProductNameToClmPresentationName = new Map<String, String>();
        for(Multichannel_Activity_Line_vod__c mcal : mcals) {
            String productName = mcal.Product_vod__r.Name;
            addNonBlankString(mcalProductNames, productName);
            addNonBlankString(mcalSegments, mcal.Segment_vod__c);
            if(String.isNotBlank(productName) && !mcalProductNameToClmPresentationName.containsKey(productName)) {
                mcalProductNameToClmPresentationName.put(productName, mcal.CLM_Presentation_vod__r.Name);
            }
        }

        // query Accounts and their allowed products (from TSF) and restricted products/ segmentations (from Account)
        List<Account> accounts = queryAccounts(accountIds);
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<Id, Set<String>> allowedProducts =  getAccountAllowedProducts(accounts);
        Map<Id, Set<String>> restrictedProducts = new Map<Id, Set<String>>();
        Map<Id, Set<String>> segmentations = new Map<Id, Set<String>>();

        for(Account account : accounts) {
            Id accountId = account.Id;
            restrictedProducts.put(accountId, getAccountRestrictedProducts(account));
            segmentations.put(accountId, getAccountSegmentations(account));
        }

        // validate against each account: Do Not Call field / MCAL's products and segments
        for(Account account : accounts) {
            Id accountId = account.Id;
            String accountFormattedName = account.Formatted_Name_vod__c;
            String accountDoNotCall = account.Do_Not_Call_vod__c;
            if(accountDoNotCall == 'Yes_vod' && accountAccessibleFields.contains('Do_Not_Call_vod__c')) { 
                result.put(accountId, buildAccountErrorResult(accountFormattedName));
                continue;
            }
            // product level restriction
            // restricted products: product blacklisting
            Set<String> accountRestrictedProducts = restrictedProducts.get(accountId);
            if(accountRestrictedProducts != null && !accountRestrictedProducts.isEmpty() && accountAccessibleFields.contains('Restricted_Products_vod__c')) {
                String firstRestrictedProduct = getFirstBacklistValidation(mcalProductNames, accountRestrictedProducts);
                if(firstRestrictedProduct != null) {
                    String clmPresentationName = mcalProductNameToClmPresentationName.get(firstRestrictedProduct);
                    result.put(accountId, buildProductErrorResult(accountFormattedName, firstRestrictedProduct, clmPresentationName));
                    continue;
                }
            }
            // allowed products: product whitelisting
            Set<String> accountAllowedProducts = allowedProducts.get(accountId);
            if(accountAllowedProducts != null && !accountAllowedProducts.isEmpty() && territoryAccessibleFields.contains('Allowed_Products_vod__c')) {
                String firstDisallowedProduct = getFirstWhitelistValidation(mcalProductNames, accountAllowedProducts);
                if(firstDisallowedProduct != null) {
                    String clmPresentationName = mcalProductNameToClmPresentationName.get(firstDisallowedProduct);
                    result.put(accountId, buildProductErrorResult(accountFormattedName, firstDisallowedProduct, clmPresentationName));
                    continue;
                }
            }

            // segment level restriction: segment whitelisting
            Set<String> accountSegmentations = segmentations.get(accountId);
            if(accountSegmentations != null && !accountSegmentations.isEmpty() && accountAccessibleFields.contains('Segmentations_vod__c') && getFirstWhitelistValidation(mcalSegments, accountSegmentations) != null) {
                result.put(accountId, buildSegmentErrorResult(accountFormattedName));
                continue;
            }
        }
        return result;
    }

    private static String getFirstWhitelistValidation(Set<String> mcalValues, Set<String> whitelisted) {
        Set<String> validations = new Set<String>(mcalValues);
        validations.removeAll(whitelisted);
        // if there's mcal value that include value that is NOT whitelisted, there's an invalid value
        return getFirstValidation(validations);
    }

    private static String getFirstBacklistValidation(Set<String> mcalValues, Set<String> backlisted) {
        Set<String> validations = new Set<String>(backlisted);
        validations.retainAll(mcalValues);
        // if there's any joint value between the mcal value and the blacklisted, there's an invalid value
        return getFirstValidation(validations);
    }

    private static String getFirstValidation(Set<String> validations) {
        if(!validations.isEmpty()) {
            return validations.iterator().next();
        } else {
            return null;
        }
    }

    private static S4LAccountValidationResult buildAccountErrorResult(String accountFormattedName) {
        return new S4LAccountValidationResult(S4LAccountValidationResult.S4LAccountValidationError.ACCOUNT_ERROR,
            accountFormattedName);
    }

    private static S4LAccountValidationResult buildProductErrorResult(String accountFormattedName, String productName, String clmPresentationName) {
        return new S4LAccountValidationResult(S4LAccountValidationResult.S4LAccountValidationError.PRODUCT_ERROR,
            accountFormattedName, productName, clmPresentationName);
    }

    private static S4LAccountValidationResult buildSegmentErrorResult(String accountFormattedName) {
        return new S4LAccountValidationResult(S4LAccountValidationResult.S4LAccountValidationError.SEGMENT_ERROR,
            accountFormattedName);
    }

    private static Map<Id, Set<String>> getAccountAllowedProducts(List<Account> accounts) {
        Map<Id, Set<String>> allowedProducts = new Map<Id, Set<String>>();
        for(Account account : accounts) {
            Set<String> accountAllowedProducts = new Set<String>();
            TSF_vod__c[] accountTsf = account.TSF_vod__r;
            if(accountTsf != null && accountTsf.size() > 0) {
                for(TSF_vod__c tsf : accountTsf) {
                    accountAllowedProducts.addAll(getAllowedProducts(tsf));
                }
            }
            allowedProducts.put(account.Id, accountAllowedProducts);
        }
        return allowedProducts;
    }

    public static List<String> getUserTerritoryNames () {
        TerritoryManagement territoryManagement = TerritoryManagementFactory.getInstance();
        Set<Id> userTerritoryIds = territoryManagement.getUserTerritories(UserInfo.getUserId());
        if(userTerritoryIds != null && !userTerritoryIds.isEmpty()) {
            return territoryManagement.getTerritoryNames(userTerritoryIds);
        }
        return new List<String>();
    }

    private static Set<String> getAllowedProducts (TSF_vod__c tsf) {
        Set<String> allowedProducts = new Set<String>();
        String tsfAllowedProducts = tsf.Allowed_Products_vod__c;
        if(String.isNotBlank(tsfAllowedProducts)) {
            for(String allowedProduct : tsfAllowedProducts.split(';;')) {
                allowedProducts.add(allowedProduct);
            }
        }
        return allowedProducts;
    }

    private static List<Account> queryAccounts(List<Id> accountIds) {
        List<String> userTerritoryNames = getUserTerritoryNames();
        return [SELECT Id, Formatted_Name_vod__c, Segmentations_vod__c, Restricted_Products_vod__c, Do_Not_Call_vod__c,
                    (SELECT Id, Account_vod__c, Allowed_Products_vod__c FROM TSF_vod__r WHERE Territory_vod__c IN :userTerritoryNames)
                FROM Account
                WHERE Id IN: accountIds];
    }

    private static Set<String> getAccountRestrictedProducts(Account account) {
        return extractDelimitedFieldFromAccount(account, 'Restricted_Products_vod__c', ';;');
    }

    private static Set<String> getAccountSegmentations(Account account) {
        return extractDelimitedFieldFromAccount(account, 'Segmentations_vod__c', ',');
    }

    private static Set<String> extractDelimitedFieldFromAccount (Account account, String field, String delimiter) {
        Set<String> values = new Set<String>();
        String value = String.valueOf(account.get(field));
        if(String.isNotBlank(value)) {
            if(delimiter != null) {
                for(String part : value.split(delimiter)) {
                    addNonBlankString(values, part);
                }
            } else {
                values.add(value);
            }
        }
        return values;
    }

    private static void addNonBlankString (Set<String> targetSet, String value) {
        if(String.isNotBlank(value)) {
            targetSet.add(value);
        }
    }
}