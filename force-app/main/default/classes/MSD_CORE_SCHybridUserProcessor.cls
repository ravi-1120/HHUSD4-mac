/*
   KRB 5/2024 - 24R2.0  -Created to support Service Cloud Hybrid Users. Allows users to switch their Profile and Role
				- Users Navigate to the Advance User Details Page and select a new Profile and Role in the Switch To Picklist Field
				- This process reads that selection and: 
						-Updates the User's Profile and Role Fields accordingly.
						-Updates the Permission Sets assigned to the selected Profile and Role
						-Updates the Swtich To Field to Null, reseting the process. 
*/

public class MSD_CORE_SCHybridUserProcessor {
    
    public void processHybridUsers(){

       List<User> usersToProcess = new List<User>();
       Set<String> profilesRolesToProcessSet = new Set<String>();
       List<String> profilesRolesToProcessList = new List<String>();
       Set<String> uniqueProfilesToQuerySet = new Set<String>();
       Set<String> uniqueRolesToQuerySet = new Set<String>();
       List<String> uniqueProfilesToQueryList = new List<String>();
       List<String> uniqueRolesToQueryList = new List<String>();
       Map<ID, Profile> profileMap = new Map<ID, Profile>();    
       Map<ID, UserRole> roleMap = new Map<ID, UserRole>();  
       List<User> usersToUpdate = new List<User>();
                
       //Permission Set Assignment 
       List<Id> userIdList = new List<Id>();
       List<PermissionSetAssignment> allExistingPermissionSetUserAssignments = new List<PermissionSetAssignment>();
       List<PermissionSetAssignment> allExistingPermissionSetAssignmentToDeleteList = new List<PermissionSetAssignment>();
       Map<Id, String> UserLastNameByIdMap = new Map<Id, String>();
       List<PermissionSetAssignment> permissionSetAssignmentsToInsert = new List<PermissionSetAssignment>();
        
       //Get all Users where MSD_CORE_Switch_To__c is not null
       usersToProcess = new List<User>([SELECT Id,
                                               FirstName,
                                               LastName,
                                        	   ProfileId, 
                                               UserRoleId,
                                               MSD_CORE_Switch_To__c
                                        FROM   User 
                                        WHERE  MSD_CORE_Switch_To__c != null ]);
        
       //Quick Exit if there is nothing to Process...
       if(usersToProcess.isEmpty()){
          System.debug('KRB: No Users to Process. Exiting.');
          return;
       }
              
       //Get a list of the Profiles and Roles that need to be Processed:
       for(User u: usersToProcess) {
          profilesRolesToProcessSet.add(u.MSD_CORE_Switch_To__c); 
          System.debug('KRB: Profiles and Roles to Process: ' + profilesRolesToProcessSet);
           
          //Used in the Permission Set Assignment Logic below 
          userIdList.add(u.id);
          UserLastNameByIdMap.put(u.id, u.LastName);
       }
        
       // ----------------------------------------------------------------------------------------- 
       // Figure out what existing Permission Sets should be Deleted...before we assign new ones...
       // Create a List of all the PermissionSetAssignment Records to Delete
       // ----------------------------------------------------------------------------------------- 

       //Get a list of all PermissionSetAssignment records that need to be deleted. We want to clean out the old and add all new. 
       allExistingPermissionSetUserAssignments = 
           new List<PermissionSetAssignment>([SELECT AssigneeId,
                                                     Id,
                                                     PermissionSetId
                                              FROM   PermissionSetAssignment 
                                              WHERE  AssigneeId in : userIdList]);
       
        //Weed out all PermissionSets that are Profile Owned - can't delete these! 
        
        //Get a list of unique Permission Set Ids to use in Query...
        Set<Id> allExistingPermissionSetUserAssignmentsSet = new Set<Id>();
        for(PermissionSetAssignment permSetAssignRec: allExistingPermissionSetUserAssignments){
            allExistingPermissionSetUserAssignmentsSet.add(permSetAssignRec.PermissionSetId);
        }
        
        List<Id> allExistingPermissionSetUserAssignmentsList = new List<Id>();
        allExistingPermissionSetUserAssignmentsList.addAll(allExistingPermissionSetUserAssignmentsSet);
        
        Map<ID, PermissionSet> permissionSetMap = new Map<ID, PermissionSet>();
        permissionSetMap = new Map<ID, PermissionSet>([SELECT Id, 
                                                              IsOwnedByProfile, 
                                                              Label, 
                                                              Name 
                                                       FROM   PermissionSet 
                                                       WHERE  Id in :allExistingPermissionSetUserAssignmentsList]);
        
         for(PermissionSetAssignment permSetAssignment: allExistingPermissionSetUserAssignments){
            if(permissionSetMap.get(permSetAssignment.PermissionSetId).IsOwnedByProfile == FALSE){
                allExistingPermissionSetAssignmentToDeleteList.add(permSetAssignment);
            } 
        }
        
        System.debug('KRB: List of PermissionSet Assignments we will be deleting: ');
        for(PermissionSetAssignment psa: allExistingPermissionSetAssignmentToDeleteList ){
           System.debug('KRB: LastName: ' + UserLastNameByIdMap.get(psa.AssigneeId) + ' Permission Set Name: ' + permissionSetMap.get(psa.PermissionSetId).Name + + ' Permission Set Label: ' + permissionSetMap.get(psa.PermissionSetId).Label);
        }
        
       // ----------------------------------------------------------------------------------------- 
        
       //split out the Profile and Roles -> dedupped
        for(String profilesRoleStr: profilesRolesToProcessSet ){

            List<String> res = profilesRoleStr.split(';', 2);
			
            System.debug('KRB: MSD_CORE_SCHybridUserProcessor: Role:' + res[0] + ' Profile: ' + res[1]);
			
            String role = res[0];
            List<String> splitRole = role.split(':', 2);
            String finalRoleValue = splitRole[1];
			String trimmedRole = finalRoleValue.trim();

            String profile = res[1];
            List<String> splitProfile = profile.split(':', 2);
            String finalProfileValue = splitProfile[1];
			String trimmedProfile = finalProfileValue.trim();

            System.debug('KRB: MSD_CORE_SCHybridUserProcessor: trimmed Role: ' + trimmedRole);
			System.debug('KRB: MSD_CORE_SCHybridUserProcessor: trimmed Profile: ' + trimmedProfile);

            uniqueProfilesToQuerySet.add(trimmedProfile);
            uniqueRolesToQuerySet.add(trimmedRole);
            
        }
        
        //Get a Map of Selected Profiles and Roles that we will need Ids for for Processing the Hybrid Users. 
        System.debug('KRB: Getting a map of Selected Profiles and Roles we will need Ids for...');

        uniqueRolesToQueryList.addAll(uniqueRolesToQuerySet);
        uniqueProfilesToQueryList.addAll(uniqueProfilesToQuerySet);
	    
        System.debug('KRB: uniqueRolesToQueryList: ' + uniqueRolesToQueryList);
        System.debug('KRB: uniqueProfilesToQueryList: ' + uniqueProfilesToQueryList);
                
        profileMap = new Map<ID, Profile>([SELECT Id, Name FROM Profile WHERE name in :uniqueProfilesToQueryList]);    
        roleMap = new Map<ID, UserRole>([SELECT Id, Name FROM UserRole WHERE name in :uniqueRolesToQueryList]);  
        
        System.debug('KRB: User Selected profileMap: ' + profileMap );
        System.debug('KRB: User Selected roleMap: ' + roleMap );
        
        // ----------------------------------------------------------------------------------------
        // Get all the PermissionSet information that is needed. 
        // ----------------------------------------------------------------------------------------

        List<MSD_CORE_Hybrid_User_PermissionSets__c> profileNmToPermissionSetList = new List<MSD_CORE_Hybrid_User_PermissionSets__c>();

        System.debug('KRB: Pulling a list of the MSD_CORE_Hybrid_User_PermissionSets__c records related to the Users Selections...');

        profileNmToPermissionSetList = 
                new List<MSD_CORE_Hybrid_User_PermissionSets__c>([SELECT MSD_CORE_ProfileNm__c,
                                                                         MSD_CORE_PermSetNm__c,
                                                                         MSD_CORE_Role_Nm__c
                                                                  FROM   MSD_CORE_Hybrid_User_PermissionSets__c 
                                                                  WHERE  MSD_CORE_ProfileNm__c in : uniqueProfilesToQueryList
                                                                  AND    MSD_CORE_Role_Nm__c in :uniqueRolesToQueryList]);
        
        System.debug('KRB: Found the following MSD_CORE_Hybrid_User_PermissionSets__c records based in the Users Selections...');
 
        for(MSD_CORE_Hybrid_User_PermissionSets__c hupRec: profileNmToPermissionSetList ){
            System.debug('KRB: Profile Name: ' + hupRec.MSD_CORE_ProfileNm__c + ' PermissionSet Name: ' + hupRec.MSD_CORE_PermSetNm__c + ' Role Name: ' + hupRec.MSD_CORE_Role_Nm__c);
        }
        
        Map<ID, PermissionSet> permissionSetIdNameMap = new Map<ID, PermissionSet>();  

        if(!profileNmToPermissionSetList.isEmpty()){
           
           Set<String> uniquePermissionSetNamesToQuerySet = new Set<String>();
           List<String> PermissionSetNameListforQuery = new List<String>();
 
           //get a unique list of PermissionSet names to Query
           for(MSD_CORE_Hybrid_User_PermissionSets__c rec : profileNmToPermissionSetList){
                uniquePermissionSetNamesToQuerySet.add(rec.MSD_CORE_PermSetNm__c);
           }
            
           PermissionSetNameListforQuery.addAll(uniquePermissionSetNamesToQuerySet);
           System.debug('KRB: unique list of PermissionSet Names that will be used to query for a Permission Set Id...');
           System.debug('KRB: ' + PermissionSetNameListforQuery);
            
           permissionSetIdNameMap = new Map<ID, PermissionSet>([SELECT Id, Name FROM PermissionSet WHERE name in :PermissionSetNameListforQuery]);    
        }else{
          System.debug('KRB: Could not find any Associated records in the MSD_CORE_Hybrid_User_PermissionSets__c Object based on the Users Profile/Role Selections...');  
        }
        
        // ----------------------------------------------------------------------------------------
       
        //Now that we have all the metadata to do the updates, let process all the requests:
        for(User u: usersToProcess) {

            System.debug('MSD_CORE_SCHybridUserProcessor: Processing User: ' + u.FirstName + ' ' + u.LastName);

            List<String> userSwitchToValue = u.MSD_CORE_Switch_To__c.split(';', 2);
			System.debug('MSD_CORE_SCHybridUserProcessor: Role Selected:' + userSwitchToValue[0] + ' Profile Selected: ' + userSwitchToValue[1]);

            String newUserRoleName = userSwitchToValue[0];
            List<String> userSplitRole = newUserRoleName.split(':', 2);
            String userFinalRoleValue = userSplitRole[1];
			String trimmedNewUserRoleName = userFinalRoleValue.trim();
            
			String newUserProfileName = userSwitchToValue[1];
            List<String> userSplitProfile = newUserProfileName.split(':', 2);
            String userFinalProfileValue = userSplitProfile[1];
			String trimmedNewUserProfileName = userFinalProfileValue.trim();

            System.debug('KRB: User Selected trimmed Role: ' + trimmedNewUserRoleName);
			System.debug('KRB: User Selected trimmed Profile: ' + trimmedNewUserProfileName);
            
            //Find the Role and Profile Ids in the Maps
            Id roleId;
            Id profileId;
            
            for (Id key : profileMap.keySet()){
                if(profileMap.get(key).name == trimmedNewUserProfileName ){
                    profileId = key;
                }
            }
            
            for (Id key : roleMap.keySet()){
                if(roleMap.get(key).name == trimmedNewUserRoleName ){
                    roleId = key;
                }
            }

            u.ProfileId = profileId;
            u.UserRoleId = roleId;
            u.MSD_CORE_Switch_To__c = null;

			System.debug('KRB: User Update Values: u.ProfileId: ' + profileId + ' u.UserRoleId:' + roleId + ' u.MSD_CORE_Switch_To__c = null');
            
            usersToUpdate.add(u);
            
            // ----------------------------------------------------------------------------------------
            // Figure out what permissionSetAssignments we need to load for the given User:
            // ----------------------------------------------------------------------------------------

            List<String> permissionSetNamesList = new List<String>();
            for(MSD_CORE_Hybrid_User_PermissionSets__c hup: profileNmToPermissionSetList){
                if(trimmedNewUserProfileName == hup.MSD_CORE_ProfileNm__c && trimmedNewUserRoleName == hup.MSD_CORE_Role_Nm__c){
                    permissionSetNamesList.add(hup.MSD_CORE_PermSetNm__c);
                }    
            }

            for(String psName: permissionSetNamesList){
                
               Id permissionSetId; 
                
               for (Id key : permissionSetIdNameMap.keySet()){
                  if(permissionSetIdNameMap.get(key).name == psName ){
                     permissionSetId = key;
                  }
               }
                
               System.debug('KRB: Adding a new PermissionSet Assignment Record for: ' +  u.LastName + ' - New PermissionSet Name: ' + permissionSetIdNameMap.get(permissionSetId).name ); 
               PermissionSetAssignment newPSA = new PermissionSetAssignment();
               newPSA.AssigneeId = u.Id;
               newPSA.PermissionSetId = permissionSetId; 
                
               permissionSetAssignmentsToInsert.add(newPSA);
            }
            
            // ----------------------------------------------------------------------------------------
           
        }
        
        try{

           // Deleting the User's Existing PermissionSet Assignments
           System.debug('KRB: Deleting all existing PermissionSetAssignments...');
           if(!allExistingPermissionSetAssignmentToDeleteList.isEmpty()){
              
              delete allExistingPermissionSetAssignmentToDeleteList;
              System.debug('KRB: Existing PermissionSetAssignments Deleted...');

           }else{
              System.debug('KRB: allExistingPermissionSetAssignmentToDeleteList was empty. Will not be deleting PermissionSetAssignments...');

           }
            
           System.debug('KRB: Updating Users now...');
           if(!usersToUpdate.isEmpty()){
              update usersToUpdate;
              System.debug('KRB: Users Updated...');
          }else{
              System.debug('KRB: usersToUpdate was empty. NOT Updating Users...');
           }
           
           System.debug('KRB: Updating Users Permission Set Assignments now...');
           if(!permissionSetAssignmentsToInsert.isEmpty()){
              
              insert permissionSetAssignmentsToInsert; 
              System.debug('KRB: Permission Set Assignments have been updated...');
          }else{
              System.debug('KRB: permissionSetAssignmentsToInsert was empty. NOT Updating User Permission Set Assignments...');              
           }
            

        }catch(DmlException e){
           System.debug('A DML exception has occurred in MSD_CORE_SCHybridUserProcessor: ' + e.getMessage()); 
        }
 
        
    }

}