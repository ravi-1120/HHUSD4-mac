public class MRK_VisibilityRuleRecordGateway{
    
    /* Copyright, 2016 MERCK & CO, INC., Kevin Brace ALL RIGHTS RESERVED */

    public static List<Id> retrieveUsersAssociatedToVisibilityRuleRecordsSalesTeams(List<Visibility_Rule_Record_MRK__c> visibilityRuleRecordList){
       
        
       List <Id> associatedVisibilityRuleIdList = new List <Id>();
               
       for (Visibility_Rule_Record_MRK__c vrr : visibilityRuleRecordList){
          associatedVisibilityRuleIdList.add(vrr.Visibility_Rule_MRK__c);
       }

       /* get a list of all the sales teams impacted by the new Rules and 
          pull back the Users impacted...
       */
        
        List<Visibility_Rule_MRK__c> visibilityRuleList = new List<Visibility_Rule_MRK__c>(
           [SELECT Visibility_Rule_MRK__c.Name, Visibility_Rule_MRK__c.Id,
                   (SELECT Sales_Team_MRK__c FROM 
                     Visibility_Rule_Sales_Teams__r)
            FROM   Visibility_Rule_MRK__c 
            WHERE  Id in :associatedVisibilityRuleIdList]);

        //Pull out all the Sales Teams Impacted....
        Set <Id> salesTeams = new Set <Id>();
        
        for (Visibility_Rule_MRK__c vr : visibilityRuleList){
           List <Visibility_Rule_Sales_Team_MRK__c> vrst= vr.Visibility_Rule_Sales_Teams__r;
            
            for (Visibility_Rule_Sales_Team_MRK__c salesTeam : vrst){ 
                salesTeams.add(salesTeam.Sales_Team_MRK__c);
            }
        }
        
        List<Id> salesTeamIdList = new List<Id>();
        
        for (Id stId: salesTeams){
            salesTeamIdList.add(stId);
        }
        
        //Now, select all the Users from the User Sales Team Object that are associated to the SalesTeams...
        List<MSD_CORE_User_Sales_Team_DO> users = new List<MSD_CORE_User_Sales_Team_DO>();
        users = MRK_UserSalesTeamGateway.retrieveUsersAssociatedToSalesTeamList(salesTeamIdList);
                    
        List<Id> idList = new List<Id>();
        
        for (MSD_CORE_User_Sales_Team_DO user : users){
           idList.add(user.User_MRK);
        }
        
        return idList;

    }
    
    public static List<Visibility_Rule_Record_MRK__c> retrieveVisibilityRuleRecordsAssociatedtoObjectIds(List<Id> objectIds)
	{
      
        List <Visibility_Rule_Record_MRK__c> tmp = new List<Visibility_Rule_Record_MRK__c>();
        
        
        try{ 
              tmp = new List<Visibility_Rule_Record_MRK__c>(
              [SELECT Visibility_Rule_Record_MRK__c.Object_Id__c,
                      Visibility_Rule_Record_MRK__c.Name,
                      Visibility_Rule_Record_MRK__c.Visibility_Rule_MRK__c
               FROM   Visibility_Rule_Record_MRK__c 
               WHERE  Visibility_Rule_Record_MRK__c.Object_Id__c in : objectIds ]
             );	    
        
        }catch(DmlException e){
            System.debug('Error in retrieveVisibilityRuleRecordsAssociatedtoObjectIds: ' + e.getMessage());
            MRK_VisibilityUtility.createErrorRecord( e.getMessage());     
        }catch(Exception e){
            System.debug('Error in retrieveVisibilityRuleRecordsAssociatedtoObjectIds: ' + e.getMessage());
            MRK_VisibilityUtility.createErrorRecord( e.getMessage()); 
        
        }
        
        return tmp;
    }
    
}