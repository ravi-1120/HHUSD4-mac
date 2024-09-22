global class MRK_LoadTerritoryCloneBatchable implements Database.Batchable<sObject>, Database.Stateful{

    /*
       KRB - 3/21/2014 - Batch Apex class to Load entire Territory Clone Table.
    */
    
   global final String Query;
   //global Map<Id, string> territoryIdtoNameMap = new Map<Id, string>();

   global MRK_LoadTerritoryCloneBatchable(String q){
      Query=q;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
      
       //We need to create a Map of the Territories for a look up to get the Parent Territory Name
       //System.debug('Kev: At start Heap Size: ' + Limits.getHeapSize());
       
       
       //Map<Id, string> territoryIdtoNameMap = new Map<Id, string>();
       /*for(sObject territory : scope){
           Territory t = (Territory)territory;
           territoryIdtoNameMap.put(t.id, t.Name);
       }
       */
       List<Territory_Clone_MRK__c> territoryCloneList = new List<Territory_Clone_MRK__c>();
       
       for (sObject territory : scope){
           
           Territory2 t = (Territory2)territory;
           Territory_Clone_MRK__c terrClone = new Territory_Clone_MRK__c();
           
           //System.debug('Processing Territory: ' + t.Name);
           terrClone.Name = t.name;
           terrClone.Territory_SFID_MRK__c = t.id;
           //terrClone.Territory_Name_MRK__c = t.Name;
           
           //if(t.ParentTerritoryId != null){
               //if (territoryIdtoNameMap.containsKey(t.ParentTerritoryId)){    
                  //terrClone.Parent_Name_MRK__c = territoryIdtoNameMap.get(t.ParentTerritoryId);
                  terrClone.Parent_Territory_SFID_MRK__c = t.ParentTerritory2Id;
               //}
           //}else{
           //    System.debug('Parent Territory is blank');
           //}
           
           territoryCloneList.add(terrClone);
           
       }
       
       System.debug('Kev: Final Heap Size: ' + Limits.getHeapSize());
       
       insert territoryCloneList;
       
   }

   global void finish(Database.BatchableContext BC){
        
     /* Get the ID of the AsyncApexJob representing this batch job
        from Database.BatchableContext.
        Query the AsyncApexJob object to retrieve the current job's information.
     */
       
     AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
     TotalJobItems, CreatedBy.Email
     FROM AsyncApexJob WHERE Id =
     :BC.getJobId()]; 
       
     System.debug('The batch Apex job, MRK_LoadTerritoryCloneBatchable, processed ' + a.TotalJobItems +
      ' batches with '+ a.NumberOfErrors + ' failures.');  
     
   }
}