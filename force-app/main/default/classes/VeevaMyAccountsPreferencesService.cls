public inherited sharing virtual class VeevaMyAccountsPreferencesService {

    private static final Set<String> REQUIRED_PREFERENCES_FIELDS_TO_READ = new Set<String>{
        'Last_Account_View_Used_vod__c', 'Last_Territory_Used_vod__c', 'User_vod__c'
    };

    private final VeevaMyAccountsService myAccountsService;
    private final VeevaBaseObject preferencesBaseObject;

    public VeevaMyAccountsPreferencesService(VeevaMyAccountsService myAccountsService) {
        this.myAccountsService = myAccountsService;
        this.preferencesBaseObject = VeevaBaseObject.create(Preferences_vod__c.getSObjectType());
    }

    public VeevaMyAccountsPreferences getMyAccountsUserPreference() {
        if (!doesUserHavePreferencesReadAccess() || !hasRequiredReadFLSForPreferences()) {
            return new VeevaMyAccountsPreferences(null, null, null);
        }
        Preferences_vod__c preferences = getPreferences();
        if (preferences == null) {
            return new VeevaMyAccountsPreferences(null, null, null);
        }

        List<VeevaUserTerritory> territories = null;
        if (!String.isBlank(preferences?.Last_Territory_Used_vod__c)) {
            VeevaUserTerritory territory = getTerritory(preferences.Last_Territory_Used_vod__c);
            if (territory != null) {
                territories = new List<VeevaUserTerritory>();
                territories.add(territory);
            }
        }

        return new VeevaMyAccountsPreferences(preferences?.Id, getLastView(preferences), territories);
    }

    private VeevaMyAccountsBaseView getLastView(Preferences_vod__c preferences) {
        Id viewId;
        if (hasLastViewVodFLS()) {
            viewId = preferences?.Last_View_Used_vod__c;
        } else {
           viewId = preferences?.Last_Account_View_Used_vod__c; 
        }

        if (viewId == null) {
            return null;
        }
        return myAccountsService.getViewDefinition(viewId, true);
    }

    protected virtual VeevaUserTerritory getTerritory(String territoryId) {
        List<Territory2> queriedTerritories = [SELECT Name FROM Territory2 WHERE Id = :territoryId];
        if (queriedTerritories.isEmpty()) {
            return null;
        }
        return new VeevaUserTerritory(territoryId, queriedTerritories.get(0).Name);
    }

    private Preferences_vod__c getPreferences() {
        Set<String> fieldsToQuery = new Set<String>(REQUIRED_PREFERENCES_FIELDS_TO_READ);
        if (hasLastViewVodFLS()) {
            fieldsToQuery.add('Last_View_Used_vod__c');
        }
        List<String> accessibleFields = new List<String>(getAccessibleFields(fieldsToQuery));

        Id userId = UserInfo.getUserId();
        List<Preferences_vod__c> preferences = Database.query(String.format(
            'SELECT {0} FROM Preferences_vod__c WHERE User_vod__c = :userId',
            new List<String>{String.join(accessibleFields, ',')}
        ));
        return preferences.isEmpty() ? null : preferences.get(0);
    }

    protected virtual Set<String> getAccessibleFields(Set<String> fields) {
        return preferencesBaseObject.getAccessibleFields(fields);
    }

    protected virtual boolean doesUserHavePreferencesReadAccess() {
        return preferencesBaseObject.getDescribe().isQueryable();
    }

    protected virtual boolean hasRequiredReadFLSForPreferences() {
        return preferencesBaseObject.getAccessibleFields(REQUIRED_PREFERENCES_FIELDS_TO_READ).size() == REQUIRED_PREFERENCES_FIELDS_TO_READ.size();
    }

    protected virtual boolean hasLastViewVodFLS() {
        return preferencesBaseObject.getAccessibleField('Last_View_Used_vod__c', false, false) != null;
    }
}