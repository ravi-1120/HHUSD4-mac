///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Attendee_Rest_Api
///   Description:    This class is a rest api which will get called from outside salesforce
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods to update of an attendee
///   Date: 24-11-2016
///   Revision History:
///-----------------------------------------------------------------
@RestResource(urlMapping='/Attendee/*')
global with sharing class PW_Attendee_Rest_Api {     
    
     @HttpPost
    global static ResponseHandler post(List<PW_Event_Attendee_Model> Attendees) { 
        
        
       // String JSONString = JSON.serialize(attendee);
        
        System.debug('Attendee Data Received From TP ' +Attendees);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
       
         try
         {   
            if(Attendees!=null || Attendees.size()>0){
              //reshandler.eventAttendeeVeevaAndRowIds=Pw_Update_Event_Attendee_From_Tp.Add_Update_Delete_Attendee_of_Veeva(Attendees); //Manipulate veeva attendee
              
                PW_QueueableAddUpdateAttendee addUpdateAttendeeJob = new PW_QueueableAddUpdateAttendee();
                addUpdateAttendeeJob.AttendeesFromTp= Attendees;
                System.enqueueJob(addUpdateAttendeeJob);
                
              }
             else{
                 Throw new Jsonexception('No Attendee has been passed, Attendeee Json not found');//throw exception in case no event has been passed
             }
             
             /*for(PW_Attendee_ID_Map_Model attendee:reshandler.eventAttendeeVeevaAndRowIds){
                 if(attendee.Message.startswith('error')){
                   reshandler.Message='Some records are not processed properly';
                   res.statusCode=500;  //ok
                   break;
                 } else{
                   res.statusCode=200; //created  
                      reshandler.Message='All records are processed properly';
                 }
                 
             }*/
            System.debug('Request processed successfully :'); 
            
            //reshandler.Message='Save successfully';
           // reshandler.Status='Success';
           // reshandler.Code='1';  
            return  reshandler;
         }
        catch(Exception e)
         {
             PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
             System.debug('Exception message :' + e);
             res.statusCode=500;  
             //res.statusCode=400; //failed
             reshandler.Message=e.getMessage();
            // reshandler.Status='error';
             //reshandler.Code='-1';            
             return reshandler;
         }        
     }
    //This class is used to handle the response of the rest api   
    global class ResponseHandler {    
   
       // public String Status {get; set;} 
        public String Message {get;set;}                
        //public String Code {get; set;} 
        public  list<PW_Attendee_ID_Map_Model> eventAttendeeVeevaAndRowIds{get; set;} 
     
    }

}