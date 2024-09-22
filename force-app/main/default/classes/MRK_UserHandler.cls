public class MRK_UserHandler implements MRK_ITrigger{
    
    /*KRB - 3/19/2014 - REL 5.0 
     *  - Added rules to identify RULE_MRK__c Object Records when Users become inactive. 
     */
    
    
    /* Member Variables    */
    
    //Profile Override Cached Data:
    Map<Id, Profile> profileIdtoProfileObjMap = new Map<Id, Profile>();
    Map<String, Id> profileNameToIdMap = new Map<String, Id>();
    List<id> inActivatedUserIdList = new List<id>();    
    
    // Constructor
    public MRK_UserHandler()
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
        }
                
        if(Trigger.isInsert){
        }
        
        if(Trigger.isDelete){
        }
    }
    
    public void bulkAfter()
    {     
        if(Trigger.isUpdate){
           cacheDataForRuleProfileOverrideProcessing();
        }
        
        if(Trigger.isInsert){
        }
        
        if(Trigger.isDelete){
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
       
        if(Trigger.isUpdate){
           if(!inActivatedUserIdList.isEmpty()){
              MRK_RuleGateway.updateActiveProfileOverrideRulestoInactiveByUserIdList(inActivatedUserIdList);
           }
        }        
        
        if(Trigger.isDelete){
        }
        
        if(Trigger.isInsert){
        }
    }
    
    
    /*
     * Custom Methods
     * 
     */
    
    /*
     * Data Caching Methods
     * 
     */
    
    
    private void cacheDataForRuleProfileOverrideProcessing(){
                
        //Identify all the Users:
        // that are being updated to "Inactive"
        // that also have an "Active"record in the Rule Object for Profile Override (ProfileOverride Type). 
        
        List <User> updatedUserList = Trigger.new;
        List <User> beforeUpdateUserList = Trigger.old;
        Map<Id, User> beforeUpdateUserMap = new Map<Id, User>();

        // Create initial Map of old Events
        for(User usrOld : beforeUpdateUserList) { 
           beforeUpdateUserMap.put(usrOld.Id, usrOld); 
        }
        
        for (User updatedUser: updatedUserList){
           User beforeUpdateUser = beforeUpdateUserMap.get(updatedUser.id);
            if(
                (updatedUser.IsActive != beforeUpdateUser.IsActive) && 
                 updatedUser.isActive == false
              ){
                System.debug('Kevin: adding User Id: ' + updatedUser.Id );
                inActivatedUserIdList.add(updatedUser.Id);
            }
        }
        //Updates to the Rule Object to inactivate specific rules 
        //occurs in the Finally section below...
    }
  

    /*
     * Processing Methods
     * 
     */
    
 }