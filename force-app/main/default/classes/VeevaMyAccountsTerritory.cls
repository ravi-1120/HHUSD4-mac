public inherited sharing class VeevaMyAccountsTerritory {
    @AuraEnabled
    public String id { get; private set; }

    @AuraEnabled
    public String name { get; private set; }

    @AuraEnabled
    public String parentId { get; private set; }

    @AuraEnabled
    public String groupId { get; private set; }

    public VeevaMyAccountsTerritory(String territoryId, String territoryName, String parentTerritoryId, String groupId) {
        this.id = territoryId;
        this.name = territoryName;
        this.parentId = parentTerritoryId;
        this.groupId = groupId;
    }
}