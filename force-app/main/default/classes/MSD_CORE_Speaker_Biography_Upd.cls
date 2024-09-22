/** 
 * Batch Apex Name : MSD_CORE_Speaker_Biography_Upd
 * This Batch Apex Class is programmed to populate the Speaker Biography field when the status of the event changes to 'Confirmed'
 */
 
global class MSD_CORE_Speaker_Biography_Upd implements Database.Batchable<sObject> {
global Date myDate = date.today();

    global Database.QueryLocator start(Database.BatchableContext BC) {
       //String query = 'SELECT Id,Status_vod__c,MSD_CORE_Speaker_Biography__c FROM EM_Event_vod__c where status_vod__c = 'MSD_CORE_Confirmed' and recordtype.name in ('MSD_CORE_Child_Home_Office_Event', 'MSD_CORE_Events_with_Speakers')';       
       String query = 'SELECT Id,Status_vod__c,MSD_CORE_Speaker_Biography__c,MSD_CORE_Speaker_Details__c,RecordType.Name FROM EM_Event_vod__c';
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<EM_Event_vod__c> scope) {
   
   //Set of Event Ids which need to be updated
     Set<Id> EventIds= new Set<Id>();
      
          //Add Event Ids to the set
         for(EM_Event_vod__c EMEvent : Scope){
         if(EMEvent.status_vod__c == 'MSD_CORE_Confirmed'){
           if(EMEvent.recordtype.name == 'MSD_CORE_Child_Home_Office_Event' || EMEvent.recordtype.name == 'MSD_CORE_Events_with_Speakers') {
            EventIds.add(EMEvent.Id);
           }
         }
         }
   
  // system.debug('Ankur EventIds' + EventIds);
   
     //Get all the Event Speaker & Biography Information
     //List<EM_Event_Speaker_vod__c> EventSpeaker = [ select Id,Speaker_vod__c,Speaker_vod__r.Speaker_Formatted_Name_vod__c,Speaker_vod__r.MSD_CORE_Speaker_Title__c,Speaker_vod__r.MSD_CORE_Biography__c from EM_Event_Speaker_vod__c where Event_vod__c ='a4M4D0000009qVUUAY'];
      
     // Create a map of the EM Events to a list of Speakers
      Map<EM_Event_vod__c, List<EM_Event_Speaker_vod__c>> EventSpeakerMap = new Map<EM_Event_vod__c, List<EM_Event_Speaker_vod__c>>();
  
  //system.debug('Ankur EventSpeakers ' + EventSpeaker );
  
 // List<EM_Event_vod__c> events = new List<EM_Event_vod__c>([select Id, MSD_CORE_Speaker_Biography__c from EM_Event_vod__c where Id = 'a4M4D0000009qVUUAY']);
     
    
//List to update the Event Speaker Biography.
List <EM_Event_vod__c> EMSpeakerUpd = new List <EM_Event_vod__c>();

 for(EM_Event_vod__c E : [select Id, MSD_CORE_Speaker_Biography__c,MSD_CORE_Speaker_Details__c from EM_Event_vod__c where Id in :EventIds]){
   String SpeakerBio = '';
   String SpeakerDetails = '';
   for(EM_Event_Speaker_vod__c ES :[select Id,Speaker_vod__c,Speaker_vod__r.Speaker_Formatted_Name_vod__c,Speaker_vod__r.MSD_CORE_Speaker_Title__c,Speaker_vod__r.MSD_CORE_Biography__c,Speaker_vod__r.Title_vod__c,Speaker_vod__r.MSD_CORE_Preferred_First_Name__c,Speaker_vod__r.MSD_CORE_Preferred_Last_Name__c,Speaker_vod__r.Suffix_vod__c from EM_Event_Speaker_vod__c where Event_vod__c =:E.Id]){
   //SpeakerBio += ES.Speaker_vod__r.MSD_CORE_Biography__c + '\r\n' + '   ';
   SpeakerBio += ES.Speaker_vod__r.MSD_CORE_Biography__c + '\r\n' + '\r\n' + '   ';
   //SpeakerDetails += ES.Speaker_vod__r.Speaker_Formatted_Name_vod__c + ' ., ' + ES.Speaker_vod__r.MSD_CORE_Speaker_Title__c + '\r\n' + '  ';
   SpeakerDetails += ES.Speaker_vod__r.MSD_CORE_Preferred_First_Name__c  + ' ' + ES.Speaker_vod__r.MSD_CORE_Preferred_Last_Name__c + ', ' + ES.Speaker_vod__r.MSD_CORE_Speaker_Title__c + '\r\n' + '  ';
   }
   E.MSD_CORE_Speaker_Biography__c = SpeakerBio;
   E.MSD_CORE_Speaker_Details__c = SpeakerDetails;
   E.MSD_CORE_Speaker_Data_Updated__c = true;
   EMSpeakerUpd.add(E);
 }
    update EMSpeakerUpd;
}
    
        
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('Batch Processing');
mail.setSubject('Batch Process Completed');
mail.setPlainTextBody('Batch Process has completed');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}