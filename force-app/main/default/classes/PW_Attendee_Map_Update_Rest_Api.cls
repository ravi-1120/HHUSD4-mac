///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Attendee_Map_Update_Rest_Api
///   Description:    This class is a rest api which will get called from outside salesforce
///   Author:         Nitesh Kodle                   
///   Notes:          Conatins methods to update of an attendee details
///    Date: 24-11-2016
///   Revision History:
///-----------------------------------------------------------------
@RestResource(urlMapping='/AttendeeMap/*')
global with sharing class PW_Attendee_Map_Update_Rest_Api {
    
 /*  @HttpPost
   global static list<Event_Attendee_vod__c> post(List<PW_Attendee_ID_Map_Model> attendees)
   {
  // return null;
        String jsonString = JSON.serialize(attendees);
        System.debug('Attendee ID Update Data Received From TP ' +jsonString);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
   
      
        if(attendees!=null&&attendees.size()>0)
            {
            
            list<Event_Attendee_vod__c> eventAttendeeLst=new list<Event_Attendee_vod__c>();
            Event_Attendee_vod__c eventAttendeeInstance;
            for(PW_Attendee_ID_Map_Model attendeeModel :attendees)
            {  
                eventAttendeeInstance=[select id,PW_Event_Attendee_Row_ID__c,PW_Participant_ID__c from Event_Attendee_vod__c where PW_Event_Attendee_Row_ID__c =:attendeeModel.PW_Event_Attendee_Row_ID limit 1];               
                eventAttendeeLst.add(eventAttendeeInstance);
            }
          
         //JSONGenerator gen = JSON.createGenerator(false);
         //gen.writeObject(attendeeLst);
         //return gen.getAsString();
            
          return  eventAttendeeLst;
          
         }
         else 
         {
            Throw new Jsonexception('No Attendee has been passed, Attendee Json not found');//throw exception in case no event has been passed         
         }
   }
   */ 
    
    
    @HttpPost
         global static ResponseHandler post(List<PW_Attendee_ID_Map_Model> attendees)
    {

        String jsonString = JSON.serialize(attendees);
        System.debug('Attendee ID Update Data Received From TP ' +jsonString);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
        integer i=0;
        
        try 
        {
            if(attendees!=null&&attendees.size()>0)
            {
                set<string> eventAttendeeIds=new set<string>(); 
                
                for(PW_Attendee_ID_Map_Model attendeeModel :attendees)
                {
                attendees[i].Message='Failed Id not present ';
                eventAttendeeIds.add(attendeeModel.Veeva_ID);
                i++;
                
                }
                list<Event_Attendee_vod__c> eventAttendeeQueryLst=[select id,EM_Event_Speaker_vod__c,EM_Attendee_vod__c,PW_Participant_ID__c,PW_Event_Attendee_Row_ID__c from  Event_Attendee_vod__c where Id in:eventAttendeeIds];
                system.debug(''+eventAttendeeQueryLst.size());
                 list<Event_Attendee_vod__c> eventAttendeeLst=new list<Event_Attendee_vod__c>();
                list<EM_Attendee_vod__c> attendeeLst=new list<EM_Attendee_vod__c>();
               // list<EM_Speaker_vod__c> speakerLst=new list<EM_Speaker_vod__c>();
                Event_Attendee_vod__c eventAttendeeInstance;
                EM_Attendee_vod__c attendeeInstance;
                  Map<id,PW_Attendee_ID_Map_Model> mapOfattendeeandMapModel=new Map<id,PW_Attendee_ID_Map_Model>();
                       Map<id,PW_Attendee_ID_Map_Model> mapOfEventattendeeandMapModel=new Map<id,PW_Attendee_ID_Map_Model>();
               // EM_Speaker_vod__c speakerInstance;
             
             
                  for(PW_Attendee_ID_Map_Model attendeeModel :attendees)
                        {  
                               for(Event_Attendee_vod__c eventAttendee:eventAttendeeQueryLst)
                               {
                               
                                    if(eventAttendee.id==attendeeModel.Veeva_ID)
                                    {
                                            
                                             if(eventAttendee.EM_Event_Speaker_vod__c!=null)
                                            {
                                                if(attendeeModel.PW_Event_Attendee_Row_ID!=null)
                                                {
                                                     eventAttendee.PW_Event_Attendee_Row_ID__c=attendeeModel.PW_Event_Attendee_Row_ID;
                                                }
                                                if(attendeeModel.PW_Participant_ID!=null)
                                                {
                                                     eventAttendee.PW_Participant_ID__c=attendeeModel.PW_Participant_ID;
                                                }           
                                                eventAttendeeLst.add(eventAttendee);
                                                 mapOfEventattendeeandMapModel.put(eventAttendee.id,attendeeModel);
                                            }
                                            else if(eventAttendee.EM_Attendee_vod__c!=null)
                                            {
                                                attendeeInstance=new EM_Attendee_vod__c();
                                                attendeeInstance.id=eventAttendee.EM_Attendee_vod__c;
                                                
                                               
                                                //[select id,PW_Event_Attendee_Row_ID__c,PW_Participant_ID__c from  EM_Attendee_vod__c where Id =:eventAttendeeInstance.EM_Attendee_vod__c limit 1];
                                                if(attendeeModel.PW_Event_Attendee_Row_ID!=null)
                                                {
                                                    attendeeInstance.PW_Event_Attendee_Row_ID__c=attendeeModel.PW_Event_Attendee_Row_ID;
                                                   //eventAttendeeInstance.PW_Event_Attendee_Row_ID__c=attendeeModel.PW_Event_Attendee_Row_ID;
                                                }
                                                if(attendeeModel.PW_Participant_ID!=null)
                                                {
                                                    attendeeInstance.PW_Participant_ID__c=attendeeModel.PW_Participant_ID;
                                                //eventAttendeeInstance.PW_Participant_ID__c=attendeeModel.PW_Participant_ID;
                                                }           
                                                attendeeLst.add(attendeeInstance);
                                                 
                                             mapOfattendeeandMapModel.put(eventAttendee.EM_Attendee_vod__c,attendeeModel);
                                            }
                                    
                                    
                                        }
                               
                               
                               }
                         
                        }
                  res.statusCode=200; //updated 
                  reshandler.Message='Update Success';
                reshandler.Status='Success';
                Database.SaveResult[] updateAttendeeLst=Database.update(attendeeLst,false);
                        for( i=0;i<updateAttendeeLst.size();i++)
                        { 
                                if(updateAttendeeLst[i].isSuccess())
                                {
                                    PW_Attendee_ID_Map_Model attendeeModel=mapOfattendeeandMapModel.get(updateAttendeeLst[i].getId());
                                    attendeeModel.Message='Success';
                                }
                                else
                                {   reshandler.Message='Update Fail';
                                    reshandler.Status='Fail';
                                    res.statusCode=500;
                                    System.debug('Attendee Map Update Failed - ' + attendeeLst.get(i).id);
                                    PW_Attendee_ID_Map_Model attendeeModel=mapOfattendeeandMapModel.get(attendeeLst.get(i).id);
                                    attendeeModel.Message=updateAttendeeLst[i].getErrors()[0].getMessage();
                                }
                        
                        }
                Database.SaveResult[] updateEventAttendee=Database.update(eventAttendeeLst,false);
                 for( i=0;i<updateEventAttendee.size();i++)
                        { 
                                if(updateEventAttendee[i].isSuccess())
                                {
                                    PW_Attendee_ID_Map_Model attendeeModel=mapOfEventattendeeandMapModel.get(updateEventAttendee[i].getId());
                                    attendeeModel.Message='Success';
                                }
                                else
                                {   
                                    reshandler.Message='Update Fail';
                                    reshandler.Status='Fail';
                                    res.statusCode=500;
                                    System.debug('Event Attendee Map Update Failed - ' + eventAttendeeLst.get(i).id);
                                    PW_Attendee_ID_Map_Model attendeeModel=mapOfEventattendeeandMapModel.get(eventAttendeeLst.get(i).id);
                                    attendeeModel.Message=updateAttendeeLst[i].getErrors()[0].getMessage();
                                }
                        
                        }
              
              reshandler.eventAttendeeVeevaAndRowIds=attendees;
                
                
                reshandler.Code='1'; 
                return reshandler;
            }
            else 
            {
                Throw new Jsonexception('No Attendee has been passed, Attendee Json not found');//throw exception in case no event has been passed         
            }
        }
        catch(Exception e)
         {
             PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');

             System.debug('Exception message :' + e);
             res.statusCode=500; //failed
            reshandler.Message='Update Fail'+e;
            reshandler.Status='Fail';  
             return reshandler;
         }   
        
       
     }
    /*
     global static ResponseHandler put(List<PW_Attendee_ID_Map_Model> attendees)
    {

        String jsonString = JSON.serialize(attendees);
        System.debug('Attendee ID Update Data Received From TP ' +jsonString);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
        
        
        try 
        {
            if(attendees!=null&&attendees.size()>0)
            {
                list<Event_Attendee_vod__c> eventAttendeeLst=new list<Event_Attendee_vod__c>();
                list<EM_Attendee_vod__c> attendeeLst=new list<EM_Attendee_vod__c>();
               // list<EM_Speaker_vod__c> speakerLst=new list<EM_Speaker_vod__c>();
                Event_Attendee_vod__c eventAttendeeInstance;
                EM_Attendee_vod__c attendeeInstance;
               // EM_Speaker_vod__c speakerInstance;
                  for(PW_Attendee_ID_Map_Model attendeeModel :attendees)
                        {  
                        
                            eventAttendeeInstance=[select id,EM_Event_Speaker_vod__c,EM_Attendee_vod__c,PW_Participant_ID__c,PW_Event_Attendee_Row_ID__c from  Event_Attendee_vod__c where Id =:attendeeModel.Veeva_ID limit 1];
                            //[select id,PW_Event_Attendee_Row_ID__c,PW_Participant_ID__c from Event_Attendee_vod__c EM_Attendee_vod__c where Id =:attendeeModel.Veeva_ID limit 1]
                                if(eventAttendeeInstance.EM_Event_Speaker_vod__c!=null)
                                {
                                    if(attendeeModel.PW_Event_Attendee_Row_ID!=null)
                                    {
                                    eventAttendeeInstance.PW_Event_Attendee_Row_ID__c=attendeeModel.PW_Event_Attendee_Row_ID;
                                    }
                                    if(attendeeModel.PW_Participant_ID!=null)
                                    {
                                    eventAttendeeInstance.PW_Participant_ID__c=attendeeModel.PW_Participant_ID;
                                    }           
                                
                                }else if(eventAttendeeInstance.EM_Attendee_vod__c!=null)
                                {
                                    attendeeInstance=[select id,PW_Event_Attendee_Row_ID__c,PW_Participant_ID__c from  EM_Attendee_vod__c where Id =:eventAttendeeInstance.EM_Attendee_vod__c limit 1];
                                    if(attendeeModel.PW_Event_Attendee_Row_ID!=null)
                                    {
                                    attendeeInstance.PW_Event_Attendee_Row_ID__c=attendeeModel.PW_Event_Attendee_Row_ID;
                                       eventAttendeeInstance.PW_Event_Attendee_Row_ID__c=attendeeModel.PW_Event_Attendee_Row_ID;
                                    }
                                    if(attendeeModel.PW_Participant_ID!=null)
                                    {
                                    attendeeInstance.PW_Participant_ID__c=attendeeModel.PW_Participant_ID;
                                    eventAttendeeInstance.PW_Participant_ID__c=attendeeModel.PW_Participant_ID;
                                    }           
                                attendeeLst.add(attendeeInstance);
                                
                                }
                          eventAttendeeLst.add(eventAttendeeInstance);
                        }
                
                update attendeeLst;
                update eventAttendeeLst;
                res.statusCode=204; //created
                reshandler.Message='Update successfully';
                reshandler.Status='Success';
                reshandler.Code='1';  
                
                return reshandler;
            }
            else 
            {
                Throw new Jsonexception('No Attendee has been passed, Attendee Json not found');//throw exception in case no event has been passed         
            }
        }
        catch(Exception e)
         {
             System.debug('Exception message :' + e);
             res.statusCode=400; //failed
             reshandler.Message=e.getMessage();
             reshandler.Status='error';
             reshandler.Code='-1';            
             return reshandler;
         }   
         return null;   
       
     }
    */
    
    /*
    global static ResponseHandler put(List<PW_Attendee_ID_Map_Model> attendees)
    {

        String jsonString = JSON.serialize(attendees);
        System.debug('Attendee ID Update Data Received From TP ' +jsonString);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
        
        
        try 
        {
            if(attendees!=null&&attendees.size()>0)
            {
                list<EM_Attendee_vod__c> attendeeLst=new list<EM_Attendee_vod__c>();
                EM_Attendee_vod__c attendeeInstance;
                  for(PW_Attendee_ID_Map_Model attendeeModel :attendees)
                        {  
                        
                            attendeeInstance=[select id,PW_Event_Attendee_Row_ID__c,PW_Participant_ID__c from EM_Attendee_vod__c where Id =:attendeeModel.Veeva_ID limit 1];
                                if(attendeeModel.PW_Event_Attendee_Row_ID!=null)
                                {
                                attendeeInstance.PW_Event_Attendee_Row_ID__c=attendeeModel.PW_Event_Attendee_Row_ID;
                                }
                                if(attendeeModel.PW_Participant_ID!=null)
                                {
                                attendeeInstance.PW_Participant_ID__c=attendeeModel.PW_Participant_ID;
                                }           
                          attendeeLst.add(attendeeInstance);
                        }
                
                update attendeeLst;
                res.statusCode=204; //created
                reshandler.Message='Update successfully';
                reshandler.Status='Success';
                reshandler.Code='1';  
                
                return reshandler;
            }
            else 
            {
                Throw new Jsonexception('No Attendee has been passed, Attendee Json not found');//throw exception in case no event has been passed         
            }
        }
        catch(Exception e)
         {
             System.debug('Exception message :' + e);
             res.statusCode=400; //failed
             reshandler.Message=e.getMessage();
             reshandler.Status='error';
             reshandler.Code='-1';            
             return reshandler;
         }   
         return null;   
       
     }
   */
   global class ResponseHandler 
   {    
   
        public String Status {get; set;} 
        public String Message {get;set;}                
        public String Code {get; set;}    
       public  list<PW_Attendee_ID_Map_Model> eventAttendeeVeevaAndRowIds{get; set;} 
      }
   }