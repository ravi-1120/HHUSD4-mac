trigger MSD_CORE_ProcessInsertedAffiliations on Child_Account_vod__c (after insert) {

    /*
     * KRB 6/1/2015 - REL 6.0 - Rep Generated Affiliations will be created immediately in 
     * the Child_Account_vod__c Object. This Trigger will then load the appropriate 
     * DCR and DCR Line Items for the New Affiliation.
    */
    
    String application = 'Veeva CRM';
    
    String usrProfileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;
    
    //fetch Custom Label records
    String ProfileCC = System.Label.MSD_CORE_Contact_Center_Profiles;

    Boolean result = ProfileCC.contains(usrProfileName);
    
    if(result){
      application = 'Service Cloud'; 
    }
    
    List<Child_Account_vod__c> repGeneratedAffiliationList = new List<Child_Account_vod__c>();
    
    for (Child_Account_vod__c childAcct : Trigger.new) {
        //Only want to Process Rep Generated Affiliations
        if (childAcct.RecordTypeId == 
            RT.getId(Child_Account_vod__c.SObjectType, RT.Name.Rep_Generated_Relationship_MRK)){
            repGeneratedAffiliationList.add(childAcct);
        }
    }
        
    if(!repGeneratedAffiliationList.isEmpty()){
        MSD_CORE_DCRService.createNewAccountAffiliationDCRs(repGeneratedAffiliationList, application);
    }
    
}