public class PW_Attendee_Validation {
    
        public string errorMessage{get;set;}

        
        private PW_General_Settings__c regSettings {get;set;}
        
        public PW_Attendee_Validation()
        {
            regSettings = PW_General_Settings__c.getValues('General Settings');
        }
        
        public boolean validateAttendee(EM_Attendee_vod__c attendee, Map<Id,EM_Event_Team_Member_vod__c> eventTeamMap ,Map<Id,EM_Event_Speaker_vod__c> eventSpeakerMap)
        {
            System.debug('Inside Validate Attendee regSettings.PW_ValidateAttendee__c::'+regSettings.PW_ValidateAttendee__c);
           
             if(regSettings.PW_ValidateAttendee__c )
             {
                //  System.debug('attendee.Attendee_Type_vod__c::'+attendee.Attendee_Type_vod__c);
                  if(!string.isEmpty(attendee.User_vod__c))
                  {
                       for(EM_Event_Team_Member_vod__c eventTeamMember : eventTeamMap.values())    
                         {
                            if(attendee.User_vod__c  == eventTeamMember.Team_Member_vod__c && attendee.Event_vod__c == eventTeamMember.Event_vod__c)
                            {           
                             
                                  errorMessage = 'Reps cannot be added as Attendee';
                                  return false;
                            }
                        }       
                  }else if((!string.isEmpty(attendee.Account_vod__c)) || (!string.isEmpty(attendee.Entity_Reference_Id_vod__c)))
                  {
                 
                      for(EM_Event_Speaker_vod__c eventSpeaker : eventSpeakerMap.values())    
                        {                         
                          if((!string.isEmpty(eventSpeaker.Account_vod__c))&&(attendee.Account_vod__c  == eventSpeaker.Account_vod__c || attendee.Entity_Reference_Id_vod__c == eventSpeaker.Account_vod__c)
                            && attendee.Event_vod__c == eventSpeaker.Event_vod__c) 
           
                            {
                                
                                 errorMessage   = 'Speaker cannot be added as Attendee';
                                 return false;
                                 
                            }
                        
                        }
                  
                  
                  }
                   
                        
                    
             }
             return true;
        }
        
        
        

}