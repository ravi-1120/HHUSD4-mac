public with sharing class VeevaSNInitData {
    @AuraEnabled public Id graphRootId { get; private set; }
    @AuraEnabled public List<Id> keyStakeholders { get; private set; }
    @AuraEnabled public Map<String, String> veevaMessages { get; private set; }
    @AuraEnabled public List<Map<String, String>> userTerritories { get; private set; }
    @AuraEnabled public VeevaSNCustomDisplayOverrides displayFieldOverrides { get; private set; }
    @AuraEnabled public Map<String, Object> appConfigOverrides { get; private set;}

    public VeevaSNInitData(Id graphRootId, List<Id> keyStakeholders, Map<String, String> veevaMessages, List<Map<String, String>> userTerritories,
        VeevaSNCustomDisplayOverrides displayFieldOverrides, Boolean hasAccessToAffiliations, Boolean enableAffiliationView) {
            
        this.graphRootId = graphRootId;
        this.keyStakeholders = keyStakeholders;
        this.veevaMessages = veevaMessages;
        this.userTerritories = userTerritories;
        this.displayFieldOverrides = displayFieldOverrides;
        this.appConfigOverrides = new Map<String, Object>();
        appConfigOverrides.put('hasAccessToAffiliations', hasAccessToAffiliations);
        appConfigOverrides.put('enableAffiliationView', enableAffiliationView);
    }

    public VeevaSNInitData() {}
}