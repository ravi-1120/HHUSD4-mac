public class MRK_RuleGateway{
    
    /*
       KRB - 4/25/2014 REL 5.0 - Object Data Access Methods for the 
             Rule_MRK__c Object. 
    */

 
      /* 
      * KRB - 3/14/2014 - REL 5.1  
      */
    
      public static Integer retrieveCountofExistingActiveParentTerritoryProfileOverrides(Rule_MRK__c  ruleRecord){
        Integer ctOfExistingActiveProfileOverrides = 0;
        
        List <Rule_MRK__c> existingORs = new List <Rule_MRK__c>();
        
        List <String> territoryNameList = new List <String>();
        territoryNameList.add(ruleRecord.Territory_Name_MRK__c);
        List <Id> ruleIdList = new List <Id>();
        ruleIdList.add(ruleRecord.Id);

        
         existingORs = new List<Rule_MRK__c>(
         [SELECT Id
          FROM   Rule_MRK__c         
          WHERE  Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
          AND    Active_MRK__c = True
          AND    Territory_Name_MRK__c IN : territoryNameList
          AND    Id not in : ruleIdList
         ]);

        
        return existingORs.size();
        
    }

    
     /* 
      * KRB - 3/14/2014 - REL 5.0  
      */

    
    //Bug Fix: 5.0 #37 KRB 5/14/2014
    public static Integer retrieveCountofExistingActiveUserProfileOverrides(Rule_MRK__c  ruleRecord){
        Integer ctOfExistingActiveProfileOverrides = 0;
        
        List <Rule_MRK__c> existingORs = new List <Rule_MRK__c>();
        
        List <Id> userIdList = new List <Id>();
        userIdList.add(ruleRecord.User_MRK__c);
        List <Id> ruleIdList = new List <Id>();
        ruleIdList.add(ruleRecord.Id);

        
         existingORs = new List<Rule_MRK__c>(
         [SELECT Id
          FROM   Rule_MRK__c         
          WHERE  Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
          AND    Active_MRK__c = True
          AND    User_MRK__c IN : userIdList
          AND    Id not in : ruleIdList
         ]);

        
        return existingORs.size();
        
    }


    
     /* 
      * KRB - 3/14/2014 - REL 5.0  
      */

    //Bug Fix: 5.0 #37 KRB 5/14/2014
    public static Integer retrieveCountofExistingActiveSalesTeamProfileOverrides(Rule_MRK__c  ruleRecord){
        Integer ctOfExistingActiveProfileOverrides = 0;
        
        List <Rule_MRK__c> existingORs = new List <Rule_MRK__c>();
        
        List <Id> salesTeamIdList = new List <Id>();
        salesTeamIdList.add(ruleRecord.Sales_Team_MRK__c);
        List <Id> ruleIdList = new List <Id>();
        ruleIdList.add(ruleRecord.Id);

        
         existingORs = new List<Rule_MRK__c>(
         [SELECT Id
          FROM   Rule_MRK__c         
          WHERE  Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
          AND    Active_MRK__c = True
          AND    Sales_Team_MRK__c IN : salesTeamIdList
          AND    Id not in : ruleIdList
         ]);

        
        return existingORs.size();
        
    }
    
    
   /* KRB - 3/14/2014 - REL 5.0  
   */
    @future
    public static void setTerritoryRuleRecordsInactiveByTerritoryNameList(List<String> terrNames){
      
      List<Rule_MRK__c> ruleRecList = new list<Rule_MRK__c>();
    
      ruleRecList = new List<Rule_MRK__c>(
         [SELECT Id, Active_MRK__c
          FROM   Rule_MRK__c         
          WHERE  Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
          AND    Territory_Name_MRK__c IN : terrNames]);

        for(Rule_MRK__c terrRule : ruleRecList)  {
            terrRule.Active_MRK__c = false;
        } 
        
        MRK_RuleHelper.setBypassValidation();
        
        update ruleRecList;
        
        MRK_RuleHelper.deactivateBypassValidation();
        
        
    }

    
   /* KRB - 3/14/2014 - REL 5.0  
   */
 
    public static List<RULE_MRK__c> retrieveAllChildTerritoryProfileRecordsByParentId(List<Id> RuleIds){
      
      List<Rule_MRK__c> ruleRecList = new list<Rule_MRK__c>();
    
      ruleRecList = new List<Rule_MRK__c>(
         [SELECT Id, Active_MRK__c, Territory_Name_MRK__c
          FROM   Rule_MRK__c         
          WHERE  Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
          AND    Parent_Rule_Id_MRK__c IN : RuleIds]);

       return ruleRecList;
       
    }
    
    
   /* KRB - 3/14/2014 - REL 5.0  
   */

    public static Map<String, Integer> retrieveActiveTerritoryProfileOverRideCountByTerritoryCloneNames(List<String> territoryCloneNames){
        
       Map<String,Integer> countsByTerritoryCloneNameMap = new Map<String,Integer>();
       
       AggregateResult[] territoriesWithProfileOverrides
          = [SELECT Territory_Name_MRK__c,count(Id) 
             FROM   Rule_MRK__c
             WHERE  Active_MRK__c = true
             AND    Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
             AND    Territory_Name_MRK__c in : territoryCloneNames
             Group By Territory_Name_MRK__c];
        
       for (AggregateResult ar : territoriesWithProfileOverrides)  {
          //System.debug('User_MRK__c' + ar.get('User_MRK__c'));
          //System.debug('count' + ar.get('expr0'));
                     
          countsByTerritoryCloneNameMap.put((String)ar.get('Territory_Name_MRK__c'), (Integer)ar.get('expr0'));
       }
          return  countsByTerritoryCloneNameMap;
    }

    /*
    public static Map<Id, Integer> retrieveActiveTerritoryProfileOverRideCountByTerritoryCloneId(List<Id> territoryCloneIds){
        
       Map<Id,Integer> countsByTerritoryCloneIdMap = new Map<Id,Integer>();
       
       AggregateResult[] salesTeamsWithProfileOverrides
          = [SELECT Territory_MRK__c, count(Id) 
             FROM   Rule_MRK__c
             WHERE  Active_MRK__c = true
             AND    Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
             AND    Territory_MRK__c in : territoryCloneIds
             Group By Territory_MRK__c];
        
       for (AggregateResult ar : salesTeamsWithProfileOverrides)  {
          //System.debug('User_MRK__c' + ar.get('User_MRK__c'));
          //System.debug('count' + ar.get('expr0'));
                     
          countsByTerritoryCloneIdMap.put((Id)ar.get('Territory_MRK__c'), (Integer)ar.get('expr0'));
       }
          return  countsByTerritoryCloneIdMap;
    }
*/
    
   /* KRB - 3/14/2014 - REL 5.0  
   */
    
    public static Map<Id, Integer> retrieveActiveSalesteamProfileOverRideCountBySalesTeamId(List<Id> salesTeamIds){
        
       Map<Id,Integer> countsBySalesTeamIdMap = new Map<Id,Integer>();
       
       AggregateResult[] salesTeamsWithProfileOverrides
          = [SELECT Sales_Team_MRK__c, count(Id) 
             FROM   Rule_MRK__c
             WHERE  Active_MRK__c = true
             AND    Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
             AND    Sales_Team_MRK__c in : salesTeamIds
             Group By Sales_Team_MRK__c];
        
       for (AggregateResult ar : salesTeamsWithProfileOverrides)  {
                     
          countsBySalesTeamIdMap.put((Id)ar.get('Sales_Team_MRK__c'), (Integer)ar.get('expr0'));
       }
          return  countsBySalesTeamIdMap;
    }

   /* KRB - 3/14/2014 - REL 5.0   
   */
    
    public static Map<Id, Integer> retrieveActiveUserProfileOverRideCountByUserId(List<Id> userIds){
        
       Map<Id,Integer> countsByUserIdMap = new Map<Id,Integer>();
       
       AggregateResult[] usersWithProfileOverrides
          = [SELECT User_MRK__c, count(Id) 
             FROM   Rule_MRK__c
             WHERE  Active_MRK__c = true
             AND    Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
             AND    User_MRK__c in : userIds
             Group By User_MRK__c];
        
       for (AggregateResult ar : usersWithProfileOverrides)  {
          //System.debug('User_MRK__c' + ar.get('User_MRK__c'));
          //System.debug('count' + ar.get('expr0'));
                     
          countsByUserIdMap.put((Id)ar.get('User_MRK__c'), (Integer)ar.get('expr0'));
       }
          return  countsByUserIdMap;
    }
    
     
   /*
    * KRB 3/13/2014 REL 5.0 - retrieves Active Profile Override Rules by User Id List
    */
        
   public static List<Rule_MRK__c> retrieveActiveProfileOverrideRuleByUserIdList(List<Id> userIds){
      List<Rule_MRK__c> ruleRecList = new list<Rule_MRK__c>();
    
      ruleRecList = new List<Rule_MRK__c>(
         [SELECT Active_MRK__c,
                 RecordTypeId,
                 User_MRK__c
          FROM   Rule_MRK__c         
          WHERE  Active_MRK__c = true
          AND    Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
          AND    User_MRK__c IN : userIds]);

       return ruleRecList;
   }
  

   /*
    * KRB 3/13/2014 REL 5.0 - Updates Profile Override Type Rule Records to 
    * Inactive, given a list of User Ids
    */
   
   @future
   public static void updateActiveProfileOverrideRulestoInactiveByUserIdList(List<Id> userIds){
         
      List<Rule_MRK__c> ruleRecList = new list<Rule_MRK__c>();
    
      ruleRecList = new List<Rule_MRK__c>(
         [SELECT Id,
                 Active_MRK__c,
                 RecordTypeId,
                 User_MRK__c
          FROM   Rule_MRK__c         
          WHERE  Active_MRK__c = true
          AND    Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
          AND    User_MRK__c IN : userIds]);

       if (!ruleRecList.isEmpty()){
           for(Rule_MRK__c rule : ruleRecList){
               rule.Active_MRK__c = false;
           } 
           
           update ruleRecList;
       } 
   }

    
   /*
    * KRB 3/13/2014 REL 5.0 - Updates Profile Override Type Rule Records to 
    * Inactive, given a list of Sales Team Ids
    */
    
   public static void updateActiveProfileOverrideRulestoInactiveBySalesTeamIdList(List<Id> salesTeamIds){
         
      List<Rule_MRK__c> ruleRecList = new list<Rule_MRK__c>();
    
      ruleRecList = new List<Rule_MRK__c>(
         [SELECT Id,
                 Active_MRK__c,
                 RecordTypeId,
                 Sales_Team_MRK__c
          FROM   Rule_MRK__c         
          WHERE  Active_MRK__c = true
          AND    Record_Type_Name_MRK__c = 'MRK_RULE_PROFILE_OVERRIDE'
          AND    Sales_Team_MRK__c IN : salesTeamIds]);

       if (!ruleRecList.isEmpty()){
           for(Rule_MRK__c rule : ruleRecList){
               rule.Active_MRK__c = false;
           } 
           
           update ruleRecList;
           
       } 
   }
}