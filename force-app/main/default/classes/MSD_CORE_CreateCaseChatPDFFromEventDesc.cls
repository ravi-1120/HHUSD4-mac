/* KRB 21R3.0 6/4/2021
 * Keytruda Chat Bot Requirement
 * Generates a PDF File from the Chat Transcript and associates it to the Case. 
*/

public with sharing class MSD_CORE_CreateCaseChatPDFFromEventDesc implements TriggersMVN.HandlerInterface{
   public void handle(){
      List<Event> eventsList = Trigger.new;
      List<Event> chatEventsToProcessList = new List<Event>();
      
      //only pass in Chat Interaction Type Events that actually have a Description that is not Null...
      for(Event e : eventsList){
         if (e.Type == 'Chat Interaction' && String.isNotBlank(e.Description)){
            chatEventsToProcessList.add(e);
         }
      }
      
      MSD_CORE_GeneratePDFTranscriptQueueable queueable = new MSD_CORE_GeneratePDFTranscriptQueueable(chatEventsToProcessList);
      System.enqueueJob(queueable);
   }    
}