///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_Event_Rest_Api
///   Description:    This classis a rest api which will get called from outside salesforce
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods to update of an event
///   Date: 24-9-2016
///   Revision History:
///-----------------------------------------------------------------
@RestResource(urlMapping='/Events/*')
global with sharing class Pw_Event_Rest_Api {
    
     @HttpPost
    global static ResponseHandler post(PW_Event_Model event) {         
                                                        
        String JSONString = JSON.serialize(event);
        System.debug(event+ 'Event Data Received From TP ' +JSONString);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
       
         try
         {   
            if(event!=null){
                //PW_Update_Veeva_Event_From_Tp.Update_Event_Speaker_TeamMembers_Of_Veeva(event); //Update veeva event
                
                PW_QueueableUpdateEvent updateEventJob = new PW_QueueableUpdateEvent();
                updateEventJob.EventFromTp = event;
                System.enqueueJob(updateEventJob);
              }
             else{
                 Throw new JsonException('No event has been passed, Event Json not found');//throw exception in case no event has been passed
             }
             
            System.debug('Request processed successfully :'); 
            res.statusCode=200; //created
            reshandler.Message='Save successfully';
            reshandler.Status='Success';
            reshandler.Code='1';  
            return  reshandler;
         }
        catch(Exception e)
         {
             PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');

             System.debug('Exception message :' + e);
              res.statusCode=400; //failed
             reshandler.Message=e.getMessage();
             reshandler.Status='error';
             reshandler.Code='-1';            
             return reshandler;
         }        
     }
    //This class is used to handle the response of the rest api   
    global class ResponseHandler {    
   
        public String Status {get; set;} 
        public String Message {get;set;}                
        public String Code {get; set;}    
     
    }

}