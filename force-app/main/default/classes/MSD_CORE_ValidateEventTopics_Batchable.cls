/*
 * Class: MSD_CORE_ValidateEventTopics_Batchable
 * 
 * Batchable Class used to update the MSD_CORE_Valid_Today__c field on the EM_Catalog_vod__c records that 
 * are not Expired and have a RecordType equal to Event_Topic_vod. If TODAY is >= the MSD_CORE_Start_Time__c value
 * AND TODAY <= MSD_CORE_Release_Time__c, the value of the MSD_CORE_Valid_Today__c field is updated to TRUE, else 
 * it is updated to FALSE.
 * 
 * Author: Kevin Brace
 * 
 * Change Log: 
 * KRB 6/19/2019 - Initial Version        
 */

global class MSD_CORE_ValidateEventTopics_Batchable implements Database.Batchable<sObject>, Database.Stateful{
    
   global final String Query;
   
   global MSD_CORE_ValidateEventTopics_Batchable(String q){
      Query=q;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
      

       List<EM_Catalog_vod__c> emCatalogList = new List<EM_Catalog_vod__c>();
       Date dateToday = Date.today(); 
       
       for (sObject emCatalog : scope){
           
           EM_Catalog_vod__c emCatRec = (EM_Catalog_vod__c)emCatalog;

           Date releaseDate = date.newinstance(emCatRec.MSD_CORE_Release_Time__c.year(), emCatRec.MSD_CORE_Release_Time__c.month(), emCatRec.MSD_CORE_Release_Time__c.day());
           Date endDate = date.newinstance(emCatRec.MSD_CORE_End_Time__c.year(), emCatRec.MSD_CORE_End_Time__c.month(), emCatRec.MSD_CORE_End_Time__c.day());
                    
           if(dateToday >= releaseDate && dateToday <= endDate ){
              System.debug('Events: Setting MSD_CORE_Valid_Today__c to True: dateToday: ' + dateToday + ' endDate: ' + endDate + ' Release Date: ' + releaseDate + ' id: ' + emCatRec.Id + ' Prior MSD_CORE_Valid_Today__c: ' + emCatRec.MSD_CORE_Valid_Today__c);
              
              if(emCatRec.MSD_CORE_Valid_Today__c == false){
                  emCatRec.MSD_CORE_Valid_Today__c = true;
                  emCatalogList.add(emCatRec);
              }
              
           }else{
              System.debug('Events: Setting MSD_CORE_Valid_Today__c to False: dateToday: ' + dateToday + ' endDate: ' + endDate + ' Release Date: ' + releaseDate + ' id: ' + emCatRec.Id + ' Prior MSD_CORE_Valid_Today__c: ' + emCatRec.MSD_CORE_Valid_Today__c);
              
              if(emCatRec.MSD_CORE_Valid_Today__c == true){
                 emCatRec.MSD_CORE_Valid_Today__c = false;
                 emCatalogList.add(emCatRec);
              }
           }
                      
       }
      
       update emCatalogList;
       
   }

   global void finish(Database.BatchableContext BC){
        
     /* Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
        Query the AsyncApexJob object to retrieve the current job's information.*/
       
     AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
     TotalJobItems, CreatedBy.Email
     FROM AsyncApexJob WHERE Id =
     :BC.getJobId()]; 
       
     System.debug('The batch Apex job, MSD_CORE_ValidateEventTopics_Batchable, processed ' + a.TotalJobItems +
      ' batches with '+ a.NumberOfErrors + ' failures.');  
     
   }
}