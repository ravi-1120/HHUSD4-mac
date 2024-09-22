///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_SpeakerCV_Rest_Api
///   Description:    This class is a rest api which will get called from outside salesforce to add Speaker CV
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods to add Speaker CV
///   Date: 20-12-2016
///   Revision History:
///-----------------------------------------------------------------

@RestResource(urlMapping='/SpeakerCV/*')
global class PW_SpeakerCV_Rest_Api {

    @HttpPost
    global static ResponseHandler post(PW_SpeakerCV_Rest_API_Modal speakerCV ) {         
         
        System.debug('CV Data Received From TP ' +speakerCV);
        String JSONString = JSON.serialize(speakerCV);
        System.debug('CV Data Received From TP ' +JSONString);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
       
         try
         {   
            if(speakerCV!=null){
                //PW_Update_Expense_Estimates_from_Tp.Update_Expense_Estimates_Of_Veeva(Estimates); //Update veeva event
                //Delete Attachments
                List<EM_Speaker_vod__c> speaker =[select Id from EM_Speaker_vod__c where PW_Speaker_ID__c =: speakerCV.TpSpeakerId limit 1];
                
                if(speaker.size()==0)
                {
                    System.debug('TP Speaker Id not found in Veeva');
                     res.statusCode=400; //failed
                     reshandler.Message='TP Speaker Id not found in Veeva';
                     reshandler.Status='error';
                     reshandler.Code='-1';            
                     return reshandler;
                    
                }
                
                
                List<Attachment> attachs =[select Id from Attachment where ParentID =: speaker[0].id ];
                if(attachs.size()>0)
                {
                    delete attachs;
                }
                
                //Add New Attachment
                
                Blob bodyBlob = EncodingUtil.base64Decode(speakerCV.CV_Body); //Convert it to a blob
            
                Attachment attach = new Attachment(); //Make an attachment
                attach.Name =speakerCV.File_Name;  
                attach.Body = bodyBlob;
                attach.ContentType= speakerCV.ContentType; //Signal what the file's MIME type is
                attach.ParentID = speaker[0].id;//speakerCV.ParentId;
                insert attach;
              }
             else{
                 Throw new Jsonexception('No CV information has been passed, Speaker CV Json not found');//throw exception in case no event has been passed
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
             System.debug('Exception message :' + e);
             PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
              res.statusCode=400; //failed
             reshandler.Message=e.getMessage();
             reshandler.Status='error';
             reshandler.Code='-1'; 
             
             return reshandler;
         }        
     }
    @HttpDelete
    global static ResponseHandler deleteCVById() {
        String Id = RestContext.request.params.get('TpSpeakerId');
        System.debug('Delete called Id = ' + Id);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
        try
        {
         if(Id!=null){
                //PW_Update_Expense_Estimates_from_Tp.Update_Expense_Estimates_Of_Veeva(Estimates); //Update veeva event
                //Delete Attachments
                List<EM_Speaker_vod__c> speaker =[select Id from EM_Speaker_vod__c where PW_Speaker_ID__c =: Id limit 1];
                
                if(speaker.size()==0)
                {
                    System.debug('TP Speaker Id not found in Veeva');
                     res.statusCode=400; //failed
                     reshandler.Message='TP Speaker Id not found in Veeva';
                     reshandler.Status='error';
                     reshandler.Code='-1';            
                     return reshandler;
                    
                }
                
                
                List<Attachment> attachs =[select Id from Attachment where ParentID =: speaker[0].id ];
                if(attachs.size()>0)
                {
                    delete attachs;
                }
         }
        else{
                 Throw new Jsonexception('No TpSpeakerId passed');//throw exception in case no event has been passed
             }
             
            System.debug('Request processed successfully :'); 
            res.statusCode=200; //created
            reshandler.Message='Delete successfully';
            reshandler.Status='Success';
            reshandler.Code='1';  
            return  reshandler;
        }
        catch(Exception e)
         {
             System.debug('Exception message :' + e);
             PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
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