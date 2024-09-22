public inherited sharing class VeevaSNAffiliationViewDataService {

    public static VeevaSNAffiliationViewDataInitRequest getRootAccountDataWithRelatedAffiliationIds(String rootAccountId, List<String> accountFields) {

        // apex limit of 50,000 with cushion for the root account data we query for
        Integer AFFILIATION_ID_LIMIT = 49000;

        List<Affiliation_vod__c> affiliations = [Select Id from Affiliation_vod__c Where From_Account_vod__c = :rootAccountId LIMIT :AFFILIATION_ID_LIMIT];
        List<String> affiliationsIds = new List<String>();
        for (Affiliation_vod__c affiliation : affiliations) {
            affiliationsIds.add(affiliation.Id);
        }

        Set<Id> accountIdsToQuery = new Set<Id>{rootAccountId};

        Map<Id, Set<String>> accountToTerritoryMap = VeevaSNQueryService.getAccountToTerritoryMap(accountIdsToQuery);
        VeevaGASUserAccess userAccess = new VeevaGASUserAccess();
        Set<Id> inTerrAccts = userAccess.getUserAccessibleAccountIds(accountIdsToQuery);

        Map<Id, VeevaSNAccount> snAccountsById = VeevaSNQueryService.queryAccountObjects(accountIdsToQuery, accountFields);
        VeevaSNAccount rootAccountData = snAccountsById.get(rootAccountId);
        rootAccountData.Territories = new List<String>(accountToTerritoryMap.get(rootAccountId));
        rootAccountData.isInTerritory = inTerrAccts.contains(rootAccountId);

        VeevaSNAffiliationViewDataInitRequest response = new VeevaSNAffiliationViewDataInitRequest();
        response.rootAccountData = rootAccountData;
        response.rootsAffiliationIds = affiliationsIds;
        return response;
    }

    public static List<VeevaSNAffiliation> getRootAccountsAffiliationData(List<String> affiliationIdChunk, List<String> accountFields, List<String> affiliationFields) {

        VeevaBaseObject affiliationBaseObject = VeevaBaseObject.create('Affiliation_vod__c');
        List<String> affiliationFieldsToQuery = new List<String>(affiliationBaseObject.getAccessibleFields(new Set<String>(affiliationFields)));
        Map<String, Object> affiliationQueryBinds = new Map<String, Object>{'affiliationIds' => affiliationIdChunk};
        List<Affiliation_vod__c> affiliations = Database.queryWithBinds(buildAffiliationQueryString(affiliationFieldsToQuery), affiliationQueryBinds, AccessLevel.SYSTEM_MODE);
        Map<String, Affiliation_vod__c> affiliationIdToAffiliationMap = getAffiliationIdToAffiliationMap(affiliations);

        List<String> toAccountsToQuery = getToAccountIdsFromQueryResult(affiliations);
        Set<Id> toAccountsToQuerySet = new Set<Id>();
        for (String toAccountToQuery : toAccountsToQuery) {
            toAccountsToQuerySet.add(toAccountToQuery);
        }

        Map<Id, VeevaSNAccount> snAccountsById = VeevaSNQueryService.queryAccountObjects(toAccountsToQuerySet, accountFields);

        Map<Id, Set<String>> accountToTerritoryMap = VeevaSNQueryService.getAccountToTerritoryMap(toAccountsToQuerySet);
        VeevaGASUserAccess userAccess = new VeevaGASUserAccess();
        Set<Id> inTerrAccts = userAccess.getUserAccessibleAccountIds(toAccountsToQuerySet);

        // how many affiliations does each to_account have?
        List<AggregateResult> toAccountAffiliationCountList = [
          SELECT
            From_Account_vod__c,
            COUNT(Id) toAccountAffiliationCount
          FROM
            Affiliation_vod__c
          WHERE
            From_Account_vod__c IN :toAccountsToQuerySet
          GROUP BY From_Account_vod__c
        ];
        Map<String, Integer> accountIdToAffiliationCount = parseAggregateQueryResult(toAccountAffiliationCountList);

        List<VeevaSNAffiliation> rootAccountAffiliations = new List<VeevaSNAffiliation>();
        for (String affiliationId : affiliationIdToAffiliationMap.keySet()) {
            Affiliation_vod__c affiliationQueryResult = affiliationIdToAffiliationMap.get(affiliationId);
            VeevaSNAffiliation affiliation = new VeevaSNAffiliation();

            // affiliation data
            affiliation.id = affiliationId;
            Map<String, Object> fields = new Map<String, Object>();
            for (String queriedField : affiliationFieldsToQuery) {
                fields.put(queriedField, affiliationQueryResult.get(queriedField));
            }
            affiliation.fields = fields;

            // toAccount data
            affiliation.toAccount = snAccountsById.get(affiliationQueryResult.To_Account_vod__c);
            affiliation.toAccount.Territories = new List<String>(accountToTerritoryMap.get(affiliationQueryResult.To_Account_vod__c));
            affiliation.toAccount.isInTerritory = inTerrAccts.contains(affiliationQueryResult.To_Account_vod__c);

            // aggregate data (default to 0)
            Integer toAccountAffiliationCount = accountIdToAffiliationCount.get(affiliationQueryResult.To_Account_vod__c);
            affiliation.toAccountAffiliationCount = toAccountAffiliationCount != null ? toAccountAffiliationCount : 0;

            rootAccountAffiliations.add(affiliation);
        }

        return rootAccountAffiliations;
    }

    public static Map<String, Object> queryAccountDataWithRelatedAffiliationData(String accountId, List<String> accountFields) {
        Set<Id> accountsToQuerySet = new Set<Id>();
        accountsToQuerySet.add(accountId);
        Map<Id, VeevaSNAccount> snAccountsById = VeevaSNQueryService.queryAccountObjects(accountsToQuerySet, accountFields);

        Map<Id, Set<String>> accountToTerritoryMap = VeevaSNQueryService.getAccountToTerritoryMap(accountsToQuerySet);
        VeevaGASUserAccess userAccess = new VeevaGASUserAccess();
        Set<Id> inTerrAccts = userAccess.getUserAccessibleAccountIds(accountsToQuerySet);

        // how many affiliations does our account have?
        Integer affiliationCount = [SELECT COUNT() FROM Affiliation_vod__c WHERE From_Account_vod__c = :accountId];

        VeevaSNAccount toAccount = snAccountsById.get(accountId);
        toAccount.Territories = new List<String>(accountToTerritoryMap.get(accountId));
        toAccount.isInTerritory = inTerrAccts.contains(accountId);

        Map<String, Object> res = new Map<String, Object>();
        res.put('toAccount', toAccount);
        res.put('toAccountAffiliationCount', affiliationCount);
        return res;
    }

    private static String buildAffiliationQueryString(List<String> affiliationFieldsToQuery) {
        return String.format('SELECT {0} FROM Affiliation_vod__c WHERE Id IN : affiliationIds', new List<Object>{
            String.join(affiliationFieldsToQuery, ',') 
        });
    }

    private static Map<String, Affiliation_vod__c> getAffiliationIdToAffiliationMap(List<Affiliation_vod__c> affiliations) {
        Map<String, Affiliation_vod__c> res = new Map<String, Affiliation_vod__c>();
        for (Affiliation_vod__c affiliation : affiliations) {
            res.put(affiliation.Id, affiliation);
        }
        return res;
    }

    private static List<String> getToAccountIdsFromQueryResult(List<Affiliation_vod__c> affiliations) {
        List<String> res = new List<String>();
        for (Affiliation_vod__c affiliation : affiliations) {
            res.add(affiliation.To_Account_vod__c);
        }
        return res;
    }

    private static Map<String, Integer> parseAggregateQueryResult(List<AggregateResult> aggregateResults) {
        Map<String, Integer> res = new Map<String, Integer>();
        for (AggregateResult aggregateResult : aggregateResults) {
            res.put((String) aggregateResult.get('From_Account_vod__c'), (Integer) aggregateResult.get('toAccountAffiliationCount'));
        }
        return res;
    }
}