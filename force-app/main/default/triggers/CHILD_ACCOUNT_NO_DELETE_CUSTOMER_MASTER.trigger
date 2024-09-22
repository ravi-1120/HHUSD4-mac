//Purpose: Users with profile starting with "MRK - Sales" cannot delete Customer Finder Relationships
//Code changed as part of 11.0 release to only allow System Admin & Integration user to delete affiliations.
trigger CHILD_ACCOUNT_NO_DELETE_CUSTOMER_MASTER on Child_Account_vod__c (before delete) {

    //Boolean isMRKuser = false;
    Boolean isMRKuser = true; //Rel 11.0

    //fetch Custom Label records
     //String ProfileCL = System.Label.MRK_PROFILES;
     //String ProfileCC = System.Label.MSD_CORE_Contact_Center_Profiles;
    String ProfileSA = System.Label.MRK_ADMIN_INT; //Rel 11.0   
    
    //Get User Profile
    
    String usrProfileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;
    
    //Boolean resultCL = ProfileCL.contains(usrProfileName);
    //Boolean resultCC = ProfileCC .contains(usrProfileName);
    Boolean resultSA = ProfileSA.contains(usrProfileName); //Rel 11.0  
    
   // if(resultCL || resultCC ){
   //        isMRKuser = true; 
   // }
    
    if(resultSA){ //Rel 11.0
          isMRKuser = false; //Rel 11.0 
    }//Rel 11.0  

    //Throw an error if the user has a normal user profile AND the child account record came from Merck's Customer Finder
    for(Child_Account_vod__c ca: Trigger.old) {

       if (isMRKuser && ca.Record_Type_Name_MRK__c == 'Customer_Master_Relationship_MRK'){
            ca.addError('To delete, you must click Edit and check Mark for Delete.');
       }
    }
    
}