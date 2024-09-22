public inherited sharing class VeevaMyAccountsPreferences {

    @AuraEnabled
    public Id preferencesId { get; private set; }

    @AuraEnabled
    public VeevaMyAccountsBaseView view { get; private set; }

    @AuraEnabled
    public List<VeevaUserTerritory> territories { get; private set; }

    public VeevaMyAccountsPreferences(Id preferencesId, VeevaMyAccountsBaseView view, List<VeevaUserTerritory> territories) {
        this.preferencesId = preferencesId;
        this.view = view;
        this.territories = territories;
    }
}