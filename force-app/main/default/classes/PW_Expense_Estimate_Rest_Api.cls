///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Expense_Estimate_Rest_Api
///   Description:    This class is a rest api which will get called from outside salesforce
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods to update of an event estimates
///   Date: 20-12-2016
///   Revision History:
///-----------------------------------------------------------------
@RestResource(urlMapping='/Estimates/*')
global class PW_Expense_Estimate_Rest_Api {
    
    @HttpPost
    global static ResponseHandler post(PW_Estimates_Rest_API_Model Estimates) {         
         
        System.debug('estimates Data Received From TP ' +Estimates);
        String JSONString = JSON.serialize(Estimates);
        System.debug('estimates Data Received From TP ' +JSONString);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
       
         try
         {   
            if(Estimates!=null){
                //PW_Update_Expense_Estimates_from_Tp.Update_Expense_Estimates_Of_Veeva(Estimates); //Update veeva event
                
                PW_QueueableUpdateEstimates updateEstimatesJob = new PW_QueueableUpdateEstimates();
                updateEstimatesJob.EstimatesFromTp = Estimates;
                System.enqueueJob(updateEstimatesJob);
              }
             else{
                 Throw new Jsonexception('No estimates has been passed, estimates Json not found');//throw exception in case no event has been passed
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