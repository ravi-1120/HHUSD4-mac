//-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Update_Veeva_Event_From_Tp
///   Description:    This class will receive the event from Tp and update the same event in veeva
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods which will validate and update an event
///   Date: 25-9-2016
///   Revision History:
///-----------------------------------------------------------------
  public class PW_Update_Veeva_Event_From_Tp {
       
        // Handle different validations
        private enum ValidateStatus {SUCCESS, NOTCONFIRMED, MISSINGFIELDS,SPEAKERNOTFOUND, TEAMMEMEBERNOTFOUND }
 
        /// <summary>
        ///     Handles all event send from tp to veeva
        /// </summary>
        /// <param name="eve">
        ///     'eve' is an instance of an eevnt model class which contains data that will get send from TP
        /// </param>   
        public static void Update_Event_Speaker_TeamMembers_Of_Veeva(PW_Event_Model eve)
        {                
            //Validate event            
            Pw_Validation_Output validEvent = ValidateVeevaEvent(eve);
            
            if(validEvent.status==Pw_Validation_Output.ValidateStatus.SUCCESS)
            {                
                    //Update event        
                    UpdateVeevaEvent(eve);
                     System.debug('i am in recordtype block true : in event update');      
                    //update speakers
                    if(eve.ListOfSpeaker!=null)
                    {
                        Pw_Event_Speakers_Manipulation.UpsertSpeakersInVeevaEvent(eve.ListOfSpeaker,eve.id); 
                    }
                
                    //update Team member
                    if(eve.ListOfEventTeamMember!=null)
                    {    System.debug('i am in recordtype block true : in speaker');                     
                        Pw_Event_Team_Members_Manipulation.UpsertTeamMemberInVeevaEvent(eve);                         
                    }
                
                    //update Attendee
                    if(eve.ListOfAttendee !=null)
                    {    System.debug('i am in recordtype block true : in ream member');                     
                      //  Pw_Event_Team_Members_Manipulation.UpsertTeamMemberInVeevaEvent(eve);                         
                    }
            }
            else {                          
                  throw new Pw_ApplicationException(validEvent.outputMessage);                
            }           
        }    
       
         static Pw_Validation_Output ValidateVeevaEvent(PW_Event_Model eventOfTp){ 
             
             
             //check confirmed status
            /* if(eventOfTp.Status!='Confirmed')
             {
                 return new Pw_Validation_Output('Event status is not confirmed',Pw_Validation_Output.ValidateStatus.NOTCONFIRMED);                 
             }*/
             
            
             //NEWLY ADDRED CODE
                Map<String, Id> mapTPSPKIDAndSPKID = new Map<String, Id>();
              
                
                List<String> lstTpSpeakerIDs = new List<string>();
                for(PW_Speaker_Model speak :eventOfTp.ListOfSpeaker)
                { 
                    lstTpSpeakerIDs.add(string.valueOf(speak.TP_Speaker_Id));
                
                }
                
                for(EM_Speaker_vod__c objSPK : [select id, PW_Speaker_ID__c from EM_Speaker_vod__c where PW_Speaker_ID__c IN:lstTpSpeakerIDs ])
                        mapTPSPKIDAndSPKID.put(objSPK.PW_Speaker_ID__c, objSPK.id);
                        
             //check whether the speaker send from TP are present in veeva or not
             for(PW_Speaker_Model speak :eventOfTp.ListOfSpeaker)
              {                       
                     //List<EM_Speaker_vod__c> speakerLocal = [select id from EM_Speaker_vod__c where PW_Speaker_ID__c =:string.valueOf(speak.TP_Speaker_Id)];                       
                     //if(speakerLocal.size()==0){
                      if(mapTPSPKIDAndSPKID.get(string.valueOf(speak.TP_Speaker_Id))==null){
                         return new Pw_Validation_Output('Event speaker not found :'+ string.valueOf(speak.TP_Speaker_Id), Pw_Validation_Output.ValidateStatus.SPEAKERNOTFOUND);                                 
                     }
              }
             //New Optimize code for --check whether the Team members send from TP are present in veeva or not
                      Map<String, Id> mapofEmpNoNUserID = new Map<String, Id>();
                       List<String> lstEmployeeNumber = new List<string>();
                       for(PW_Event_Team_Member_Model member :eventOfTp.ListOfEventTeamMember)
                       {                       
                              lstEmployeeNumber.add( member.Employee_number);
                       }
                       for(User userobj : [select id, name,EmployeeNumber from User where EmployeeNumber IN:lstEmployeeNumber ])
                        mapofEmpNoNUserID.put(userobj.EmployeeNumber, userobj.id);
             
              //check whether the Team members send from TP are present in veeva or not
              for(PW_Event_Team_Member_Model member :eventOfTp.ListOfEventTeamMember)
               {                       
                      //list<user> userExist =[select id, name from user where EmployeeNumber=:member.Employee_number limit 1];
                      //if(userExist.size()==0){ 
                      if(mapofEmpNoNUserID.get(member.Employee_number)==null)
                      {
                         return new Pw_Validation_Output('User not found of Employee number :'+ member.Employee_number, Pw_Validation_Output.ValidateStatus.TEAMMEMEBERNOTFOUND);                                                            
                      }
               }
             
             RecordType fetchedRecordType = [SELECT Name, developername FROM RecordType 
                                      WHERE SObjectType = 'EM_Event_vod__c' and id =:eventOfTp.Record_Type_Id limit 1];
              System.debug('i am in recordtype block true :'+fetchedRecordType.DeveloperName);
             
             //Validate fields whether mandatory fields are blank or null 
             
             if (string.isNotblank(eventOfTp.Topic) && string.isNotblank(eventOfTp.Event_Format) && string.isNotblank(eventOfTp.Start_Time) 
                        && string.isNotblank(eventOfTp.End_Time) && string.isNotblank(eventOfTp.Time_Zone) && eventOfTp.Estimated_Attendance!=null)
                     {
                         System.debug('i am in if block true :'+ fetchedRecordType.name);
                         return new Pw_Validation_Output('Event is proper', Pw_Validation_Output.ValidateStatus.SUCCESS);                                                                                    
                     }                 
            
              return new Pw_Validation_Output('Mandatory fields are missing or please check the record type', Pw_Validation_Output.ValidateStatus.MISSINGFIELDS);               
         }
        
        
        
        static Datetime convertToUTCBasedOnUserTimezone(string dt,Id eventOwnerId,EM_Event_vod__c event){
            Datetime res = datetime.valueOfGMT(dt.replaceAll('/','-'));
            User user = [SELECT TimeZoneSidKey,Username FROM User WHERE id =: eventOwnerId];
            //EM_Event_vod__c event  = [Select Id,Name,start_time_vod__c from EM_Event_vod__c where id='a2v4C0000003aQN'];
            string dateTimeStr = event.Start_time_vod__c.format('yyyy-MM-dd HH:mm:ss',  user.TimeZoneSidKey);
            string dateGmtStr  = event.Start_time_vod__c.formatGMT('yyyy-MM-dd HH:mm:ss');
            Datetime localDateTime = DateTime.valueOf(dateTimeStr);
            Datetime baseGMTTime = DateTime.valueOf(dateGMTStr);
            Long milliSecDiff =  baseGMTTime.getTime() - localDateTime.getTime();
            Long minDiff = milliSecDiff / 1000 / 60;
            Datetime outDateTime = res.addMinutes(minDiff.intValue());
            return outDateTime;
        }
        
        
        
        
        /// <summary>
        ///     Update veeva event
        /// </summary>
        /// <param name="eventOfTp">
        ///     'eventOfTp' is an instance of an eevnt model class which contains data that will get send from TP
        /// </param> 
        static void UpdateVeevaEvent(PW_Event_Model eventOfTp)
        {    
                List<EM_Event_vod__c> lstevent = [select PW_Is_SIS_Good_Status__c,Status_vod__c,start_time_vod__c,OwnerId  from EM_Event_vod__c where id=:eventOfTp.Id limit 1 ];
                
                boolean Is_SIS_Good_Status= false;
                String startingStatus='';
                EM_Event_vod__c event = new EM_Event_vod__c();  
                if( lstevent.size()>0)
                {
                    Is_SIS_Good_Status= lstevent[0].PW_Is_SIS_Good_Status__c;
                    startingStatus= lstevent[0].Status_vod__c;
                    event.OwnerId= lstevent[0].OwnerId;
                    event.start_time_vod__c = lstevent[0].start_time_vod__c;
                } 
                else
                {
                       throw new Pw_ApplicationException('The Event Id '+ eventOfTp.Id + ' not found in EM' );  
                       return;             
                }              
                                     
               list<user> userList =[select id, name from user where EmployeeNumber=:eventOfTp.Owner_Emp_number limit 1];
                        if(userList.size()>0){ 
                         event.OwnerId= userList[0].id;
                }              
                event.Event_Configuration_vod__c=GetEventConf(eventOfTp.Record_Type_Id);
           
                event.Id = eventOfTp.Id;
                //event.name= eventOfTp.Event_Name;
                //event.PW_Product__c=eventOfTp.Product;
                //event.Indication_Disease_State__c=eventOfTp.Indication_Disease_State;
                event.Topic_vod__c=eventOfTp.Topic;                          
                //event.Start_Time_vod__c=datetime.valueOf(eventOfTp.Start_Time.replaceAll('/','-'));
                //event.End_Time_vod__c=datetime.valueOf(eventOfTp.End_Time.replaceAll('/','-'));
                
                PW_StartTime_EndTime_TimeZone_Utility timeutility = new PW_StartTime_EndTime_TimeZone_Utility(true, event);
                timeutility.SetStartTimeEndTimeAndTimeZone(eventOfTp);    
              
                event.Location_vod__c=eventOfTp.Location;
                event.Location_Address_vod__c=eventOfTp.Location_Address;            
                event.Location_Address_Line_2_vod__c=eventOfTp.Location_Address_Line_2;
                //event.PW_Location_Type__c=eventOfTp.Location_Type;//i3
                event.PW_TP_Event_ID__c = eventOfTp.TP_Event_ID;//newly added
                event.PW_Event_Format__c=eventOfTp.Event_Format;  
            
                event.City_vod__c=eventOfTp.City;
               // event.State_Province_vod__c=eventOfTp.State_Province;  
                event.State_Province_vod__c=eventOfTp.State_Province;          
                event.Postal_Code_vod__c=eventOfTp.Postal_Code;
                event.Venue_vod__c=eventOfTp.Venue;  //For the latest venue flow
                //event.Venue_vod__c=null;
                event.Vendor_vod__c=eventOfTp.Vendor;
                event.Status_vod__c=eventOfTp.Status;            
                event.Description_vod__c=eventOfTp.Description;
                event.PW_Tour__c=eventOfTp.Tour;
            
                //i3 fields
                event.PW_Coordinator_Email__c=eventOfTp.Coordinator_Email;
                event.PW_Coordinator_Name__c=eventOfTp.Coordinator_Name;
                event.PW_Speaker_Bureau_Phone_Number__c=eventOfTp.Speaker_Bureau_Phone_Number;
                //event.PW_I_attest_this_program_was_compliant__c=eventOfTp.Is_Attestad;
            
                //Add on fields needs to be tested
                event.PW_Event_Web_Call_In_Participant_Code__c=eventOfTp.Event_Web_Call_In_Participant_Code;
                event.PW_Event_Web_Organizers_Email__c=eventOfTp.Event_Web_Organizers_Email;
                event.PW_Event_Web_Participant_Call_In_Number__c=eventOfTp.Event_Web_Participant_Call_In_Number;
                event.PW_Event_Web_Participant_Code__c=eventOfTp.Event_Web_Participant_Code;
                event.PW_Event_Web_Speaker_Call_In_Number__c=eventOfTp.Event_Web_Speaker_Call_In_Number;
                event.PW_Event_Web_URL__c=eventOfTp.Event_Web_URL;
                //event.recordtype.name=eventOfTp.Record_Type;
                System.debug('event updated successfully record:' + eventOfTp.Record_Type_Id);
                event.RecordTypeId=eventOfTp.Record_Type_Id;
                event.Estimated_Attendance_vod__c=eventOfTp.Estimated_Attendance;
               
                //HIGHPOINT
                event.Pw_Event_Type__c= eventOfTp.EventType;
               // event.owner.username=eventOfTp.Owner_UserName;      
               
               //Location Confirmed
               event.PW_Is_Location_Confirmed__c = eventOfTp.PW_Is_Location_Confirmed; 
               
               //Caterer Confirmed
               event.PW_Is_Caterer_Confirmed__c = eventOfTp.PW_Is_Caterer_Confirmed;
                
               //NOV Release
               event.PW_AV_REP_Will_Provide__c  = eventOfTp.PW_AV_REP_Will_Provide;
               event.PW_AV_PW_Will_Provide__c  = eventOfTp.PW_AV_PW_Will_Provide;
               //Merck 2020 April
               event.PW_Audience_Flex_Field_1__c = eventOfTp.PW_Audience_Flex_Field_1;
               event.PW_Venue_Category__c= eventOfTp.PW_Venue_Category;
               
               if(Is_SIS_Good_Status==false)
               {
                   event.PW_Is_SIS_Good_Status__c= eventOfTp.PW_Is_SIS_Good_Status;
               }
               
                update event;
               insertEventHistory(eventOfTp.Id,startingStatus,eventOfTp.Status);
                
                System.debug('event updated successfully :' + event.id);
        }   
      
      static id GetEventConf(id recordType){
         
          RecordType fetchedRecordType = [SELECT Name, developername FROM RecordType 
                                      WHERE SObjectType = 'EM_Event_vod__c' and id =:recordType limit 1];
          
         list<EM_Event_Configuration_vod__c> eventConfigList= [select id from EM_Event_Configuration_vod__c where Event_Type_vod__c =: fetchedRecordType.developername limit 1];
          return eventConfigList[0].id;
          
      }
      static void insertEventHistory(id EventId,String startingStatus, String endingStatus)
      {
          EM_Event_History_vod__c history = new EM_Event_History_vod__c();
          history.Event_vod__c = EventId;
          history.Action_Datetime_vod__c=System.Now();
          history.User_vod__c = UserInfo.getUserId(); 
          history.Action_Type_vod__c = 'Event Status Updated by PW Connector';
          history.Starting_Status_vod__c =startingStatus;
          history.Ending_Status_vod__c = endingStatus;
          
          insert history;        
      }
      
      
                  
}