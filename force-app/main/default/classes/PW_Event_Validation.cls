//-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Event_Validation 
///   Description:    26564 - User shouldn’t be able to hit complete button before end date and time has past 
///                   26563 - In order to complete, need speaker and attendees status required and meal opt in status required 
///                   Validates whether speaker is added to event on submission.
///   Author:         Khushbu Khetan                  
///   Date: 28-12-2017
///   Revision History:
///-----------------------------------------------------------------
public class PW_Event_Validation {


        public string errorMessage{get;set;}
        
        private PW_General_Settings__c regSettings {get;set;}
        
        public PW_Event_Validation()
        {
            regSettings = PW_General_Settings__c.getValues('General Settings');
        }
        
        public boolean validateSpeakerPresentInEvent(EM_Event_vod__c event)
        {
              if(!string.isEmpty(regSettings.PW_Event_Status_For_Speaker_Check__c))
              {
                    
                     List<String> eventStatusLst = regSettings.PW_Event_Status_For_Speaker_Check__c.toLowerCase().split(';'); //Added
                    
                     if(regSettings.PW_Speaker_Present_Check__c && eventStatusLst.contains(event.Status_vod__c.toLowerCase()) && regSettings.PW_EventTypes_For_Speaker_Check__c.contains(event.PW_Event_Type__c))
                     {
                            integer speakerCount = [select count() from EM_Event_Speaker_vod__c where Event_vod__c =: event.Id];
                            if(speakerCount==0)
                            {
                                //event.addError('Event must have a speaker to submit.');
                                errorMessage = 'Event must have a speaker to submit.';
                                return false;
                            }
                     }
             }
             return true;
        }
        public boolean validateTopicNotChangeInEvent(EM_Event_vod__c event,EM_Event_vod__c oldEVent)
        {          
      
             if(regSettings.PW_PreventTopicChange__c ) 
             {
                   
                    if(oldEVent.Topic_vod__c != event.Topic_vod__c)
                    {
                        integer speakerCount = [select count() from EM_Event_Speaker_vod__c where Event_vod__c =: event.Id];
                         if(speakerCount >0)
                      {
                          errorMessage = 'Topic cannot be changed once Speaker is added.';
                          return false;
                      }
                    }
             }
             return true;
        }
        public boolean validateEventEndTimeForCompletion(EM_Event_vod__c event,EM_Event_vod__c oldEvent)
        {
            
             if(regSettings.PW_Completion_Check__c)
             {
                  if(event.Status_vod__c==regSettings.PW_Complete_Status__c && oldEvent.Status_vod__c!=regSettings.PW_Complete_Status__c )
                  {
                    if(Datetime.now() < event.End_Time_vod__c)
                    {
                       errorMessage = 'Sorry, you can not complete an event before it is finished.';
                       return false;
                    }
                  }
             }
             return true;
        }
        
        public boolean validateAV(EM_Event_vod__c event,EM_Event_vod__c oldEvent)
        {
               
           String AVPicklistRepWillProvide = event.PW_AV_REP_Will_Provide__c;
           String AVPicklistPwWillProvide = event.PW_AV_PW_Will_Provide__c;
           
           if(string.IsEmpty(AVPicklistRepWillProvide)||string.IsEmpty(AVPicklistPwWillProvide))
           {
               return true;
           }
           List<String> individualAVSelections = AVPicklistRepWillProvide.split(';');
           for(String av:individualAVSelections)
           {
              if(AVPicklistPwWillProvide.Contains(av))
                {
                    errorMessage = 'Both PW and REP cannot provide the same AV equipment';
                       return false;
                    
                }           
           }
             return true;
        }
        
        public boolean validateAttendeeAndSpeakerAttendanceForCompletion(EM_Event_vod__c event,EM_Event_vod__c oldEvent)
        {
            
             if(regSettings.PW_Completion_Check__c)
             {
                  if(event.Status_vod__c==regSettings.PW_Complete_Status__c && oldEvent.Status_vod__c!=regSettings.PW_Complete_Status__c )
                  {
                       Set<String> attendeeStatuses = new Set<String>(regSettings.PW_Completable_Attendee_Statuses__c.split(';'));
                       Set<String> speakerStatuses = new Set<String>(regSettings.PW_Completable_Speaker_Statuses__c.split(';'));
                       
                       
                       List<EM_Attendee_vod__c> attendees = [select Id, Status_vod__c from EM_Attendee_vod__c  where Event_vod__c=:event.Id];
                       
                       for (EM_Attendee_vod__c attendee: attendees) {                      
                           if (!attendeeStatuses.contains(attendee.Status_vod__c)) {
                               errorMessage ='Please update the statuses for all invited attendees before completing the event.\n';
                               return false;
                           }                           
                       }
                       
                       List<EM_Event_Speaker_vod__c> speakers = [select Id, Status_vod__c from EM_Event_Speaker_vod__c  where Event_vod__c=:event.Id];
                       for (EM_Event_Speaker_vod__c speaker: speakers) {
                           if (!speakerStatuses.contains(speaker.Status_vod__c)) {
                               errorMessage = 'Please update the speaker status before completing the event.\n';
                               return false;
                           }
                       }
                  }
             }
             return true;
        }
        

}