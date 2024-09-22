public without sharing class VeevaEngageProfileTriggerHandler extends VeevaTriggerHandler {    
    private List<Engage_Profile_vod__c> newEngageProfiles = new List<Engage_Profile_vod__c>();
    private List<Engage_Profile_vod__c> oldEngageProfiles = new List<Engage_Profile_vod__c>();
    private Map<Id, Engage_Profile_vod__c> newEngageProfilesMap = new Map<Id, Engage_Profile_vod__c>();
    private Map<Id, Engage_Profile_vod__c> oldEngageProfilesMap = new Map<Id, Engage_Profile_vod__c>();

    private final String NO_PROFILE_ASSOCIATED_VOD = 'No_Profile_Associated_vod';
    private final String PROFILE_ASSOCIATED_VOD = 'Profile_Associated_vod';
    private final STRING ACTIVE_VOD = 'Active_vod';

    Map<Id, Account> acctsToUpsert = new Map<Id, Account>();
    Set<Id> acctsToQuery = new Set<Id>();
    Set<Id> profilesToIgnore = new Set<Id>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.newEngageProfiles = (List<Engage_Profile_vod__c>) triggerNew;
        this.oldEngageProfiles = (List<Engage_Profile_vod__c>) triggerOld;
        this.newEngageProfilesMap = (Map<Id, Engage_Profile_vod__c>) triggerNewMap;
        this.oldEngageProfilesMap = (Map<Id, Engage_Profile_vod__c>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'Engage_Profile_vod__c';
    }

    protected override void beforeInsert() {
        handleEngageProfileStatusInsert();
    }

    protected override void beforeUpdate() {
        handleEngageProfileStatusUpdate();
    }

    protected override void afterDelete() {
        handleEngageProfileStatusDelete();
    }

    private void handleEngageProfileStatusInsert(){
        for(Engage_Profile_vod__c profile : this.newEngageProfiles){
            Id profileAcct = profile.Account_vod__c;

            if(acctsToUpsert.containsKey(profileAcct)){
                continue;
            } else if(profileHasActiveConnection(profile) && profileAcct != null) {
                acctsToUpsert.put(profileAcct, createAcctToUpsert(profileAcct, PROFILE_ASSOCIATED_VOD));
                acctsToQuery.remove(profileAcct);
            } else {
                acctsToQuery.add(profileAcct);
                profilesToIgnore.add(profile.Id);
            }
        }

        setQueryAcctsEPStatus();
    }

    private void handleEngageProfileStatusUpdate(){
        for(Engage_Profile_vod__c profile : this.newEngageProfiles){
            Id profileAcct = profile.Account_vod__c;

            Engage_Profile_vod__c oldProfile = this.oldEngageProfilesMap.get(profile.Id); 
            if(profileAcct != oldProfile.Account_vod__c){ // Check if account switched
                acctsToQuery.add(oldProfile.Account_vod__c);
                profilesToIgnore.add(oldProfile.Id); 
            }

            if(acctsToUpsert.containsKey(profileAcct)){
                continue;
            } else if(profileHasActiveConnection(profile) && profileAcct != null) {
                acctsToUpsert.put(profileAcct, createAcctToUpsert(profileAcct, PROFILE_ASSOCIATED_VOD));
                acctsToQuery.remove(profileAcct);
            } else {
                acctsToQuery.add(profileAcct);
                profilesToIgnore.add(profile.Id);
            }
        }

        setQueryAcctsEPStatus();
    }

    private void handleEngageProfileStatusDelete(){
        for(Engage_Profile_vod__c profile : this.oldEngageProfiles){
            acctsToQuery.add(profile.Account_vod__c);
            profilesToIgnore.add(profile.Id);
        }

        setQueryAcctsEPStatus();
    }

    private void setQueryAcctsEPStatus(){
        Map<Id, Account> updatedAccounts = updateRelatedProfileAccts();
        acctsToUpsert.putAll(updatedAccounts);
        Database.update((List<Account>) acctsToUpsert.values(), false);
    }

    private Map<Id, Account> updateRelatedProfileAccts(){
        Map<Id, Account> updatedAccts = new Map<Id, Account>();
        acctsToQuery.remove(null);
        profilesToIgnore.remove(null);

        if(acctsToQuery.isEmpty()){
            return updatedAccts;
        }

        List<Account> queriedAccts = queryForEngageProfileFromAccount();
        for(Account acct : queriedAccts) {
            String epStatus = (acct.Engage_Profile_vod__r.isEmpty()) ? NO_PROFILE_ASSOCIATED_VOD : PROFILE_ASSOCIATED_VOD;
            updatedAccts.put(acct.Id, createAcctToUpsert(acct.Id, epStatus));
        }
    
        return updatedAccts;
    }

    private Account createAcctToUpsert(Id accountID, String epStatus){
        return new Account(Id=accountID, Engage_Profile_Status_vod__c=epStatus);
    }

    private List<Account> queryForEngageProfileFromAccount(){
        return [SELECT (SELECT Connection_Status_vod__c FROM Engage_Profile_vod__r WHERE Connection_Status_vod__c=:ACTIVE_VOD AND Id not in :profilesToIgnore LIMIT 1) FROM Account WHERE Id in :acctsToQuery];
    }

    private boolean profileHasActiveConnection(Engage_Profile_vod__c profile){
        return (profile.isSet('Connection_Status_vod__c') && profile.Connection_Status_vod__c == ACTIVE_VOD);
    }
}