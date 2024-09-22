/*
 * Class: MSD_CORE_ValidateEventTopics_Schedulable
 * 
 * Schedulable Class used to update the MSD_CORE_Valid_Today__c field on the EM_Catalog_vod__c records that 
 * are not Expired and have a RecordType equal to Event_Topic_vod. If TODAY is >= the MSD_CORE_Start_Time__c value
 * AND TODAY <= MSD_CORE_Release_Time__c, the value of the MSD_CORE_Valid_Today__c field is updated to TRUE, else 
 * it is updated to FALSE.
 * 
 * Author: Kevin Brace
 * 
 * Change Log: 
 * KRB 6/19/2019 - Initial Version        
 */


global class MSD_CORE_ValidateEventTopics_Schedulable implements Schedulable{
   global void execute(SchedulableContext sc) {

       
       String soqlSELECT =      'SELECT Id, MSD_CORE_Valid_Today__c, MSD_CORE_End_Time__c, MSD_CORE_Release_Time__c ';
       String soqlFROM   =      'FROM EM_Catalog_vod__c ';
       String soqlWHERE  =      'WHERE RecordType.name = \'Event_Topic_vod\' AND '; 
       soqlWHERE  = soqlWHERE + 'Status_vod__c = \'Approved_vod\'';

       MSD_CORE_ValidateEventTopics_Batchable vtb = 
          new MSD_CORE_ValidateEventTopics_Batchable (soqlSELECT + soqlFROM + soqlWHERE); 
      
       database.executebatch(vtb);
 
   }
}