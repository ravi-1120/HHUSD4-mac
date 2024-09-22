public class MRK_RuleHandler implements MRK_ITrigger{
    
    /*
     * KRB - 3/19/2014 - REL 5.0 - Handler Class that is used to Process all 
     * Profile Overrides on the Rule_MRK__c Object. Override can be done at the 
     * following levels for Rel 5.0: Sales Team and User. REL 5.1 includes Territory.
     */
    
    
    /* Member Variables    */
    
    //Required Cached Data for User and Sales Team Profile Override Processing:
    List<Rule_MRK__c> m_insertedSalesTeamProfileOverrideRuleList = new List<Rule_MRK__c>();
    List<Rule_MRK__c> m_insertedUserProfileOverrideRuleList = new List<Rule_MRK__c>();
    Map<Id, Integer> m_existingUserProfileOverRideCountByIdMap = new Map<Id, Integer>();
    Map<Id, Integer> m_existingSalesTeamProfileOverRideCountByIdMap = new Map<Id, Integer>();
    Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Rule_MRK__c.fields.getMap();
   
    
    //Territory Profile Override Processing
    Map<id, list<id>> parentIdToChildrenIdListTerrClonedMap = new Map<id, list<id>>();
    List <Rule_MRK__c> newTerritoryOverrideRuleRecList = new List <Rule_MRK__c>();
    MRK_TerritoryCloneTreeUtil TerritoryCloneTreeUtil = MRK_TerritoryCloneTreeUtil.getInstance();
    Map<Id, String> territoryCloneOrigSFIDandNameMap = new Map<Id, String>();
    List<Rule_MRK__c> m_insertedTerritoryProfileOverrideRuleList = new List<Rule_MRK__c>();
    Map<String, Integer> m_existingTerritoryProfileOverRideCountByNameMap = new Map<String, Integer>();
    Map<Id, Territory_Clone_MRK__c> m_NewCloneTerrInsertionsIdtoTerrCloneObjMap = new Map<Id, Territory_Clone_MRK__c>();
    List<Rule_MRK__c> m_RuleRecordsUpdatedToActive= new List<Rule_MRK__c>();
    List<Rule_MRK__c> m_RuleRecordsUpdatedToInActive= new List<Rule_MRK__c>();


    // Constructor
    public MRK_RuleHandler()
    {
    }

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore()
    {
                
        if(Trigger.isUpdate){
           System.debug('kevin: Just enteted the isUpdate');
        }
                
        if(Trigger.isInsert){  
             System.debug('kevin: Just enteted the isInsert');
            
           //User and Sales Team Processing
           cacheRuleDataForOverrideRuleUserAndSalesTeamInsertProcessing();
           
           //Preprocess the Territory Override Records.... 
           preprocessTerritoryProfileOverrideRecords();
           
           //Territory Override Processing...
           cacheDataForOverrideRuleTerritoryInsertProcessing();
        }
        
        if(Trigger.isDelete){
        }
    }
    
    public void bulkAfter()
    { 
        
        if(Trigger.isUpdate){   
            
            processChildTerritoryUpdateCascade();
        }
        
        if(Trigger.isInsert){
            
            //Need this in the bulkAfter so that we have SF Id for the RULE Object. Will 
            //use this id on the Child Records to identify the Parent....
             cacheDataForTerritoryProfileOverrideChildTerritoryProcessing();
            
        }
        
        if(Trigger.isDelete){
        }
        
    }
        
    public void beforeInsert(SObject so)
    {
        
        
        //Validate that a duplicate Override does not exist
        Rule_MRK__c rule = (Rule_MRK__c)so;
        
        //Validate Profile Override Records:
        if(rule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE'){
            
           //TODO Add a rule for the Territory Stuff....no duplicates
           validateProfileOverrideRecordInserted(so);
        }
    }
    
    public void beforeUpdate(SObject oldSo, SObject so)
    {
       
       Rule_MRK__c oldRule = (Rule_MRK__c) oldSo;
       Rule_MRK__c newRule = (Rule_MRK__c) so;
        
       //Below Rules only apply to Profile Overrides.... //KRB REL 8.0
       if(!MRK_RuleHelper.shouldBypassValidation() 
          && (oldRule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE')){
            
          //Ensures only the Active Field was Changed.
       
          for (String str : fieldMap.keyset()) { 
             System.debug('Field name: '+str +'. New value: ' + newRule.get(str) +'. Old value: '+oldRule.get(str)); 

             if((str != 'active_mrk__c') && (newRule.get(str) != oldRule.get(str))){ 
                   so.addError('Only the Active Field can be Updated. Changes have not been Saved.');
             } 
          }
           
        //ensure that if the Active Field was updated from Inactive to Active, that there are no other
        //Active records with the same User/SalesTeam/Territory
        if(oldRule.Active_MRK__c == False && newRule.Active_MRK__c == True){
          if(newRule.User_MRK__c != null ){
              Integer countOfExistingActiveUserOverrides = MRK_RuleGateway.retrieveCountofExistingActiveUserProfileOverrides(newRule);
              if (countOfExistingActiveUserOverrides > 0){
                 so.addError('There is already an Active Profile Override for this User. Changes have not been Saved.');
              }
          }  
      
          if(newRule.Sales_Team_MRK__c != null ){
              Integer countOfExistingActiveSalesTeamOverrides = MRK_RuleGateway.retrieveCountofExistingActiveSalesTeamProfileOverrides(newRule);
              if (countOfExistingActiveSalesTeamOverrides > 0){
                 so.addError('There is already an Active Profile Override for this Sales Team. Changes have not been Saved.');
              }
          }
        
        } 
           
         //Ensure that if the Active field was changed on a Territory Record, it was a Parent Territory Record.
        //Updates can not occur on Child Territory Rule Records. 
        
        if(
            (oldRule.Active_MRK__c != newRule.Active_MRK__c) &&
            (newRule.Territory_Name_MRK__c != null) &&
            (newRule.Parent_Rule_Id_MRK__c != null) &&
            (newRule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE')
        ){
           so.addError('The Active Field can only be Updated on a Parent Territory Record. Changes have not been Saved.');
        }
           
        if(oldRule.Active_MRK__c == False && newRule.Active_MRK__c == True){
   
           //Ensure that an Active Parent Territory Rule does not already exist...   
           if ((newRule.Territory_MRK__c != null) &&
               (newRule.Parent_Rule_Id_MRK__c == null) &&
               (newRule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE')
              ) {
              
              Integer countOfExistingParentTerritoryProfileOverrides = MRK_RuleGateway.retrieveCountofExistingActiveParentTerritoryProfileOverrides(newRule);
              
              if (countOfExistingParentTerritoryProfileOverrides > 0){
                 so.addError('There is already an Active Profile Override for this Territory. Changes have not been Saved.');
              }
            
             //Ensure that an Active Child record of the Parent does not exist.
             //1. Get all the child Names of the Parent about to be activated (All records that have the Id of this record in their Parent Field)
             //2. Preform a SOQL to retrieve a count of existing Active Child Overrides
             //3. If count is >0 throw an error. 
           
             List <RULE_MRK__c> childRules = new List<Rule_MRK__c>();
             List<Id> parentIdList = new List<Id>();
             parentIdList.add(newRule.Id);
             childRules = MRK_RuleGateway.retrieveAllChildTerritoryProfileRecordsByParentId(parentIdList);
             
             if (!childRules.isEmpty()){
                List<String> childNames = new List<String>();
                for (Rule_MRK__c rule : childRules){
                     childNames.add(rule.Territory_Name_MRK__c);
                }
                
                 Map<String, Integer> existingTerrMap = new Map<String, Integer>();
                 existingTerrMap = MRK_RuleGateway.retrieveActiveTerritoryProfileOverRideCountByTerritoryCloneNames(childNames);
                 if(!existingTerrMap.isEmpty()){
                     so.addError('There is already an Active Profile Override for a Child of this Territory. Changes have not been Saved.');
                 }   
             }
              
              
           }
        }
          
       }else{
           System.debug('We are Bypassing the Validation...');
       }
        
   }        
    
    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(SObject so)
    {          
    }
    
    public void afterInsert(SObject so)
    {        
    }
    
    public void afterUpdate(SObject oldSo, SObject so)
    {
    }
    
    public void afterDelete(SObject so)
    {
    }
    
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally()
    {
       
        if(Trigger.isUpdate){

           //Update the records with Active Indicator Updates. 
           System.debug('In Finally, about to process Update: Count of m_RuleRecordsUpdatedToInActive ' + m_RuleRecordsUpdatedToInActive.size());
           System.debug('In Finally, about to process Update: Count of m_RuleRecordsUpdatedToActive ' + m_RuleRecordsUpdatedToActive.size());

            //Preforming the Update will fire this trigger again. 
            //Need to bypass the Validation logic....
            
            MRK_RuleHelper.setBypassValidation(); 
            
            if(!m_RuleRecordsUpdatedToActive.isEmpty()){
               Update m_RuleRecordsUpdatedToActive;
            }

            if(!m_RuleRecordsUpdatedToInActive.isEmpty()){
               Update m_RuleRecordsUpdatedToInActive;
            }

            MRK_RuleHelper.deactivateBypassValidation();
           System.debug('Done in the Finally Method...' );
            
        }        
        
        if(Trigger.isDelete){
        }
        
        if(Trigger.isInsert){
        
            System.debug('Kevin: Just entered the Finally Method Trigger isInsert:' );
            System.debug('Kevin: Looping over the newTerritoryOverrideRuleRecList:' );

            for (Rule_MRK__c ruleRec: newTerritoryOverrideRuleRecList){
                 System.debug('Kevin: Parent_Rule_Id_MRK__c:' + ruleRec.Parent_Rule_Id_MRK__c );
                 System.debug('Kevin: Profile_MRK__c:' + ruleRec.Profile_MRK__c );
                 System.debug('Kevin: Territory_Name_MRK__c:' + ruleRec.Territory_Name_MRK__c );
                 System.debug('Kevin: Active_MRK__c:' + ruleRec.Active_MRK__c );
                        
            }

            if (!newTerritoryOverrideRuleRecList.isEmpty()){
                insert newTerritoryOverrideRuleRecList;
            }
        }
    }
    
    
    /*
     * Custom Methods
     * 
     */
 
    
     /*
     * KRB 3/20/2014 - Data needed to Validate Territory Override insert
     */

    private void processChildTerritoryUpdateCascade(){
        
     /*
        KRB - If the Active Indicator changed on a Parent "Territory" 
              Profile Override Record, Cascade the change to all Child 
              Records.
     */
        
       List<Id> setChildrenAsActiveIdList = new List<Id>();
       List<Id> setChildrenAsInActiveIdList = new List<Id>();
              
       for (SObject obj: Trigger.new) {
           
           Rule_MRK__c updatedRule = (Rule_MRK__c) obj;
           Rule_MRK__c oldRule = (Rule_MRK__c) Trigger.oldMap.get(updatedRule.ID);
           
              if(oldRule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE'){ //KRB REL8.0

                 System.debug('In Processing Cascade Updates: Working with: ' + updatedRule.Id);
                 System.debug('new Value =  ' + updatedRule.Active_MRK__c);
                 System.debug('old Value =  ' + oldRule.Active_MRK__c);
                 System.debug('updatedRule.Territory_MRK__c Value =  ' + updatedRule.Territory_MRK__c);
                 System.debug('updatedRule.Parent_Rule_Id_MRK__c Value =  ' + updatedRule.Parent_Rule_Id_MRK__c);
                 System.debug('updatedRule.Record_Type_Name_MRK__c Value =  ' + updatedRule.Record_Type_Name_MRK__c);
           
                 //Make sure we are dealing with Parent Territory Updates only...
                 if ((updatedRule.Active_MRK__c != oldRule.Active_MRK__c) &&
                    ((updatedRule.Territory_MRK__c != null) || (updatedRule.Territory_Name_MRK__c != null)) &&
                     (updatedRule.Parent_Rule_Id_MRK__c == null) &&
                     (updatedRule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE')
                     ) {
                    
                    //Create 2 Lists: setChildrenAsActiveIdList and setChildrenAsInActiveIdList
                    if(updatedRule.Active_MRK__c == True){
                        System.debug('Kevin: Adding it to the Active List');
                        setChildrenAsActiveIdList.add(updatedRule.Id);
                    }else{
                        setChildrenAsInActiveIdList.add(updatedRule.Id);
                        System.debug('Kevin: Adding it to the InActive List');
                    }
                 }
            }//KRB Release 8.0       
       
       }
        
       //Send Lists to Gateway to get 2 lists (global) of all the Children that need to be updated (ID LIST)
       
       if(!setChildrenAsActiveIdList.isEmpty()){
          m_RuleRecordsUpdatedToActive = MRK_RuleGateway.retrieveAllChildTerritoryProfileRecordsByParentId(setChildrenAsActiveIdList);            
          System.debug('Count of m_RuleRecordsUpdatedToActive ' + m_RuleRecordsUpdatedToActive.size());
          for(Rule_MRK__c rule: m_RuleRecordsUpdatedToActive){
             rule.Active_MRK__c = True;
          }
       }
               
       if(!setChildrenAsInActiveIdList.isEmpty()){
          m_RuleRecordsUpdatedToInActive = MRK_RuleGateway.retrieveAllChildTerritoryProfileRecordsByParentId(setChildrenAsInActiveIdList);            
          System.debug('Count of m_RuleRecordsUpdatedToInActive ' + m_RuleRecordsUpdatedToInActive.size());
       
          for(Rule_MRK__c rule: m_RuleRecordsUpdatedToInActive){
             rule.Active_MRK__c = False;
          }
       }
        
       //Update the Records in the Finally Method.                            
    }

    
     /*
     * KRB 3/20/2014 - Data needed to Validate Territory Override insert
     */
   

    private void preprocessTerritoryProfileOverrideRecords(){
        
      List<Id> newTerrOverrideTerritoryCloneIdList =  new List<Id>();
      
      //update the Name of the Territory in the inserted record.
  
      for(sObject obj : Trigger.new){
          Rule_MRK__c rule = (Rule_MRK__c)obj;
          if(rule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE'){

             if(rule.Territory_MRK__c != null){
                newTerrOverrideTerritoryCloneIdList.add(rule.Territory_MRK__c);
             }
          }
       }
        
       
       if(!newTerrOverrideTerritoryCloneIdList.isEmpty()){ //KRB Rel 8.0
          m_NewCloneTerrInsertionsIdtoTerrCloneObjMap 
           = MRK_TerritoryCloneGateway.retrieveAllTerritoriesByIdList(newTerrOverrideTerritoryCloneIdList);
          System.debug('Kevin1: m_NewCloneTerrInsertionsIdtoTerrCloneObjMap count: ' + m_NewCloneTerrInsertionsIdtoTerrCloneObjMap.size());
       
          //update the Name of the Territory in the inserted record.
       
          for(sObject obj : Trigger.new){
             Rule_MRK__c rule = (Rule_MRK__c)obj; 
                if(rule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE'){

                   if(rule.Territory_MRK__c != null){
                      rule.Territory_Name_MRK__c = m_NewCloneTerrInsertionsIdtoTerrCloneObjMap.get(rule.Territory_MRK__c).Name;
                      System.debug('rule.Territory_Name_MRK__c = ' + rule.Territory_Name_MRK__c);
             
                   }
                }
            }
        }//KRB Rel 8.0
    
    }
    
    /*
     * KRB 3/20/2014 - Data needed to Validate Territory Override insert
     */

    private void cacheDataForOverrideRuleTerritoryInsertProcessing(){
       
       /* Need the Name of the Territory that is being inserted from the Territory Clone Table 
          - New Gateway Method that returns a Map of inserted Terr Clone Override Ids and the Name of the Terr.
          Method that aggregates the Count of Name on the Rule Object (Active) for the List of Name collected above.
       */
        
       List<Rule_MRK__c> insertedRuleList = Trigger.new;
       List<Rule_MRK__c> insertedTerritoryOverrideRuleList = new List<Rule_MRK__c>();
       List<String> territoryNameList = new List<String>();
        

       for(Rule_MRK__c rule : insertedRuleList){
            
          if(rule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE'){

             if(rule.Territory_MRK__c != null){
                territoryNameList.add(m_NewCloneTerrInsertionsIdtoTerrCloneObjMap.get(rule.Territory_MRK__c).Name);
             }
          }
       }
        
       if (!territoryNameList.isEmpty()){    
           
           m_existingTerritoryProfileOverRideCountByNameMap =
               MRK_RuleGateway.retrieveActiveTerritoryProfileOverRideCountByTerritoryCloneNames(territoryNameList);
               
      }
    }
    
    
    /*
     * KRB 3/20/2014 - retrieves entire Territory Structure
     */

    private void cacheDataForTerritoryProfileOverrideChildTerritoryProcessing(){
                
       List<Rule_MRK__c> insertedRuleList = Trigger.new;

       for(Rule_MRK__c rule : insertedRuleList){
            
          if(rule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE'){

             if(rule.Territory_MRK__c != null){
                System.debug('Adding to the m_insertedTerritoryProfileOverrideRuleList' );
                m_insertedTerritoryProfileOverrideRuleList.add(rule);
             }
          }
       }
        
        
       //Territory Override records were inserted via the UI, Territory Cache Needed.
       if (!m_insertedTerritoryProfileOverrideRuleList.isEmpty()){
           
           List<Id> terrCloneId = new List<Id>();
           
           for(Rule_MRK__c terrRule : m_insertedTerritoryProfileOverrideRuleList){
               terrCloneId.add(terrRule.Territory_MRK__c);
           }
           
           createNewTerritoryCloneRecords();       
        }
    }


    /*
     * KRB 3/20/2014 REL 5.0
     */
    
    private void cacheRuleDataForOverrideRuleUserAndSalesTeamInsertProcessing(){
        
        System.debug('In cacheRuleDataForOverrideRuleInsertProcessing Method...');
        
        List<Rule_MRK__c> insertedRuleList = Trigger.new;
        
        for(Rule_MRK__c rule : insertedRuleList){
            
            if(rule.Record_Type_Name_MRK__c == 'MRK_RULE_PROFILE_OVERRIDE'){
               
               System.debug('rule.User_MRK__c:' + rule.User_MRK__c);
               System.debug('rule.Sales_Team_MRK__c:' + rule.Sales_Team_MRK__c);
              
                
               if(rule.User_MRK__c != null ){
                  System.debug('Adding to the m_insertedUserProfileOverrideRuleList' );
                  m_insertedUserProfileOverrideRuleList.add(rule);
               }  
      
               if(rule.Sales_Team_MRK__c != null ){
                  System.debug('Adding to the m_insertedSalesTeamProfileOverrideRuleList' );
                  m_insertedSalesTeamProfileOverrideRuleList.add(rule);
               }  
            }
        }
        
        //Cache needed User Information.
        if (!m_insertedUserProfileOverrideRuleList.isEmpty()){
           
            List<Id> userIdList= new List<Id>();
            
            for(Rule_MRK__c rule : m_insertedUserProfileOverrideRuleList){
                userIdList.add(rule.User_MRK__c);
            }
            
            m_existingUserProfileOverRideCountByIdMap = 
               MRK_RuleGateway.retrieveActiveUserProfileOverRideCountByUserId(userIdList);
        }

        
        //cache required Sales Team Information.
        if (!m_insertedSalesTeamProfileOverrideRuleList.isEmpty()){
           
           List<Id> salesTeamIdList= new List<Id>(); 
 
           for(Rule_MRK__c rule : m_insertedSalesTeamProfileOverrideRuleList){
                salesTeamIdList.add(rule.Sales_Team_MRK__c);
            }
             
           m_existingSalesTeamProfileOverRideCountByIdMap = 
               MRK_RuleGateway.retrieveActiveSalesteamProfileOverRideCountBySalesTeamId(salesTeamIdList);
        }
    }    
    

    /*
     * KRB 3/20/2014 REL 5.0
     */
    
    private void createNewTerritoryCloneRecords(){
        
       System.debug('In createNewTerritoryCloneRecords' );
        
       //Using the Rule_MRK__c.Territory_MRK__c Id, pull all the Territory Clone Records Impacted.        
        
       List<Id> insertedRuleTerritoryCloneIds = new List<Id>();  
      
       for(Rule_MRK__c terrRuleRec : m_insertedTerritoryProfileOverrideRuleList){
          insertedRuleTerritoryCloneIds.add(terrRuleRec.Territory_MRK__c); 
           // Remember, this is the ID of the Territory on the Territory_Clone_MRK__c Table, we need to work with the 
           // Actual ORIGINAL SFID of the Territory stored on this Table because the Territory_Clone Object gets 
           // Refreshed Nightly and the ID of the Object will be gone....
       }
        
       System.debug('InsertedRuleTerritoryCloneIds count ' + insertedRuleTerritoryCloneIds.size());
         
       Map<Id,Territory_Clone_MRK__c> terrCloneMap = new Map<Id,Territory_Clone_MRK__c>();
     
       terrCloneMap = MRK_TerritoryCloneGateway.retrieveAllTerritoriesByIdList(insertedRuleTerritoryCloneIds);
 
       System.debug('terrCloneMap count ' + terrCloneMap.size());

        
       for(Rule_MRK__c terrRuleRec : m_insertedTerritoryProfileOverrideRuleList){
 
          //find all the Children for each Territory Profile Override record inserted.
          List<Id> territoryChildIdList = new List<Id>();
            
          //Get a list of all the Children Territory Ids - Original SFID ids     
          territoryChildIdList = 
                TerritoryCloneTreeUtil.getAllChildrenGivenParentNodeId((Id)terrCloneMap.get(terrRuleRec.Territory_MRK__c).Territory_SFID_MRK__c);
          
           System.debug('TerritoryChildIdList count ' + territoryChildIdList.size());
           
           
          Map<Id, Territory_Clone_MRK__c> childCloneTerritoryMap = 
              MRK_TerritoryCloneGateway.retrieveCloneTerritoriesMapByTerritorySFIDList(territoryChildIdList);

           System.debug('ChildCloneTerritoryMap count ' + childCloneTerritoryMap.size());

           
           //create a Map that has Original Territory SF ID to Territory Name:
           Map<Id, String> terrIdToterrNameMap = new Map<Id, String>();
           
           for(Id terrId: childCloneTerritoryMap.keySet()){
               terrIdToterrNameMap.put(childCloneTerritoryMap.get(terrId).Territory_SFID_MRK__c, childCloneTerritoryMap.get(terrId).Name);
           }
           
           System.debug('TerrIdToterrNameMap count ' + terrIdToterrNameMap.size());
          
           
          for(Id childTerritoryId : territoryChildIdList){
                
             Rule_MRK__c newRuleRec = new Rule_MRK__c();
               
             newRuleRec.Parent_Rule_Id_MRK__c = terrRuleRec.Id;
             newRuleRec.Profile_MRK__c = terrRuleRec.Profile_MRK__c;
             newRuleRec.Territory_Name_MRK__c = terrIdToterrNameMap.get(childTerritoryId); 
             newRuleRec.Active_MRK__c = terrRuleRec.Active_MRK__c;
 
             newTerritoryOverrideRuleRecList.add(newRuleRec);
                
          }
       }
    }   
    
    
    
    /*
     * KRB 3/20/2014 REL 5.0
     */

    private void validateProfileOverrideRecordInserted(SObject so){
        
        Rule_MRK__c rule = (Rule_MRK__c) so;
        
        if(rule.User_MRK__c != null){
           if(m_existingUserProfileOverRideCountByIdMap.containsKey(rule.User_MRK__c)){
              so.addError('An Active User Profile Override record already exists for this User. Record cannot be Saved.');
           }
            
            if((rule.Sales_Team_MRK__c !=null) || (rule.Territory_MRK__c !=null) ){
               so.addError('Only one of the following Fields can be populated on an insert: User, Sales Team, Territory. Record cannot be Saved.');
            }
        }
        
        if(rule.Sales_Team_MRK__c != null){
           if(m_existingSalesTeamProfileOverRideCountByIdMap.containsKey(rule.Sales_Team_MRK__c)){
              so.addError('An Active Sales Team Profile Override record already exists for this Sales Team. Record cannot be Saved.');
           }
           
           if((rule.User_MRK__c !=null) || (rule.Territory_MRK__c !=null) ){
               so.addError('Only one of the following Fields can be populated on an insert: User, Sales Team, Territory. Record cannot be Saved.');
           }
        }


        if(rule.Territory_MRK__c != null){
 
            
           //Need a Validation Method that throws an error if *ANY* of the CHILDREN of the Parent Territory
           //about to be inserted already exist, ACTIVE, in the RULE_MRK__c Object. 
           //So, fail the Parent record if any of the children already exist, active...
           //Eample...V2_20 already exists active and then someone tries to enter MVDA_V2 (its parent...)
           //Method does the following:
           //1. Gets the list of all the Children of the Parent (territory node entered via the UI) -
           //   Need the "Names" of the Children
           //3. Submit a SOQL count() that queries the Rule Object for any of the Child Names ..that are active.
           //4. Throw an error that states that one of the Territory's Children already exist. 
           
            
           //Validation 1. Check that none of the Child Territories of the Parent just entered already exists and are active. 
           List<Id> insertedRuleTerritoryCloneIds = new List<Id>();  
           insertedRuleTerritoryCloneIds.add(rule.Territory_MRK__c);
      
           Map<Id,Territory_Clone_MRK__c> terrCloneMap = new Map<Id,Territory_Clone_MRK__c>();
     
           terrCloneMap = MRK_TerritoryCloneGateway.retrieveAllTerritoriesByIdList(insertedRuleTerritoryCloneIds);
         
           //find all the Children for each Territory Profile Override record inserted.
           List<Id> territoryChildIdList = new List<Id>();
            
          //Get a list of all the Children Territory Ids - Original SFID ids     
          territoryChildIdList = 
                TerritoryCloneTreeUtil.getAllChildrenGivenParentNodeId((Id)terrCloneMap.get(rule.Territory_MRK__c).Territory_SFID_MRK__c);
          
           System.debug('territoryChildIdList count ' + territoryChildIdList.size());
           
           Map<Id, Territory_Clone_MRK__c> childCloneTerritoryMap = 
              MRK_TerritoryCloneGateway.retrieveCloneTerritoriesMapByTerritorySFIDList(territoryChildIdList);

           System.debug('childCloneTerritoryMap count ' + childCloneTerritoryMap.size());
           
           //create a Map that has Original Territory SF ID to Territory Name:
           Map<Id, String> terrIdToterrNameMap = new Map<Id, String>();
           
           for(Id terrId: childCloneTerritoryMap.keySet()){
               terrIdToterrNameMap.put(childCloneTerritoryMap.get(terrId).Territory_SFID_MRK__c, childCloneTerritoryMap.get(terrId).Name);
           }
           
           System.debug('terrIdToterrNameMap count ' + terrIdToterrNameMap.size());
          
           List<String> childTerritoryNames = new List<String>();  
           
           //List of all the Child Territory Names about to be inserted as a result of the Terr Record Insert
           //Need to ensure none of these already exist in the Rule Object.... 
           childTerritoryNames =  terrIdToterrNameMap.values();
            
           //get a count Map (Name to Count) of the Child Terr Names from the Rule Object.
           //public static Map<String, Integer> retrieveActiveTerritoryProfileOverRideCountByTerritoryCloneNames(List<String> territoryCloneNames){
           if (!childTerritoryNames.isEmpty()){
            
              Map<String, Integer> existingTerritoryOverrideRecordNametoCountMap = new Map<String, Integer>();
              existingTerritoryOverrideRecordNametoCountMap = MRK_RuleGateway.retrieveActiveTerritoryProfileOverRideCountByTerritoryCloneNames(childTerritoryNames);   
            
              if(!existingTerritoryOverrideRecordNametoCountMap.isEmpty()){
                 
                  for (String childTerrName : childTerritoryNames){
                      if(existingTerritoryOverrideRecordNametoCountMap.containsKey(childTerrName)){
                           so.addError('A Child Territory of the Territory Entered already Exists.\n  Record cannot be Saved.\n Please deactivate the existing Child Territories.');
                      } 
                  }
              }
            
           }else{
               System.debug('validateProfileOverrideRecordInserted: Entered Parent Node has No Child Territories');
           }
               
           //Validation 2. Check that the Parent Node just entered does not already exist.
           if(m_existingTerritoryProfileOverRideCountByNameMap.containsKey(m_NewCloneTerrInsertionsIdtoTerrCloneObjMap.get(rule.Territory_MRK__c).Name)){
              so.addError('An Active Territory Profile Override record already exists for this Territory. Record cannot be Saved.');
           }
                      
           //Validation 3. Ensure that only the Territory Field was populated.
           if((rule.User_MRK__c !=null) || (rule.Sales_Team_MRK__c !=null) ){
               so.addError('Only one of the following Fields can be populated on an insert: User, Sales Team, Territory. Record cannot be Saved.');
           }
        }
    }
    
 }