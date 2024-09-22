global class MRK_AccountPlanDeleteSchedulable implements Schedulable{
    
    /*
       KRB - REL 5.0 4/2/2014 - Batch Apex class to delete Unapproved, greater than 90 day old,
                                Account Plans. 
    */
    
    global void execute(SchedulableContext sc) {
        
       String sDTTM;
       DateTime DTTM = DateTime.now().addDays(-90);
       sDTTM = DTTM.formatGMT('yyyy-MM-dd') + 'T' + dttm.formatGMT('HH:mm:ss.SSS') + 'Z';  
                  
       String soqlSELECT =      'SELECT Id,CreatedDate,Status__c,Name ';
       String soqlFROM   =      'FROM   Account_Plan_vod__c ';
       String soqlWHERE  =      'WHERE  Status__c = \'Draft\' AND ';
       soqlWHERE = soqlWHERE +  'CreatedDate < ' + sDTTM;

       System.debug('MRK_AccountPlanDeleteSchedulable: Debug: ' + soqlSELECT + soqlFROM + soqlWHERE);
        
        MRK_AccountPlanDeleteBatchable apdb = 
          new MRK_AccountPlanDeleteBatchable (soqlSELECT + soqlFROM + soqlWHERE); 
      
       database.executebatch(apdb, 40);
   }   
}