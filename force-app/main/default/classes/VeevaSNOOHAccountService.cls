public inherited sharing class VeevaSNOOHAccountService {

    public static VeevaSNOOHAccountResponse getOOHAccountResponse(VeevaSNOOHAccountRequest outOfHierarchyAccountRequest) {

        VeevaSNOOHAccountResponse outOfHierarchyAccountResponse = new VeevaSNOOHAccountResponse();
        outOfHierarchyAccountResponse.originAccountId = outOfHierarchyAccountRequest.originAccountId;

        Set<Id> accountIdSet = new Set<Id>();
        for (String accountId : outOfHierarchyAccountRequest.accountIds) {
            accountIdSet.add(accountId);
        }

        Map<Id, VeevaSNAccount> snAccountsById = VeevaSNQueryService.queryAccountObjects(accountIdSet, outOfHierarchyAccountRequest.accountFields);
      
        Map<Id, Set<String>> accountToTerritoryMap = VeevaSNQueryService.getAccountToTerritoryMap(accountIdSet);
        VeevaGASUserAccess userAccess = new VeevaGASUserAccess();
        Set<Id> inTerrAccts = userAccess.getUserAccessibleAccountIds(accountIdSet);

        List<VeevaSNAccount> res = new List<VeevaSNAccount>();
        for (String accountId : accountIdSet) {
            VeevaSNAccount snAccount = snAccountsById.get(accountId);
            snAccount.Territories = new List<String>(accountToTerritoryMap.get(accountId));
            snAccount.isInTerritory = inTerrAccts.contains(accountId);
            res.add(snAccount);
        }

        outOfHierarchyAccountResponse.accounts = res;
        return outOfHierarchyAccountResponse;
    }
}