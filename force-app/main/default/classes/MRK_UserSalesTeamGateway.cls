public class MRK_UserSalesTeamGateway {

    /* Copyright, 2016 MERCK & CO, INC., Kevin Brace ALL RIGHTS RESERVED */
  
    
    //US Instance
    
    public static List<MSD_CORE_User_Sales_Team_DO> retrieveUserSalesTeamRecordsbyUserId(List<Id> userIdList){
   
        List<MSD_CORE_User_Sales_Team_DO> temp = new List<MSD_CORE_User_Sales_Team_DO>(); 
         
        List<User_Sales_Team_MRK__c> ustList = new List<User_Sales_Team_MRK__c>(
           [SELECT User_MRK__c, sales_team_MRK__c
            FROM   User_Sales_Team_MRK__c 
            WHERE  User_MRK__c in :userIdList]);
         
         if (!ustList.isEmpty()){
             for(User_Sales_Team_MRK__c x: ustList){
                 MSD_CORE_User_Sales_Team_DO ustdo = new MSD_CORE_User_Sales_Team_DO();
                 ustdo.sales_team_MRK = x.Sales_Team_MRK__c;
                 ustdo.User_MRK = x.User_MRK__c;
                 temp.add(ustdo);
             }
             
         }
        
        return temp;
         
     }
     
     public static List<MSD_CORE_User_Sales_Team_DO> retrieveUserSalesTeamListOfUsersHavingMoreThanOneSalesTeamAssignedbyUserIdList(List<Id> userIdList){
    
         list<Id> userIds = new List <Id>();  
         List<MSD_CORE_User_Sales_Team_DO> ustList = new List<MSD_CORE_User_Sales_Team_DO>();
         
         AggregateResult[] groupedResults = 
             [SELECT User_MRK__c, count(Id)
              FROM   User_Sales_Team_MRK__c 
              WHERE  User_MRK__c in :userIdList
              Group By User_MRK__c];
         
        for (AggregateResult ar : groupedResults)  {
            if ((Integer)ar.get('expr0') > 1 ){
                userIds.add((Id)ar.get('User_MRK__c'));
            }         
        }
         
         if (!userIds.isEmpty()){
            ustList = retrieveUserSalesTeamRecordsbyUserId(userIds);
             
         }
         
        return ustList;

     }
    
     public static List<MSD_CORE_User_Sales_Team_DO> retrieveUsersAssociatedToSalesTeamList(List<Id> salesTeamIdList){
        
        List<MSD_CORE_User_Sales_Team_DO> temp = new List<MSD_CORE_User_Sales_Team_DO>(); 
         
        List<User_Sales_Team_MRK__c> users = new List<User_Sales_Team_MRK__c>(
           [SELECT User_MRK__c, Sales_Team_MRK__c
            FROM   User_Sales_Team_MRK__c
            WHERE  Sales_Team_MRK__c in : salesTeamIdList]);
        
        if (!users.isEmpty()){
           for(User_Sales_Team_MRK__c x: users){
               MSD_CORE_User_Sales_Team_DO ustdo = new MSD_CORE_User_Sales_Team_DO();
               ustdo.sales_team_MRK = x.Sales_Team_MRK__c;
               ustdo.User_MRK = x.User_MRK__c;
               temp.add(ustdo);
           }
        }
 
       return temp;
     
     }
        
     public static List<MSD_CORE_User_Sales_Team_DO> retrieveUsersAssociatedToSalesTeamId(Id salesTeamId){

        List<MSD_CORE_User_Sales_Team_DO> temp = new List<MSD_CORE_User_Sales_Team_DO>(); 

        List<User_Sales_Team_MRK__c> users = new List<User_Sales_Team_MRK__c>();
        users = new List<User_Sales_Team_MRK__c>(
           [SELECT User_MRK__c, Sales_Team_MRK__c
            FROM   User_Sales_Team_MRK__c
            WHERE  Sales_Team_MRK__c = : salesTeamId]);

        if (!users.isEmpty()){
           for(User_Sales_Team_MRK__c x: users){
               MSD_CORE_User_Sales_Team_DO ustdo = new MSD_CORE_User_Sales_Team_DO();
               ustdo.sales_team_MRK = x.Sales_Team_MRK__c;
               ustdo.User_MRK = x.User_MRK__c;
               temp.add(ustdo);
           }
        }
         
        return temp;
     
     }
    
     //US Instance -  End
    
    //Global Instance - Start
    /*
        public static List<MSD_CORE_User_Sales_Team_DO> retrieveUserSalesTeamRecordsbyUserId(List<Id> userIdList){
   
        List<MSD_CORE_User_Sales_Team_DO> temp = new List<MSD_CORE_User_Sales_Team_DO>(); 
         
        List<MSD_CORE_User_Sales_Team__c> ustList = new List<MSD_CORE_User_Sales_Team__c>(
           [SELECT MSD_CORE_User__c, MSD_CORE_Sales_Team__c 
            FROM   MSD_CORE_User_Sales_Team__c 
            WHERE  MSD_CORE_User__c in :userIdList]);
         
         if (!ustList.isEmpty()){
             for(MSD_CORE_User_Sales_Team__c x: ustList){
                 MSD_CORE_User_Sales_Team_DO ustdo = new MSD_CORE_User_Sales_Team_DO();
                 ustdo.sales_team_MRK = x.MSD_CORE_Sales_Team__c;
                 ustdo.User_MRK = x.MSD_CORE_User__c;
                 temp.add(ustdo);
             }
             
         }
        
        return temp;
         
     }
     
     public static List<MSD_CORE_User_Sales_Team_DO> retrieveUserSalesTeamListOfUsersHavingMoreThanOneSalesTeamAssignedbyUserIdList(List<Id> userIdList){
    
         list<Id> userIds = new List <Id>();  
         List<MSD_CORE_User_Sales_Team_DO> ustList = new List<MSD_CORE_User_Sales_Team_DO>();
         
         AggregateResult[] groupedResults = 
             [SELECT MSD_CORE_User__c, count(Id)
              FROM   MSD_CORE_User_Sales_Team__c 
              WHERE  MSD_CORE_User__c in :userIdList
              Group By MSD_CORE_User__c];
         
        for (AggregateResult ar : groupedResults)  {
            if ((Integer)ar.get('expr0') > 1 ){
                userIds.add((Id)ar.get('MSD_CORE_User__c'));
            }         
        }
         
         if (!userIds.isEmpty()){
            ustList = retrieveUserSalesTeamRecordsbyUserId(userIds);
             
         }
         
        return ustList;

     }
    
     public static List<MSD_CORE_User_Sales_Team_DO> retrieveUsersAssociatedToSalesTeamList(List<Id> salesTeamIdList){
        
        List<MSD_CORE_User_Sales_Team_DO> temp = new List<MSD_CORE_User_Sales_Team_DO>(); 
         
        List<MSD_CORE_User_Sales_Team__c> users = new List<MSD_CORE_User_Sales_Team__c>(
           [SELECT MSD_CORE_User__c, MSD_CORE_Sales_Team__c
            FROM   MSD_CORE_User_Sales_Team__c
            WHERE  MSD_CORE_Sales_Team__c in : salesTeamIdList]);
        
        if (!users.isEmpty()){
           for(MSD_CORE_User_Sales_Team__c x: users){
               MSD_CORE_User_Sales_Team_DO ustdo = new MSD_CORE_User_Sales_Team_DO();
               ustdo.sales_team_MRK = x.MSD_CORE_Sales_Team__c;
               ustdo.User_MRK = x.MSD_CORE_User__c;
               temp.add(ustdo);
           }
        }
 
       return temp;
     
     }
        
     public static List<MSD_CORE_User_Sales_Team_DO> retrieveUsersAssociatedToSalesTeamId(Id salesTeamId){

        List<MSD_CORE_User_Sales_Team_DO> temp = new List<MSD_CORE_User_Sales_Team_DO>(); 

        List<MSD_CORE_User_Sales_Team__c> users = new List<MSD_CORE_User_Sales_Team__c>();
        users = new List<MSD_CORE_User_Sales_Team__c>(
           [SELECT MSD_CORE_User__c, MSD_CORE_Sales_Team__c
            FROM   MSD_CORE_User_Sales_Team__c
            WHERE  MSD_CORE_Sales_Team__c = : salesTeamId]);

        if (!users.isEmpty()){
           for(MSD_CORE_User_Sales_Team__c x: users){
               MSD_CORE_User_Sales_Team_DO ustdo = new MSD_CORE_User_Sales_Team_DO();
               ustdo.sales_team_MRK = x.MSD_CORE_Sales_Team__c;
               ustdo.User_MRK = x.MSD_CORE_User__c;
               temp.add(ustdo);
           }
        }
         
        return temp;
     
     }
*/
    
    
    //Global Instance - End    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
   
  /* Old Methods to Retire    
     public static List<User_Sales_Team_MRK__c> retrieveUserSalesTeamRecordsbyUserId(List<Id> userIdList){
   
        List<User_Sales_Team_MRK__c> ustList = new List<User_Sales_Team_MRK__c>(
           [SELECT User_MRK__c, sales_team_MRK__c
            FROM   User_Sales_Team_MRK__c 
            WHERE  User_MRK__c in :userIdList]);
        
        return ustList;
         
     }
     
     public static List<User_Sales_Team_MRK__c> retrieveUserSalesTeamListOfUsersHavingMoreThanOneSalesTeamAssignedbyUserIdList(List<Id> userIdList){
    
         list<Id> userIds = new List <Id>();  
         List<User_Sales_Team_MRK__c> ustList = new List<User_Sales_Team_MRK__c>();
         
         AggregateResult[] groupedResults = 
             [SELECT User_MRK__c, count(Id)
              FROM   User_Sales_Team_MRK__c 
              WHERE  User_MRK__c in :userIdList
              Group By User_MRK__c];
         
        for (AggregateResult ar : groupedResults)  {
            if ((Integer)ar.get('expr0') > 1 ){
                userIds.add((Id)ar.get('User_MRK__c'));
            }         
        }
         
         if (!userIds.isEmpty()){
            ustList = retrieveUserSalesTeamRecordsbyUserId(userIds);
         }
         
        return ustList;

     }
    
     public static List<User_Sales_Team_MRK__c> retrieveUsersAssociatedToSalesTeamList(List<Id> salesTeamIdList){
     
        List<User_Sales_Team_MRK__c> users = new List<User_Sales_Team_MRK__c>(
           [SELECT User_MRK__c, Sales_Team_MRK__c//, MSD_CORE_Country_Code__c
            FROM   User_Sales_Team_MRK__c
            WHERE  Sales_Team_MRK__c in : salesTeamIdList]);
        
        return users;
     
     }
        
     public static List<User_Sales_Team_MRK__c> retrieveUsersAssociatedToSalesTeamId(Id salesTeamId){
    
        List<User_Sales_Team_MRK__c> users = new List<User_Sales_Team_MRK__c>();
        users = new List<User_Sales_Team_MRK__c>(
           [SELECT User_MRK__c, Sales_Team_MRK__c
            FROM   User_Sales_Team_MRK__c
            WHERE  Sales_Team_MRK__c = : salesTeamId]);
        
        return users;
     
     }
    
*/
     

}