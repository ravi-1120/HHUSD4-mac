/* 
 * Trigger: MSD_CORE_Event_User
 * 
 * This Class implments the Singleton Pattern to help limit the SOQL Queries needed for User information. 
 * 
 * Author: Kevin Brace
 * 
 * Change Log: 
 * KRB 6/11/2019 - Initial Version
*/

public class MSD_CORE_Event_User {
    
    private static MSD_CORE_Event_User instance = null;
    public String profileName {get;private set;} 

    private MSD_CORE_Event_User(){
        profileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;
    }
    
    public static MSD_CORE_Event_User getInstance(){
        if(instance == null) instance = new MSD_CORE_Event_User();
        return instance;
    }
}