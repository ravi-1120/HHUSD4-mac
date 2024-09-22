//Event Modal
//-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Event_Model
///   Description:    This class contains all the fields that are going to be send to TP as aJson
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods which will send lsit of speakers and team members of an event
///   Date: 24-9-2016
///   Revision History:
///-----------------------------------------------------------------

global class PW_Event_Model
{
   public Id Id{get;set;}//Event_Id updated to id 
   public String Event_Name{get;set;}
   public Id Product{get;set;}
   public String Indication_Disease_State{get;set;}
   public Id Topic{get;set;}
   public String Event_Format{get;set;}
   public String Start_Time{get;set;}
   public String  End_Time{get;set;}
   public String Time_Zone{get;set;}  
   public String Location{get;set;}
   public String Location_Address{get;set;}
   public String Location_Address_Line_2{get;set;}
   public String City{get;set;}
   public String State_Province{get;set;}
   public String Postal_Code{get;set;}
   public Id  Vendor{get;set;}
   public Id Venue{get;set;}
    public string Venue_Name{get;set;}
   public String Status{get;set;}    
   public String Description{get;set;}
   public boolean Tour{get;set;}
   public String Record_Type{get;set;}
   public Id Record_Type_Id{get;set;}
   public string Owner_Emp_number {get;set;}
   public decimal Estimated_Attendance{get;set;}
   public String Owner_UserName{get;set;}
   public string Tp_Event_ID{get;set;}
    
    
   //i3
   public string Location_Type{get;set;}
   public string Coordinator_Email{get;set;}
   public string Coordinator_Name{get;set;}
   public string Speaker_Bureau_Phone_Number{get;set;}
   //public boolean Is_Attestad{get;set;}
    
    
    
   public List<PW_Speaker_Model> ListOfSpeaker{get;set;}//stores the speakers of the event
   public List<PW_Event_Team_Member_Model> ListOfEventTeamMember{get;set;}//stores team members of the event
   public List<PW_Expense_Estimate_Model> ListOfEstimate{get;set;}
   public List<PW_Event_Attendee_Model> ListOfAttendee{get;set;}
    
    
   //Added new fields for web conference record type
   public String Event_Web_Call_In_Participant_Code{get;set;}
    public String Event_Web_Organizers_Email{get;set;}
    public String Event_Web_Participant_Call_In_Number{get;set;}
    public String Event_Web_Participant_Code{get;set;}
    public String Event_Web_Speaker_Call_In_Number{get;set;}
    public String Event_Web_URL{get;set;}
    
    //HIGHPOINT
    //
    public string EventType{get;set;}
    public Id Parent_Event{get;set;}
    public boolean  PW_Is_Location_Confirmed{get;set;}
    public boolean  PW_Is_Caterer_Confirmed{get;set;}
    public Integer Message_Id{get;set;}
    
    //NOV Release
    public string PW_AV_REP_Will_Provide{get;set;}
    public string PW_AV_PW_Will_Provide{get;set;}
    
    //Mercl Release
    public boolean PW_Is_SIS_Good_Status{get;set;}
    public String Status_Label{get;set;}

    //April 2020 Release
    public String PW_Audience_Flex_Field_1{get;set;}
    public String PW_Venue_Category{get;set;}
    
    // Jan 2021 Release
    public string PW_Program_Designation{get;set;} 
    
    public void PopulateModel(Id EventId)
    {
        //Fetch event data fields that needs to be send to TP
        List<em_event_vod__c> events=[select Id,name,PW_Location_Type__c,topic_vod__c,topic_vod__r.PW_Product__c,PW_Event_Format__c,start_time_vod__c,end_time_vod__c,PW_Time_Zone__c,
                               location_vod__c,location_address_vod__c,Location_Address_Line_2_vod__c,city_vod__c,state_province_vod__c,postal_code_vod__c,PW_Speaker_Bureau_Phone_Number__c,
                               PW_Therapeutic_Area__c,vendor_vod__c,Venue_vod__c,Estimated_Attendance_vod__c,status_vod__c,description_vod__c,PW_Tour__c,recordtype.name,recordtype.id,PW_Coordinator_Email__c,
                               owner.username,PW_Coordinator_Name__c,PW_Duration__c,PW_Local_Start_Time__c,PW_Local_Start_Date__c, PW_Event_Type__c,Parent_Event_vod__c, PW_AV_REP_Will_Provide__c, PW_AV_PW_Will_Provide__c, toLabel(Status_vod__c) StatusLabel, PW_Audience_Flex_Field_1__c, PW_Venue_Category__c, PW_Program_Designation__c, OwnerID, End_Date_vod__c, End_Time_Local_vod__c, Start_Date_vod__c, Start_Time_Local_vod__c, Time_Zone_vod__c  from em_event_vod__c where id =:EventId limit 1];                
      
        if(events.size()>0){
            
            em_event_vod__c event= events[0];
            
            list<user> userList =[select id, EmployeeNumber from user where id=:event.ownerid limit 1];
        if(userList.size()>0){ 
           Owner_Emp_number= userList[0].EmployeeNumber ; 
        }
                   
        //Fill the event model 
        Id=event.Id;
        Event_Name=event.name;
        Product=event.topic_vod__r.PW_Product__c;
        Indication_Disease_State=event.PW_Therapeutic_Area__c;// Changed as per kevin 
        Topic=event.Topic_vod__c;
        Event_Format=event.PW_Event_Format__c; 
        
        PW_StartTime_EndTime_TimeZone_Utility gettime = new PW_StartTime_EndTime_TimeZone_Utility(true, event);
        Start_Time = gettime.GetStartTime(); // JULY 2021 release
        End_Time= gettime.GetEndTime(); // JULY 2021 release       
        Time_Zone=gettime.GetTimeZone(); // JULY 2021 release
        
        Location=event.Location_vod__c;
        Location_Address=event.Location_Address_vod__c;
        Location_Type=event.PW_Location_Type__c;//i3
        Location_Address_Line_2=event.Location_Address_Line_2_vod__c;
        City=event.City_vod__c;
        State_Province=event.State_Province_vod__c;// Changed as per kevin 
        EventType = event.PW_Event_Type__c;
        Parent_Event = event.Parent_Event_vod__c; //Parent Child
        
        Postal_Code=event.Postal_Code_vod__c;
        Vendor=event.Vendor_vod__c;
        Venue=event.Venue_vod__c;
            
        if(Venue!= null){
           Venue_Name=[select name from EM_Venue_vod__c  where id =:Venue limit 1].name;  // to addvenue name (i3)
        }  
            
        Status=event.Status_vod__c;
        
        Description=event.Description_vod__c;
        Tour=event.PW_Tour__c;
        Record_Type=event.recordtype.name;
        Record_Type_Id=event.RecordTypeId;
        Estimated_Attendance=event.Estimated_Attendance_vod__c;             
        Owner_UserName=event.owner.username;
         
            
        Coordinator_Email=event.PW_Coordinator_Email__c; //i3
        Coordinator_Name=event.PW_Coordinator_Name__c;//i3
        Speaker_Bureau_Phone_Number  = event.PW_Speaker_Bureau_Phone_Number__c;//i3
        //Is_Attestad=event.PW_I_attest_this_program_was_compliant__c; //Complete status
        
        //NOV Release
        PW_AV_REP_Will_Provide = event.PW_AV_REP_Will_Provide__c;
        PW_AV_PW_Will_Provide = event.PW_AV_PW_Will_Provide__c;
        // Merc Release 
        Status_Label = (String)event.get('StatusLabel');
        //Merck 2020 April
        PW_Audience_Flex_Field_1 = event.PW_Audience_Flex_Field_1__c;
        PW_Venue_Category= event.PW_Venue_Category__c;
        //Jan 2021 Release
        PW_Program_Designation = event.PW_Program_Designation__c;
        
        PopulateSpeakerList(EventId);
        PopulateTeamMemberDetails(EventId);
        PopulateBudgetEstimate(EventId);
        PopulateAttendee(EventId);
            
       system.debug('Generated json'+ JSON.serialize(this));
        }
    }
    
    
     /// <summary>
    ///     Handles the start and end time
    /// </summary>
    /// <param name="StartTime">
    ///     Start Time contains the local start date and time field data  
    /// </param> 
    //<param name="Duration">
    ///         Duration contains the duaration of the event
    /// </param>    
    public string GetEndDate(decimal duration, datetime startDateTime){              
         System.debug(' duration  ' +duration); 
        integer durationInMinutes= (integer)math.round(duration*60);
        System.debug(' duration  ' +durationInMinutes); 
        datetime endDateLocal =startDateTime.addMinutes(durationInMinutes);
        System.debug(' duration after addition  ' +endDateLocal); 
         return string.valueOf(endDateLocal);
       
    }
    
    /// <summary>
    ///     Handles the speakers of an event
    /// </summary>
    /// <param name="EventId">
    ///     Event Id contains the id of the vent that is just submitted and is going to be send to TP
    /// </param>    
    public void PopulateSpeakerList(Id EventId)
    {
        List<EM_Event_Speaker_vod__c> Speaker=[select id,Speaker_vod__r.PW_Speaker_ID__c,Speaker_vod__c,PW_Speaker_Priority__c,PW_Speaker_Recruited__c from EM_Event_Speaker_vod__c 
                                               where Event_vod__c =:EventId and Speaker_vod__r.PW_Speaker_ID__c!=null] ;    //Limits.getLimitQueryRows() - Limits.getQueryRows()   
        ListOfSpeaker=new List<PW_Speaker_Model>();
        System.debug('Speaker count'+Speaker.size());
        for(EM_Event_Speaker_vod__c speakerLocal :Speaker)
        {
            PW_Speaker_Model SpeakerModel =new PW_Speaker_Model();
            SpeakerModel.Veeva_Speaker_Id=speakerLocal.Speaker_vod__c;
            SpeakerModel.TP_Speaker_Id=Integer.valueof(speakerLocal.Speaker_vod__r.PW_Speaker_ID__c.trim());
            SpeakerModel.PW_Speaker_Priority=speakerLocal.PW_Speaker_Priority__c;
            SpeakerModel.PW_Speaker_Recruited=speakerLocal.PW_Speaker_Recruited__c; 
            ListOfSpeaker.add(SpeakerModel);
        }
        system.debug('Lst Speaker'+ListOfSpeaker);
    }
    
    /// <summary>
    ///     Handles the Team members of an event
    /// </summary>
    /// <param name="EventId">
    ///     Event Id contains the id of the vent that is just submitted and is going to be send to TP
    /// </param>   
    public void PopulateTeamMemberDetails(Id EventId)
    {
        List<EM_Event_Team_Member_vod__c> Team_Member=[select Team_Member_vod__r.Id,Team_Member_vod__r.EmployeeNumber,Team_Member_vod__r.userName, Role_vod__c from EM_Event_Team_Member_vod__c 
                                                       where Event_vod__c =:EventId];
        ListOfEventTeamMember=new List<PW_Event_Team_Member_Model>();
        integer flag=0;
         for(EM_Event_Team_Member_vod__c EventTeamMemberLocal :Team_Member)
        {
            if(EventTeamMemberLocal.Role_vod__c.containsIgnoreCase('organizer')||EventTeamMemberLocal.Role_vod__c.containsIgnoreCase('cohost'))
            {
                PW_Event_Team_Member_Model EventTeamMemberModel =new PW_Event_Team_Member_Model();
                EventTeamMemberModel.Employee_number=EventTeamMemberLocal.Team_Member_vod__r.EmployeeNumber;
                EventTeamMemberModel.User_Name=EventTeamMemberLocal.Team_Member_vod__r.userName;
                EventTeamMemberModel.Role = EventTeamMemberLocal.Role_vod__c;
                ListOfEventTeamMember.add(EventTeamMemberModel);
                system.debug(ListOfEventTeamMember);
            }
            if(EventTeamMemberLocal.Role_vod__c.containsIgnoreCase('organizer'))
            {
                flag=1;
            }
            
        }
        if(flag==0)//There are no organizers
        {
            system.debug('No Organizer for the event ' + EventId + 'throwing error');
            String errormssg= 'No Organizer fournd for the event ' + String.Valueof(EventId);
            throw  new StringException(errormssg);
            
        }
        
    }
    
    
     /// <summary>
    ///     Handles the Estimates of an event
    /// </summary>
    /// <param name="EventId">
    ///     Event Id contains the id of the vent that is just submitted and is going to be send to TP
    /// </param>   
    public void PopulateBudgetEstimate(Id EventId)
    {
        List<EM_Expense_Estimate_vod__c> EstimateList=[select Actual_vod__c,Committed_vod__c,Estimate_vod__c,Expense_Type_vod__c,
                                                       Expense_Type_Name_vod__c from EM_Expense_Estimate_vod__c where Event_vod__c =:EventId];
        ListOfEstimate=new List<PW_Expense_Estimate_Model>();
         for(EM_Expense_Estimate_vod__c EventEstimateLocal :EstimateList)
        {
            PW_Expense_Estimate_Model EventEstimateModel =new PW_Expense_Estimate_Model();
                         
                EventEstimateModel.Estimate=EventEstimateLocal.Estimate_vod__c;
                EventEstimateModel.Expense_Type=EventEstimateLocal.Expense_Type_vod__c;
                EventEstimateModel.Expense_Type_Name=EventEstimateLocal.Expense_Type_Name_vod__c;                      
            
            ListOfEstimate.add(EventEstimateModel);
            system.debug('ListOfEstimate ' + ListOfEstimate);
        }
        
    }
    
    /// <summary>
    ///     Handles Attendee of an event
    /// </summary>
    /// <param name="EventId">
    ///     Event Id contains the id of the vent that is just submitted and is going to be send to TP
    /// </param>   
    public void PopulateAttendee(Id EventId)
    {
        //set<id> accountIds= new set<id>();
        ListOfAttendee=new List<PW_Event_Attendee_Model>();
       // Map<id,string> mapOfUser= new Map<id,string>(); 
        List<Event_Attendee_vod__c> AttendeeeList=[SELECT Account_vod__c,Account_vod__r.PW_Client_ID__c,User_vod__r.EmployeeNumber,Attendee_Type_vod__c,EM_Event_Speaker_vod__r.Speaker_vod__r.PW_Speaker_ID__c,Medical_Event_vod__r.EM_Event_vod__r.Status_vod__c,
                                                   Status_vod__c,PW_State__c,First_Name_vod__c,PW_Salutation__c,Medical_Event_vod__r.EM_Event_vod__c,Last_Name_vod__c,Meal_Opt_In_vod__c,Walk_In_Status_vod__c,Credentials_vod__c,EM_Attendee_vod__r.Credentials_vod__c,
                                                   EM_Event_Speaker_vod__c,PW_Address_Type__c,Zip_vod__c,City_vod__c,PW_Attendee_Type__c,PW_Client_ID__c,/*PW_Credentials__c,*/PW_Office_Name__c,
                                                   PW_Participant_ID__c,PW_Event_Attendee_Row_ID__c, PW_Specialty__c,Address_Line_1_vod__c,Address_Line_2_vod__c,PW_SL_State__c,PW_SL__c,PW_NPI__c,PW_Position__c,Signature_vod__c, PW_Samples__c, PW_SKit__c, PW_SLotNo__c, Email_vod__c, Phone_vod__c, PW_MobNo__c, PW_Professional_Designation__c FROM Event_Attendee_vod__c 
                                                   where Medical_Event_vod__r.EM_Event_vod__c =:EventId and Attendee_Type_vod__c not in ('Online Registrant', 'Contact') and EM_Event_Speaker_vod__c =null and EM_Event_Team_Member_vod__c=null]; // Added 'and EM_Event_Team_Member_vod__c=null' for ticket 68021
        
       // list<EM_Event_Speaker_vod__c> eveSpeakerList=[SELECT Id, Speaker_vod__r.Account_vod__c  FROM EM_Event_Speaker_vod__c where Event_vod__c =: eventId];
       /*  List<User> userList = [SELECT id,EmployeeNumber FROM User limit: Limits.getLimitQueryRows() - Limits.getQueryRows()];
       
       for(User userLocal :userList){
            mapOfUser.put(userLocal.id ,userLocal.EmployeeNumber);  
          }*/
               
         for(Event_Attendee_vod__c EventAttendeeLocal :AttendeeeList)
         {   
            PW_Event_Attendee_Model attendeeModel = new PW_Event_Attendee_Model();
             attendeeModel.FillAttendeeModelBulk(EventAttendeeLocal,null);
            ListOfAttendee.add(attendeeModel);           
         }
         system.debug('ListOfAttendee ' + ListOfAttendee );
    }        
}