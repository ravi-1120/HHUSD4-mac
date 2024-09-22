public class MRK_UserSalesTeamGenericHandler implements MRK_ITrigger{

     /* Copyright, 2016 MERCK & CO, INC., Kevin Brace ALL RIGHTS RESERVED */

    /*  
      
        KRB - 3/14/2014 REL 5.0 Class houses processing logic for the 
                               User_Sales_Team_MRK__c Object
        Need to Handle:
        User Sales Team Inserts and Deletes - NO UPDATES


        KRB - 4/2016 OA Complete
    */
    
    
    /* Member Variables    */
     SharingRulesEngine_MRK sharingRulesEngine = New SharingRulesEngine_MRK();
     
     /*
         Visibility Engine Member Variables
      */
    
     //For Deletes
     //================================================
     //US Instance
     List<User_Sales_Team_MRK__c> m_UserSalesTeamRecordDeletedList = new List<User_Sales_Team_MRK__c>();
     
     //Global Instance
     /*
     List<MSD_CORE_User_Sales_Team__c> m_UserSalesTeamRecordDeletedList = new List<MSD_CORE_User_Sales_Team__c>();
     */
     //================================================
    
     List<Visibility_Rule_Sales_Team_MRK__c> m_AssociatedVisibilityRuleSalesTeamForDeletionList = new List<Visibility_Rule_Sales_Team_MRK__c>();        
     Map<Id, Visibility_Rule_MRK__c> m_AssociatedVisibilityRulesForDeletionMap = new Map<Id, Visibility_Rule_MRK__c>();
     List<MSD_CORE_User_Sales_Team_DO> m_ALLUserSalesTeamRecordsForUsersInUserSalesTeamRecordDeletedList = new List<MSD_CORE_User_Sales_Team_DO>();
     List<Visibility_Rule_Sales_Team_MRK__c> m_ALLVisibilityRuleSalesTeamRecordsforAllSalesTeamsAssociatedToUsersInDeleteRecordsList = new List<Visibility_Rule_Sales_Team_MRK__c>();  
     Map<Id, Visibility_Rule_MRK__c> m_ALLVisibilityRecordsAssociatedToALLVisibilityRuleSalesTeamRecordsMap = new Map<Id, Visibility_Rule_MRK__c>();    
     List<MSD_CORE_User_Sales_Team_DO> m_UserSalesTeamRecordsOfUsersHavingMoreThanOneSalesTeamList = new List<MSD_CORE_User_Sales_Team_DO>();
     Set<Id> m_UserIdsOfUsersHavingMoreThanOneSalesTeamAssignedSet = new Set<Id>();
    
     //For Inserts and Validation
     
     //US Instance
     List<User_Sales_Team_MRK__c> m_UserSalesTeamRecordInsertList = new List<User_Sales_Team_MRK__c>();
     
     //Global Instance
     /*
     List<MSD_CORE_User_Sales_Team__c> m_UserSalesTeamRecordInsertList = new List<MSD_CORE_User_Sales_Team__c>();
     */
    
    
     List<Visibility_Rule_Sales_Team_MRK__c> m_AssociatedVisibilityRuleSalesTeamList = new List<Visibility_Rule_Sales_Team_MRK__c>();     
     Map<Id, Visibility_Rule_MRK__c> m_AssociatedVisibilityRuleMap = new Map<Id, Visibility_Rule_MRK__c>();
     
     //Generic List to store the Sharing Records that need to be loaded/Deleted into the Apprioriate Sharing Table.
     private List<sObject> m_sharingRulesToInsert = new List<sObject>(); 
     private List<sObject> m_sharingRulesToDelete = new List<sObject>(); 

     Map<Id,RecordType>m_rtMap = new Map<Id,RecordType>();
     String m_deletedRTName = ''; 
     Map<String, List<id>> m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap = new Map<String, List<id>>();
     Map<String, List<id>> m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap = new Map<String, List<id>>();

     List<MSD_CORE_Visibility_Rule_Access_Levels__c> m_AccessLevelsByCountryAndObject = new List<MSD_CORE_Visibility_Rule_Access_Levels__c>();
     Map<Id, User> m_UserCountryCodesMap = new Map<Id, User>(); 



     /*
         Profile Override Member Variables
      */
    
    
    // Constructor
    public MRK_UserSalesTeamGenericHandler()
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
           cacheDataRequiredForUserSalesTeamValidationAndSharingRuleInsertion();    
           
           //For Inserting Shares:
           createGenericShareRecordsforInsertion();
        }
        
        if(Trigger.isDelete){
           cacheDataRequiredForVisibilityRuleSalesTeamDelete();
            
           //For Deleting Shares:
           identifyGenericShareRecordsforDeletion();
        }
    }
    
    public void bulkAfter()
    {       
       if(Trigger.isInsert){
         
       }
 
    }
        
    public void beforeInsert(SObject so)
    {
    }
    
    public void beforeUpdate(SObject oldSo, SObject so)
    {
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
       
        if(Trigger.isDelete){
            if(m_sharingRulesToDelete.size() > 0){
                delete m_sharingRulesToDelete;
            }
        }
        
        if(Trigger.isInsert){
            if(m_sharingRulesToInsert.size() > 0 ){
            
            m_sharingRulesToInsert.sort();
            
            insert m_sharingRulesToInsert;
            }
        }
    }
    
    
    /*
       KRB - 1/31/2014 REL 5.0
       KRB - 4/2016 OA Complete
    */

    private void cacheDataRequiredForUserSalesTeamValidationAndSharingRuleInsertion(){
        
        List <Id> salesTeamIds = new List<Id>();
        
        m_UserSalesTeamRecordInsertList = Trigger.new;
        
        
        //US INSTANCE
        for (User_Sales_Team_MRK__c ust : m_UserSalesTeamRecordInsertList){
           salesTeamIds.add(ust.Sales_Team_MRK__c);
        }
        
        //GLOBAL INSTANCE
        /*
        for (<GLOBAL INSTANCE USER SALES TEAM OBJ API NAME> ust : m_UserSalesTeamRecordInsertList){
           salesTeamIds.add(ust.Sales_Team_MRK__c);
        }
        */

        
        m_AssociatedVisibilityRuleSalesTeamList = MRK_VisibilityRuleSalesTeamGateway.retrieveVisibilityRuleSalesTeamRecordsBySalesTeamIdList(salesTeamIds);
        
        List <Id> visibilityRuleIds = new List<Id>();
        
        for (Visibility_Rule_Sales_Team_MRK__c vrst: m_AssociatedVisibilityRuleSalesTeamList){
           visibilityRuleIds.add(vrst.Visibility_Rule_MRK__c);
        }   
        
        m_AssociatedVisibilityRuleMap = MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(visibilityRuleIds);
        
    }

            
    /*
       KRB - 1/31/2014 REL 5.0 
       KRB - 4/2016 OA Complete
    */
        
    private void cacheDataRequiredForVisibilityRuleSalesTeamDelete(){
    
        List <Id> salesTeamIds = new List<Id>();
        List <Id> UserIds = new List<Id>();
        
        m_UserSalesTeamRecordDeletedList = Trigger.old;
        
        
        
        //US Instance
        for (User_Sales_Team_MRK__c ust : m_UserSalesTeamRecordDeletedList){
            salesTeamIds.add(ust.Sales_Team_MRK__c);
            UserIds.add(ust.User_MRK__c);
        }
        //Global
        /*
        for (MSD_CORE_User_Sales_Team__c ust : m_UserSalesTeamRecordDeletedList){
            salesTeamIds.add(ust.MSD_CORE_Sales_Team__c);
            UserIds.add(ust.MSD_CORE_User__c);
        }
        */
        
        //retrieve a list of all the Users that have more than one Sales Team
        m_UserSalesTeamRecordsOfUsersHavingMoreThanOneSalesTeamList = 
            MRK_UserSalesTeamGateway.retrieveUserSalesTeamListOfUsersHavingMoreThanOneSalesTeamAssignedbyUserIdList(UserIds);
        
        for(MSD_CORE_User_Sales_Team_DO ust : m_UserSalesTeamRecordsOfUsersHavingMoreThanOneSalesTeamList){
           m_UserIdsOfUsersHavingMoreThanOneSalesTeamAssignedSet.add(ust.User_MRK);
           System.debug('Kevin a: User having more then one Sales Team: ' + ust.User_MRK);
        }
        
        //Data for Specific UST records deleted
        m_AssociatedVisibilityRuleSalesTeamForDeletionList = MRK_VisibilityRuleSalesTeamGateway.retrieveVisibilityRuleSalesTeamRecordsBySalesTeamIdList(salesTeamIds);
        
        List <Id> visibilityRuleIds = new List<Id>();
        
        for (Visibility_Rule_Sales_Team_MRK__c vrst: m_AssociatedVisibilityRuleSalesTeamForDeletionList){
           visibilityRuleIds.add(vrst.Visibility_Rule_MRK__c);
           System.debug('Kevin b: VRST record impacted by UST record Delete: ' + vrst.Id);

        }   
        
        m_AssociatedVisibilityRulesForDeletionMap = MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(visibilityRuleIds);

        //Data required for Users that have more than one sales teams assigned.
        
        //List of all the User Sales Team Records for the Given Users in the Delete List....
        m_ALLUserSalesTeamRecordsForUsersInUserSalesTeamRecordDeletedList = MRK_UserSalesTeamGateway.retrieveUserSalesTeamRecordsbyUserId(UserIds);
        
        List <Id> allAssociatedSalesTeamIdList = new List <Id>();
        Set <Id> allAssociatedSalesTeamsIdSet = new Set <Id>();
        
        for(MSD_CORE_User_Sales_Team_DO ust: m_ALLUserSalesTeamRecordsForUsersInUserSalesTeamRecordDeletedList){
           allAssociatedSalesTeamsIdSet.add(ust.Sales_Team_MRK);
           //System.debug('Kevin c: ALL User Sales Team Records related to deleyed User in UST Record: ' + ust.Id);

        }
        
        for(Id stId: allAssociatedSalesTeamsIdSet){
           allAssociatedSalesTeamIdList.add(stId);
        }
        
        //A list of all the Visibility Rule Sales Team Records associated to All the Sales teams associated to the Users in the Delete List....
        m_ALLVisibilityRuleSalesTeamRecordsforAllSalesTeamsAssociatedToUsersInDeleteRecordsList = 
            MRK_VisibilityRuleSalesTeamGateway.retrieveVisibilityRuleSalesTeamRecordsBySalesTeamIdList(allAssociatedSalesTeamIdList);
        
        List <Id> vrIdsList = new List <Id>();
        List <Id> vrIdsSet = new List <Id>();
        
        for (Visibility_Rule_Sales_Team_MRK__c vrst : m_ALLVisibilityRuleSalesTeamRecordsforAllSalesTeamsAssociatedToUsersInDeleteRecordsList){
           vrIdsSet.add(vrst.Visibility_Rule_MRK__c);

        }
        
        for (Id vrId : vrIdsSet){
            System.debug('Kevin d: ALL VR Records associated to ALL related VRST Recs for to deleted User in UST Record: ' + vrId);

            vrIdsList.add(vrId);
        }
        
        /*
           A MAP of all the Visibility Rules (with Associated VRST and VRR Lists) 
           that are associated to the Visibility Rule Sales Team Records from above...
        */
        m_ALLVisibilityRecordsAssociatedToALLVisibilityRuleSalesTeamRecordsMap = 
            MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(vrIdsList);
       
     }

    
    
    /*
       KRB - 1/31/2014 REL 5.0
       KRB - 4/2016 OA Complete
    */

    private void createGenericShareRecordsforInsertion(){
       
        if (m_AssociatedVisibilityRuleMap.isEmpty()){
            return;
        }
        
      /*
          For each new ust record inserted: (contains user and sales team)
             find the vrst records that have a match and create a list of VR Ids
                For each VR Id, get the VR's associated VRRs
                   For each VRR,  create a Share Record...
      */ 
        
       //Cache Data needed for Share Record Access Level Calculation...
       Set<String> countryCodeSet = new Set<String>();
       List<String> countryCodeList = new List<String>();
       List<Id> userIdsList = new List<Id>();
        
       //=====================================================
       //US INSTANCE 
       for (User_Sales_Team_MRK__c ust: m_UserSalesTeamRecordInsertList){
          userIdsList.add(ust.User_MRK__c);          
       }
       //Global Instance
       /* 
       for (MSD_CORE_User_Sales_Team__c ust: m_UserSalesTeamRecordInsertList){
          userIdsList.add(ust.MSD_CORE_User__c);          
       }
       */
       //=======================================================

       //get all the users Country Codes which will be used to determine Access Levels for the Insert
       m_UserCountryCodesMap = MRK_UserGateway.retrieveUserCountryCodesMap(userIdsList);
        
       for ( ID userId : m_UserCountryCodesMap.keySet() ){
         countryCodeSet.add(m_UserCountryCodesMap.get(userId).MSD_CORE_Country_Code__c);
       }
       
       if(!countryCodeSet.isEmpty()){
         countryCodeList.addAll(countryCodeSet);
       }
        
       m_AccessLevelsByCountryAndObject = MRK_UserGateway.retrieveAllVisibilityRuleAccessLevelsByCountryCodesList(countryCodeList);
       //End - Cache Data needed for Share Record Access Level Calculation...
        

        //US INSTANCE
        for (User_Sales_Team_MRK__c ust: m_UserSalesTeamRecordInsertList){
        //GLOBAL INSTANCE
        //for (MSD_CORE_User_Sales_Team__c ust: m_UserSalesTeamRecordInsertList){
                   
            
            
           System.debug('Kevin e: Working with MSD_CORE_User_Sales_Team_DO record: ' + ust.id);

           List <Id> visibilityRuleIdList = new List<Id>();
           
            for (Visibility_Rule_Sales_Team_MRK__c vrst: m_AssociatedVisibilityRuleSalesTeamList){
                if (vrst.Sales_Team_MRK__c == ust.sales_Team_MRK__c){
                    visibilityRuleIdList.add(vrst.Visibility_Rule_MRK__c);
                    System.debug('Kevin f: Found associated Visibility_Rule_Sales_Team_MRK__c record: ' + vrst.id + ' And adding in VR :' + vrst.Visibility_Rule_MRK__c );
                }
            }
            
            for (Id vr : visibilityRuleIdList){

                List <Visibility_Rule_Record_MRK__c> vrrList = new List <Visibility_Rule_Record_MRK__c>();
                vrrList = m_AssociatedVisibilityRuleMap.get(vr).Visibility_Rule_Records_MRK__r;
                
                if(vrrList.size() > 0){
                    for (Visibility_Rule_Record_MRK__c vrr: vrrList){
                       String rt = m_rtMap.get(vrr.RecordTypeId).DeveloperName; 
                       String defaultAccess = 'READ';
                       String vrrObjectAPIName = rt + '__c';
                       vrrObjectAPIName = vrrObjectAPIName.toUpperCase();  
                       System.debug('KRB: Access Level: vrrObjectAPIName: ' + vrrObjectAPIName);

                       //Sharing Record Access Level Processing
                       String userAccessLevel;
                  
                         if(m_UserCountryCodesMap.containsKey(ust.User_MRK__c)){
                            System.debug('KRB: Access Level 1');
                            if(!String.isBlank(m_UserCountryCodesMap.get(ust.User_MRK__c).MSD_CORE_Country_Code__c)){
                              System.debug('KRB: Access Level 2');
                              String usersCountryCode = m_UserCountryCodesMap.get(ust.User_MRK__c).MSD_CORE_Country_Code__c;              
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
                                                                  ust.User_MRK__c,
                                                                  userAccessLevel,
                                                                  'VE_' + rt  + '__c'));                       
                    }
                }
            
            }
        }
        
    }

    
    /*
       KRB - 1/31/2014 REL 5.0 
    */
    
    private void identifyGenericShareRecordsforDeletion(){
        
        /*
            Logic required for Deletion:

             For each User Sales Team Record Deleted
                 for the given User
                    find all the VRST records that have the Sales Team Assigned (need a list of all the VRSTs that have all the Sales Teams for all the UST records deleted)
                       get a list of all the VRs from the vrst records (need a Map of all the Associated VRs for the VRSTs above)
                            for each VR, 
                                Get the VR's  VRRs
                                    for each VRR 
                                       if the User only has one sales team assigned:
                                          if the Map entry for the Presentation does not already exist, create it
                                              Add the user to the List associated to the Object Id
 

                                       if the User has multiple Sales Teams Assigned: 
                                          Get a List of all the users Sales Teams (cache this data...for all records delete, pull out the User Ids, query for the Sales teams associated and then Query for all VRST records with the list of sales teams..also, get a Map of all the associated VRs..)
                                             for each Sales Team assigned to the User
                                                get a list of all the VRST records assigned
                                                    for each vrst record
                                                        get the Associated VR
                                                            For the given VR, get a list of all the VRRs
                                                                if a match is found, NO SHARE DELETE
                                                                if a match is not found, Delete Share
                                                                
                                        
        */
        
        //We will use this Map to track what Shares, by User, we need to Delete...
        Map<Id, List<Id>> userIdToClmPresentationListForDeletion = new Map<Id, List<Id>>();
            
        //for each User/Sales Team record being deleted...
        
        //========================================================================
        //US INSTANCE
        for (User_Sales_Team_MRK__c ust: m_UserSalesTeamRecordDeletedList){
        //Global Instance    
        //for (MSD_CORE_User__c ust: m_UserSalesTeamRecordDeletedList){
        //========================================================================        
            
            
            System.debug('Kevin e: Working with MSD_CORE_User_Sales_Team_DO record: ' + ust.id);
           
            List<Id> objectIdSharesToDelete = new List<Id>();
            
            //Determine of the user has more than one sales team assigned...
            Boolean userHasMoreThanOneSalesTeamAssigned = false;
            
            for (Id userId : m_UserIdsOfUsersHavingMoreThanOneSalesTeamAssignedSet){
                if (ust.User_MRK__c == userId){
                    System.debug('Kevin f: User Has more than one Sales Team Assigned');
                    userHasMoreThanOneSalesTeamAssigned = true;
                }
            }

            //Get a list of all the VRST records that have a matching Sales Team....
            List<Visibility_Rule_Sales_Team_MRK__c> vrstRecordsHavingMatchingSalesTeamList = new List<Visibility_Rule_Sales_Team_MRK__c>();
            List<Id> vrIdsAssociatedToSalesTeamList = new List<Id>();
            System.debug('Kevin g: Locating all VRST records that have the SAles team assigned: '+ ust.Sales_Team_MRK__c);
            
            for (Visibility_Rule_Sales_Team_MRK__c vrst : m_AssociatedVisibilityRuleSalesTeamForDeletionList){
                if(vrst.Sales_Team_MRK__c == ust.Sales_Team_MRK__c){
                   System.debug('Kevin h: Found One: '+ vrst.id);

                   vrstRecordsHavingMatchingSalesTeamList.add(vrst);
                   vrIdsAssociatedToSalesTeamList.add(vrst.Visibility_Rule_MRK__c);
                }
            }
            
            /* Get a Map of all the Associated Visibility Rule Records...
               Remember, we need to Delete all Object Id VRRs Hanging off of VRs that have the same Sales
               Team identified in their VRST records.  

            */
            
            Map<Id, Visibility_Rule_MRK__c> vrsHavingAssociatedVRSTRecordsWithDeletedRecordsSalesTeamMap = 
                new Map<Id, Visibility_Rule_MRK__c>();
                
            vrsHavingAssociatedVRSTRecordsWithDeletedRecordsSalesTeamMap = 
                MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(vrIdsAssociatedToSalesTeamList);


            System.debug('Kevin i: Looping through associated VRs: ');

            for(Id vr:vrsHavingAssociatedVRSTRecordsWithDeletedRecordsSalesTeamMap.keySet()){
                System.debug('Kevin j: Working with VR: '+ vr);
                
                //Identify all the vr's VRRs
                List<Visibility_Rule_Record_MRK__c> clmPresentationVrrList = new List<Visibility_Rule_Record_MRK__c>();
                List<Visibility_Rule_Record_MRK__c> vrrList = new List<Visibility_Rule_Record_MRK__c>();
                
                vrrList = vrsHavingAssociatedVRSTRecordsWithDeletedRecordsSalesTeamMap.get(vr).Visibility_Rule_Records_MRK__r;
                
                //for each Vrr associated to this VR...
                for (Visibility_Rule_Record_MRK__c vrr: vrrList){
                   System.debug('Kevin k: Working with VRR: '+ vrr.id);
                    
                    //User has more than one Sales Team Assigned...
                    if(userHasMoreThanOneSalesTeamAssigned){
                        System.debug('Kevin l: User has more than one Sales Team');

                        List<MSD_CORE_User_Sales_Team_DO> allSalesTeamsAssignedToUser = new List<MSD_CORE_User_Sales_Team_DO>();
                        List<Id> salesTeamIds = new List<Id>();
                        
                        for (MSD_CORE_User_Sales_Team_DO userSalesTeamRecord : m_ALLUserSalesTeamRecordsForUsersInUserSalesTeamRecordDeletedList){
                            if(userSalesTeamRecord.User_MRK == ust.User_MRK__c){
                                allSalesTeamsAssignedToUser.add(userSalesTeamRecord);
                                salesTeamIds.add(userSalesTeamRecord.Sales_Team_MRK);
                                System.debug('Kevin m: User has SalesTeam :' + userSalesTeamRecord.Sales_Team_MRK);

                            }
                        }
                        List<Visibility_Rule_Sales_Team_MRK__c> allVRSTRecordsHavingAssoicatedUsersSalesTeamList = new List<Visibility_Rule_Sales_Team_MRK__c>();
                        
                        allVRSTRecordsHavingAssoicatedUsersSalesTeamList =
                            MRK_VisibilityRuleSalesTeamGateway.retrieveVisibilityRuleSalesTeamRecordsBySalesTeamIdList(salesTeamIds);
                        
                        Set<Id> vrsAssociatedToUserSalesTeamsIdSet = new Set<Id>();
                        
                        for (MSD_CORE_User_Sales_Team_DO userSalesTeam : allSalesTeamsAssignedToUser){
                            
                            for(Visibility_Rule_Sales_Team_MRK__c vrst : allVRSTRecordsHavingAssoicatedUsersSalesTeamList){
                               if(userSalesTeam.Sales_Team_MRK == vrst.Sales_Team_MRK__c ){
                                   //allVRSTRecordsHavingAssoicatedUsersSalesTeamList.add(vrst);
                                   vrsAssociatedToUserSalesTeamsIdSet.add(vrst.Visibility_Rule_MRK__c);
                               }
                           }
                        }
                            
                        
                        Boolean matchFoundGrantingSameVisibility = false;
                        
                        System.debug('Kevin n: Determining if other VRs grant the same visibility using a different sales team...');
                        
                        for(Id vrId : vrsAssociatedToUserSalesTeamsIdSet ){

                           List <Visibility_Rule_Record_MRK__c> vrrforUserList = new List <Visibility_Rule_Record_MRK__c>();
                           vrrforUserList = 
                               m_ALLVisibilityRecordsAssociatedToALLVisibilityRuleSalesTeamRecordsMap.get(vrId).Visibility_Rule_Records_MRK__r;
                        
                            for(Visibility_Rule_Record_MRK__c vrrforUser : vrrforUserList){
                                
                                   if(vrrforUser.Object_id__c == vrr.Object_id__c ){
                                   System.debug('Kevin o: found a Object_id that matches...');
                                   
                                      List <Visibility_Rule_Sales_Team_MRK__c> vrstforUserList = new List <Visibility_Rule_Sales_Team_MRK__c>();
                                      vrstforUserList = 
                                          m_ALLVisibilityRecordsAssociatedToALLVisibilityRuleSalesTeamRecordsMap.get(vrId).Visibility_Rule_Sales_Teams__r;
                                     
                                       //for each Sales Team...if the salesteam <> the sales team of the outer loop AND the Sales Team is one of the Users, we have a match
                                       for (Visibility_Rule_Sales_Team_MRK__c vrst: vrstforUserList){
                                          if(vrst.Sales_Team_MRK__c != ust.Sales_Team_MRK__c){
                                              for (MSD_CORE_User_Sales_Team_DO userSalesTeam : allSalesTeamsAssignedToUser){
                                                  if(userSalesTeam.Sales_Team_MRK == vrst.Sales_Team_MRK__c){
                                                      
                                                      System.debug('Kevin p: Found a matching VR that grants same Visibility...');
                                                      
                                                      matchFoundGrantingSameVisibility = true;
                                                  }else{
                                                      System.debug('Kevin q: No Match Found ...');
                                                      
                                                  }
                                              
                                              }
                                              
                                              
                                          }
                                       }
                                       
                                       
                                    }
                                
                            }
                            
                        }
                        
                        if(!matchFoundGrantingSameVisibility){
                        
                            String rtDeveloperName = m_rtMap.get(vrr.RecordTypeId).DeveloperName;
                            
                            objectIdSharesToDelete.add(vrr.Object_id__c);
                        
                            if(m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.get(rtDeveloperName)==null){
                                m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.put(rtDeveloperName, new List<Id>{vrr.Object_id__c});
                            } else{
                               m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.get(rtDeveloperName).add(vrr.Object_id__c);
                            }
                            
                            if(m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.get(rtDeveloperName)==null){
                                m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.put(rtDeveloperName, new List<Id>{ust.User_MRK__c});
                            } else{
                               m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.get(rtDeveloperName).add(ust.User_MRK__c);
                            }

                         }
                        
                    }else{ //If the user only has one sales team assigned...
                        System.debug('Kevin r: No Match Found ...');
                        
                        String rtDeveloperName = m_rtMap.get(vrr.RecordTypeId).DeveloperName;
                            
                        objectIdSharesToDelete.add(vrr.Object_id__c);
                        
                        if(m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.get(rtDeveloperName)==null){
                           m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.put(rtDeveloperName, new List<Id>{vrr.Object_id__c});
                        } else{
                           m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.get(rtDeveloperName).add(vrr.Object_id__c);
                        }
                        
                        if(m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.get(rtDeveloperName)==null){
                           m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.put(rtDeveloperName, new List<Id>{ust.User_MRK__c});
                        } else{
                           m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.get(rtDeveloperName).add(ust.User_MRK__c);
                        }
                    }
                }
                
            }//for(Id vr:vrsHavingAssociatedVRSTRecordsWithDeletedRecordsSalesTeamMap.keySet()){
                        
        }//for (User_Sales_Team_MRK__c ust: m_UserSalesTeamRecordDeletedList){
        
        //New Delete Method Start:
        for(String rtDeveloperName : m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.keySet()){

           List<Id> objectsToQuery = m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.get(rtDeveloperName);
           List<Id> usersToQuery = m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.get(rtDeveloperName);
            
           String objectShareName = rtDeveloperName + '__Share';   
           String RowCause = 'VE_' + rtDeveloperName + '__c';
           String query = 'SELECT Id,ParentId,UserOrGroupId FROM ' + objectShareName +  ' WHERE ParentId in : objectsToQuery AND UserOrGroupId in : usersToQuery AND RowCause = \'' + RowCause + '\'' ;
           m_sharingRulesToDelete.addAll(Database.query(query));

        }

    } 
}