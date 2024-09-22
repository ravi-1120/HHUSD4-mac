public class PreferencesUtil {

    @future

    public static void createPreferences(Id usersid) {

 List<Preferences_vod__c> pref = new List<Preferences_vod__c>(); 

        Preferences_vod__c pvc= new Preferences_vod__c( OwnerId = usersid, User_vod__c = usersid, Type_vod__c = 'User', Event_Country_Config_vod__c  = 'US;0', Event_Management_User_vod__c  = true );        
       pref.add(pvc);
        
        insert pref;

    }

}