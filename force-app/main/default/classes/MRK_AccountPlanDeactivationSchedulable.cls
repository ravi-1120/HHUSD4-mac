global class  MRK_AccountPlanDeactivationSchedulable implements Schedulable{

    /*
       KRB - REL 5.0 5/29/2014 - Batch Apex class to deactivate Account Plans a Day After their End Date.
    */
    
    global void execute(SchedulableContext sc) {
                          
       String soqlSELECT =      'SELECT Id, Active_vod__c ';
       String soqlFROM   =      'FROM   Account_Plan_vod__c ';
       String soqlWHERE  =      'WHERE  End_Date_MRK__c < TODAY and Active_vod__c = True';
       

       System.debug('MRK_AccountPlanDeactivationSchedulable: Debug: ' + soqlSELECT + soqlFROM + soqlWHERE);
        
        MRK_AccountPlanDeactivationBatchable apdb = 
          new MRK_AccountPlanDeactivationBatchable (soqlSELECT + soqlFROM + soqlWHERE); 
      
       database.executebatch(apdb, 40);
   }   
}