global class MRK_AccountPlanActivateSchedulable implements Schedulable{
    
    /*
       KRB - REL 5.0 4/2/2014 - Batch Apex class sets Account_Plan_vod__c.Active_vod__c to 
                                true when Start_Date_MRK__c <= Today and 
                                End_Date_MRK__c >= Today and
                                Status__c == 'Approved' and Plan is not active. 
    */
    
    global void execute(SchedulableContext sc) {
                  
       String soqlSELECT =      'SELECT Id, Active_vod__c ';
       String soqlFROM   =      'FROM   Account_Plan_vod__c ';
       String soqlWHERE  =      'WHERE  Active_vod__c = false AND Status__c = \'Approved\' AND '; 
       soqlWHERE  = soqlWHERE + 'Start_Date_MRK__c <= ' + DateTime.now().format('yyyy-MM-dd') + ' AND ';
       soqlWHERE  = soqlWHERE + 'End_Date_MRK__c >= ' + DateTime.now().format('yyyy-MM-dd');

        MRK_AccountPlanActivateBatchable apab = 
          new MRK_AccountPlanActivateBatchable (soqlSELECT + soqlFROM + soqlWHERE); 
      
       database.executebatch(apab);
   }   
}