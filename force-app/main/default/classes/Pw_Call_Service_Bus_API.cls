///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_Call_Service_Bus_API
///   Description:    This class will make a callout to the remote site to send the event json
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods which will add and delete team members
///   Date: 25-9-2016
///   Revision History:
///-----------------------------------------------------------------
public class Pw_Call_Service_Bus_API {
                
    /// <summary>
    ///     To fill necessary fields of the json
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    Public static void MakeCallout(Id  evtId)
    {                                    
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
        
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
           evtjsongen.Set_Json_After_For_Event(evtId);
           evtjsongen.EventType = custSetting.EventType__c;
           evtjsongen.EventDate = System.now();
           //evtjsongen.ModelId =(integer)custSetting.ModelId__c;
           evtjsongen.ModelId =evtId;
           evtjsongen.ModelName = custSetting.ModelName__c;
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           // evtjsongen.TenantID = UserInfo.getOrganizationId();
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug('Event jason : '+evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );                
    }    
    
    /// <summary>
    ///     To fill necessary fields of the json // OCT 2020
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    Public static void MakeCalloutEventUpdMsg(Id  eventId)
    {                                    
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
        
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
          if(evtjsongen.Set_Json_After_For_Event_UpdMsg(eventId)){
           evtjsongen.EventType = custSetting.EventTypeUpdate__c;
           evtjsongen.EventDate = System.now();
           //evtjsongen.ModelId =(integer)custSetting.ModelId__c;
           evtjsongen.ModelId =eventId;
           evtjsongen.ModelName = 'EventUpdate';//custSetting.AttendeeModelName__c;
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           // evtjsongen.TenantID = UserInfo.getOrganizationId();
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
          }else{
          
            System.debug('Event status other than Sub Con Com Clo'); 
          }                
    }    
    
    /// <summary>
    ///     To fill necessary fields of the json
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    Public static void MakeCalloutAddAttendee(Id  attendeeId)
    {                                    
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
        
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
          if(evtjsongen.Set_Json_After_For_Attendee(AttendeeId, null)){
           evtjsongen.EventType = custSetting.EventType__c;
           evtjsongen.EventDate = System.now();
           //evtjsongen.ModelId =(integer)custSetting.ModelId__c;
           evtjsongen.ModelId =AttendeeId;
           evtjsongen.ModelName = custSetting.AttendeeModelName__c;
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           // evtjsongen.TenantID = UserInfo.getOrganizationId();
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
          }else{
          
            System.debug('Event status other than Sub Con Com Clo'); 
          }                
    }    
     Public static void MakeCalloutAddAttendeeBulk(List<Id> AttenfeeIdList)
    {    

     List<Event_Attendee_vod__c> AttendeeList=[SELECT Id, Account_vod__c,Account_vod__r.PW_Client_ID__c,User_vod__r.EmployeeNumber,Attendee_Type_vod__c,EM_Event_Speaker_vod__r.Speaker_vod__r.PW_Speaker_ID__c,EM_Attendee_vod__r.Credentials_vod__c,
                                                   Status_vod__c,PW_State__c,First_Name_vod__c,PW_Salutation__c,Medical_Event_vod__r.EM_Event_vod__r.Status_vod__c,Medical_Event_vod__r.EM_Event_vod__c,Last_Name_vod__c,Meal_Opt_In_vod__c,Walk_In_Status_vod__c,
                                                   EM_Event_Speaker_vod__c,PW_Address_Type__c,Zip_vod__c,City_vod__c,PW_Attendee_Type__c,PW_Client_ID__c,PW_Office_Name__c,Credentials_vod__c,
                                                   PW_Participant_ID__c,PW_Event_Attendee_Row_ID__c, PW_Specialty__c,Address_Line_1_vod__c,Address_Line_2_vod__c,PW_SL_State__c,PW_SL__c,PW_NPI__c,PW_Position__c,Signature_vod__c, PW_Samples__c, PW_SKit__c, PW_SLotNo__c, Email_vod__c, Phone_vod__c, PW_MobNo__c, PW_Professional_Designation__c FROM Event_Attendee_vod__c 
                                                   where id in :AttenfeeIdList and Attendee_Type_vod__c not in ('Online Registrant', 'Contact') and EM_Event_Team_Member_vod__c=null]; // Added 'and EM_Event_Team_Member_vod__c=null' for ticket 68021
                           
    List<Pw_Event_Model_JsonGenerator> jsonAfterList=new List<Pw_Event_Model_JsonGenerator>();
        //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');                       
                           
      if(AttendeeList.size()>0)
        {
    
            Integer sec=0;
    for(Event_Attendee_vod__c eventAttendee :AttendeeList)
    {
                  sec+=20;
                  Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
                       if(evtjsongen.Set_Json_After_For_AttendeeBulk(eventAttendee, null)){
                        evtjsongen.EventType = custSetting.EventType__c;
                        //evtjsongen.EventDate = System.now().addSeconds(sec);
                        //evtjsongen.ModelId =(integer)custSetting.ModelId__c;
                        //evtjsongen.EventDate = System.now();
                        evtjsongen.EventDate = DateTime.newInstance(System.now().getTime()+sec);
                        evtjsongen.ModelId =eventAttendee.Id;
                        evtjsongen.ModelName = custSetting.AttendeeModelName__c;
                        evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
                        evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
                        evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
                        // evtjsongen.TenantID = UserInfo.getOrganizationId();
                        evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
                        evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
                        evtjsongen.UserFirstName = userinfo.getFirstName();
                        evtjsongen.UserLastName = userinfo.getLastName();
                        evtjsongen.UserEmail = userinfo.getUserEmail();
                                    
                        System.debug(evtjsongen.GetJSONString()); 
                         
                        //Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
            jsonAfterList.add(evtjsongen);
                       }else{
                       
                         System.debug('Event status other than Sub Con Com Clo'); 
                       } 
    }
            if(jsonAfterList.size() == 0)
    {
     System.debug('No attendee to be sent'); 
     return;
    }
    List<String> strjsonafterList=new List<String>();
    List<String> modalNameList =new List<String>();
    List<String> modalIdList=new List<String>();
/*    for( Pw_Event_Model_JsonGenerator  evtjsongen :jsonAfterList)
    {
            strjsonafterList.add(evtjsongen.GetJSONString());
            modalNameList.add(evtjsongen.ModelName);
            modalIdList.add(evtjsongen.ModelId);
    }
    Pw_Call_Service_Bus_API.callAPIBulk(strjsonafterList,modalNameList,modalIdList);
*/
        // We have decided to add 5 Attendee Per fututre call inspite of the fact that future call can make 100 callout
       // because the time out limit per transaction is 120 sec which is cumulative of all the callout make per transaction.
       // Hence we will get 24 sec timeout limit per callout.A trigger have at the most 200 record.Per transaction we can make 
       // 50 future calls(200/5=40).
       //  
        Integer count=1;
    for( Pw_Event_Model_JsonGenerator  evtjsongen :jsonAfterList)
    {
        
            strjsonafterList.add(evtjsongen.GetJSONString());
            modalNameList.add(evtjsongen.ModelName);
            modalIdList.add(evtjsongen.ModelId);
        if( math.mod(count, 5) == 0)
        {
        
          Pw_Call_Service_Bus_API.callAPIBulk(strjsonafterList,modalNameList,modalIdList);
          strjsonafterList=new List<String>();
          modalNameList =new List<String>();
          modalIdList=new List<String>();
        
        }
        count++;
    }
    
    if(strjsonafterList.size()>0)
    {
      Pw_Call_Service_Bus_API.callAPIBulk(strjsonafterList,modalNameList,modalIdList);
    }
    }
               
    }
    
    
      /// <summary>
    ///     To fill necessary fields of the json
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    Public static void MakeCalloutUpdateAttendee(Id  attendeeId, Event_Attendee_vod__c eventAttendeeOld)
    {                                    
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
        
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
               if(evtjsongen.Set_Json_After_For_Attendee(AttendeeId, eventAttendeeOld)){
           evtjsongen.EventType = custSetting.EventTypeUpdate__c;
           evtjsongen.EventDate = System.now();
          // evtjsongen.ModelId =(integer)custSetting.ModelId__c;
           evtjsongen.ModelId =AttendeeId;
           evtjsongen.ModelName = custSetting.AttendeeModelName__c;
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           // evtjsongen.TenantID = UserInfo.getOrganizationId();
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
            }else{
          
            System.debug('Event status other than Sub Con Com Clo'); 
          }          
    } 
    
      Public static void MakeCalloutUpdateAttendeeBulk(List<Id>  AttenfeeIdList,  Map<Id,Event_Attendee_vod__c>  eventAttendeeOldMap)
    {                                    
            List<Event_Attendee_vod__c> AttendeeList=[SELECT Id, Account_vod__c,Account_vod__r.PW_Client_ID__c,User_vod__r.EmployeeNumber,Attendee_Type_vod__c,EM_Event_Speaker_vod__r.Speaker_vod__r.PW_Speaker_ID__c,EM_Attendee_vod__r.Credentials_vod__c,
                                                   Status_vod__c,PW_State__c,First_Name_vod__c,PW_Salutation__c,Medical_Event_vod__r.EM_Event_vod__r.Status_vod__c,Medical_Event_vod__r.EM_Event_vod__c,Last_Name_vod__c,Meal_Opt_In_vod__c,Walk_In_Status_vod__c,
                                                   EM_Event_Speaker_vod__c,PW_Address_Type__c,Zip_vod__c,City_vod__c,PW_Attendee_Type__c,PW_Client_ID__c,PW_Office_Name__c,Credentials_vod__c,
                                                   PW_Participant_ID__c,PW_Event_Attendee_Row_ID__c, PW_Specialty__c,Address_Line_1_vod__c,Address_Line_2_vod__c,PW_SL_State__c,PW_SL__c,PW_NPI__c,PW_Position__c,Signature_vod__c, PW_Samples__c, PW_SKit__c, PW_SLotNo__c, Email_vod__c, Phone_vod__c, PW_MobNo__c, PW_Professional_Designation__c FROM Event_Attendee_vod__c 
                                                   where id in :AttenfeeIdList and Attendee_Type_vod__c not in ('Online Registrant', 'Contact') and EM_Event_Team_Member_vod__c=null]; // Added 'and EM_Event_Team_Member_vod__c=null' for ticket 68021
                           
    List<Pw_Event_Model_JsonGenerator> jsonAfterList=new List<Pw_Event_Model_JsonGenerator>();
        //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');                       
                           
      if(AttendeeList.size()>0)
        {
    Integer sec=0;
    for(Event_Attendee_vod__c eventAttendee :AttendeeList)
    {
                sec+=20;  
                  Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
                       if(evtjsongen.Set_Json_After_For_AttendeeBulk(eventAttendee, eventAttendeeOldMap.get(eventAttendee.id))){
                        evtjsongen.EventType = custSetting.EventTypeUpdate__c;
            evtjsongen.EventDate = DateTime.newInstance(System.now().getTime()+sec);
                        evtjsongen.ModelId =eventAttendee.Id;
                        evtjsongen.ModelName = custSetting.AttendeeModelName__c;
                        evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
                        evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
                        evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
                        // evtjsongen.TenantID = UserInfo.getOrganizationId();
                        evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
                        evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
                        evtjsongen.UserFirstName = userinfo.getFirstName();
                        evtjsongen.UserLastName = userinfo.getLastName();
                        evtjsongen.UserEmail = userinfo.getUserEmail();
                                    
                        System.debug(evtjsongen.GetJSONString()); 
                         
                        //Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
            jsonAfterList.add(evtjsongen);
                       }else{
                       
                         System.debug('Event status other than Sub Con Com Clo'+eventAttendee); 
                       } 
    }
        if(jsonAfterList.size() == 0)
    {
     System.debug('No attendee to be sent'); 
     return;
    }
    List<String> strjsonafterList=new List<String>();
    List<String> modalNameList =new List<String>();
    List<String> modalIdList=new List<String>();
    /*for( Pw_Event_Model_JsonGenerator  evtjsongen :jsonAfterList)
    {
            strjsonafterList.add(evtjsongen.GetJSONString());
            modalNameList.add(evtjsongen.ModelName);
            modalIdList.add(evtjsongen.ModelId);
    }
    Pw_Call_Service_Bus_API.callAPIBulk(strjsonafterList,modalNameList,modalIdList); */
       // We have decided to add 5 Attendee Per fututre call inspite of the fact that future call can make 100 callout
       // because the time out limit per transaction is 120 sec which is cumulative of all the callout make per transaction.
       // Hence we will get 24 sec timeout limit per callout.A trigger have at the most 200 record.Per transaction we can make 
       // 50 future calls(200/5=40).
       //  
               Integer count=1;
    for( Pw_Event_Model_JsonGenerator  evtjsongen :jsonAfterList)
    {
        
            strjsonafterList.add(evtjsongen.GetJSONString());
            modalNameList.add(evtjsongen.ModelName);
            modalIdList.add(evtjsongen.ModelId);
        if( math.mod(count, 5) == 0)
        {
        
          Pw_Call_Service_Bus_API.callAPIBulk(strjsonafterList,modalNameList,modalIdList);
          strjsonafterList=new List<String>();
          modalNameList =new List<String>();
          modalIdList=new List<String>();
        
        }
        count++;
    }
    
    if(strjsonafterList.size()>0)
    {
      Pw_Call_Service_Bus_API.callAPIBulk(strjsonafterList,modalNameList,modalIdList);
    }
    }
    } 
     /// <summary>
    ///     To fill necessary fields of the json
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    Public static void MakeCalloutDeleteAttendee(Id  attendeeId)
    {                                    
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
        
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
               if(evtjsongen.Set_Json_After_For_Attendee(AttendeeId, null)){
           evtjsongen.EventType = custSetting.EventTypeDelete__c;
           evtjsongen.EventDate = System.now();
           //evtjsongen.ModelId =(integer)custSetting.ModelId__c;
           evtjsongen.ModelId =AttendeeId;
           evtjsongen.ModelName = custSetting.AttendeeModelName__c;
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           // evtjsongen.TenantID = UserInfo.getOrganizationId();
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
            }else{
          
            System.debug('Event status other than Sub Con Com Clo'); 
          }                
    }    
     Public static void MakeCalloutDeleteAttendeeBulk(List<Id> AttenfeeIdList)
    {    

     List<Event_Attendee_vod__c> AttendeeList=[SELECT Id, Account_vod__c,Account_vod__r.PW_Client_ID__c,User_vod__r.EmployeeNumber,Attendee_Type_vod__c,EM_Event_Speaker_vod__r.Speaker_vod__r.PW_Speaker_ID__c,EM_Attendee_vod__r.Credentials_vod__c,
                                                   Status_vod__c,PW_State__c,First_Name_vod__c,PW_Salutation__c,Medical_Event_vod__r.EM_Event_vod__r.Status_vod__c,Medical_Event_vod__r.EM_Event_vod__c,Last_Name_vod__c,Meal_Opt_In_vod__c,Walk_In_Status_vod__c,
                                                   EM_Event_Speaker_vod__c,PW_Address_Type__c,Zip_vod__c,City_vod__c,PW_Attendee_Type__c,PW_Client_ID__c,PW_Office_Name__c,Credentials_vod__c,
                                                   PW_Participant_ID__c,PW_Event_Attendee_Row_ID__c, PW_Specialty__c,Address_Line_1_vod__c,Address_Line_2_vod__c,PW_SL_State__c,PW_SL__c,PW_NPI__c,PW_Position__c,Signature_vod__c, PW_Samples__c, PW_SKit__c, PW_SLotNo__c, Email_vod__c, Phone_vod__c, PW_MobNo__c, PW_Professional_Designation__c FROM Event_Attendee_vod__c 
                                                   where id in :AttenfeeIdList and Attendee_Type_vod__c not in ('Online Registrant', 'Contact') and EM_Event_Team_Member_vod__c=null]; // Added 'and EM_Event_Team_Member_vod__c=null' for ticket 68021
                           
    List<Pw_Event_Model_JsonGenerator> jsonAfterList=new List<Pw_Event_Model_JsonGenerator>();
        //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');                       
                           
      if(AttendeeList.size()>0)
        {
    Integer sec=0;
    for(Event_Attendee_vod__c eventAttendee :AttendeeList)
    {
                     sec+=20;
                  Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
                       if(evtjsongen.Set_Json_After_For_AttendeeBulk(eventAttendee, null)){
                        evtjsongen.EventType = custSetting.EventTypeDelete__c;
                        evtjsongen.EventDate = DateTime.newInstance(System.now().getTime()+sec);
                        //evtjsongen.EventDate = System.now();
                        //evtjsongen.EventDate = System.now();
                        //evtjsongen.ModelId =(integer)custSetting.ModelId__c;
                        evtjsongen.ModelId =eventAttendee.Id;
                        evtjsongen.ModelName = custSetting.AttendeeModelName__c;
                        evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
                        evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
                        evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
                        // evtjsongen.TenantID = UserInfo.getOrganizationId();
                        evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
                        evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
                        evtjsongen.UserFirstName = userinfo.getFirstName();
                        evtjsongen.UserLastName = userinfo.getLastName();
                        evtjsongen.UserEmail = userinfo.getUserEmail();
                                    
                        System.debug(evtjsongen.GetJSONString()); 
                         
                        //Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
            jsonAfterList.add(evtjsongen);
                       }else{
                       
                         System.debug('Event status other than Sub Con Com Clo'); 
                       } 
    }
    if(jsonAfterList.size() == 0)
    {
     System.debug('No attendee to be sent'); 
     return;
    }
    List<String> strjsonafterList=new List<String>();
    List<String> modalNameList =new List<String>();
    List<String> modalIdList=new List<String>();
    /* for( Pw_Event_Model_JsonGenerator  evtjsongen :jsonAfterList)
    {
            strjsonafterList.add(evtjsongen.GetJSONString());
            modalNameList.add(evtjsongen.ModelName);
            modalIdList.add(evtjsongen.ModelId);
    }
    Pw_Call_Service_Bus_API.callAPIBulk(strjsonafterList,modalNameList,modalIdList); */
       // We have decided to add 5 Attendee Per fututre call inspite of the fact that future call can make 100 callout
       // because the time out limit per transaction is 120 sec which is cumulative of all the callout make per transaction.
       // Hence we will get 24 sec timeout limit per callout.A trigger have at the most 200 record.Per transaction we can make 
       // 50 future calls(200/5=40).
       //  
               Integer count=1;
    for( Pw_Event_Model_JsonGenerator  evtjsongen :jsonAfterList)
    {
        
            strjsonafterList.add(evtjsongen.GetJSONString());
            modalNameList.add(evtjsongen.ModelName);
            modalIdList.add(evtjsongen.ModelId);
        if( math.mod(count, 5) == 0)
        {
        
          Pw_Call_Service_Bus_API.callAPIBulk(strjsonafterList,modalNameList,modalIdList);
          strjsonafterList=new List<String>();
          modalNameList =new List<String>();
          modalIdList=new List<String>();
        
        }
        count++;
    }
    
    if(strjsonafterList.size()>0)
    {
      Pw_Call_Service_Bus_API.callAPIBulk(strjsonafterList,modalNameList,modalIdList);
    }
    }
               
    }
    /// <summary>
    ///     To fill necessary fields of the json
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    Public static void MakeCalloutAddAttachment(Id  atachmentId, id parentId,string firstname,string lastname,string employeeNumber)
    {       
           system.debug('Event Attachment ID in call service :'+ atachmentId);
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
        
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
           if(evtjsongen.Set_Json_After_For_Attachment(atachmentId, parentId,firstname,lastname,employeeNumber)){
           evtjsongen.EventType = custSetting.EventType__c;
           evtjsongen.EventDate = System.now();
           //evtjsongen.ModelId =(integer)custSetting.ModelId__c;
           evtjsongen.ModelId =atachmentId;
           evtjsongen.ModelName = 'Event Attachment';
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           // evtjsongen.TenantID = UserInfo.getOrganizationId();
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
          }else{
          
            System.debug('Event status other than Sub Con Com Clo'); 
          }                
    }
    
    /// <summary>
    ///     To fill necessary fields of the json
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    Public static void MakeCalloutUpdateAttachment(Id  atachmentId, id parentId,string firstname,string lastname,string employeeNumber)
    {       
           system.debug('Event Attachment ID in call service :'+ atachmentId);
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
        
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
           if(evtjsongen.Set_Json_After_For_Attachment(atachmentId, parentId,firstname,lastname,employeeNumber)){
           evtjsongen.EventType = custSetting.EventTypeUpdate__c;
           evtjsongen.EventDate = System.now();
           //evtjsongen.ModelId =(integer)custSetting.ModelId__c;
           evtjsongen.ModelId =atachmentId;
           evtjsongen.ModelName = 'Event Attachment';
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           // evtjsongen.TenantID = UserInfo.getOrganizationId();
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
          }else{
          
            System.debug('Event status other than Sub Con Com Clo'); 
          }                
    }
    
    /// <summary>
    ///     To fill necessary fields of the json
    /// </summary>
    /// <param name="eventId">
    ///     'eventId' contains event id
    /// </param> 
    Public static void MakeCalloutDeleteAttachment(Id  atachmentId, id parentId,string firstname,string lastname,string employeeNumber)
    {       
           system.debug('Event Attachment ID in call service :'+ atachmentId);
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
        
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
          if(evtjsongen.Set_Json_After_For_Attachment(atachmentId, parentId,firstname,lastname,employeeNumber)){
           evtjsongen.EventType = custSetting.EventTypeDelete__c;
           evtjsongen.EventDate = System.now();
           //evtjsongen.ModelId =(integer)custSetting.ModelId__c;
           evtjsongen.ModelId =atachmentId;
           evtjsongen.ModelName = 'Event Attachment';
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           // evtjsongen.TenantID = UserInfo.getOrganizationId();
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
          }else{
          
            System.debug('Event status other than Sub Con Com Clo'); 
          }                
    }
    /// <summary>
    ///     To fill message in the Json
    /// </summary>

     Public static void MakeCalloutDeleteTeamMember(Id  teamMemberId , EM_Event_Team_Member_vod__c oldEventTeamMember)
        {                                    
               //Custom setting call            
               Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
            
               Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
              if(evtjsongen.Set_Json_After_For_TeamMember(teamMemberId,oldEventTeamMember)){                                 
               evtjsongen.EventType = custSetting.EventTypeDelete__c;                          //----------------Change
               evtjsongen.EventDate = System.now();
             //  evtjsongen.ModelId =(integer)custSetting.ModelId__c;
               evtjsongen.ModelId =teamMemberId;
               evtjsongen.ModelName = 'EventTeamMember';                                     //custSetting.AttendeeModelName__c;
               evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
               evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
               evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
               // evtjsongen.TenantID = UserInfo.getOrganizationId();
               evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
               evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
               evtjsongen.UserFirstName = userinfo.getFirstName();
               evtjsongen.UserLastName = userinfo.getLastName();
               evtjsongen.UserEmail = userinfo.getUserEmail();
                           
               System.debug(evtjsongen.GetJSONString()); 
                
               Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
              }else{          
                System.debug('Event status doesnot support sending event team member'); 
              }                
        }  
    Public static void MakeCalloutInsertTeamMember(Id  teamMemberId , EM_Event_Team_Member_vod__c eventTeamMember)
        {                                    
               //Custom setting call            
               Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
            
               Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
              if(evtjsongen.Set_Json_After_For_TeamMember(teamMemberId,eventTeamMember)){                                 
               evtjsongen.EventType = custSetting.EventType__c;                          //----------------Change
               evtjsongen.EventDate = System.now();
             //  evtjsongen.ModelId =(integer)custSetting.ModelId__c;
               evtjsongen.ModelId =teamMemberId;
               evtjsongen.ModelName = 'EventTeamMember';                                     //custSetting.AttendeeModelName__c;
               evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
               evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
               evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
               // evtjsongen.TenantID = UserInfo.getOrganizationId();
               evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
               evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
               evtjsongen.UserFirstName = userinfo.getFirstName();
               evtjsongen.UserLastName = userinfo.getLastName();
               evtjsongen.UserEmail = userinfo.getUserEmail();
                           
               System.debug(evtjsongen.GetJSONString()); 
                
               Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
              }else{          
                System.debug('Event status doesnot support sending event team member'); 
              }                
        }  
     /// <summary>
    ///     To fill message in the Json
    /// </summary>
         Public static void MakeCalloutEventStatus(id event)
             {                                    
               //Custom setting call    
                   System.Debug('InSide Pw Call service MakeCalloutEventStatus ::'+event);        
                 Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
                 
                 Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
                 if(evtjsongen.Set_Json_After_For_Event_Staus(event)){  
                       
                     evtjsongen.EventType = custSetting.EventTypeUpdate__c;
                     evtjsongen.EventDate = System.now();
                     //  evtjsongen.ModelId =(integer)custSetting.ModelId__c;
                     evtjsongen.ModelId =event;
                     evtjsongen.ModelName = 'EventStatus';                                     //custSetting.AttendeeModelName__c;
                     evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
                     evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
                     evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
                     // evtjsongen.TenantID = UserInfo.getOrganizationId();
                     evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
                     evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
                     evtjsongen.UserFirstName = userinfo.getFirstName();
                     evtjsongen.UserLastName = userinfo.getLastName();
                     evtjsongen.UserEmail = userinfo.getUserEmail();
                     
                     System.debug(evtjsongen.GetJSONString()); 
                      System.Debug(' MakeCalloutEventStatus() End::Pw_Call_Service_Bus_API.callAPI ::'+event);
                     Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
                 }else{          
                     System.debug('Some Error in creating Json After For event Status'); 
                 }                
        }  
    /// <summary>
    ///     To fill message in the Json
    /// </summary> 
    public static void MakeCalloutUpdateSpeakerStatus(Id  speakerId ,String Status ,String  PW_Speaker_ID, String  LastModifiedDate)
        {                                    
               //Custom setting call            
               Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
            
               Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
              if(evtjsongen.Set_Json_After_For_UpdateSpeakerStatus(Status,PW_Speaker_ID,speakerId, LastModifiedDate)){                             
               evtjsongen.EventType = custSetting.EventTypeUpdate__c;    //----EventUpdateType
               evtjsongen.EventDate = System.now();
             //  evtjsongen.ModelId =(integer)custSetting.ModelId__c;
               evtjsongen.ModelId =PW_Speaker_ID;//speakerId;
               evtjsongen.ModelName = 'SpeakerStatus';                                     //custSetting.AttendeeModelName__c;
               evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
               evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
               evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
               // evtjsongen.TenantID = UserInfo.getOrganizationId();
               evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
               evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
               evtjsongen.UserFirstName = userinfo.getFirstName();
               evtjsongen.UserLastName = userinfo.getLastName();
               evtjsongen.UserEmail = userinfo.getUserEmail();
                           
               System.debug(evtjsongen.GetJSONString()); 
                
               Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,speakerId );
              }else{          
                System.debug('Error in sending Speaker Status.'); 
              }                
        } 
    /// <summary>
    ///     To fill message in the Json
    /// </summary>
   public static void MakeCalloutInsertSpeakerQualification(Id speakerQualificationId,String triggerEvent)
        {                                    
               //Custom setting call            
               Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
            
               Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
         PW_Send_Speaker_Qualification_Model  speakerQualification=new PW_Send_Speaker_Qualification_Model();
         
            //  if(evtjsongen.Set_Json_After_For_InsertUpdateDeleteSpeakerQualification(speakerQualificationId,triggerEvent)){    
             if(speakerQualification.initializeSpeakerQualification(speakerQualificationId,triggerEvent) ){ 
          if(string.IsEmpty(speakerQualification.Tp_Speaker_ID))
          {
            System.debug('Tp_Speaker_ID is Empty For :-.'+speakerQualification); 
            return ;
          }
       evtjsongen.Set_Json_After_For_InsertUpdateDeleteSpeakerQualification(speakerQualification);
               evtjsongen.EventType = custSetting.EventType__c;    //----EventUpdateType
               evtjsongen.EventDate = System.now();
             //  evtjsongen.ModelId =(integer)custSetting.ModelId__c;
               evtjsongen.ModelId =   speakerQualification.Tp_Speaker_ID;//speakerQualificationId;
               evtjsongen.ModelName = 'SpeakerTopicTraining';                                     //custSetting.AttendeeModelName__c;
               evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
               evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
               evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
               // evtjsongen.TenantID = UserInfo.getOrganizationId();
               evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
               evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
               evtjsongen.UserFirstName = userinfo.getFirstName();
               evtjsongen.UserLastName = userinfo.getLastName();
               evtjsongen.UserEmail = userinfo.getUserEmail();
                           
               System.debug(evtjsongen.GetJSONString()); 
                
               Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,speakerQualificationId );
              }else{          
                System.debug('Error in sending Qualification Insert.'); 
              }                
        } 

 public static void MakeCalloutUpdateSpeakerQualification(Id speakerQualificationId,String triggerEvent)
        {                                    
               //Custom setting call            
               Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
            
               Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
          PW_Send_Speaker_Qualification_Model  speakerQualification=new PW_Send_Speaker_Qualification_Model();
        
             // if(evtjsongen.Set_Json_After_For_InsertUpdateDeleteSpeakerQualification(speakerQualificationId,triggerEvent)){ 
          if(speakerQualification.initializeSpeakerQualification(speakerQualificationId,triggerEvent) ){ 
          if(string.IsEmpty(speakerQualification.Tp_Speaker_ID))
          {
            System.debug('Tp_Speaker_ID is Empty For :-.'+speakerQualification); 
            return ;
          }
         evtjsongen.Set_Json_After_For_InsertUpdateDeleteSpeakerQualification(speakerQualification);
               evtjsongen.EventType = custSetting.EventTypeUpdate__c;    //----EventUpdateType
               evtjsongen.EventDate = System.now();
             //  evtjsongen.ModelId =(integer)custSetting.ModelId__c;
               evtjsongen.ModelId =   speakerQualification.Tp_Speaker_ID;//speakerQualificationId;
               evtjsongen.ModelName = 'SpeakerTopicTraining';                                     //custSetting.AttendeeModelName__c;
               evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
               evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
               evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
               // evtjsongen.TenantID = UserInfo.getOrganizationId();
               evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
               evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
               evtjsongen.UserFirstName = userinfo.getFirstName();
               evtjsongen.UserLastName = userinfo.getLastName();
               evtjsongen.UserEmail = userinfo.getUserEmail();
                           
               System.debug(evtjsongen.GetJSONString()); 
                
               Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,speakerQualificationId );
              }else{          
                System.debug('Error in sending Speaker Qualification Update.'); 
              }                
        } 

 public static void MakeCalloutDeleteSpeakerQualification(Id speakerQualificationId,String triggerEvent)
        {                                    
               //Custom setting call            
               Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
            
               Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
         PW_Send_Speaker_Qualification_Model  speakerQualification=new PW_Send_Speaker_Qualification_Model();
         
             // if(evtjsongen.Set_Json_After_For_InsertUpdateDeleteSpeakerQualification(speakerQualificationId,triggerEvent)){ 
        if(speakerQualification.initializeSpeakerQualification(speakerQualificationId,triggerEvent) ){ 
          if(string.IsEmpty(speakerQualification.Tp_Speaker_ID))
          {
            System.debug('Tp_Speaker_ID is Empty For :-.'+speakerQualification); 
            return ;
          }
         evtjsongen.Set_Json_After_For_InsertUpdateDeleteSpeakerQualification(speakerQualification);       
               evtjsongen.EventType = custSetting.EventTypeDelete__c;    //----EventUpdateType
               evtjsongen.EventDate = System.now();
             //  evtjsongen.ModelId =(integer)custSetting.ModelId__c;
               evtjsongen.ModelId =   speakerQualification.Tp_Speaker_ID;//speakerQualificationId;
               evtjsongen.ModelName = 'SpeakerTopicTraining';                                     //custSetting.AttendeeModelName__c;
               evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
               evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
               evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
               // evtjsongen.TenantID = UserInfo.getOrganizationId();
               evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
               evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
               evtjsongen.UserFirstName = userinfo.getFirstName();
               evtjsongen.UserLastName = userinfo.getLastName();
               evtjsongen.UserEmail = userinfo.getUserEmail();
                           
               System.debug(evtjsongen.GetJSONString()); 
                
               Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,speakerQualificationId );
              }else{          
                System.debug('Error in sending Speaker Qualification Delete.'); 
              }                
        } 
    ///// <summary>
    ///     To fill message in the Json
    /// </summary>
    Public static void MakeCallOutSuccessFailureMessage(Integer messageId,string message,string status,Id eventId)
    {                                    
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
           system.debug('Message parameters in Bus Api'+messageId+' '+message+' '+status);
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
           evtjsongen.Set_Json_After_For_Message(messageId,message,status);
           evtjsongen.EventType = custSetting.EventType__c;
           evtjsongen.EventDate = System.now();
           evtjsongen.ModelId = eventId;
           evtjsongen.ModelName = 'EventFinancialsNotification';
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
    }  
    
    /// <summary>
    ///     To fill message in the Json
    /// </summary>     
    Public static void MakeCallOutSuccessFailureMessageForEvent(Integer messageId,string message,string status,Id eventId)
    {                                    
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
           system.debug('Message parameters in Bus Api'+messageId+' '+message+' '+status);
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
           evtjsongen.Set_Json_After_For_Message(messageId,message,status);
           evtjsongen.EventType = custSetting.EventType__c;
           evtjsongen.EventDate = System.now();
           evtjsongen.ModelId = eventId;
           evtjsongen.ModelName = 'EventNotification';
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );
    }
    
    /// <summary>
    ///     To fill message in the Json
    /// </summary>     
    Public static void MakeCallOutSuccessFailureMessageForEstimates(Integer messageId,string message,string status,Id eventId)
    {                                    
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
           system.debug('Message parameters in Bus Api'+messageId+' '+message+' '+status);
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
           evtjsongen.Set_Json_After_For_Message(messageId,message,status);
           evtjsongen.EventType = custSetting.EventType__c;
           evtjsongen.EventDate = System.now();
           evtjsongen.ModelId = eventId;
           evtjsongen.ModelName = 'FinanceEstimatesNotification';
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );                
    }
    
    /// <summary>
    ///     To fill message in the Json
    /// </summary>     
    Public static void MakeCallOutSuccessFailureMessageForAttendee(Integer messageId,string message,string status,Id eventId,list<PW_Attendee_ID_Map_Model> lstofAttendeeVeevaAndRowIds)
    {                                    
           //Custom setting call            
           Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');  
           system.debug('Message parameters in Bus Api'+messageId+' '+message+' '+status);
           Pw_Event_Model_JsonGenerator evtjsongen = new Pw_Event_Model_JsonGenerator();
           evtjsongen.Set_Json_After_For_MessageAttendee(messageId,message,status,lstofAttendeeVeevaAndRowIds);
           evtjsongen.EventType = custSetting.EventType__c;
           evtjsongen.EventDate = System.now();
           evtjsongen.ModelId = eventId;
           evtjsongen.ModelName = 'AttendeeNotification';
           evtjsongen.ApplicationId = (integer)custSetting.ApplicationId__c;
           evtjsongen.ApplicationTitle = custSetting.ApplicationTitle__c ;
           evtjsongen.ApplicationVersion = custSetting.ApplicationVersion__c;
           evtjsongen.TenantID =custSetting.TenantID__c;//given by Hari subjected to changes
           evtjsongen.UserId  =(integer)custSetting.User_ID__c ; 
           evtjsongen.UserFirstName = userinfo.getFirstName();
           evtjsongen.UserLastName = userinfo.getLastName();
           evtjsongen.UserEmail = userinfo.getUserEmail();
                       
           System.debug(evtjsongen.GetJSONString()); 
            
           Pw_Call_Service_Bus_API.callAPI(evtjsongen.GetJSONString(),evtjsongen.ModelName,evtjsongen.ModelId );                
    }
    
    /// <summary>
    ///     To make callouts
    /// </summary>
    /// <param name="jsonbody">
    ///     'jsonbody' contains event json
    /// </param> 
    @future(callout=true) Public static void callAPI(string jsonbody,string modalName, string modalId)        {
         try
         {
            integer noofcalloutcount=0;
            integer maxcalloutcount;
            integer callinseconds;
            integer timeout;   
            Http http = new Http();
            HttpResponse resp = new HttpResponse();
            HttpRequest req = new HttpRequest();
            //req.setEndPoint('http://veeva-events-api.azurewebsites.net/api/Events');
            Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');
            maxcalloutcount = calloutsettings.Max_Callout__c.intValue();
            callinseconds = calloutsettings.Seconds_Gap_Between_Callout__c.intValue();
            timeout = calloutsettings.PW_Timeout_Milliseconds__c.intValue();
            
            PW_Veeva_Event_Url__c veevaeVentUrl= PW_Veeva_Event_Url__c.getValues('veeva_url');
            Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');
            system.debug('veevaeVentUrl:::'+veevaeVentUrl);
            system.debug('custSetting:::'+custSetting);
            system.debug('JSON :::'+jsonbody);
            if( veevaeVentUrl != null)
            {               
                req.setEndPoint(veevaeVentUrl.URL__c);
            }
            req.setTimeout(timeout);
            req.setHeader('content-type', 'application/json');
            req.setHeader('Authorization', 'Basic '+custSetting.Token__c);            
            req.setCompressed(false);
            req.setMethod('POST');
            req.setBody(jsonbody);
            
            
            try
            {
                if(!Test.isRunningTest())
                {
                    System.debug('before request send');
                  //  MockTimeOut();
                    resp = http.send(req);
                    System.debug('after request send');
                    System.debug('Status :'+resp.getStatusCode());
                    if(resp.getStatusCode()!=201)
                    {  
                        System.debug('modalName :'+modalName);
                        string errmsg = 'Unable to send payload failed with status :' + resp.getStatusCode()+' '+resp.getStatus();                        
                        PW_Log_Into_CustomLogger.Log('',errmsg, Pw_Logger_Constants.CALLOUT_INCORRECT_STATUS_CODE,jsonbody, noofcalloutcount, UserInfo.getUserName(), modalId, modalName);
                        
                        if(modalName== 'Event')
                         {
                              System.debug('Send email method start Event');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmail(modalId,' <b>'+ errmsg +'</b>');
                         }
                         else if(modalName== 'Attendee')
                         {
                             System.debug('Send email method start Attendee');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttendee(modalId,' <b>'+ errmsg +'</b>');
                         }
                         else if(modalName == 'Event Attachment')
                         {
                             System.debug('Send email method start Attachment');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttachment(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'EventTeamMember')
                         {
                             System.debug('Send email method start EventTeamMember');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventTeamMember(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'EventStatus')
                         {
                             System.debug('Send email method start EventStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventStatus(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'SpeakerStatus')
                         {
                             System.debug('Send email method start SpeakerStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerStatus(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'SpeakerTopicTraining')
                         {
                             System.debug('Send email method start SpeakerTopicTraining');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerQualification(modalId,' <b>'+ errmsg +'</b>');
                         
                         }
                         else if(modalName == 'EventUpdate') // OCT 2020
                         {
                             System.debug('Send email method start EventUpdMsg');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventUpdMsg(modalId,' <b>'+ errmsg +'</b>');
                         
                         }
                    }
                }
                
                System.debug('Status :'+resp.getStatus());
                System.debug('Status Code :' + resp.getStatusCode()); 
                
            }
            catch(System.CalloutException e)
            {
                System.debug('Callout error: '+ e);
                System.debug(resp.toString());
                 noofcalloutcount++;
                     if(noofcalloutcount<=maxcalloutcount)
                    {
                        PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.CALLOUT_RETRY_ATTEMPT,jsonbody, noofcalloutcount, UserInfo.getUserName(), modalId, modalName);
                        
                        DateTime currentDateTime=System.now().addSeconds(callinseconds);                            
                        String nextScheduleTime=String.valueof(currentDateTime.second()) +' '+String.valueof(currentDateTime.minute())+' '
                                        +String.valueof(currentDateTime.hour())+' '+String.valueof(currentDateTime.day())+' '
                                        +String.valueof(currentDateTime.month())+' ? '+String.valueof(currentDateTime.Year());
                
                        PW_CalloutRetryScheduler Job = new PW_CalloutRetryScheduler ();
                        Job.noofcalloutcount=noofcalloutcount;
                        Job.maxcalloutcount=maxcalloutcount;
                        Job.jsonbody=jsonbody;
                        Job.modalName= modalName;
                        Job.modalId = modalId;
                        Job.callinseconds = callinseconds;
                        system.schedule('Scheduled at '+Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'), nextScheduleTime, Job );
                      }
                      else
                      {
                          //Send email
                          PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.CALLOUT_FINAL_FAIL,jsonbody, noofcalloutcount-1, UserInfo.getUserName(), modalId, modalName);
                          
                          if(modalName== 'Event')
                          {
                              system.debug('call api callout max fail email start');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmail(modalId,' <b>' +e.getMessage() + '</b>');
                          }
                          else if(modalName== 'Attendee')
                         {
                             System.debug('Send email method start Attendee');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttendee(modalId,' <b>'+ e.getMessage() +'</b>');
                         }
                         else if(modalName == 'Event Attachment')
                         {
                             System.debug('Send email method start Attachment');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttachment(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'EventTeamMember')
                         {
                             System.debug('Send email method start EventTeamMember');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventTeamMember(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'EventStatus')
                         {
                             System.debug('Send email method start EventStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerStatus')
                         {
                             System.debug('Send email method start SpeakerStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerTopicTraining')
                         {
                             System.debug('Send email method start SpeakerTopicTraining');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerQualification(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }
                         else if(modalName == 'EventUpdate') // OCT 2020
                         {
                             System.debug('Send email method start EventUpdMsg');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventUpdMsg(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }
                          
                      }
    
                    //throw new dmlexception();
                    
               }
            }
            catch(Exception e)
            {
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.CALLOUT_GENERAL_EXCEPTION, jsonbody, 0, UserInfo.getUserName(), modalId, modalName);
                 //Callout general exception
                 if(modalName== 'Event')
                 {
                     system.debug('call api general exception fail email start');
                      Pw_Send_Email_On_CalloutFailure.CreateAndSendEmail(modalId,e.getMessage());
                 }
                 else if(modalName== 'Attendee')
                 {
                             System.debug('Send email method start Attendee');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttendee(modalId,' <b>'+ e.getMessage()+'</b>');
                 }
                 else if(modalName == 'Event Attachment')
                 {
                             System.debug('Send email method start Attachment');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttachment(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                 }else if(modalName == 'EventTeamMember')
                         {
                             System.debug('Send email method start EventTeamMember');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventTeamMember(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'EventStatus')
                         {
                             System.debug('Send email method start EventStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerStatus')
                         {
                             System.debug('Send email method start SpeakerStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerTopicTraining')
                         {
                             System.debug('Send email method start SpeakerTopicTraining');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerQualification(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         } else if(modalName == 'EventUpdate') // OCT 2020
                         {
                             System.debug('Send email method start EventUpdMsg');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventUpdMsg(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }
            }     
                    
                            
    }
          /// <summary>
    ///     To make callouts
    /// </summary>
    /// <param name="jsonbody">
    ///     'jsonbody' contains event json
    /// </param> 
    @future(callout=true) Public static void callAPIBulk(List<String> strjsonafterList,List<String> modalNameList,List<String> modalIdList)        {
     Integer i=0;   
for(  String  jsonbody :strjsonafterList)
{
    string modalName =modalNameList[i];
    string modalId =modalIdList[i];
    i++;
    try
         {
            integer noofcalloutcount=0;
            integer maxcalloutcount;
            integer callinseconds;
            integer timeout;   
            Http http = new Http();
            HttpResponse resp = new HttpResponse();
            HttpRequest req = new HttpRequest();
            //req.setEndPoint('http://veeva-events-api.azurewebsites.net/api/Events');
            Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');
            maxcalloutcount = calloutsettings.Max_Callout__c.intValue();
            callinseconds = calloutsettings.Seconds_Gap_Between_Callout__c.intValue();
            timeout = calloutsettings.PW_Timeout_Milliseconds__c.intValue();
            
            PW_Veeva_Event_Url__c veevaeVentUrl= PW_Veeva_Event_Url__c.getValues('veeva_url');
            Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');
            system.debug('veevaeVentUrl:::'+veevaeVentUrl);
            system.debug('custSetting:::'+custSetting);
            system.debug('JSON :::'+jsonbody);
            if( veevaeVentUrl != null)
            {               
                req.setEndPoint(veevaeVentUrl.URL__c);
            }
            req.setTimeout(timeout);
            req.setHeader('content-type', 'application/json');
            req.setHeader('Authorization', 'Basic '+custSetting.Token__c);            
            req.setCompressed(false);
            req.setMethod('POST');
            req.setBody(jsonbody);
            
            
            try
            {
                if(!Test.isRunningTest())
                {
                    System.debug('before request send');
                  //  MockTimeOut();
                    resp = http.send(req);
                    System.debug('after request send');
                    System.debug('Status :'+resp.getStatusCode());
                    if(resp.getStatusCode()!=201)
                    {  
                        System.debug('modalName :'+modalName);
                        string errmsg = 'Unable to send payload failed with status :' + resp.getStatusCode()+' '+resp.getStatus();                        
                        PW_Log_Into_CustomLogger.Log('',errmsg, Pw_Logger_Constants.CALLOUT_INCORRECT_STATUS_CODE,jsonbody, noofcalloutcount, UserInfo.getUserName(), modalId, modalName);
                        
                        if(modalName== 'Event')
                         {
                              System.debug('Send email method start Event');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmail(modalId,' <b>'+ errmsg +'</b>');
                         }
                         else if(modalName== 'Attendee')
                         {
                             System.debug('Send email method start Attendee');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttendee(modalId,' <b>'+ errmsg +'</b>');
                         }
                         else if(modalName == 'Event Attachment')
                         {
                             System.debug('Send email method start Attachment');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttachment(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'EventTeamMember')
                         {
                             System.debug('Send email method start EventTeamMember');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventTeamMember(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'EventStatus')
                         {
                             System.debug('Send email method start EventStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventStatus(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'SpeakerStatus')
                         {
                             System.debug('Send email method start SpeakerStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerStatus(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'SpeakerTopicTraining')
                         {
                             System.debug('Send email method start SpeakerTopicTraining');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerQualification(modalId,' <b>'+ errmsg +'</b>');
                         
                         } else if(modalName == 'EventUpdate') // OCT 2020
                         {
                             System.debug('Send email method start EventUpdMsg');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventUpdMsg(modalId,' <b>'+ errmsg +'</b>');
                         
                         }
                    }
                }
                
                System.debug('Status :'+resp.getStatus());
                System.debug('Status Code :' + resp.getStatusCode()); 
                
            }
            catch(System.CalloutException e)
            {
                System.debug('Callout error: '+ e);
                System.debug(resp.toString());
                 noofcalloutcount++;
                     if(noofcalloutcount<=maxcalloutcount)
                    {
                        PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.CALLOUT_RETRY_ATTEMPT,jsonbody, noofcalloutcount, UserInfo.getUserName(), modalId, modalName);
                        
                        DateTime currentDateTime=System.now().addSeconds(callinseconds);                            
                        String nextScheduleTime=String.valueof(currentDateTime.second()) +' '+String.valueof(currentDateTime.minute())+' '
                                        +String.valueof(currentDateTime.hour())+' '+String.valueof(currentDateTime.day())+' '
                                        +String.valueof(currentDateTime.month())+' ? '+String.valueof(currentDateTime.Year());
                
                        PW_CalloutRetryScheduler Job = new PW_CalloutRetryScheduler ();
                        Job.noofcalloutcount=noofcalloutcount;
                        Job.maxcalloutcount=maxcalloutcount;
                        Job.jsonbody=jsonbody;
                        Job.modalName= modalName;
                        Job.modalId = modalId;
                        Job.callinseconds = callinseconds;
                        system.schedule('Scheduled at '+Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'), nextScheduleTime, Job );
                      }
                      else
                      {
                          //Send email
                          PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.CALLOUT_FINAL_FAIL,jsonbody, noofcalloutcount-1, UserInfo.getUserName(), modalId, modalName);
                          
                          if(modalName== 'Event')
                          {
                              system.debug('call api callout max fail email start');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmail(modalId,' <b>' +e.getMessage() + '</b>');
                          }
                          else if(modalName== 'Attendee')
                         {
                             System.debug('Send email method start Attendee');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttendee(modalId,' <b>'+ e.getMessage() +'</b>');
                         }
                         else if(modalName == 'Event Attachment')
                         {
                             System.debug('Send email method start Attachment');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttachment(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'EventTeamMember')
                         {
                             System.debug('Send email method start EventTeamMember');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventTeamMember(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'EventStatus')
                         {
                             System.debug('Send email method start EventStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerStatus')
                         {
                             System.debug('Send email method start SpeakerStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerTopicTraining')
                         {
                             System.debug('Send email method start SpeakerTopicTraining');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerQualification(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         } else if(modalName == 'EventUpdate') // OCT 2020
                         {
                             System.debug('Send email method start EventUpdMsg');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventUpdMsg(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }
                          
                      }
    
                    //throw new dmlexception();
                    
               }
            }
            catch(Exception e)
            {
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.CALLOUT_GENERAL_EXCEPTION, jsonbody, 0, UserInfo.getUserName(), modalId, modalName);
                 //Callout general exception
                 if(modalName== 'Event')
                 {
                     system.debug('call api general exception fail email start');
                      Pw_Send_Email_On_CalloutFailure.CreateAndSendEmail(modalId,e.getMessage());
                 }
                 else if(modalName== 'Attendee')
                 {
                             System.debug('Send email method start Attendee');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttendee(modalId,' <b>'+ e.getMessage()+'</b>');
                 }
                 else if(modalName == 'Event Attachment')
                 {
                             System.debug('Send email method start Attachment');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttachment(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                 }else if(modalName == 'EventTeamMember')
                         {
                             System.debug('Send email method start EventTeamMember');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventTeamMember(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'EventStatus')
                         {
                             System.debug('Send email method start EventStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerStatus')
                         {
                             System.debug('Send email method start SpeakerStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerTopicTraining')
                         {
                             System.debug('Send email method start SpeakerTopicTraining');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerQualification(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         } else if(modalName == 'EventUpdate') // OCT 2020
                         {
                             System.debug('Send email method start EventUpdMsg');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventUpdMsg(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }
            }     
                    
       }  //For loop Close.                     
    }  
    /// <summary>
    ///     To make callouts
    /// </summary>
    /// <param name="jsonbody">
    ///     'jsonbody' contains event json
    /// </param> 
    Public static void callAPIFromQueuable (string jsonbody, integer noofcalloutcount, integer maxcalloutcount,integer callinseconds, string modalName, string modalId)
        {
           try
           {
                integer timeout;
                Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');
                timeout = calloutsettings.PW_Timeout_Milliseconds__c.intValue();
                
                Http http = new Http();
                HttpResponse resp = new HttpResponse();
                HttpRequest req = new HttpRequest();
                //req.setEndPoint('http://veeva-events-api.azurewebsites.net/api/Events');
                PW_Veeva_Event_Url__c veevaeVentUrl= PW_Veeva_Event_Url__c.getValues('veeva_url');
                Event_Generator_JSON_Setting__c custSetting = Event_Generator_JSON_Setting__c.getValues('EventSetting');
                system.debug('veevaeVentUrl:::'+veevaeVentUrl);
                system.debug('custSetting:::'+custSetting);
                system.debug('JSON :::'+jsonbody);
                if( veevaeVentUrl != null)
                {               
                    req.setEndPoint(veevaeVentUrl.URL__c);
                }
                req.setTimeout(timeout);
                req.setHeader('content-type', 'application/json');
                req.setHeader('Authorization', 'Basic '+custSetting.Token__c);            
                req.setCompressed(false);
                req.setMethod('POST');
                req.setBody(jsonbody);
                
                try
                {
                    if(!Test.isRunningTest())
                    {
                       // MockTimeOut();
                        System.debug('before request send call out queueable');
                        resp = http.send(req);
                        System.debug('after request send  call out queueable');
                        System.debug('Status queueable:'+resp.getStatusCode());
                        if(resp.getStatusCode()!=201)
                        { 
                             System.debug('modalName queueable:'+modalName);
                             string errmsg = 'Unable to send payload  failed with status :' + resp.getStatusCode()+' '+resp.getStatus(); 
                             //string errmsgattendee = 'Attendee failed with status :' + resp.getStatusCode()+' '+resp.getStatus();   
                                                                         
                             PW_Log_Into_CustomLogger.Log('',errmsg, Pw_Logger_Constants.CALLOUT_INCORRECT_STATUS_CODE,jsonbody, noofcalloutcount, UserInfo.getUserName(), modalId, modalName);
                             
                            
                            if(modalName== 'Event')
                             {
                                  System.debug('queueable email start');
                                  Pw_Send_Email_On_CalloutFailure.CreateAndSendEmail(modalId,' <b>'+errmsg+'</b>');
                             }
                             else if(modalName== 'Attendee')
                            {
                                 System.debug('Send email method start Attendee');
                                  Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttendee(modalId,' <b>'+ errmsg+'</b>');
                           }
                           else if(modalName == 'Event Attachment')
                          {
                             System.debug('Send email method start Attachment');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttachment(modalId,' <b>'+ errmsg+'</b>');
                         
                          }else if(modalName == 'EventTeamMember')
                         {
                             System.debug('Send email method start EventTeamMember');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventTeamMember(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'EventStatus')
                         {
                             System.debug('Send email method start EventStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventStatus(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'SpeakerStatus')
                         {
                             System.debug('Send email method start SpeakerStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerStatus(modalId,' <b>'+ errmsg +'</b>');
                         
                         }else if(modalName == 'SpeakerTopicTraining')
                         {
                             System.debug('Send email method start SpeakerTopicTraining');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerQualification(modalId,' <b>'+ errmsg +'</b>');
                         
                         } else if(modalName == 'EventUpdate') // OCT 2020
                         {
                             System.debug('Send email method start EventUpdMsg');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventUpdMsg(modalId,' <b>'+ errmsg +'</b>');
                         
                         }
                        }
                        
                    }
                    
                    System.debug('Status :'+resp.getStatus());
                    System.debug('Status Code :' + resp.getStatusCode()); 
                    
                }
                catch(System.CalloutException e)
                {
                    System.debug('Callout error: '+ e);
                    System.debug(resp.toString());
                    
                     noofcalloutcount++;
                     if(noofcalloutcount<=maxcalloutcount)
                    {
                     
                        PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.CALLOUT_RETRY_ATTEMPT,jsonbody, noofcalloutcount, UserInfo.getUserName(), modalId, modalName);
                        
                        DateTime currentDateTime=System.now().addSeconds(callinseconds);                            
                        String nextScheduleTime=String.valueof(currentDateTime.second()) +' '+String.valueof(currentDateTime.minute())+' '
                                        +String.valueof(currentDateTime.hour())+' '+String.valueof(currentDateTime.day())+' '
                                        +String.valueof(currentDateTime.month())+' ? '+String.valueof(currentDateTime.Year());
                
                        PW_CalloutRetryScheduler Job = new PW_CalloutRetryScheduler ();
                        Job.noofcalloutcount=noofcalloutcount;
                        Job.maxcalloutcount=maxcalloutcount;
                        Job.jsonbody=jsonbody;
                        Job.modalName= modalName;
                        Job.modalId = modalId;
                        Job.callinseconds=callinseconds;
                        system.schedule('Scheduled at '+Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'), nextScheduleTime, Job );
                      }
                      else
                      {
                          //Send email
                          PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.CALLOUT_FINAL_FAIL,jsonbody, noofcalloutcount-1, UserInfo.getUserName(), modalId, modalName);
                          
                          if(modalName== 'Event')
                          {
                              system.debug('Queueable max callout fail email start');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmail(modalId,' <b>' +e.getMessage() + '</b>');
                          }
                          else if(modalName== 'Attendee')
                         {
                             System.debug('Send email method start Attendee');
                              Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttendee(modalId,' <b>'+ e.getMessage() +'</b>');
                         }
                         else if(modalName == 'Event Attachment')
                         {
                             System.debug('Send email method start Attachment');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttachment(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'EventTeamMember')
                         {
                             System.debug('Send email method start EventTeamMember');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventTeamMember(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'EventStatus')
                         {
                             System.debug('Send email method start EventStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerStatus')
                         {
                             System.debug('Send email method start SpeakerStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerTopicTraining')
                         {
                             System.debug('Send email method start SpeakerTopicTraining');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerQualification(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         } else if(modalName == 'EventUpdate') // OCT 2020
                         {
                             System.debug('Send email method start EventUpdMsg');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventUpdMsg(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }
                         
                      }
    
                    //throw new dmlexception();
                    
                }   
             }
             catch(Exception e)
             {
                 //Callout general exception
                 PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.CALLOUT_GENERAL_EXCEPTION, jsonbody, 0, UserInfo.getUserName(), modalId, modalName);
                 
                 if(modalName== 'Event')
                 {
                     system.debug('Queueable max general exception fail email start');
                      Pw_Send_Email_On_CalloutFailure.CreateAndSendEmail(modalId,e.getMessage());
                 }
                 else if(modalName== 'Attendee')
                 {
                       System.debug('Send email method start Attendee');
                       Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttendee(modalId,' <b>'+ e.getMessage() +'</b>');
                 }
                 else if(modalName == 'Event Attachment')
                 {
                             System.debug('Send email method start Attachment');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailAttachment(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                 }else if(modalName == 'EventTeamMember')
                         {
                             System.debug('Send email method start EventTeamMember');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventTeamMember(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'EventStatus')
                         {
                             System.debug('Send email method start EventStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerStatus')
                         {
                             System.debug('Send email method start SpeakerStatus');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerStatus(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }else if(modalName == 'SpeakerTopicTraining')
                         {
                             System.debug('Send email method start SpeakerTopicTraining');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailSpeakerQualification(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         } else if(modalName == 'EventUpdate') // OCT 2020
                         {
                             System.debug('Send email method start EventUpdMsg');
                             Pw_Send_Email_On_CalloutFailure.CreateAndSendEmailEventUpdMsg(modalId,' <b>'+ e.getMessage() +'</b>');
                         
                         }
             }             
        }
        
        public static void MockTimeOut()
        {
            CalloutException e = new CalloutException();
            e.setMessage('This is a constructed Time out exception!');
            throw e;
        }
}