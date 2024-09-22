public class MRK_VisibilityRuleSlsTeamGenericHandler implements MRK_ITrigger{
     
/* Copyright, 2016 MERCK & CO, INC., Kevin Brace ALL RIGHTS RESERVED */
    
    /* Member Variables    

*/
    
    
     SharingRulesEngine_MRK sharingRulesEngine = New SharingRulesEngine_MRK();
    
     //For Deletes
     Map <id, Visibility_Rule_MRK__c> m_VisibilityRuleDeleteMap = new Map<id, Visibility_Rule_MRK__c>();
     List <Visibility_Rule_Sales_Team_MRK__c> m_VisibilityRuleSalesTeamTriggerDeleteList = new List <Visibility_Rule_Sales_Team_MRK__c>();
     List <MSD_CORE_User_Sales_Team_DO> m_UserSalesTeamDeleteList = new List <MSD_CORE_User_Sales_Team_DO>();
     Map<Id,Visibility_Rule_MRK__c> m_visibilityRuleAssociatedToDeletedSalesTeam = new Map<Id,Visibility_Rule_MRK__c>();  
     List <Visibility_Rule_MRK__c> m_allVRsWithSameAssignedObjectIdVRR = new List <Visibility_Rule_MRK__c>();
     Set<Id> m_usersImpactedByDeletedVRSTSet = new Set<Id>();
     List<MSD_CORE_User_Sales_Team_DO> m_usersImpactedbyVRSTDeleteAndTheirAssociatedSalesTeamsList = new List<MSD_CORE_User_Sales_Team_DO>();
     List<MSD_CORE_User_Sales_Team_DO> m_UsersImpactedThatHaveMoreThanOneSalesTeamsAssignedList = new List<MSD_CORE_User_Sales_Team_DO>();
     Map<Id,List<Id>> m_ObjectIdToUsersForDeletionMap = new Map<Id,List<Id>>();
    
    
     //For Inserts and Validation
     List <Visibility_Rule_Sales_Team_MRK__c> m_visibilityRuleSalesTeamforInsertSalesTeamsMatchedList = new List <Visibility_Rule_Sales_Team_MRK__c>();
     Map<Id, Visibility_Rule_MRK__c> m_visibilityRuleForInsertsSalesTeamsMatchedMap = new Map<Id, Visibility_Rule_MRK__c>();
     List<Visibility_Rule_Record_MRK__c> m_visibilityRuleRecordsForInsertsSalesTeamsMatchedList = new List<Visibility_Rule_Record_MRK__c>();
     Map<Id, Visibility_Rule_Record_MRK__c> m_visibilityRuleRecordsForInsertsSalesTeamsMatchedCLMPresentationMap = new Map<Id, Visibility_Rule_Record_MRK__c>();
     Map<Id, Visibility_Rule_MRK__c> m_newInsertsAssociatedVisibilityRulesMap = new Map<Id, Visibility_Rule_MRK__c>();
     List<MSD_CORE_User_Sales_Team_DO> m_UserSalesTeamsAssociatedToNewVisibilityRuleSalesTeamRecordsList = new List<MSD_CORE_User_Sales_Team_DO>();
     List<MSD_CORE_Visibility_Rule_Access_Levels__c> m_AccessLevelsByCountryAndObject = new List<MSD_CORE_Visibility_Rule_Access_Levels__c>();
     Map<Id, User> m_UserCountryCodesMap = new Map<Id, User>(); 
    
     //Generic List to store the Sharing Records that need to be loaded/Deleted into the Apprioriate Sharing Table.
     private List<sObject> m_sharingRulesToInsert = new List<sObject>(); 
     private List<sObject> m_sharingRulesToDelete = new List<sObject>(); 
    
     Map<Id,RecordType>m_rtMap = new Map<Id,RecordType>();
     String m_deletedRTName = ''; 
     Map<String, List<id>> m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap = new Map<String, List<id>>();
     Map<String, List<id>> m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap = new Map<String, List<id>>();


    // Constructor
    public MRK_VisibilityRuleSlsTeamGenericHandler()
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

        //Need to do some validation prior to insert, hence the reason why we are caching now...
        if(Trigger.isInsert){
           cacheDataRequiredForVisibilityRuleSalesTeamValidationAndInsertion();    
           
           //For Inserting CLM Shares:
           createGenericShareRecordsforInsertion();
           
        }
        
        if(Trigger.isDelete){
           
           performDeleteValidation();
           
           cacheDataRequiredForVisibilityRuleSalesTeamDelete();
            
           //For Deleting CLM Shares:
           System.debug('KRB: deleting 1');
           identifyShareRecordsforDeletion();
        }
    }
    
    public void bulkAfter()
    {       
    }
        
    public void beforeInsert(SObject so)
    {
        /* 
           Validate each record inserted to ensure:
           1. The sales team / visibility rule doesn't already exist in another VR.
           2. The VR that the VRST record is getting assigned to doesn't already have the same sales team added.
        */
        
        validateVisibilityRuleSalesTeamRecordIsUniqueForAssociatedVisibilityRule(so);
        validateVisibilityRuleSalesTeamVisibilityRuleRecordisUniqueAcrossAllVisibilityRules(so);
        
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
            if(m_sharingRulesToInsert.size() > 0){
               insert m_sharingRulesToInsert;
            }
        }
    }
    
    //Custom Methods:

    
    /* *************************
       Validation Methods:
    ************************** */
    
    /*
       KRB - 1/31/2014 REL 5.0 
        Limits Deletes on Visibilty Rule Sales Team Records to one at a time. 
    */

    private void performDeleteValidation(){
       List <Visibility_Rule_Sales_Team_MRK__c> visibilityRuleSalesTeamDeletedList = Trigger.old;
        if (visibilityRuleSalesTeamDeletedList.size() > 1){
            throw new MRK_TriggerException('You can not Delete more than one Visibility Rule Sales Team Record at a time.');
        }
    }
    

    /*
       KRB - 1/31/2014 REL 5.0 
       KRB - 4/2016 OA completed
    */
    
    private void validateVisibilityRuleSalesTeamRecordIsUniqueForAssociatedVisibilityRule(SObject so){
        
        Visibility_Rule_Sales_Team_MRK__c newVisibilityRuleSalesTeamRecord = (Visibility_Rule_Sales_Team_MRK__c)so; 
        
        //look up the VR assigned to it and validate the Sales Team is not already assigned.       
        Map<Id, Visibility_Rule_MRK__c> vrMap = new Map<Id, Visibility_Rule_MRK__c>();
                                          
        vrMap = MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleId(newVisibilityRuleSalesTeamRecord.Visibility_Rule_MRK__c);
    
        List <Visibility_Rule_Sales_Team_MRK__c> vrstList = new List <Visibility_Rule_Sales_Team_MRK__c>();
        vrstList= vrMap.get(newVisibilityRuleSalesTeamRecord.Visibility_Rule_MRK__c).Visibility_Rule_Sales_Teams__r;
        
        for (Visibility_Rule_Sales_Team_MRK__c vrst : vrstList){
            if (vrst.sales_team_MRK__c == newVisibilityRuleSalesTeamRecord.Sales_Team_MRK__c){
               so.addError('Sales Team already Exists for this Visibility Rule. This record cannot be saved.');
            }
        }
 
    }
    

    /*
       KRB - 1/31/2014 REL 5.0 
       KRB - 4/2016 OA Complete
    */
    
    private void validateVisibilityRuleSalesTeamVisibilityRuleRecordisUniqueAcrossAllVisibilityRules(SObject so){
         
        //need to ensure that no other rules have the same Sales Team and associated Visibility Rules Records assigned to a Visibility Rule
        //New record VR Map: m_newInsertsAssociatedVisibilityRulesMap
        //Existing VR records that have matching sales Teams: m_visibilityRuleForInsertsSalesTeamsMatchedMap

        Visibility_Rule_Sales_Team_MRK__c newVisibilityRuleSalesTeamRecord = (Visibility_Rule_Sales_Team_MRK__c)so; 

        List <Visibility_Rule_Record_MRK__c> vrrsAssociatedToNewVisibilityRuleSalesTeamRecordList = new List <Visibility_Rule_Record_MRK__c>();
        vrrsAssociatedToNewVisibilityRuleSalesTeamRecordList = 
            m_newInsertsAssociatedVisibilityRulesMap.get(newVisibilityRuleSalesTeamRecord.Visibility_Rule_MRK__c).Visibility_Rule_Records_MRK__r;
         
        //Loop through each existing VR....find the VRs that have matching Sales Team.....create a list of VRRs that have CLM Pres populated
        List <Visibility_Rule_Record_MRK__c> existingVrrsThatHaveMatchingSalesTeamsList = new List<Visibility_Rule_Record_MRK__c>();
        
        for (Visibility_Rule_MRK__c vr : m_visibilityRuleForInsertsSalesTeamsMatchedMap.values()){
            //find matching sales teams in the vr...
            List<Visibility_Rule_Sales_Team_MRK__c> visibilityRuleSalesTeamList = new List<Visibility_Rule_Sales_Team_MRK__c>();
            
            visibilityRuleSalesTeamList = vr.Visibility_Rule_Sales_Teams__r;
            
            for (Visibility_Rule_Sales_Team_MRK__c visibilityRuleSaleTeam : visibilityRuleSalesTeamList){
                
                if(visibilityRuleSaleTeam.Sales_Team_MRK__c == newVisibilityRuleSalesTeamRecord.Sales_Team_MRK__c){
                     //compare the CLM Type VRRs associated to the VR and see if there is a match....
                     
                     List<Visibility_Rule_Record_MRK__c> visibilityRuleRecordsList = new List<Visibility_Rule_Record_MRK__c>();
            
                     visibilityRuleRecordsList = vr.Visibility_Rule_Records_MRK__r;
                    
                    for (Visibility_Rule_Record_MRK__c visibilityRuleRecord : visibilityRuleRecordsList ){
                        
                       for (Visibility_Rule_Record_MRK__c vrr : vrrsAssociatedToNewVisibilityRuleSalesTeamRecordList){
                          if (vrr.Object_Id__c == visibilityRuleRecord.Object_Id__c ){
                             so.addError('Adding this Sales Team will create a Duplicate Visibility Rule. This Sales Team cannot be used for this Visibility Rule.');
                          }
                       }
                    }
                }
            }
        }
    }

    
    /*
       KRB - 1/31/2014 REL 5.0 
       KRB - OA 4/2016 Completed
    */

    private void cacheDataRequiredForVisibilityRuleSalesTeamValidationAndInsertion(){
        
        /*
        Before Insert, we need to validate that the following Combo does not already exist...even in the current VR.
        Sales Team -> Presentation 
        *AND* make sure we don't already have a record in the Visibility Rule Sales Team Object that is already assigned to this VR 
           with the same sales team....
        */
        List <Visibility_Rule_Sales_Team_MRK__c> visibilityRuleSalesTeamInsertList = Trigger.new;
        
        List<Id> salesTeamIdList = new List<Id>();
        List<Id> visibilityRuleIdList = new List<Id>();
        
        for (Visibility_Rule_Sales_Team_MRK__c vrst: visibilityRuleSalesTeamInsertList){
            salesTeamIdList.add(vrst.sales_Team_MRK__c);
            visibilityRuleIdList.add(vrst.Visibility_Rule_MRK__c);
        }
                
        m_visibilityRuleSalesTeamforInsertSalesTeamsMatchedList = MRK_VisibilityRuleSalesTeamGateway.retrieveVisibilityRuleSalesTeamRecordsBySalesTeamIdList(salesTeamIdList);
        
        //get a Map of associated VRs
        List<Id> vrIdList = new List<Id>(); 
        
        for (Visibility_Rule_Sales_Team_MRK__c vrst : m_visibilityRuleSalesTeamforInsertSalesTeamsMatchedList){
            vrIdList.add(vrst.Visibility_Rule_MRK__c);
        }
                                                                          
        m_visibilityRuleForInsertsSalesTeamsMatchedMap = MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(vrIdList);
        
        List<Id> vrIds = new List<Id>();
        
        for (Id vrId : m_visibilityRuleForInsertsSalesTeamsMatchedMap.keySet()){
           vrIds.add(vrId);
        }
    
        //need to get a List of all the Newly Inserted Records' associated VR records (to compare their VRRs against existing VRs that have matching Sales Teams...)
        m_newInsertsAssociatedVisibilityRulesMap = MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(visibilityRuleIdList);
                                                                 
        m_UserSalesTeamsAssociatedToNewVisibilityRuleSalesTeamRecordsList = MRK_UserSalesTeamGateway.retrieveUsersAssociatedToSalesTeamList(salesTeamIdList);
    
        // 4/2016 - Access Level Data Caching...
        //Get a unique set of Country Codes for the Users...
        Set<String> countryCodeSet = new Set<String>();
        List<String> countryCodeList = new List<String>();

        Set<Id> userIds = new Set<Id>();
        List<Id> userIdsList = new List<Id>(); 
        
        for(MSD_CORE_User_Sales_Team_DO ustRec: m_UserSalesTeamsAssociatedToNewVisibilityRuleSalesTeamRecordsList){
            userIds.add(ustRec.User_MRK);
        }
        
        if(!userIds.isEmpty()){
            userIdsList.addAll(userIds); 
        }
        
        //get all the users Country Codes which will be used to determine Access Levels for the Insert
        m_UserCountryCodesMap = MRK_UserGateway.retrieveUserCountryCodesMap(userIdsList);
        
       for ( ID userId : m_UserCountryCodesMap.keySet() ){
         countryCodeSet.add(m_UserCountryCodesMap.get(userId).MSD_CORE_Country_Code__c);
       }
       
        if(!countryCodeSet.isEmpty()){
            countryCodeList.addAll(countryCodeSet);
        }
        
        m_AccessLevelsByCountryAndObject = MRK_UserGateway.retrieveAllVisibilityRuleAccessLevelsByCountryCodesList(countryCodeList);
    
    }
      
    /*
       KRB - 1/31/2014 REL 5.0 
       KRB - 4/2016 OA Complete
    */

    private void createGenericShareRecordsforInsertion(){
        List <Visibility_Rule_Sales_Team_MRK__c> newVisibilityRuleSalesTeam = Trigger.new;

        /* need the following information to Process :
           1. need a Map of all the VR associated to the new vrst records 
           2. All the User Sales Team Records that are associated to the Sales Teams on the New Records
           
           LOGIC:
             for each Visibility_Rule_Sales_Team record....
        	    Find all users assigned to that Sales Team
        	    Find all VRRs assigned to the associated VR on the Sales Team Record...
                Create the Share Record to be Loaded in the Finally Method....
       */
       
        for  (Visibility_Rule_Sales_Team_MRK__c vrst: newVisibilityRuleSalesTeam){
            system.debug('kevin 1');
            List<Id> userIds = new List<Id>();
            
            //Get a list of all the Users that Sharing Rules will need to be created for
            for (MSD_CORE_User_Sales_Team_DO ust : m_UserSalesTeamsAssociatedToNewVisibilityRuleSalesTeamRecordsList){
            system.debug('kevin 2');

                if (ust.Sales_Team_MRK == vrst.sales_team_MRK__c){
                    system.debug('kevin 3');
                    userIds.add(ust.User_MRK);
                }
            }

            //Get a list of all the Object Ids that are included in Visibility Rule Records assigned to the same Visibility Rule...
            List <Visibility_Rule_Record_MRK__c> allVrrs = new List <Visibility_Rule_Record_MRK__c>();
            List <Visibility_Rule_Record_MRK__c> vrrs = new List <Visibility_Rule_Record_MRK__c>();
            vrrs = m_newInsertsAssociatedVisibilityRulesMap.get(vrst.Visibility_Rule_MRK__c).Visibility_Rule_Records_MRK__r;
        
            for (Visibility_Rule_Record_MRK__c vrr : vrrs ){
                    system.debug('kevin 5');
                    allVrrs.add(vrr);
            }
            
            //add records to the share collection for insertion...for each CLM Presentation, add a share for each User...
        
            for(Visibility_Rule_Record_MRK__c vrr: allVrrs){
              String rt = m_rtMap.get(vrr.RecordTypeId).DeveloperName; 
              //String accessLvl = vrr.MSD_CORE_Access_Level__c;
              String defaultAccess = 'READ';
              String vrrObjectAPIName = rt + '__c';
              vrrObjectAPIName = vrrObjectAPIName.toUpperCase();  
              System.debug('KRB: Access Level: vrrObjectAPIName: ' + vrrObjectAPIName);

              for (Id userId : userIds){
                  System.debug('KRB: Access Level 0: UserId ' + userId);
                  
                  
                  //Sharing Record Access Level Processing
                  String userAccessLevel;
                  
                  if(m_UserCountryCodesMap.containsKey(userId)){
                      System.debug('KRB: Access Level 1');
                      if(!String.isBlank(m_UserCountryCodesMap.get(userId).MSD_CORE_Country_Code__c)){
                          System.debug('KRB: Access Level 2');
                          String usersCountryCode = m_UserCountryCodesMap.get(userId).MSD_CORE_Country_Code__c;              
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
                                 }else{
                                     System.debug('KRB: Access Level 5: NO Match Found');
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
                  system.debug('kevin 7');
                  m_sharingRulesToInsert.add(SharingRulesEngine.createShareObj(
                                                                  rt + '__Share',
                                                                  vrr.Object_Id__c,
                                                                  userId,
                                                                  userAccessLevel,
                                                                  'VE_' + rt  + '__c'));

             }
           }
        }
        
        system.debug('size of collection for insertion is: ' + m_sharingRulesToInsert.size() );
    }
       

    /*
       KRB - 1/31/2014 REL 5.0
       KRB - 4/2016 OA...
    */

    private void cacheDataRequiredForVisibilityRuleSalesTeamDelete(){
        m_VisibilityRuleSalesTeamTriggerDeleteList = Trigger.old;
        
        List <id> vrstIds = new List <id>();
        
        for (Visibility_Rule_Sales_Team_MRK__c visibilityRuleSalesTeamDelete : m_VisibilityRuleSalesTeamTriggerDeleteList){
            vrstIds.add(visibilityRuleSalesTeamDelete.Visibility_Rule_MRK__c);
        }
        
        //Retrieve all the VRs and VRRs that have the Sales Team Assigned
        m_visibilityRuleDeleteMap = MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleIdsList(vrstIds);
       
        //Retrieve all the Users assigned to the Sales Teams that are getting deleted
        List <Id> salesTeamIdList = new List <Id>();
        
        for(Visibility_Rule_Sales_Team_MRK__c visibilityRuleSalesTeam: m_VisibilityRuleSalesTeamTriggerDeleteList){
           salesTeamIdList.add(visibilityRuleSalesTeam.sales_team_MRK__c);
        
        }
        
        //Retrieve a List of all the User Sales Team Records Impacted
        m_UserSalesTeamDeleteList = MRK_UserSalesTeamGateway.retrieveUsersAssociatedToSalesTeamList(salesTeamIdList);
        
        
        //Get a unique set of Users impacted for the Deleted VR Sales Team...

        List<Id> userIdList = new List<Id>();
        
        for (MSD_CORE_User_Sales_Team_DO ust: m_UserSalesTeamDeleteList){
            m_usersImpactedByDeletedVRSTSet.add(ust.User_MRK);
        }
        
        //convert to List 
        for(Id userId : m_usersImpactedByDeletedVRSTSet){
            userIdList.add(userId);
        }
        
        m_usersImpactedbyVRSTDeleteAndTheirAssociatedSalesTeamsList = 
            MRK_UserSalesTeamGateway.retrieveUserSalesTeamRecordsbyUserId(userIdList);   
        
        //CLM Presentation Specific Caching Methods...
        cacheDataRequiredforVisbilityRuleRecordsAssociatedToVisibilityRuleSalesTeamDeletes();
        
        //Get a list of Users that have more than One Sales Team....
        m_UsersImpactedThatHaveMoreThanOneSalesTeamsAssignedList = 
            MRK_UserSalesTeamGateway.retrieveUserSalesTeamListOfUsersHavingMoreThanOneSalesTeamAssignedbyUserIdList(userIdList);
        
        
    }


    /*
       KRB - 1/31/2014 REL 5.0 
       KRB - 4/2016 OA Complete
    */
    
    private void cacheDataRequiredforVisbilityRuleRecordsAssociatedToVisibilityRuleSalesTeamDeletes(){
        
        /* For the Visibility Rule Sales Team Deleted
              Get a list of all the Visibility Rule Records associated to the VR the deleted Sales Team is associated to
                Get a Map of all the Visibility Rules that have these Object Ids Assigned to it
        */
        
        Visibility_Rule_Sales_Team_MRK__c vrst = m_VisibilityRuleSalesTeamTriggerDeleteList[0];
        m_visibilityRuleAssociatedToDeletedSalesTeam = MRK_VisibilityRuleGateway.retrieveGenericVisiblityRuleMapbyVisibilityRuleId(vrst.Visibility_Rule_MRK__c);
        
        if (m_visibilityRuleAssociatedToDeletedSalesTeam.isEmpty()){
            System.debug('Kevin: m_visibilityRuleAssociatedToDeletedSalesTeam was empty...');
            Return;
        }
        
        List <Visibility_Rule_Record_MRK__c> vvrs = new List <Visibility_Rule_Record_MRK__c>();
        vvrs = m_visibilityRuleAssociatedToDeletedSalesTeam.get(vrst.Visibility_Rule_MRK__c).Visibility_Rule_Records_MRK__r;
        
        if(vvrs.size() == 0){
            return;
        }
        
        List <Id> objectIdImpactedList = new List <Id>();
         
        for (Visibility_Rule_Record_MRK__c vrr : vvrs){
           objectIdImpactedList.add(vrr.Object_Id__c);
        }
        
        //Get a Map of all the VRs that have these CLM Presentations assigned to them...
        List<Visibility_Rule_MRK__c> vrs =  MRK_VisibilityRuleGateway.findVisibilityRulesAssociatedtoVRRObjectIds(objectIdImpactedList);
        
        system.debug('Kevin: Size of vrs is ' + vrs.size());
        //Note, we are keeping the VR associated to the Deleted VR Sales Team because there might be another Sales Team Assigned to it that 
        //grants a User (with Multiple Sales Teams) access to the same CLM Presentation
        //We do want to weed out all VRs that have no VR Sales Teams Assigned...
        
        for (Visibility_Rule_MRK__c vr : vrs ){
            List <Visibility_Rule_Sales_Team_MRK__c> visibilityRuleSalesTeams = new List <Visibility_Rule_Sales_Team_MRK__c>();            
            visibilityRuleSalesTeams = vr.Visibility_Rule_Sales_Teams__r;
            
            if(visibilityRuleSalesTeams.size() > 0 ){
                m_allVRsWithSameAssignedObjectIdVRR.add(vr);
            }
        }
    }

    
    /*
       KRB - 1/31/2014 REL 5.0 
       KRB - 4/2016 OA Complete
    */
    
    private void identifyShareRecordsforDeletion(){
        System.debug('KRB: deleting 2');
        Map<String,Id> objectIdToRecordTypeIdMap = new Map<String,Id>();  

        
        /* For each Visibility Rule Sales Team deleted, 
			Retrieve the Associated Visibility Rule using the Visibility Rule Sales Team's Visibility Rule Id
				For the Given Visibility Rule, retrieve all the associated Visibility Rule Records
                        -get a list of users that are assigned to the Sales Team.
                            - Validate that no other rule grants the same visibility as the one to be deleted...
                        
 		                     Call out to Delete the Shares - .  */
		/*
           Note: There are different list of users to delete per VRR impacted. Reason is that another VR could grant access to the 
                  same Object rec but have a different Sales Team Assigned that one of the users impacted by this VR Sales Team
                  is part of. Because of this, we need to handle each VRR Deletion Seperately, with a separate set of Users impacted.
                  A Map was created to adress this: m_ObjectIdtoUsersForDeletionMap
                  The Id = the Presentation Id and the Value, a List, is a list of the Users impacted that need to have their share deleted...
                  This Map will be passed to the Class' Finally() method so that it can properly preform the deletion of the CLM Shares....
        
         */

        List<Visibility_Rule_Record_MRK__c> vrrObjectIdsRelatedToVRSTDeletedList = new List<Visibility_Rule_Record_MRK__c>();
        
        Visibility_Rule_Sales_Team_MRK__c vrstBeingDeleted = m_VisibilityRuleSalesTeamTriggerDeleteList[0];
        
        //For each CLM VRR assigned to the related VR, get list of Object's shared....
        List <Visibility_Rule_Record_MRK__c> visibilityRuleRecordsAssociatedToDeletedVRST = 
            m_visibilityRuleAssociatedToDeletedSalesTeam.get(vrstBeingDeleted.Visibility_Rule_MRK__c).Visibility_Rule_Records_MRK__r;
        
        for (Visibility_Rule_Record_MRK__c vrr : visibilityRuleRecordsAssociatedToDeletedVRST){
               vrrObjectIdsRelatedToVRSTDeletedList.add(vrr); 
        }
        
        //For each CLM Presentation VRR assigned to the Visibility Rule that is associated to the Sales Team being Deleted...
        for (Visibility_Rule_Record_MRK__c objectVrr: vrrObjectIdsRelatedToVRSTDeletedList){
            
            system.debug('Kevin b: working with VRR - Id: ' + objectVrr.Id);
            
            //do a delete for each VRR in the Finally() Method. Users impacted could be different due to other VRs granting the same access...
            
            List<Id> userIdsToDelete = new List<Id>();
           
            //For each User impacted by the Deleted VR Sales Team...
            for(Id userId : m_usersImpactedByDeletedVRSTSet){
                
                system.debug('Kevin c: Working with User impacted by deleted vrst - User Id: ' + userId);
                
                Boolean matched = false;
                
                //First, lets determine if we need to do the following logic.
                //If the User only has one sales team assigned, No Need for the Logic...
                for (MSD_CORE_User_Sales_Team_DO userWithMultipleSalesTeams : m_UsersImpactedThatHaveMoreThanOneSalesTeamsAssignedList){
                    if(userWithMultipleSalesTeams.User_MRK == userId ){
                        matched = true;
                    }
                }
                
               Boolean matchedSalesTeam = false;
                
               if(matched){
                     
                    //User has more than one sales Team...
                    system.debug('Kevin d: User has more then one sales team..processing ST Matching Logic...');
                    
                    //get a list of sales teams assigned to the User...
                   List<Id> usersAssignedSalesTeams = new List<Id>();
                   
                   system.debug('Kevin e: Users assigned Sales Teams...');
                   
                   for (MSD_CORE_User_Sales_Team_DO ust: m_usersImpactedbyVRSTDeleteAndTheirAssociatedSalesTeamsList){
                     if (ust.User_MRK == userId){
                        usersAssignedSalesTeams.add(ust.Sales_Team_MRK);
                        system.debug('Kevin f: Sales Team Id: ' + ust.Sales_Team_MRK);
    
                     }
                   }

                   /*Loop through each of the User's Sales Teams..
                     Loop through each of the Visibility Rules (make sure the VRR CLM Pres matches..
                        and see if the same sales team is assigned...
                     If match is found, this individual does not get added to the list...
                   */
                    
                    for(Id salesTeamId : usersAssignedSalesTeams){
                        
                        system.debug('Kevin g: Working with Sales Team Id: ' + salesTeamId);
                        
                        for (Visibility_Rule_MRK__c vr: m_allVRsWithSameAssignedObjectIdVRR){
    
                           system.debug('Kevin h: Working with VR: ' + vr.Id);
                            
                            
                           List<Visibility_Rule_Record_MRK__c> vrrList = vr.Visibility_Rule_Records_MRK__r;
                           List<Visibility_Rule_Sales_Team_MRK__c> vrstList = vr.Visibility_Rule_Sales_Teams__r;
                            
                            for (Visibility_Rule_Record_MRK__c vrr : vrrList){
                                system.debug('Kevin i: Working with VRR: ' + vrr.Id);

                                if(vrr.Object_Id__c == objectVrr.Object_Id__c){

                                    system.debug('Kevin j: Presentations Match!' );
                                    //see if any of the sales teams assigned to the VR match the sales team for the user...
                                    
                                    for (Visibility_Rule_Sales_Team_MRK__c vrst: vrstList){
                                       //Note: We need to make sure we aren't looking at the same VRST record that just got deleted! 
                                       system.debug('Kevin k: working with vest Id' + vrst );

                                        if((vrst.sales_team_MRK__c == salesTeamId) && (vrst.id != vrstBeingDeleted.id)){
                                            system.debug('Kevin l: we found a match! not adding user to delete List' );
                                            matchedSalesTeam = true;
                                       }
                                    }

                                }
                            }
                        }
                        
                    }
                    

                }
                
                
                if (!matchedSalesTeam){
                   userIdsToDelete.add(userId);
                }else{
                   System.debug('Kevin: We found a matching Sales team...not adding User to the list for deletion');
                }

             }//for(Id userId : m_usersImpactedByDeletedVRSTSet){
                    
           m_ObjectIdToUsersForDeletionMap.put(objectVrr.Object_id__c, userIdsToDelete);
           
           //new Map for Dynamic Deletion 4/2016:
           //Map<RecordType, <List of Users>>
           //Map<RecordType, <List of Object Ids>>
           //New KRB 4/2016 
            String rtDeveloperName = m_rtMap.get(objectVrr.RecordTypeId).DeveloperName; 
            //Need to do the below routine to build the dynamic Query  below....
            if(!userIdsToDelete.isEmpty()){
               if(m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.get(rtDeveloperName)==null){
                  m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.put(rtDeveloperName, userIdsToDelete.clone());
               } else{
                  m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.get(rtDeveloperName).addAll(userIdsToDelete.clone());
               }
            
               if(m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.get(rtDeveloperName)==null){
                  m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.put(rtDeveloperName, new List<Id>{objectVrr.Object_id__c});
               } else{
                  m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.get(rtDeveloperName).add(objectVrr.Object_id__c);
               }
            }
           
        }//for (Visibility_Rule_Record_MRK__c clmPresentationVrr: vrrCLMPresentationRelatedToVRSTDeletedList){
        
        //New Delete Method Start:
        for(String rtDeveloperName : m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.keySet()){
            
           System.debug('KRB: deleting 2'); 

           List<Id> objectsToQuery = m_sharesToDeleteRecordTypeIdtoListOfObjectIdsMap.get(rtDeveloperName);
           
           System.debug('KRB: deleting 3');
           List<Id> usersToQuery = m_sharesToDeleteRecordTypeIdtoListOfUserIdsMap.get(rtDeveloperName);
           System.debug('KRB: deleting 4');
            
           String objectShareName = rtDeveloperName + '__Share';   
           String RowCause = 'VE_' + rtDeveloperName + '__c';
           String query = 'SELECT Id,ParentId,UserOrGroupId FROM ' + objectShareName +  ' WHERE ParentId in : objectsToQuery AND UserOrGroupId in : usersToQuery AND RowCause = \'' + RowCause + '\'' ;
           
           List<sObject> queryResults = new List<sObject>();
           queryResults = Database.query(query);
           
            if(!queryResults.isEmpty()){
              m_sharingRulesToDelete.addAll(queryResults);  
            }
            
        }
     }
        
}