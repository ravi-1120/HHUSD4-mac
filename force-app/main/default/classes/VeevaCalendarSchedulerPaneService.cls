public with sharing class VeevaCalendarSchedulerPaneService {

    public static Id getSchedulerUserPreferences() {
        try {
            VeevaBaseObject preferenceObj = VeevaBaseObject.create('Preferences_vod__c');
            if (preferenceObj?.getAccessibleField('Last_Scheduler_Account_List_vod__c', false, false) != null) {
                List<Preferences_vod__c> preferences = [SELECT Last_Scheduler_Account_List_vod__c FROM Preferences_vod__c WHERE OwnerId = :UserInfo.getUserId()];
                Preferences_vod__c preference = preferences.size() > 0 ? preferences.get(0) : createPreferencesRecord();

                Id lastViewOrList = preference.Last_Scheduler_Account_List_vod__c;
                if (lastViewOrList != null) {
                    return lastViewOrList;
                }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static void setLastSchedulerAccountList(Id accountListId){
        try {
            VeevaBaseObject preferenceObj = VeevaBaseObject.create('Preferences_vod__c');
            if (preferenceObj?.getAccessibleField('Last_Scheduler_Account_List_vod__c', false, false) != null) {
                List<Preferences_vod__c> preferences = [SELECT Id, Last_Scheduler_Account_List_vod__c FROM Preferences_vod__c WHERE OwnerId = :UserInfo.getUserId()];
                Preferences_vod__c preference = preferences.size() > 0 ? preferences.get(0) : createPreferencesRecord();
                preference.Last_Scheduler_Account_List_vod__c = accountListId;
                update preference;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Preferences_vod__c createPreferencesRecord() {
        try {
            Preferences_vod__c preference = new Preferences_vod__c(User_vod__c = UserInfo.getUserId(), Type_vod__c = 'User');
            insert preference;
            return preference;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}