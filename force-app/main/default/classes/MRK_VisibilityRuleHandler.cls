public class MRK_VisibilityRuleHandler implements MRK_ITrigger{
     /* Member Variables    */
    
     
     //Generic List to store the Sharing Records that need to be loaded/Deleted into the Apprioriate Sharing Table.
     
    // Constructor
    public MRK_VisibilityRuleHandler()
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
        if(Trigger.isInsert){
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
        Visibility_Rule_MRK__c vrr = (Visibility_Rule_MRK__c)so;
        if (vrr.Visibility_Rule_Records_Assigned_MRK__c > 0 || vrr.Visibility_Rule_Sales_Teams_Assigned_MRK__c > 0){
 
           String error = '';
 
            
           Boolean ruleRecordsAreAssigned = false;
           Boolean salesTeamsAreAssigned = false;
            
            if (vrr.Visibility_Rule_Records_Assigned_MRK__c > 0){
                ruleRecordsAreAssigned = true;
            }
             
            if (vrr.Visibility_Rule_Sales_Teams_Assigned_MRK__c > 0){
                salesTeamsAreAssigned = true;
            }
            
            if(ruleRecordsAreAssigned == true && salesTeamsAreAssigned == true){
               error = 'You cannot Delete a Visibility Rule that has Visibility Rule Records and Sales Teams assigned to it.\n';
            }else if(ruleRecordsAreAssigned == true){
               error = 'You cannot Delete a Visibility Rule that has Visibility Rule Records assigned to it.\n';
            }else if(salesTeamsAreAssigned == true){
               error = 'You cannot Delete a Visibility Rule that has Sales Teams assigned to it.\n';
            }
            
           so.addError(error);
        }
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
    }
    
    //Custom Methods:
    
    
}