global class PW_Event_Attendee_Model {
    
    public String Pw_Credentials{get;set;}
    public String Pw_Specialty{get;set;}
    public String Pw_Salutation{get;set;}
    public String First_Name{get;set;}
    public String Last_Name{get;set;}
    public String Pw_Address_Type{get;set;}
    public String Pw_Office_Name{get;set;}
    public String Address_Line_1{get;set;}
    public String City{get;set;}
    public String Pw_State{get;set;}
    public String Zip{get;set;}
    public String Status{get;set;}
    public boolean Meal_Opt_In{get;set;}
     // public String Signature{get;set;}  
    public String Pw_Participant_ID{get;set;} 
    public String Pw_Attendee_Type{get;set;} 
    public String Attendee_Type{get;set;}
    public String Pw_Client_ID{get;set;}  
    public String PW_Event_Attendee_Row_ID{get;set;} 
    public String Veeva_Account_id{get;set;} 
    public String Pw_Employee_number {get;set;} 
    public id Veeva_Attendee_Id {get;set;} 
    public id Event_Id {get;set;}
    public String Speaker_Tp_Id {get;set;}
    private transient String Event_Status{get;set;}
    public String PW_SL_State {get;set;}  // For Medical Id CR
    public String PW_SL {get;set;}      // For Medical Id CR
    public String PW_NPI {get;set;}     // For Medical Id CR
    public String PW_Position {get;set;}        // For 23918 Write-In Data CR
    public Boolean PW_Is_Signed {get;set;}
    public Integer Message_Id{get;set;}
    public String User_ID{get;set;}
    public boolean PW_Sample_Kit{get;set;}        //ADDED for Merck
    public Integer PW_Samples{get;set;}        //ADDED for Merck
    public String PW_Samples_Lot_Number {get;set;}    //ADDED for Merck  
    public String PW_ReconciledTo {get;set;}    //ADDED for Merck  
    public String PW_Walk_In_Status {get;set;}    //ADDED for Merck  
    public String Email {get;set;}    //ADDED for Merck  
    public String Phone {get;set;}    //ADDED for Merck  
    public String PW_MobNo {get;set;}    //ADDED for Merck  
    public String Walk_In_Type {get;set;} // 51076 Support new Veeva Walk-In field -> TP to Veeva
    public String PW_Professional_Designation {get;set;} // 49142 Supports the designation with the EM Integration. Bi- Directional, May Release 2021
    
    
    public String getEventStatus()
    {
        return Event_Status;
    }
    
    public void FillAttendeeModel(Event_Attendee_vod__c EventAttendeeLocal,Map<id,string> mapOfUser, Event_Attendee_vod__c eventAttendeeOld)
   {            
           //Pw_Credentials= EventAttendeeLocal.PW_Credentials__c; as per requirement 
           Pw_Credentials= EventAttendeeLocal.EM_Attendee_vod__r.Credentials_vod__c;
           Status=EventAttendeeLocal.Status_vod__c;
           First_Name = EventAttendeeLocal.First_Name_vod__c;
           Last_Name = EventAttendeeLocal.Last_Name_vod__c;                
           Address_Line_1 = EventAttendeeLocal.Address_Line_1_vod__c;
           City = EventAttendeeLocal.City_vod__c;
           Zip = EventAttendeeLocal.Zip_vod__c;
           Meal_Opt_In = EventAttendeeLocal.Meal_Opt_In_vod__c; 
           Attendee_Type =EventAttendeeLocal.Attendee_Type_vod__c; 
           Pw_Specialty=EventAttendeeLocal.PW_Specialty__c;
           Pw_Salutation=EventAttendeeLocal.PW_Salutation__c;
           Pw_Address_Type=EventAttendeeLocal.PW_Address_Type__c;
           Pw_Office_Name=EventAttendeeLocal.PW_Office_Name__c;
           Pw_State=EventAttendeeLocal.PW_State__c;
           Pw_Participant_ID=EventAttendeeLocal.PW_Participant_ID__c;
           Pw_Attendee_Type =EventAttendeeLocal.PW_Attendee_Type__c;
           Pw_Client_ID=EventAttendeeLocal.Account_vod__r.PW_Client_ID__c;//PW_Client_ID__c;
           PW_Event_Attendee_Row_ID = EventAttendeeLocal.PW_Event_Attendee_Row_ID__c; 
           Veeva_Account_id=EventAttendeeLocal.Account_vod__c;
           Veeva_Attendee_Id =EventAttendeeLocal.id;              
           Event_Id =EventAttendeeLocal.Medical_Event_vod__r.EM_Event_vod__c;
           Event_Status=EventAttendeeLocal.Medical_Event_vod__r.EM_Event_vod__r.Status_vod__c;
           PW_SL_State = EventAttendeeLocal.PW_SL_State__c;
           PW_SL = EventAttendeeLocal.PW_SL__c;
           PW_NPI = EventAttendeeLocal.PW_NPI__c; 
           PW_Position = EventAttendeeLocal.PW_Position__c;
           User_ID = EventAttendeeLocal.User_vod__c; //Newly added to send userid
           PW_Sample_Kit = EventAttendeeLocal.PW_SKit__c;//ADDED for Merck
           PW_Samples = Integer.valueOf(EventAttendeeLocal.PW_Samples__c); //ADDED for Merck
           PW_Samples_Lot_Number = EventAttendeeLocal.PW_SLotNo__c;//ADDED for Merck
            PW_Walk_In_Status = EventAttendeeLocal.Walk_In_Status_vod__c;//ADDED for Merck
           Email = EventAttendeeLocal.Email_vod__c; //ADDED for Merck
           Phone = EventAttendeeLocal.Phone_vod__c;//ADDED for Merck
            PW_MobNo = EventAttendeeLocal.PW_MobNo__c;//ADDED for Merck
            PW_Professional_Designation = EventAttendeeLocal.PW_Professional_Designation__c;// 49142 Supports the designation with the EM Integration. Bi- Directional
       
           
           if(! string.isempty(EventAttendeeLocal.Signature_vod__c))
           {
                PW_Is_Signed = true;
           }
           else
           {
                PW_Is_Signed = false;
           }
           if (EventAttendeeLocal.Account_vod__c !=null)
           {
                Attendee_Type='Account'; 
           }
    
           PW_ReconciledTo='';
       if(string.isNotBlank(EventAttendeeLocal.Walk_In_Status_vod__c) ){
              Attendee_Type='Walk In'; 
           if(EventAttendeeLocal.Account_vod__c !=null)
           {
               Attendee_Type='Account'; 
               if(eventAttendeeOld != null)
               {
                   if(eventAttendeeOld.Account_vod__c == null)
                   {
                       PW_ReconciledTo='Account';
                   }
               }
           }
           if(EventAttendeeLocal.User_vod__c !=null)
           {
               Attendee_Type='User'; 
               Pw_Employee_number= mapOfUser.get(EventAttendeeLocal.User_vod__c); 
               if(eventAttendeeOld != null)
               {
                   if(eventAttendeeOld.User_vod__c == null)
                   {
                       PW_ReconciledTo='User';
                     
                   }
               }
           }
           }else if(EventAttendeeLocal.EM_Event_Speaker_vod__c!=null) {
                Attendee_Type='Speaker'; 
                Speaker_Tp_Id = EventAttendeeLocal.EM_Event_Speaker_vod__r.Speaker_vod__r.PW_Speaker_ID__c;          
           } else if(Attendee_Type=='User' ){                
                 Pw_Employee_number= mapOfUser.get(EventAttendeeLocal.User_vod__c);          
           }           
   }   
     public void FillAttendeeModelBulk(Event_Attendee_vod__c EventAttendeeLocal, Event_Attendee_vod__c eventAttendeeOld)
   {            
           //Pw_Credentials= EventAttendeeLocal.PW_Credentials__c; as per requirement 
           Pw_Credentials= EventAttendeeLocal.EM_Attendee_vod__r.Credentials_vod__c;
           Status=EventAttendeeLocal.Status_vod__c;
           First_Name = EventAttendeeLocal.First_Name_vod__c;
           Last_Name = EventAttendeeLocal.Last_Name_vod__c;                
           Address_Line_1 = EventAttendeeLocal.Address_Line_1_vod__c;
           City = EventAttendeeLocal.City_vod__c;
           Zip = EventAttendeeLocal.Zip_vod__c;
           Meal_Opt_In = EventAttendeeLocal.Meal_Opt_In_vod__c; 
           Attendee_Type =EventAttendeeLocal.Attendee_Type_vod__c; 
           Pw_Specialty=EventAttendeeLocal.PW_Specialty__c;
           Pw_Salutation=EventAttendeeLocal.PW_Salutation__c;
           Pw_Address_Type=EventAttendeeLocal.PW_Address_Type__c;
           Pw_Office_Name=EventAttendeeLocal.PW_Office_Name__c;
           Pw_State=EventAttendeeLocal.PW_State__c;
           Pw_Participant_ID=EventAttendeeLocal.PW_Participant_ID__c;
           Pw_Attendee_Type =EventAttendeeLocal.PW_Attendee_Type__c;
           Pw_Client_ID=EventAttendeeLocal.Account_vod__r.PW_Client_ID__c;//PW_Client_ID__c;
           PW_Event_Attendee_Row_ID = EventAttendeeLocal.PW_Event_Attendee_Row_ID__c; 
           Veeva_Account_id=EventAttendeeLocal.Account_vod__c;
           Veeva_Attendee_Id =EventAttendeeLocal.id;              
           Event_Id =EventAttendeeLocal.Medical_Event_vod__r.EM_Event_vod__c;
           Event_Status=EventAttendeeLocal.Medical_Event_vod__r.EM_Event_vod__r.Status_vod__c;
           PW_SL_State = EventAttendeeLocal.PW_SL_State__c;
           PW_SL = EventAttendeeLocal.PW_SL__c;
           PW_NPI = EventAttendeeLocal.PW_NPI__c; 
           PW_Position = EventAttendeeLocal.PW_Position__c;
           User_ID = EventAttendeeLocal.User_vod__c; //Newly added to send userid
           PW_Sample_Kit = EventAttendeeLocal.PW_SKit__c;//ADDED for Merck
           PW_Samples = Integer.valueOf(EventAttendeeLocal.PW_Samples__c); //ADDED for Merck
           PW_Samples_Lot_Number = EventAttendeeLocal.PW_SLotNo__c;//ADDED for Merck
            PW_Walk_In_Status = EventAttendeeLocal.Walk_In_Status_vod__c;//ADDED for Merck
           Email = EventAttendeeLocal.Email_vod__c; //ADDED for Merck
           Phone = EventAttendeeLocal.Phone_vod__c;//ADDED for Merck
            PW_MobNo = EventAttendeeLocal.PW_MobNo__c;//ADDED for Merck
            PW_Professional_Designation = EventAttendeeLocal.PW_Professional_Designation__c;// 49142 Supports the designation with the EM Integration. Bi- Directional, May Release 2021
           
           if(! string.isempty(EventAttendeeLocal.Signature_vod__c))
           {
                PW_Is_Signed = true;
           }
           else
           {
                PW_Is_Signed = false;
           }
           if (EventAttendeeLocal.Account_vod__c !=null)
           {
                Attendee_Type='Account'; 
           }
    
           PW_ReconciledTo='';
       if(string.isNotBlank(EventAttendeeLocal.Walk_In_Status_vod__c) ){
              Attendee_Type='Walk In'; 
           if(EventAttendeeLocal.Account_vod__c !=null)
           {
               Attendee_Type='Account'; 
               if(eventAttendeeOld != null)
               {
                   if(eventAttendeeOld.Account_vod__c == null)
                   {
                       PW_ReconciledTo='Account';
                   }
               }
           }
           if(EventAttendeeLocal.User_vod__c !=null)
           {
               Attendee_Type='User'; 
             //  Pw_Employee_number= mapOfUser.get(EventAttendeeLocal.User_vod__c); 
       Pw_Employee_number=EventAttendeeLocal.User_vod__r.EmployeeNumber;
               if(eventAttendeeOld != null)
               {
                   if(eventAttendeeOld.User_vod__c == null)
                   {
                       PW_ReconciledTo='User';
                     
                   }
               }
           }
           }else if(EventAttendeeLocal.EM_Event_Speaker_vod__c!=null) {
                Attendee_Type='Speaker'; 
                Speaker_Tp_Id = EventAttendeeLocal.EM_Event_Speaker_vod__r.Speaker_vod__r.PW_Speaker_ID__c;          
           } else if(Attendee_Type=='User' ){                
                // Pw_Employee_number= mapOfUser.get(EventAttendeeLocal.User_vod__c); 
        Pw_Employee_number=EventAttendeeLocal.User_vod__r.EmployeeNumber;        
           }           
   }      
}