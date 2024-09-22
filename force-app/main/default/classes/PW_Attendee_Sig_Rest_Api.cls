///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Attendee_Sig_Rest_Api 
///   Description:    This class is a rest api which will get called from outside salesforce
///   Author:         khushbu khetan                   
///   Notes:          Conatins methods to send signature data of an event attendee
///   Date: 30-10-2017
///   Revision History:
///-----------------------------------------------------------------
@RestResource(urlMapping='/AttendeeSignature/*')
global with sharing class PW_Attendee_Sig_Rest_Api { 

    @HttpGet
    global static ResponseHandler get() { 
        String Id = RestContext.request.params.get('Id');
        system.debug('Id : '+Id);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
        try
        {
            if(Id==null || Id==''){
                res.statusCode=400; //failed
                 reshandler.Message='Id cannot be null or empty.';
                 reshandler.Status='error';
                 reshandler.Code='-1';            
                 return reshandler;
            }
            else
            {
                List<Event_Attendee_vod__c> eventAttendeeList = [Select Id,Signature_vod__c,Signature_Datetime_vod__c from Event_Attendee_vod__c where Id =:Id];
                if(eventAttendeeList!=null && eventAttendeeList.size()>0)
                {
                    if(string.IsEmpty(eventAttendeeList[0].Signature_vod__c))
                    {
                         res.statusCode=400; //failed
                         reshandler.Message='Signature is empty for the Attendee : '+Id;
                         reshandler.Status='error';
                         reshandler.Code='-1';            
                         return reshandler;
                    }
                    else{
                        System.debug('Request processed successfully :'); 
                        res.statusCode=200; //created
                        reshandler.Message='Success';
                        reshandler.Status='Success';
                        reshandler.Code='1';  
                        reshandler.signature =eventAttendeeList[0].Signature_vod__c;
                        reshandler.AttestedDateTime=string.valueof(eventAttendeeList[0].Signature_Datetime_vod__c);
                        return  reshandler;
                    }
                }
                else
                {
                 res.statusCode=400; //failed
                 reshandler.Message='Attendee Id was not found : '+Id;
                 reshandler.Status='error';
                 reshandler.Code='-1';            
                 return reshandler;
                }
            }
        }
        catch(Exception e)
         {
             System.debug('Exception message :' + e);
             res.statusCode=400; //failed
             reshandler.Message=e.getMessage();
             reshandler.Status='error';
             reshandler.Code='-1';
             PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
             return reshandler;
         }
    }
    
    //This class is used to handle the response of the rest api   
    global class ResponseHandler {    
   
        public String Status {get; set;} 
        public String Message {get;set;}                
        public String Code {get; set;}   
        public String signature{get;set;}
        public String AttestedDateTime{get;set;} 
     
    }

}