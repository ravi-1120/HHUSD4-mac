public without sharing class VeevaGASAccountManagement {
    private static Set<String> ADDRESS_QUERY_FIELDS = new Set<String> {
        'Id', 'Name', 'Address_Line_2_vod__c', 'City_vod__c', 'toLabel(State_vod__c)', 'Zip_vod__c'
    };

    public List<Account> getParentAccounts(String accountId) {
        List<String> parentAccountIds = getParentAccountIds(accountId);
        List<String> userAccessibleAddressFields = new List<String>(getUserAccessibleAddressQueryFields());
        List<String> queryFields = new List<String> { 'Id', 'Name' };
        if (userAccessibleAddressFields.size() > 0) {
            queryFields.add(String.format(
                '(SELECT {0} FROM Address_vod__r ORDER BY Primary_vod__c DESC, CreatedDate ASC LIMIT 1)',
                new List<Object>{ String.join(userAccessibleAddressFields, ', ') }
            ));
        }

        List<Account> parentAccounts = Database.query(
            String.format(
                'SELECT {0} FROM Account WHERE Id IN :parentAccountIds',
                new List<Object> { String.join(queryFields, ', ') }
            )
        );
        return parentAccounts;
    }

    // Note this method assumes that the ATL upsertion is a synchronous process. This is a safe assumption with the kind of data that GAS deals with, however if the
    // volume of data is large enough ATL upsertion will become asynchronous through some logic in it's triggers. This method should NOT be used for any kind of mass assignment
    public VeevaGASTerritoryAssignmentResult assignAccountsToTerritories(List<String> accountIds, List<String> territoryIds, String platform, String source) {

        VeevaGASAlignmentHistoryService veevaGASAlignmentHistoryService = new VeevaGASAlignmentHistoryService();
        boolean shouldGenerateManualAlignmentLog = veevaGASAlignmentHistoryService.alignmentHistoryPermissionCheck();

        // if we need to generate a manual alignment log, we need to retrieve the existing territories for the accounts before the assignment
        Map<String, List<String>> beforeAssignmentAccountToTerritoryNameMap = null;
        if (shouldGenerateManualAlignmentLog) {
            beforeAssignmentAccountToTerritoryNameMap = getAccountsToTerritoryNameMap(accountIds);
        }

        List<Territory2> territories = [SELECT Id, Name FROM Territory2 WHERE Id IN :territoryIds];
        String territoryNamesForATL = getTerritoriesToAddForATL(territories);
        List<Account_Territory_Loader_vod__c> accountAtls = getOrCreateATLRecordForAccounts(accountIds);
        for (Account_Territory_Loader_vod__c accountAtl : accountAtls) {
            accountAtl.Territory_To_Add_vod__c = territoryNamesForATL;
        }

        // Upserts ATLs with Territories to Add and returns false if any one of the ATLs failed to upsert
        List<Database.UpsertResult> upsertResults = Database.upsert(accountAtls, false);
        for (Database.UpsertResult upsertResult : upsertResults) {
            if (!upsertResult.isSuccess()) {
                return new VeevaGASTerritoryAssignmentResult(false, upsertResult.getErrors().get(0).getMessage());
            }
        }

        Map<String, Set<String>> afterAssignmentAccountToTerritoryIdMap = getAccountsToTerritoryIdMap(accountIds);
        VeevaGASATLUpsertionResult atlUpsertResult = new VeevaGASATLUpsertionResult(territoryIds, territories, afterAssignmentAccountToTerritoryIdMap);

        if (shouldGenerateManualAlignmentLog) {
            Map<String, List<String>> successfulAssignmentsAccountToTerritoryNameMap = atlUpsertResult.findSuccessAssignments();
            veevaGASAlignmentHistoryService.createAlignmentHistories(accountIds, beforeAssignmentAccountToTerritoryNameMap, successfulAssignmentsAccountToTerritoryNameMap, platform, source);
        }

        Map<String, List<String>> failedAssignmentsAccountToTerritoryNameMap = atlUpsertResult.findFailedAssignments();
        if (!failedAssignmentsAccountToTerritoryNameMap.isEmpty()) {
            String formattedAssignmentErrorMessage = atlUpsertResult.getFailedAssignmentsMessages(failedAssignmentsAccountToTerritoryNameMap);
            return new VeevaGASTerritoryAssignmentResult(false, formattedAssignmentErrorMessage);
        }

        return new VeevaGASTerritoryAssignmentResult(true, '');
    }

    private List<String> getParentAccountIds(String accountId) {
        List<Child_Account_vod__c> relatedChildAccountRecords = [SELECT Parent_Account_vod__c FROM Child_Account_vod__c WHERE Child_Account_vod__c = :accountId];

        List<String> parentAccountIds = new List<String>();
        for (Child_Account_vod__c childRelationship : relatedChildAccountRecords) {
            parentAccountIds.add(childRelationship.Parent_Account_vod__c);
        }

        return parentAccountIds;
    }

    private Set<String> getUserAccessibleAddressQueryFields() {
        Set<String> userAccessibleFields = new Set<String>();
        Schema.DescribeSObjectResult addressDescribe = Address_vod__c.getSObjectType().getDescribe();
        if (addressDescribe.isAccessible() && addressDescribe.isQueryable()) {
            Map<String, Schema.SObjectField> addressFieldDefinitions = addressDescribe.fields.getMap();
            for (String field : ADDRESS_QUERY_FIELDS) {
                String strippedFieldName = field.startsWith('toLabel') ? field.substringBetween('(', ')') : field;
                Schema.SObjectField fieldDefinition = addressFieldDefinitions.get(strippedFieldName);
                if (fieldDefinition != null && fieldDefinition.getDescribe().isAccessible()) {
                    userAccessibleFields.add(field);
                }
            }
        }
        return userAccessibleFields;        
    }

    private List<Account_Territory_Loader_vod__c> getOrCreateATLRecordForAccounts(List<String> accountIds) {
        List<Account_Territory_Loader_vod__c> accountATLRecords = [SELECT Id, Account_vod__c, Territory_vod__c, Territory_To_Add_vod__c FROM Account_Territory_Loader_vod__c WHERE Account_vod__c IN :accountIds];
        Map<String, Account_Territory_Loader_vod__c> accountToAtl = new Map<String, Account_Territory_Loader_vod__c>();
        for (Account_Territory_Loader_vod__c atl : accountATLRecords) {
            accountToAtl.put(atl.Account_vod__c, atl);
        }

        accountAtlRecords = new List<Account_Territory_Loader_vod__c>();
        for (String accountId : accountIds) {
            Account_Territory_Loader_vod__c atl = accountToAtl.get(accountId);
            if (atl == null) {
                atl = new Account_Territory_Loader_vod__c(
                    Account_vod__c=accountId
                );
            }
            accountATLRecords.add(atl);
        }
        return accountATLRecords;
    }

    private String getTerritoriesToAddForATL(List<Territory2> territories) {
        List<String> territoryNames = new List<String>();
        for (Territory2 territory : territories) {
            territoryNames.add(territory.Name);
        }
        return ';' + String.join(territoryNames, ';') + ';';
    }

    private Map<String, Set<String>> getAccountsToTerritoryIdMap(List<String> accountIds) {
        Map<String, Set<String>> accountToTerritoryIdMap = new Map<String, Set<String>>();

        for (ObjectTerritory2Association assocation : [SELECT Id, ObjectId, Territory2Id FROM ObjectTerritory2Association WHERE ObjectId in :accountIds]) {
            Set<String> terrForAcct = accountToTerritoryIdMap.get(assocation.ObjectId);
            if (terrForAcct == null) {
                accountToTerritoryIdMap.put(assocation.ObjectId, new Set<String>{assocation.Territory2Id});
            } else {
                terrForAcct.add(assocation.Territory2Id);
            }
        }

        return accountToTerritoryIdMap;
    }

    private Map<String, List<String>> getAccountsToTerritoryNameMap(List<String> accountIds) {
        Map<String, Set<String>> accountToTerritoryIdMap = new Map<String, Set<String>>();
        Set<String> relevantTerritoryIds = new Set<String>();

        for (ObjectTerritory2Association assocation : [SELECT Id, ObjectId, Territory2Id FROM ObjectTerritory2Association WHERE ObjectId in :accountIds]) {
            relevantTerritoryIds.add(assocation.Territory2Id);
            Set<String> terrForAcct = accountToTerritoryIdMap.get(assocation.ObjectId);
            if (terrForAcct == null) {
                accountToTerritoryIdMap.put(assocation.ObjectId, new Set<String>{assocation.Territory2Id});
            } else {
                terrForAcct.add(assocation.Territory2Id);
            }
        }

        Map<Id, Territory2> relevantTerritories = new Map<Id, Territory2>([SELECT Id, Name FROM Territory2 WHERE Id IN :relevantTerritoryIds]);
        Map<String, List<String>> accountToTerritoryNameMap = new Map<String, List<String>>();
        for (String accountId : accountToTerritoryIdMap.keySet()) {
            List<String> territoryNames = new List<String>();
            for (String territoryId : accountToTerritoryIdMap.get(accountId)) {
                territoryNames.add(relevantTerritories.get(territoryId).Name);
            }
            accountToTerritoryNameMap.put(accountId, territoryNames);
        }

        return accountToTerritoryNameMap;
    }
}