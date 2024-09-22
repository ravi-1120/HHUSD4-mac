global class MRK_DeleteTerritoryCloneSchedulable implements Schedulable{

   global void execute(SchedulableContext sc) {
      
       String soql = 'SELECT Id FROM Territory_Clone_MRK__c';
       
       MRK_DeleteTerritoryCloneBatchable dtcb = 
          new MRK_DeleteTerritoryCloneBatchable (soql); 
      
       database.executebatch(dtcb);
   }
}