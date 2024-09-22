public inherited sharing class VeevaSNAccountBatchService {

    public static VeevaSNAccountBatch getAccountBatchResponse(String batchId, List<String> snAccountIds, List<String> accountFields, List<String> affiliationFields) {

        // first let's query for our account information
        VeevaSNAccountBatch accountBatchResponse = new VeevaSNAccountBatch();
        accountBatchResponse.batchId = batchId;

        Set<Id> accountIds = translateStakeholderUIDs(snAccountIds);
        accountBatchResponse.accounts = queryAndFormAccountObjects(accountIds, snAccountIds, accountFields);
        
        try {
            accountBatchResponse = addAffiliationsToResult(accountBatchResponse, accountIds, affiliationFields);
        } catch(Exception e) {
            //affiliation object access is not required for SN to load
            //SN will simply load with no affiliations
            System.debug('No access to Affiliation Object');
        }

        return accountBatchResponse;
    }

    private static List<VeevaSNAccount> queryAndFormAccountObjects(Set<Id> accountIds, List<String> snAccountIds, List<String> accountFields) {

        Map<Id, VeevaSNAccount> snAccountsById = VeevaSNQueryService.queryAccountObjects(accountIds, accountFields);
      
        Map<Id, Set<String>> accountToTerritoryMap = VeevaSNQueryService.getAccountToTerritoryMap(accountIds);
        VeevaGASUserAccess userAccess = new VeevaGASUserAccess();
        Set<Id> inTerrAccts = userAccess.getUserAccessibleAccountIds(accountIds);
      
        // set territory related fields of accounts
        List<VeevaSNAccount> res = new List<VeevaSNAccount>();
        for (String snAccountId : snAccountIds) {

            List<String> accParentSplit = snAccountId.split('-');
            String acctId = accParentSplit.get(0);
            String parentId = accParentSplit.get(1);
            VeevaSNAccount snAccount = snAccountsById.get(acctId);

            snAccount.parentId = parentId;
            snAccount.Territories = new List<String>(accountToTerritoryMap.get(acctId));
            snAccount.isInTerritory = inTerrAccts.contains(acctId);
            res.add(snAccount);
        }
      
        return res;
    }
      
    private static Set<Id> translateStakeholderUIDs(List<String> snAccountIds) {
        Set<Id> accountIds = new Set<Id>();
        for (String account : snAccountIds) {
            accountIds.add(String.escapeSingleQuotes(account.split('-')[0]));
        }
        return accountIds;
    }

    private static VeevaSNAccountBatch addAffiliationsToResult(VeevaSNAccountBatch batchResult, Set<Id> accountIds, List<String> affFields) {
        //first do Affiliation OLS check as this class runs with elevated permissions
        Integer affLimit = 47000;
        DescribeSobjectResult affObj = Affiliation_vod__c.sObjectType.getDescribe();
        if (!affObj.isQueryable() || !affObj.isAccessible()) {
            return batchResult;
        }
        affFields = prepareAffiliationFields(affFields, affObj);
        String queryString = buildAffiliationQueryString(affFields, accountIds, affLimit);
        List<Affiliation_vod__c> affs = Database.query(queryString);
        if (affs.size() >= affLimit) {
            batchResult.limitTriggered = true;
        }
        batchResult.affiliations = affs;
        return batchResult;
    }
      
    private static List<String> prepareAffiliationFields(List<String> inputAffFields, DescribeSobjectResult affObj) {

        if (inputAffFields == null || inputAffFields.size() == 0) {
            inputAffFields =  new List<String> {
                'Id', 'From_Account_vod__c', 'To_Account_vod__c', 'Influence_vod__c', 'Relationship_Strength_vod__c',
                'Role_vod__c', 'Therapeutic_Area_vod__c', 'Comments_vod__c'
            };
        }

        VeevaBaseObject affBaseObject = (VeevaBaseObject.create(Affiliation_vod__c.sObjectType));
        return new List<String>(affBaseObject.getAccessibleFields(new Set<String> (inputAffFields)));
    }
      
    private static String buildAffiliationQueryString(List<String> fields, Set<Id> ids, Integer queryLimit) {
        return String.format('SELECT {0} FROM Affiliation_vod__c WHERE From_Account_vod__c IN ({1}) LIMIT {2}', new List<Object>{
                String.join(fields, ','), 
                '\'' + String.join(new List<Id>(ids), '\',\'') + '\'',
                queryLimit
            });
    }
}