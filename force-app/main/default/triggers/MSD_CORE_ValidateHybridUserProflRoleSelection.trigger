/*
    KRB: Service Cloud Related. 24R2.0 5/2024
		 Trigger performs 2 Validations on Hybrid Users: 
            1. Validates that the Hybrid User changing their Profile/Role via the Switch 
				to Field has permission to make the Switch.
		    2. Validates that the Profile and Role Combination that the User Selected 
				is a Valid Selection given the current user's Profile and Role
*/

trigger MSD_CORE_ValidateHybridUserProflRoleSelection on User (before update) {
    String usrProfileName = [SELECT Profile.Name  FROM User WHERE id = :Userinfo.getUserId()].Profile.Name;
    String usrRoleName =    [SELECT UserRole.Name FROM user WHERE id = :Userinfo.getUserId()].UserRole.Name;
    System.debug('KRB: Profile/Role of the User making the Switch: usrProfileName: ' + usrProfileName + ' usrRoleName:' + usrRoleName);

    //Skip Validation if Integration User or System Admin
    if ((usrProfileName == 'MRK - Integration User') || (usrProfileName == 'System Administrator') ){
       System.debug('KRB: User is a System Admin or Integration User. Exiting. ');
       return;
    }else{
       System.debug('KRB: User is NOT a System Admin or Integration User. Continuing... ');        
    }

    //Pull a list of the Profile and Role Combinations that are allowed to Switch  
    List<MSD_CORE_Hybrid_User_Details__c> validProfileRoleCombinations = 
        new List<MSD_CORE_Hybrid_User_Details__c>(
        										    [SELECT MSD_CORE_CrrntPrfl__c,
                                                            MSD_CORE_CurrentRole__c
                                                     FROM   MSD_CORE_Hybrid_User_Details__c
                                                     WHERE  MSD_CORE_isActive__c = true]);

    //Pull a list of the New Profile and Role Combinations that the user is allowed to Switch to... 
    List<MSD_CORE_Hybrid_User_Details__c> possibleSwitchToValues =
        new List<MSD_CORE_Hybrid_User_Details__c>([SELECT MSD_CORE_CrrntPrfl__c,
                                                          MSD_CORE_CurrentRole__c,
                                                          MSD_CORE_NewPrfl__c,
                                                          MSD_CORE_NewRole__c 
                                                   FROM   MSD_CORE_Hybrid_User_Details__c 
                                                   WHERE  MSD_CORE_CrrntPrfl__c = : usrProfileName
                                                   AND    MSD_CORE_CurrentRole__c = : usrRoleName
                                                   AND    MSD_CORE_isActive__c = true ]);
    

    //Only want to Validate if "Switch To" Value Changed and its not null/Empty
    for (User record : trigger.new){
        
       System.debug('KRB: Old Switch To Field Value: ' + trigger.oldMap.get(record.Id).MSD_CORE_Switch_To__c );
       System.debug('KRB: New Switch To Field Value: ' + record.MSD_CORE_Switch_To__c );
        
       if ((trigger.oldMap.get(record.Id).MSD_CORE_Switch_To__c != record.MSD_CORE_Switch_To__c) &&
           (!String.isEmpty(record.MSD_CORE_Switch_To__c))){

          System.debug('KRB: Switched To Value Changed and is not null... ');
          System.debug('KRB: About to Validate that the User is allowed to Switch Profiles and Roles... ');
    
           //First Validation: Ensure that the Current User's Profile and Role making the Change to the Switch To Field is 
           //present in the MSD_CORE_Hybrid_User_Details__c Object's Current Profile and Current Role Fields
           boolean isValid = false;
               
           for (MSD_CORE_Hybrid_User_Details__c details : validProfileRoleCombinations){
              System.debug('KRB: Valid Profile ' + details.MSD_CORE_CrrntPrfl__c  + ' Valid Role: ' +  + details.MSD_CORE_CurrentRole__c);
              System.debug('KRB: Current Users Profile and Role:  usrProfileName: ' + usrProfileName + ' Current usrRoleName: ' + usrRoleName);
        
               if((details.MSD_CORE_CrrntPrfl__c == usrProfileName) && (details.MSD_CORE_CurrentRole__c == usrRoleName)){
                  System.debug('KRB: This is a Valid User! They can switch their Profile and Role' );
                   isValid = true;
                   break;
               }else{
                  System.debug('KRB: Not a matching valid Profile and Role, continuing to next Profile/Role...' );
               }   
           }
               
           if(!isValid){
               System.debug('KRB: Not a valid User. They can not swith their Profile and Role.' );
               record.addError('You do not have permission to Switch your Profile and Role.');    

           //Second Validation: The user has permission to switch their Profile and Role, 
           //Now we need to check to see if the Profile and Role selected by the User 
           //is associated to the Current Users Profile and Role
           
           }else{
 
              System.debug('KRB: **User is Valid** They have permission to change their Profile and Role.');
              System.debug('KRB: Now Validate the Profile and Role that was Selected by User...' );
 
              if(!possibleSwitchToValues.isEmpty()){ 
               
                 //Parse the User's Selection into a Profile and Role Variable. 
                 List<String> res = record.MSD_CORE_Switch_To__c.split(';', 2);
                 System.debug('KRB: Raw User Selection:  Role:' + res[0] + ' Profile: ' + res[1]);
                 
                 //Role
                 String role = res[0];
                 List<String> splitRole = role.split(':', 2);
                 String finalRoleValue = splitRole[1];
                 String trimmedRole = finalRoleValue.trim();

                 //Profile
                 String profile = res[1];
                 List<String> splitProfile = profile.split(':', 2);
                 String finalProfileValue = splitProfile[1];
                 String trimmedProfile = finalProfileValue.trim();

                 System.debug('KRB: User Selected trimmed Role: ' + trimmedRole + ' Selected trimmed Profile: ' + trimmedProfile);
                 System.debug('KRB: About to Validate the Users new Profile and Role Selection... ');
    
                 //validate that the Profile and Role the user selected is associated to the Current Users Profile and Role
                 boolean isValidSwitchToValues = false;
               
                 for (MSD_CORE_Hybrid_User_Details__c details : possibleSwitchToValues){
                    System.debug('KRB: Valid New profile ' + details.MSD_CORE_NewPrfl__c  + ' and New role: ' +  + details.MSD_CORE_NewRole__c);
        
                    if((details.MSD_CORE_NewPrfl__c == trimmedProfile) && (details.MSD_CORE_NewRole__c == trimmedRole)){
                       System.debug('KRB: This is a Valid Profile/Role Selection given the Users Current Profile and Role!');
                       isValidSwitchToValues = true;
                       break;
                    }else{
                       System.debug('KRB: Not a valid New Profile/Role Selection, continuing to next Profile/Role...' );
                    }  
                }
               
                if(!isValidSwitchToValues){
                   System.debug('KRB: Not a valid Profile/Role Selection. They cannot switch their Profile and Role to their current Selection.' );
                   record.addError('The Profile and Role selected is not valid for your current assigned Profile and Role. Please select a valid Profile and Role.');    
                }                 

             }else{
                System.debug('KRB: There is no Metadata for your Given Profile and Role...throwing an error' );
                record.addError('There is no Metadata for your Given Profile and Role. You cannot change your Profile and Role.');    
             }

           }   
                      
         }else{
            System.debug('KRB: MSD_CORE_ValidateHybridUserProflRoleSelection: Switch To Field Value did not change or is blank. Not Validating. Exiting.' );  
         }
    }
                
}