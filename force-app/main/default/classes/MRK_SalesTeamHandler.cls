public class MRK_SalesTeamHandler implements MRK_ITrigger{  
    
    /*
     * KRB - 3/14/2014 - REL 5.0 Class houses all processing logic for the Sales_Team_MRK__c Obj. 
     */
    
    //Profile Override Member Variables
    List<Id> inActivatedSalesTeamIdList = new List<Id>();
    
    // Constructor
    public MRK_SalesTeamHandler()
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
    }
    
    public void bulkAfter()
    {
        //Cache all the Data we will need to process the changes....
        
        //For Inserts...
        if(Trigger.isInsert){
        }
        
        //For Updates
        if(Trigger.isUpdate){ 
            cacheDataForRuleProfileOverrideProcessing();
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
           if(!inActivatedSalesTeamIdList.isEmpty()){
              MRK_RuleGateway.updateActiveProfileOverrideRulestoInactiveBySalesTeamIdList(inActivatedSalesTeamIdList);
           }
        }
    }
    
    
    private void cacheDataForRuleProfileOverrideProcessing(){
        
        List <Sales_Team_MRK__c> updatedSalesTeamList = Trigger.new;
        List <Sales_Team_MRK__c> beforeUpdateSalesTeamList = Trigger.old;
        Map<Id, Sales_Team_MRK__c> beforeUpdateSalesTeamMap = new Map<Id, Sales_Team_MRK__c>();

        //Create initial Map of old Events
        for(Sales_Team_MRK__c salesTeamOld : beforeUpdateSalesTeamList) { 
           beforeUpdateSalesTeamMap.put(salesTeamOld.Id, salesTeamOld); 
        }
        
        for (Sales_Team_MRK__c updatedSalesTeam: updatedSalesTeamList){
           Sales_Team_MRK__c beforeUpdateSalesTeam = beforeUpdateSalesTeamMap.get(updatedSalesTeam.id);
            if(
                (updatedSalesTeam.Active_MRK__c != beforeUpdateSalesTeam.Active_MRK__c) && 
                 updatedSalesTeam.Active_MRK__c == false
              ){
                  
                inActivatedSalesTeamIdList.add(updatedSalesTeam.Id);
            }
        }
        //Updates to the Rule Object to inactivate specific rules 
        //occurs in the Finally section below...
    }
  
 
    
}