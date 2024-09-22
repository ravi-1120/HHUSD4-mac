public class MRK_VisibilityRuleRecordGenericHandler implements MRK_ITrigger{
  
/* Copyright, 2016 MERCK & CO, INC., Kevin Brace ALL RIGHTS RESERVED */ 
    
     /* Member Variables    */
     SharingRulesEngine_MRK sharingRulesEngine = New SharingRulesEngine_MRK();
     List<Visibility_Rule_Record_MRK__c> m_visibilityRuleRecordsDeletedList = new List<Visibility_Rule_Record_MRK__c>();
     List<Visibility_Rule_Record_MRK__c> m_visibilityRuleRecordsInsertedList = new List<Visibility_Rule_Record_MRK__c>();

     /* Visibility Rule Record Member Variables */
     List<Visibility_Rule_MRK__c> m_VisibilityRulesBeforeInsertObjectVRValidationList = new List<Visibility_Rule_MRK__c>(); 
     Map <Id, Visibility_Rule_MRK__c> m_visibilityRuleBeforeInsertValidationMap = new Map<Id, Visibility_Rule_MRK__c>();
     Map <Id, Visibility_Rule_MRK__c> m_visibilityRulesAssociatedToNewVisibilityRuleRecordInsertsMap = new Map<Id, Visibility_Rule_MRK__c>();
     List<MSD_CORE_Visibility_Rule_Access_Levels__c> m_AccessLevelsByCountryAndObject = new List<MSD_CORE_Visibility_Rule_Access_Levels__c>();
     Map<Id, User> m_UserCountryCodesMap = new Map<Id, User>(); 

     //Generic List to store the Sharing Records that need to be loaded/Deleted into the Appropriate Sharing Table.
     private List<sObject> m_sharingRulesToInsert = new List<sObject>(); 
     private List<sObject> m_sharingRulesToDelete = new List<sObject>(); 
    
     //Map of Id to Name for All vvr types
     Map<Id,RecordType>m_rtMap = new Map<Id,RecordType>();
     String m_deletedRTName = ''; 
    
    // Constructor
    public MRK_VisibilityRuleRecordGenericHandler()
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
        m_rtMap = new Map<Id,RecordType>([SELECT DeveloperName,Id FROM RecordType WHERE SobjectType = 'Visibility_Rule_Record_MRK__c']);

        if(Trigger.isInsert){
           cacheDataRequiredForVisibilityRuleRecordValidationAndInsertion();
           createShareRecordsForInsertion();
        }
        
        if(Trigger.isDelete){
           performDeleteValidation();
           cacheDataRequiredForVisibilityRuleRecordDeletion();
           identifyShareRecordsForDeletion();
        }
    }
    
    public void bulkAfter()
    {
    }
        
    public void beforeInsert(SObject so)
    {
       validateVisibilityRuleRecord(so); 
    }
    
    public void beforeUpdate(SObject oldSo, SObject so)
    {
        performBeforeUpdateValidation(oldSo, so); 
    }
    
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
       
        if(Trigger.isInsert){
            insert m_sharingRulesToInsert;
        }

        if(Trigger.isDelete){
           delete m_sharingRulesToDelete;
        }
    }
    
    
    /* ********************************************************************************************
       Custom Methods:
    ******************************************************************************************** */

    
    /* *************************
       Cache Data Methods:
    ************************** */
    
    /*
       KRB - 1/31/2014 REL 5.0 
    */    
    private void cacheDataRequiredForVisibilityRuleRecordDeletion(){
        m_visibilityRuleRecordsDeletedList = Trigger.old;
        
        //Validate fires before this point to ensure we are only throwing one 
        //Deleted record to this trigger at a time (due to complexity...)
        //So, lets save off the Record Type of this VVR to be used later in 
        //the compilation of the Delete Records. 
        m_deletedRTName = m_rtMap.get(m_visibilityRuleRecordsDeletedList[0].RecordTypeId).DeveloperName;
        
        /* 
            for each vrr deleted:
				need to make sure that for each user associated to the Sales teams, that no other rule grants the same Share.
                If it does, remove the User from the list of Deletes...
        */
        
    }
    

    /*
       KRB - 1/31/2014 REL 5.0 
    */
    private void cacheDataRequiredForVisibilityRuleRecordValidationAndInsertion(){
        
       //Infomation required for ALL Types of Visibility Rule Record Validation And Insertion...
       cacheBaseDataRequiredForVisibilityRuleRecordValidationAndInsertion();
             
        //New
        cacheDataRequiredForGenericVisibilityRuleRecordValidationAndInsertion();
       //Add Additional methods as needed for different Share Record validation and insertions...
    }
    

    /*
       KRB - 1/31/2014 REL 5.0 
    */
    private void cacheBaseDataRequiredForVisibilityRuleRecordValidationAndInsertion(){
        
        m_visibilityRuleRecordsInsertedList = Trigger.new;
 
        List<Id> vrIdList = new List<Id>();
       
        for (Visibility_Rule_Record_MRK__c vvr: m_visibilityRuleRecordsInsertedList){
           vrIdList.add(vvr.Visibility_Rule_MRK__c);
        }
                                                                              
        m_visibilityRuleBeforeInsertValidationMap = MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(vrIdList); 
    }
    
    
    /* 
       KRB - 4/2016  
    */
    private void cacheDataRequiredForGenericVisibilityRuleRecordValidationAndInsertion(){
        System.debug('Kevin: In cacheDataRequiredForGenericVisibilityRuleRecordValidationAndInsertion()');
       
       //create a Set of the Object Ids listed on the VRRs
       Set <Id> newRecordObjectIdSet = new Set <Id>();
        
       for (Visibility_Rule_Record_MRK__c vvr : m_visibilityRuleRecordsInsertedList){
          newRecordObjectIdSet.add(vvr.Object_Id__c);
       }

       //Convert to List for querying... 
       List <Id> newRecordObjectIdList = new List <Id>();
       for (Id objId : newRecordObjectIdSet){
           newRecordObjectIdList.add(objId);
        }
       
       m_VisibilityRulesBeforeInsertObjectVRValidationList = MRK_VisibilityRuleGateway.findVisibilityRulesAssociatedtoVRRObjectIds(newRecordObjectIdList);
       
        
    }

    


    /* *************************
       Validation Methods:
    ************************** */
    
    /*
       KRB - 1/31/2014 REL 5.0 
        Limits Deletes on Visibilty Rule Records to one at a time. 
    */

    private void performDeleteValidation(){
       m_visibilityRuleRecordsDeletedList = Trigger.old;
        if (m_visibilityRuleRecordsDeletedList.size() > 1){
            throw new MRK_TriggerException('You can not Delete more than one Visibility Record at a time.');
        }
    }

        
    /*
       KRB - 1/31/2014 REL 5.0 
    */
        
    private void performBeforeUpdateValidation(SObject oldSo, SObject so){
       so.addError('You cannot Update a Visibility Rule Record. Please delete the Record and enter a new Visibility Rule Record.');
    }

    
    /*
       KRB - 1/31/2014 REL 5.0 
    */
    private void validateVisibilityRuleRecord(SObject so){
        
       Visibility_Rule_Record_MRK__c vrr = (Visibility_Rule_Record_MRK__c)so;
               
       //NEW 
       //Handle Generic Validation
       validateGenericVisibilityRuleRecord(so);      
        
       //Add in additional Validation Methods if needed on the Record...

    }



    /* NEW
       KRB - 4/2016 
    */
     private void validateGenericVisibilityRuleRecord(SObject so){
         
         //New
         validateGenericDuplicateVisibilityRuleRecordDoesNotExist(so);
         
         //New
         validateGenericVisibilityRuleRecordIsUniqueForAssociatedVisibilityRule(so);
     }


    /* NEW
      *  KRB - 4/2016  
      */
    
     private void validateGenericVisibilityRuleRecordIsUniqueForAssociatedVisibilityRule(SObject so){
        
        Visibility_Rule_Record_MRK__c newVisibilityRuleRecord = (Visibility_Rule_Record_MRK__c)so; 
        
        //look up the VR assigned to it and validate the Object to Share is not already assigned.       
        Map<Id, Visibility_Rule_MRK__c> vrMap = new Map<Id, Visibility_Rule_MRK__c>();
        
        vrMap = MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleId(newVisibilityRuleRecord.Visibility_Rule_MRK__c);
         
        List <Visibility_Rule_Record_MRK__c> vrrList = new List <Visibility_Rule_Record_MRK__c>();
        vrrList= vrMap.get(newVisibilityRuleRecord.Visibility_Rule_MRK__c).Visibility_Rule_Records_MRK__r;
        
        for (Visibility_Rule_Record_MRK__c vrr : vrrList){
            if (vrr.Object_Id__c == newVisibilityRuleRecord.Object_Id__c){
               so.addError('Object is already assigned to this Visibility Rule. This record cannot be saved.');
            }
        }
 
    }
        
    
    /* NEW
       KRB - 4/2016 
    */
    public void validateGenericDuplicateVisibilityRuleRecordDoesNotExist(SObject so){
        
        Visibility_Rule_Record_MRK__c newRuleRecord = (Visibility_Rule_Record_MRK__c)so;
         
        system.debug('Kevin:The new vrrs Object Id is: ' + newRuleRecord.Object_Id__c);
        
        for (Visibility_Rule_MRK__c vr : m_VisibilityRulesBeforeInsertObjectVRValidationList){
            
            system.debug('Kevin: Working With existing VR: ' + vr.name);
            
            List <Visibility_Rule_Record_MRK__c> vrrList = vr.Visibility_Rule_Records_MRK__r;
           
            for (Visibility_Rule_Record_MRK__c vrr : vrrList ){
                
                system.debug('Kevin: Working With existing VRR: ' + vrr.id);
                system.debug('Kevin: Working With existing VRRs prentation id: ' + vrr.Object_Id__c);
                
                if (newRuleRecord.Object_Id__c == vrr.Object_Id__c){ 
                
                    system.debug('Kevin: We have a match...now checking sales teams for the same rule');

                    List <Visibility_Rule_Sales_Team_MRK__c> vrst = vr.Visibility_Rule_Sales_Teams__r;
                    
                    for (Visibility_Rule_Sales_Team_MRK__c existingSalesTeam : vrst){
                       
                        system.debug('Kevin: working with existing salesteam: ' + existingSalesTeam.Sales_Team_MRK__c + ' for VR: ' + vr.name  );
                      
                       //Get information on the new Record's associated sales Teams....
                       List <Visibility_Rule_Sales_Team_MRK__c> newRecordsAssociatedSalesTeams = 
                               m_visibilityRuleBeforeInsertValidationMap.get(newRuleRecord.Visibility_Rule_MRK__c).Visibility_Rule_Sales_Teams__r;
                        
                        for(Visibility_Rule_Sales_Team_MRK__c newRecordsAssociatedSalesTeam: newRecordsAssociatedSalesTeams){
                           system.debug('Kevin: working with New Record salesteam: ' + newRecordsAssociatedSalesTeam.Sales_Team_MRK__c );
   
                            if (  existingSalesTeam.Sales_Team_MRK__c == newRecordsAssociatedSalesTeam.Sales_Team_MRK__c){
                               system.debug('we have a MATCH!!!');
                                if(newRuleRecord.Visibility_Rule_MRK__c == vr.id){
                                   so.addError('Visibility Rule Record already Exists on this Visibility Rule.');
                                }else{
                                   so.addError('The Same Sales Team and Object Visibility Rule Record already exists in a Visibility Rule.');
                                }
                            }else{
                               system.debug('we Dont have a MATCH!!!');

                            }
                        }
                    }
                }
            }
        }
    }
   
    
   
 
    /* *************************
       Share Deletion Methods:
    ************************** */
    
    /*
       KRB - 1/31/2014 REL 5.0 
    */
    private void identifyShareRecordsForDeletion(){
        identifyGenericShareRecordsForDeletion();
    }
    
    
    //New
    /*
       KRB - 4/2016 
    */

    private void identifyGenericShareRecordsForDeletion(){
                
       List<Visibility_Rule_Record_MRK__c> clmVisibilityRuleRecordDeletedList = new List<Visibility_Rule_Record_MRK__c>();
       Set <Id> associatedObjectIdList = new Set<Id>();

       //NOTE: Validation only limits one Record being deleted for a given Session...
       Visibility_Rule_Record_MRK__c visibilityRuleRecordDeleted = m_visibilityRuleRecordsDeletedList[0];
        
       associatedObjectIdList.add(visibilityRuleRecordDeleted.Object_Id__c);
        
       //Get the Visibility Rule, and associated Sales Team Records associated to the VR
       Map<Id, Visibility_Rule_MRK__c> associatedVisibilityRuleRecord = 
           MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleId(visibilityRuleRecordDeleted.Visibility_Rule_MRK__c);
                                             
        //Get a list of all the associated Visibility Rule Sales Teams
        if (associatedVisibilityRuleRecord.isEmpty()){
            return;
        }
        
        //Get all the Users assigned to the Sales Teams that are assigned to Rule, that is associated to the VRR, that was deleted...
        List<Visibility_Rule_Sales_Team_MRK__c> associatedVisibilityRuleSalesTeamsList = 
            associatedVisibilityRuleRecord.get(visibilityRuleRecordDeleted.Visibility_Rule_MRK__c).Visibility_Rule_Sales_Teams__r;
        
        //if no sales teams are currently assigned to the Rule, Exit...
        
        if(associatedVisibilityRuleSalesTeamsList.size() == 0 || associatedVisibilityRuleSalesTeamsList.isEmpty() ){
            return;
        }
        
        List<Id> salesTeamIdList = new List<Id>();
        List<Id> userIdList = new List<Id>();
        Set<Id>  UserIdSet = new Set<Id>();
        
        for (Visibility_Rule_Sales_Team_MRK__c vrst : associatedVisibilityRuleSalesTeamsList){
            salesTeamIdList.add(vrst.Sales_Team_MRK__c);
        }
        
        List<MSD_CORE_User_Sales_Team_DO> associatedUserSalesTeamList = 
            MRK_UserSalesTeamGateway.retrieveUsersAssociatedToSalesTeamList(salesTeamIdList);
    
        for (MSD_CORE_User_Sales_Team_DO ust: associatedUserSalesTeamList){
            UserIdSet.add(ust.User_MRK);
        }
        
        for (Id userId : UserIdSet){
           userIdList.add(userId);
        }
        
        //For all the Users impacted, get a list of all their associated Salesteams....
        
        List<MSD_CORE_User_Sales_Team_DO> userSalesTeamRecordsForImpactedUsersList =  MRK_UserSalesTeamGateway.retrieveUserSalesTeamRecordsbyUserId(userIdList);

        /*
           For each user impacted, we need to be sure that no other Visibility Rule
              grants the same Object Visibility to another sales team the User might be assigned to.

           Scenario - 
               Visibility Rule #1 -> Object Id (VRR) abc -> Sales Team 1
               Visibility Rule #2 -> Object Id (VRR) xyz -> Sales Team 2
               User 1 is assigned to both Sales Team 1 and 2
               In this case, we do not want to delete the Share Record since there is
               another Rule that grants the Visibility....
        */
        
        //Before we do any logic, lets see if it is even necessary....
        List<MSD_CORE_User_Sales_Team_DO> ustHavingMoreThanOneSalesTeamList =  
            MRK_UserSalesTeamGateway.retrieveUserSalesTeamListOfUsersHavingMoreThanOneSalesTeamAssignedbyUserIdList(userIdList);

       List<Id> usersToDeleteFromShareTable = new List<Id>();
        
       if (!ustHavingMoreThanOneSalesTeamList.isEmpty()){
           
           system.debug('Kevin 1');

           //Get a list of all the Visibility Rules that have a VRR that has the same Presentation Assigned...
            List<Id> clmPresentationIdList = new List<Id>();
            clmPresentationIdList.add(visibilityRuleRecordDeleted.Object_Id__c);
            List<Visibility_Rule_Record_MRK__c> vrrWithSameCMLPresentationIdsList = 
                MRK_VisibilityRuleRecordGateway.retrieveVisibilityRuleRecordsAssociatedtoObjectIds(clmPresentationIdList); 
            
           for(Visibility_Rule_Record_MRK__c vrr: vrrWithSameCMLPresentationIdsList){ 
              System.debug('Kevin 2: vrr.Description ' + vrr.name);
           }
           
            List<Id> visibilityRuleIdList = new List<Id>();
            for (Visibility_Rule_Record_MRK__c vrr : vrrWithSameCMLPresentationIdsList ){
               //We do not want to include the VRR being deleted! 
               if (vrr.id != visibilityRuleRecordDeleted.id){
                  visibilityRuleIdList.add(vrr.Visibility_Rule_MRK__c);
               }
            }
            
           for(Id vrrId: visibilityRuleIdList){ 
              System.debug('Kevin 3: After removing current...whats left: ' + vrrId);
           }

           
            Map<Id, Visibility_Rule_MRK__c> visibilityRulesHavingSameObjectIdAssignedMap = 
                MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(visibilityRuleIdList);
            
            /* For each user associated to the VRR being deleted, 
                  For each sales team the user is assigned to (Get a List of the Users Sales Teams..)
                    See if there is another VR (sharing out the same Object Id..) 
                    that has one of the User's Sales Team assigned to it 
            */
            
            for (Id userId : UserIdSet){
                
                System.debug('Kevin 4: User Id: ' + userId);
                
                Boolean matched = false;
                
               //get a list of all the User's Sales Teams...
                List<Id> salesTeamsAssociatedToUserList = new List<Id>();
                
                for (MSD_CORE_User_Sales_Team_DO ustl : userSalesTeamRecordsForImpactedUsersList){
                    if (userId == ustl.User_MRK){
                        salesTeamsAssociatedToUserList.add(ustl.Sales_Team_MRK);
                    }
                }
                
                System.debug('Kevin 4.5: Number of Sales Teams Associated to User: ' + salesTeamsAssociatedToUserList.size());

                
                /*
                    For each VR that shares out the same Object Id, see if we have a Sales team 
                    assigned that match one of the Users. If we do, we do not want to delete the User 
                    from the Share Table. If we can't find a match, then delete the User's Share 
                    Record
                */
                
                for(Id usersSalesTeamId : salesTeamsAssociatedToUserList){
                    
                   System.debug('Kevin 5: working with Sales team Id: ' + usersSalesTeamId);
                
                   for(Visibility_Rule_MRK__c vr : visibilityRulesHavingSameObjectIdAssignedMap.values()){

                      System.debug('Kevin 6: working with vr Id: ' + vr.id );
                       
                      List<Visibility_Rule_Sales_Team_MRK__c> vrsts = new List<Visibility_Rule_Sales_Team_MRK__c>();
                      vrsts = visibilityRulesHavingSameObjectIdAssignedMap.get(vr.Id).Visibility_Rule_Sales_Teams__r;
                    
                      for (Visibility_Rule_Sales_Team_MRK__c vrst : vrsts ){
                          System.debug('Kevin 7: working with vrst: ' + vrst.id );
                         
                          
                         if (vrst.sales_team_MRK__c == usersSalesTeamId){
                            System.debug('Kevin 8: we have a match' );
                             matched = true;
                         }
                      }
                    
                    }
                }
                
                if(matched == false){
                    System.debug('Kevin 9: adding User to List for Deletion:' + userId);

                    usersToDeleteFromShareTable.add(userId);
                }
                
            }
            
        }else{
            for (Id userId: userIdList){
                usersToDeleteFromShareTable.add(userId);
            }
        }
               
        //Remember, we Validate up front that only one VRR can be deleted at a time. Soo...
        //...All the shares we are about to delete are from the same Share table... 
        
        if (!associatedObjectIdList.isEmpty() && !usersToDeleteFromShareTable.isEmpty()){
           String objectShareName = m_deletedRTName + '__Share';   
           String RowCause = 'VE_' + m_deletedRTName + '__c';

           String query = 'SELECT Id,ParentId,UserOrGroupId FROM ' + objectShareName +  ' WHERE ParentId in : associatedObjectIdList AND UserOrGroupId in : usersToDeleteFromShareTable AND RowCause = \'' + RowCause + '\'' ;
           
           List<sObject> queryResults = new List<sObject>();
           queryResults = Database.query(query);

           if(!queryResults.isEmpty()){ 
              m_sharingRulesToDelete.addAll(queryResults);
           }
        }     

}

 
    /* *************************
        Share Insertion Methods:
    ************************** */
    
   /*
       KRB - 1/31/2014 REL 5.0 
    */
    private void createShareRecordsForInsertion(){
        //Compile Object Share Records...
                
        //Add additional methods as needed to create different types of share methods...
        createGenericShareRecordsForInsertion();
    }


    /* New
       KRB - 4/2016  
    */
    private void createGenericShareRecordsForInsertion(){
    
       List<Visibility_Rule_Record_MRK__c> genericVisibilityRuleRecordList = new List<Visibility_Rule_Record_MRK__c>();
       List <Id> associatedGenericVisibilityRuleIdList = new List <Id>();
       
      /* Create a list of the associated  Visibility Rules */
        
       for (Visibility_Rule_Record_MRK__c vrr : m_visibilityRuleRecordsInsertedList){
               genericVisibilityRuleRecordList.add(vrr);
               associatedGenericVisibilityRuleIdList.add(vrr.Visibility_Rule_MRK__c);
       }
        
       //Need to get the VRr's Parent, along with any sales Team records associated to it.   
       Map <Id, Visibility_Rule_MRK__c> genericVisibilityRuleMap = MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(associatedGenericVisibilityRuleIdList);
        
       List <Id> userIdsList = new List <Id>();
       List <MSD_CORE_User_Sales_Team_DO> userSalesTeamList = new List <MSD_CORE_User_Sales_Team_DO>();
       //here 1 
       userIdsList = MRK_VisibilityRuleRecordGateway.retrieveUsersAssociatedToVisibilityRuleRecordsSalesTeams(genericVisibilityRuleRecordList); 
       
       //Cache Data needed for Share Record Access Level Calculations
       Set<String> countryCodeSet = new Set<String>();
       List<String> countryCodeList = new List<String>();

       //get all the users Country Codes which will be used to determine Access Levels for the Insert
       m_UserCountryCodesMap = MRK_UserGateway.retrieveUserCountryCodesMap(userIdsList);
        
       for ( ID userId : m_UserCountryCodesMap.keySet() ){
         countryCodeSet.add(m_UserCountryCodesMap.get(userId).MSD_CORE_Country_Code__c);
       }
       
       if(!countryCodeSet.isEmpty()){
         countryCodeList.addAll(countryCodeSet);
       }
        
       m_AccessLevelsByCountryAndObject = MRK_UserGateway.retrieveAllVisibilityRuleAccessLevelsByCountryCodesList(countryCodeList);
       //End Cache Data needed for Share Record Access Level Calculations
        
       userSalesTeamList = MRK_UserSalesTeamGateway.retrieveUserSalesTeamRecordsbyUserId(userIdsList);
       
       for (Visibility_Rule_Record_MRK__c vrr : genericVisibilityRuleRecordList){
            
            String rt = m_rtMap.get(vrr.RecordTypeId).DeveloperName;
            String defaultAccess = 'READ';
            String vrrObjectAPIName = rt + '__c';
            vrrObjectAPIName = vrrObjectAPIName.toUpperCase();  
            System.debug('KRB: Access Level: vrrObjectAPIName: ' + vrrObjectAPIName);
             
            //Get the VR associated Sales Team (split it into a List) 
            Visibility_Rule_MRK__c vr = genericVisibilityRuleMap.get(vrr.Visibility_Rule_MRK__c);
            
            //Get a list of Sales Teams from the VR Record...
            List <Visibility_Rule_Sales_Team_MRK__c> vrst= vr.Visibility_Rule_Sales_Teams__r;
            
            List<Id> vrSalesTeamIdList = new List<Id>();
             
            for (Visibility_Rule_Sales_Team_MRK__c salesTeam : vrst){ 
                vrSalesTeamIdList.add(salesTeam.Sales_Team_MRK__c);
            }

             
             if (vrSalesTeamIdList.size() > 0){
                
                //Loop through the Sales team and for each Sales Team...  
                //List<String> vrSalesTeams = vr.Sales_Team_MRK__c.split(m_SALES_TEAM_DELIMITER);
                
                for (Id vrSalesTeamId : vrSalesTeamIdList){
                    
                /*Loop through the Users. 
                           If the User's Sales Team matches one of the VVR VR's sales teams
                                Create a  Share Record.
                */
                
                   for (MSD_CORE_User_Sales_Team_DO u : userSalesTeamList){
                          
                      if (u.sales_team_MRK == vrSalesTeamId){
                          
                         System.debug('KRB: Access Level 0: UserId: ' + u.user_MRK);
                  
                         //Sharing Record Access Level Processing
                         String userAccessLevel;
                  
                         if(m_UserCountryCodesMap.containsKey(u.user_MRK)){
                            System.debug('KRB: Access Level 1');
                            if(!String.isBlank(m_UserCountryCodesMap.get(u.user_MRK).MSD_CORE_Country_Code__c)){
                              System.debug('KRB: Access Level 2');
                              String usersCountryCode = m_UserCountryCodesMap.get(u.user_MRK).MSD_CORE_Country_Code__c;              
                              if(String.isNotBlank(usersCountryCode)){
                                 usersCountryCode = usersCountryCode.toUpperCase();
                              }
                          
                              System.debug('KRB: Access Level 3: usersCountryCode ' + usersCountryCode);
                              for(MSD_CORE_Visibility_Rule_Access_Levels__c accessLevel : m_AccessLevelsByCountryAndObject){
               
                                 System.debug('KRB: Access Level 4: accessLevel.MSD_CORE_Country_Code__c: ' + accessLevel.MSD_CORE_Country_Code__c);
                                 System.debug('KRB: Access Level 4: usersCountryCode: ' + usersCountryCode);
                                 System.debug('KRB: Access Level 4: accessLevel.Object_API_Name__c: ' + accessLevel.Object_API_Name__c);
                                 System.debug('KRB: Access Level 4: vrrObjectAPIName: ' + vrrObjectAPIName);
                                 System.debug('KRB: Access Level 4: accessLevel.MSD_CORE_Access_Level__c: ' + accessLevel.MSD_CORE_Access_Level__c);

                                 String accessLevelCountryCode = accessLevel.MSD_CORE_Country_Code__c;
                                 
                                 if(String.isNotBlank(accessLevelCountryCode)){
                                    accessLevelCountryCode = accessLevelCountryCode.toUpperCase();
                                 }
                              
                                 String accessLevelObjectAPIName = accessLevel.Object_API_Name__c;
                                 
                                 if(String.isNotBlank(accessLevelObjectAPIName)){
                                    accessLevelObjectAPIName = accessLevelObjectAPIName.toUpperCase();
                                 }

                                 if((accessLevelCountryCode == usersCountryCode) &&
                                    (accessLevelObjectAPIName == vrrObjectAPIName)){
                                        System.debug('KRB: Access Level 5: Found Match');

                                     if(!String.isBlank(accessLevel.MSD_CORE_Access_Level__c)){
                                         userAccessLevel = accessLevel.MSD_CORE_Access_Level__c;
                                         System.debug('KRB: Access Level 5: Found Match');
                                         System.debug('KRB: Access Level 5: userAccessLevel : ' + userAccessLevel);
                                         System.debug('KRB: Access Level 5: accessLevel.MSD_CORE_Access_Level__c : ' + accessLevel.MSD_CORE_Access_Level__c);
                                         break;
                                         
                                     }
                                 }
                              }
                             }
                           }
                  
                           System.debug('KRB: Access Level 6: userAccessLevel = ' + userAccessLevel);


                           if(String.isBlank(userAccessLevel)){
                              System.debug('KRB: Access Level 7');
                              userAccessLevel = defaultAccess;
                           }
                  
                           //End Sharing Record Access Level Processing                         
                          
                         m_sharingRulesToInsert.add(SharingRulesEngine.createShareObj(
                                                                 rt + '__Share',
                                                                  vrr.Object_Id__c,
                                                                  u.user_MRK,
                                                                  userAccessLevel,
                                                                  'VE_' + rt  + '__c'                                                              ));
                          
                     }//if (u.sales_team_MRK__c == vrSalesTeamId){
                   }
                }
                
            }
         }
    }

   
}