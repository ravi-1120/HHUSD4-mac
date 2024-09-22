public inherited sharing class VeevaRemoveFromTerritoryAlignmentData {

    private Map<String, ObjectTerritory2Association> accountTerritoryToAlignment;
    private Map<Id, Account_Territory_Loader_vod__c> accountToATL;

    public VeevaRemoveFromTerritoryAlignmentData(Set<Id> accountIds, Set<String> territoryIds) {
        this.accountTerritoryToAlignment = new Map<String, ObjectTerritory2Association>();
        List<ObjectTerritory2Association> accountTerritoryAlignments = 
            [SELECT Id, Territory2Id, ObjectId, Territory2.Name FROM ObjectTerritory2Association WHERE Territory2Id IN :territoryIds AND ObjectId IN :accountIds AND AssociationCause = 'Territory2Manual'];
        for (ObjectTerritory2Association alignment : accountTerritoryAlignments) {
            // Joint key of the account and territory ID for the alignment to map to the corresponding OT2A
            String accountTerritoryKey = String.valueOf(alignment.ObjectId) + ':' + String.valueOf(alignment.Territory2Id);
            this.accountTerritoryToAlignment.put(accountTerritoryKey, alignment);
        }

        this.accountToATL = new Map<Id, Account_Territory_Loader_vod__c>();
        List<Account_Territory_Loader_vod__c> atls = [SELECT Id, Account_vod__c, Territory_vod__c FROM Account_Territory_Loader_vod__c WHERE Account_vod__c IN :accountIds];
        for (Account_Territory_Loader_vod__c atl : atls) {
            this.accountToATL.put(atl.Account_vod__c, atl);
        }
    }

    public ObjectTerritory2Association getAlignment(Id accountId, String territoryId) {
        String accountTerritoryKey = String.valueOf(accountId) + ':' + territoryId;
        return this.accountTerritoryToAlignment.remove(accountTerritoryKey);
    }

    public Account_Territory_Loader_vod__c getATL(Id accountId) {
        return this.accountToATL.get(accountId);
    }
}