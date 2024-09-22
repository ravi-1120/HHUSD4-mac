///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_Event_Model_JsonGenerator
///   Description:    This class is awraper class which will get serialized in json and send to TP
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods create and get the json
///   Date: 25-9-2016
///   Revision History:
///-----------------------------------------------------------------
global class Pw_Event_Model_JsonGenerator {
    
        public String  EventType { get; set;}
        public DateTime EventDate { get; set;}
       // public integer ModelId { get; set; }
        public string ModelId { get; set; } //updated for jeopardy
        public string ModelName { get; set; }//"ModelType" updated to "ModelName"
        public integer ApplicationId { get; set;}
        public string ApplicationTitle { get; set; }
        public string ApplicationVersion { get; set; }
        public String TenantID { get; set;}// correcetd Tennant spelling
        public integer UserId { get; set;}
        public string UserFirstName { get;set; }
        public string UserLastName { get; set;}
        public string UserEmail { get; set; }
        public string JsonBefore { get; set;}
        public string JsonAfter { get; set; }
       
    public string MessageId{get;set{ // add as per ajay's suggession
            MessageId=null;
      }
        
 }
    
  
    
    
    /// <summary>
    ///     serialize the event
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    public void Set_Json_After_For_Event(Id evtId)
    {
        PW_Event_Model evt=new PW_Event_Model();
        evt.PopulateModel(evtId);
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeObject(evt); 
        JsonAfter = gen.getAsString(); 
        System.debug('Json Aft'+JsonAfter);
        //JsonAfter= JSON.serialize(evt);
    }
    
    
    /// <summary>
    ///     serialize the attendee
    /// </summary>
    /// <param name="attendeeId">
    ///     'attendeeId' contains attendee id
    /// </param> 
    
    public Boolean Set_Json_After_For_Attendee(id eventAttendeeId,  Event_Attendee_vod__c eventAttendeeOld)
    {
       // set<id> accountIds= new set<id>();
      
        Map<id,string> mapOfUser= new Map<id,string>(); 
        List<Event_Attendee_vod__c> AttendeeList=[SELECT Account_vod__c,Account_vod__r.PW_Client_ID__c,User_vod__r.EmployeeNumber,Attendee_Type_vod__c,EM_Event_Speaker_vod__r.Speaker_vod__r.PW_Speaker_ID__c,EM_Attendee_vod__r.Credentials_vod__c,
                                                   Status_vod__c,PW_State__c,First_Name_vod__c,PW_Salutation__c,Medical_Event_vod__r.EM_Event_vod__r.Status_vod__c,Medical_Event_vod__r.EM_Event_vod__c,Last_Name_vod__c,Meal_Opt_In_vod__c,Walk_In_Status_vod__c,
                                                   EM_Event_Speaker_vod__c,PW_Address_Type__c,Zip_vod__c,City_vod__c,PW_Attendee_Type__c,PW_Client_ID__c,PW_Office_Name__c,Credentials_vod__c,
                                                   PW_Participant_ID__c,PW_Event_Attendee_Row_ID__c, PW_Specialty__c,Address_Line_1_vod__c,Address_Line_2_vod__c,PW_SL_State__c,PW_SL__c,PW_NPI__c,PW_Position__c,Signature_vod__c, PW_Samples__c, PW_SKit__c, PW_SLotNo__c, Email_vod__c, Phone_vod__c, PW_MobNo__c FROM Event_Attendee_vod__c 
                                                   where id=:eventAttendeeId and Attendee_Type_vod__c not in ('Online Registrant', 'Contact')];
        /*[SELECT Account_vod__c,Account_vod__r.PW_Client_ID__c,User_vod__r.EmployeeNumber,Attendee_Type_vod__c,Address_Line_1_vod__c,Address_Line_2_vod__c,Address_Type__c,Zip_vod__c,
                                               First_Name_vod__c,PW_Salutation__c,Event_vod__c,Last_Name_vod__c,Meal_Opt_In_vod__c,Walk_In_Status_vod__c,Status_vod__c,PW_Address_Type__c,
                                               City_vod__c,PW_Attendee_Type__c,PW_Client_ID__c,PW_Credentials__c,PW_Office_Name__c,PW_Participant_ID__c,PW_Event_Attendee_Row_ID__c, PW_Specialty__c,PW_State__c 
                                               FROM EM_Attendee_vod__c where id=:attendeeId and Attendee_Type_vod__c not in ('Online Registrant', 'Contact')];*/
        if(AttendeeList.size()>0)
        {
            list<EM_Event_Speaker_vod__c> eveSpeakerList=[SELECT Id, Speaker_vod__r.Account_vod__c  FROM EM_Event_Speaker_vod__c where Event_vod__c =: AttendeeList[0].Medical_Event_vod__r.EM_Event_vod__c];
            
            List<User> userList = [SELECT id,EmployeeNumber FROM User limit: Limits.getLimitQueryRows() - Limits.getQueryRows()];
           
            for(User userLocal :userList)
            {
                mapOfUser.put(userLocal.id ,userLocal.EmployeeNumber);   
            }
    
            /*for(EM_Event_Speaker_vod__c eventSpeaker :eveSpeakerList)
            {            
               accountIds.add(eventSpeaker.Speaker_vod__r.Account_vod__c);             
            } */               
             
             
            PW_Event_Attendee_Model attendeeModel = new PW_Event_Attendee_Model();
            attendeeModel.FillAttendeeModel(AttendeeList[0],mapOfUser,eventAttendeeOld);
            String eventStatus=attendeeModel.getEventStatus();
            
             PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
            if(regSettings.PW_Send_Attendee_Statuses__c.contains(eventStatus)){
           
            //if( eventStatus=='Confirmed'||eventStatus=='Completed'||eventStatus=='Closed_vod'||eventStatus=='Submitted'||eventStatus=='Completing' ||  eventStatus== 'Pending'){
            JSONGenerator gen = JSON.createGenerator(false);
            gen.writeObject(attendeeModel); 
            JsonAfter = gen.getAsString(); 
            System.debug('Json Aft'+JsonAfter);
            return true;
            
           }
              
         }
     return false;
    }
    public Boolean Set_Json_After_For_AttendeeBulk(Event_Attendee_vod__c eventAttendee,  Event_Attendee_vod__c eventAttendeeOld)
    {

            PW_Event_Attendee_Model attendeeModel = new PW_Event_Attendee_Model();
            attendeeModel.FillAttendeeModelBulk(eventAttendee,eventAttendeeOld);//******************To do Check Map of USERiD
            String eventStatus=attendeeModel.getEventStatus();
            
             PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
            if(regSettings.PW_Send_Attendee_Statuses__c.contains(eventStatus)){
           
            //if( eventStatus=='Confirmed'||eventStatus=='Completed'||eventStatus=='Closed_vod'||eventStatus=='Submitted'||eventStatus=='Completing' ||  eventStatus== 'Pending'){
            JSONGenerator gen = JSON.createGenerator(false);
            gen.writeObject(attendeeModel); 
            JsonAfter = gen.getAsString(); 
            System.debug('Json Aft'+JsonAfter);
            return true;
            
           }
              
         
     return false;
    }

    /// <summary>
    ///     serialize the event attachement
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    public boolean Set_Json_After_For_Attachment(Id atachmentId, id parentId,string firstname,string lastname,string employeeNumber)
    {
        PW_Event_Attachment_Model attachModel =new PW_Event_Attachment_Model(atachmentId,parentId,firstname,lastname,employeeNumber);
        system.debug('Attachment model '+attachModel);
       // attachModel.PopulateModel(atachmentId);
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeObject(attachModel); 
        JsonAfter = gen.getAsString(); 
        System.debug('Json Aft'+JsonAfter);
        //JsonAfter= JSON.serialize(evt);
        return true;
    }
    
    /// <summary>
    ///     serialize the message
    /// </summary> 
    public void Set_Json_After_For_Message(Integer messageId,string message,string status)
    {
        system.debug('Message parameters '+messageId+' '+message+' '+status);
        PW_ActualStatusResponse_Model messageRes = new PW_ActualStatusResponse_Model(messageId,message,status);
        system.debug('MessageResponse '+messageRes);
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeObject(messageRes); 
        JsonAfter = gen.getAsString(); 
        System.debug('Json Aft'+JsonAfter);
    }
      /// <summary>
    ///     serialize the message
    /// </summary> PW_Speaker_Status_Model
    public Boolean Set_Json_After_For_UpdateSpeakerStatus(String Status ,String  PW_Speaker_ID ,Id spkId ,String  LastModifiedDate)
    {
        PW_Speaker_Status_Model  speakerStatus=new PW_Speaker_Status_Model();
            if( speakerStatus.initializeSpeakerStatus(Status,PW_Speaker_ID, spkId, LastModifiedDate) == false)
            {
                return false;
            }
            else
            {
            JSONGenerator gen = JSON.createGenerator(false);
                gen.writeObject(speakerStatus);    // Pass  List
                JsonAfter = gen.getAsString(); 
                System.debug('Json Aft'+JsonAfter);               
            }       
     return true;
    }
    /// <summary>
    ///     serialize the message
    /// </summary> 
    public void Set_Json_After_For_MessageAttendee(Integer messageId,string message,string status,list<PW_Attendee_ID_Map_Model> lstofAttendeeVeevaAndRowIds)
    {
        system.debug('Message parameters '+messageId+' '+message+' '+status);
        PW_AttendeeStatusResponse_Model messageRes = new PW_AttendeeStatusResponse_Model(messageId,message,status,lstofAttendeeVeevaAndRowIds);
        system.debug('MessageResponse '+messageRes);
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeObject(messageRes); 
        JsonAfter = gen.getAsString(); 
        System.debug('Json Aft'+JsonAfter);
    }
    
    public Boolean Set_Json_After_For_TeamMember(id eventTeamMemberId ,EM_Event_Team_Member_vod__c eventTeamMember)
    {
        PW_Veeva_Event_Team_Member_Model  VeevaEventTeamMembers=new PW_Veeva_Event_Team_Member_Model();
            if( VeevaEventTeamMembers.initializeEventTeamMember(eventTeamMemberId,eventTeamMember) == false)
            {
                return false;
            }
            if(VeevaEventTeamMembers.isEventStatusValidToSendTeamMember())
            {
                JSONGenerator gen = JSON.createGenerator(false);
                gen.writeObject(VeevaEventTeamMembers);    // Pass  List
                JsonAfter = gen.getAsString(); 
                System.debug('Json Aft'+JsonAfter);
                return true;
            }
     
        
     return false;
    }
        /// <summary>
    ///     serialize the message
    /// </summary> 
    public Boolean Set_Json_After_For_Event_Staus(id event){
        System.Debug('InSide Json Genrator  Set_Json_After_For_Event_Staus ::'+event);
      List< EM_Event_vod__c> events=[select id,toLabel(Status_vod__c) from EM_Event_vod__c where id=:event LIMIT 1];
        PW_Event_Status_Model EventStatus =new PW_Event_Status_Model();
        if(events.size()>0)
        {
            EventStatus.EventID =events[0].id;
            EventStatus.Status_Label =events[0].Status_vod__c;
            JSONGenerator gen = JSON.createGenerator(false);
            gen.writeObject(EventStatus);    // Pass  List
            JsonAfter = gen.getAsString(); 
            System.debug('Json Aft'+JsonAfter);
            return true;
        
        }
        else
        {
            return false;
        }
    }
        /// <summary>
    ///     serialize the message
    /// </summary> 
   public void Set_Json_After_For_InsertUpdateDeleteSpeakerQualification(PW_Send_Speaker_Qualification_Model  speakerQualification)
    {
       
            JSONGenerator gen = JSON.createGenerator(false);
                gen.writeObject(speakerQualification);    // Pass  List
                JsonAfter = gen.getAsString(); 
                System.debug('Json Aft'+JsonAfter);               
            
    }   
    public string  GetJSONString()
    {        
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeObject(this);
        return gen.getAsString();
        
    }
    
        /// <summary>
    ///     serialize the Event Msg October 2020//
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    public boolean Set_Json_After_For_Event_UpdMsg(Id EventID)
    {
        PW_Event_MSG_Model EvtMsgModel =new PW_Event_MSG_Model();
        system.debug('EvtMsgModel model '+EvtMsgModel);
        EvtMsgModel.PopulateModel(EventID);
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeObject(EvtMsgModel); 
        JsonAfter = gen.getAsString(); 
        System.debug('Json Aft'+JsonAfter);
        //JsonAfter= JSON.serialize(evt);
        return true;
    }
    
    
}