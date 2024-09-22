global class MRK_ProcessGasODAlignmntHistSchedulable implements Schedulable{
    
    /*
     * KRB - 3/27/2014 - REL 5.0 
     *   Batch Job processes new One Day Alignment GAS_Alignment_History_vts__c records. 
     *   For each new record added, if the associated Account does not
     *   have an associated unsubmitted calls, adds a Drop to the Accounts ATL 
     *   record for the given New Territory. Once Processed, Job updated the Processed Flag on 
     *   to True so that records are not pulled in during subsequent Batch Runs.
     */
    
    global void execute(SchedulableContext sc) {
      
       String soqlSELECT = 'SELECT Id, Account__c, Account_Territory_Loader__c, New_Territory__c, Processed_MRK__c, Source_MRK__c ';
       String soqlFROM   = 'FROM GAS_Alignment_History_vts__c ';
       String soqlWHERE  = 'WHERE Processed_MRK__c = false AND Source_MRK__c = \'ODA\'';
        
       MRK_ProcessGasODAlignmntHistBatchable pgah = 
          new MRK_ProcessGasODAlignmntHistBatchable (soqlSELECT + soqlFROM + soqlWHERE); 
      
       database.executebatch(pgah);
   }   

}