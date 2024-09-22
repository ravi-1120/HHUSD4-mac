/**
 * Class MRK_UserGateway
 *
 * Provides finder methods for accessing data in the User object.
 */
public class MRK_UserGateway
{
 
     public static List<User> findUsersAssociatedToSalesTeams(String salesTeamString)
	{
        List<User> tmp = new List<User>();
      
        try{ 
          System.debug('Debug: About to run the following Statement: ' + 'select Id, Sales_Team_MRK__c from Users where Sales_Team_MRK__c includes (' + salesTeamString + ')');
          
		  tmp =  Database.query('select Id, MSD_CORE_Country_Code__c,  Sales_Team_MRK__c from User where Sales_Team_MRK__c includes (' + salesTeamString + ')');
	    
        }catch(DmlException e){
            System.debug('Error in findUsersAssociatedToSalesTeams: ' + e.getMessage());
            MRK_VisibilityUtility.createErrorRecord( e.getMessage());     
        }catch(Exception e){
            System.debug('Error in findUsersAssociatedToSalesTeams: ' + e.getMessage());
            MRK_VisibilityUtility.createErrorRecord( e.getMessage()); 
        
        }
        
        return tmp;
        
    }
    
    //KRB 4/2016
    
    public static List<MSD_CORE_Visibility_Rule_Access_Levels__c> retrieveAllVisibilityRuleAccessLevelsByCountryCodesList(List <String> countryCodesList)
	{
      
        List <MSD_CORE_Visibility_Rule_Access_Levels__c> tmp = new List<MSD_CORE_Visibility_Rule_Access_Levels__c>();
        
        try{ 
              tmp = new List<MSD_CORE_Visibility_Rule_Access_Levels__c>(
              [SELECT MSD_CORE_Access_Level__c,
                      MSD_CORE_Country_Code__c,
                      Object_API_Name__c
               FROM   MSD_CORE_Visibility_Rule_Access_Levels__c
               WHERE  MSD_CORE_Country_Code__c in : countryCodesList]);	    
        
        }catch(DmlException e){
            System.debug('Error in retrieveAllVisibilityRuleAccessLevelsByCountryCodesList: ' + e.getMessage());
            MRK_VisibilityUtility.createErrorRecord( e.getMessage());     
        }catch(Exception e){
            System.debug('Error in retrieveAllVisibilityRuleAccessLevelsByCountryCodesList: ' + e.getMessage());
            MRK_VisibilityUtility.createErrorRecord( e.getMessage()); 
        
        }
        
        return tmp;
    }
    
    // KRB 4/2016
     public static Map<Id, User> retrieveUserCountryCodesMap(List<Id> userIds){
     
        Map<Id, User> users = new Map<Id, User>(
           [SELECT id, MSD_CORE_Country_Code__c
            FROM   User
            WHERE  id in : userIds]);
        
        return users;
     
     }


 
    
    

}