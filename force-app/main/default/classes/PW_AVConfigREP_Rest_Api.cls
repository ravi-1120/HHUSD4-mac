///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_AVConfigREP_Rest_Api 
///   Description:    This class is a rest api which will get called from outside salesforce
///   Author:         Anshuman Hazarika                   
///   Notes:          Conatins methods to update the REP will provide Multisesect piclkist
///                   and create dependency with Event Type
///   Date: 20-08-2018
///   Revision History:
///-----------------------------------------------------------------

@RestResource(urlMapping='/AVCONFIGREP/*')
global with sharing class PW_AVConfigREP_Rest_Api {     
    
     @HttpPost
    global static ResponseHandler post(List<PW_AV_Config_Model> ListOfAVs) { 
        
        
       // String JSONString = JSON.serialize(attendee);
        
        System.debug('AV Data Received From TP ' + ListOfAVs);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
       
         try
         {   
            if(ListOfAVs!=null || ListOfAVs.size()>0){
              
             UpdateAVForRepWillProvide(ListOfAVs);
             //UpdateAVForPWWillProvide(ListOfAVs);
             
                
              }
             else{
                 Throw new Jsonexception('No AV information has been passed to the AVCONFIG Rest API');//throw exception in case no event has been passed
             }
             
             
            System.debug('Request processed successfully :'); 
            
              reshandler.Message='Save successfully';
              reshandler.Status='Success';
              reshandler.Code='1';  
            return  reshandler;
         }
        catch(Exception e)
         {
             PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
             System.debug('Exception message :' + e);
             res.statusCode=500;  
             //res.statusCode=400; //failed
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
    public class MetadataServiceExamplesException extends Exception { }
    
     public static void handleSaveResults(MetadataService.SaveResult saveResult)
    {
        // Nothing to see?
        if(saveResult==null || saveResult.success)
            return;
        // Construct error message and throw an exception
        if(saveResult.errors!=null)
        {
            List<String> messages = new List<String>();
            messages.add(
                (saveResult.errors.size()==1 ? 'Error ' : 'Errors ') +
                    'occured processing component ' + saveResult.fullName + '.');
            for(MetadataService.Error error : saveResult.errors)
                messages.add(
                    error.message + ' (' + error.statusCode + ').' +
                    ( error.fields!=null && error.fields.size()>0 ?
                        ' Fields ' + String.join(error.fields, ',') + '.' : '' ) );
            if(messages.size()>0)
                throw new MetadataServiceExamplesException(String.join(messages, ' '));
        }
        if(!saveResult.success)
            throw new MetadataServiceExamplesException('Request failed with no specified error.');
    }
     public static MetadataService.MetadataPort createService()
    {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        service.timeout_x = 120000; 
        return service;
    }
    public static void UpdateAVForRepWillProvide(List<PW_AV_Config_Model> ListOfAVs)
    {
        MetadataService.MetadataPort service = createService();
             MetadataService.CustomField customField = new MetadataService.CustomField();
             customField.fullName = 'EM_Event_vod__c.PW_AV_REP_Will_Provide__c';
             customField.label = 'Rep Will Provide';
             customField.type_x = 'MultiselectPicklist';
            //customField.type_x = 'MultiselPicklist';
           //customField.type_x = 'Picklist';
             customField.visibleLines=4;
            metadataservice.Picklist pt = new metadataservice.Picklist();
            pt.sorted= false;
            pt.controllingField = 'PW_Event_Type__c';
            
            
            pt.picklistValues = new list<metadataservice.PicklistValue>();
            
             for(PW_AV_Config_Model AVitem:ListOfAVs)
             {
                //List<String> lstControllingValues = new List<String>();
               // lstControllingValues.add('Out Of Office');
             
                metadataservice.PicklistValue plValue = new metadataservice.PicklistValue();
                plValue.fullName= AVitem.AV_Name;//'Room Rental';
                plValue.default_x=false ;
                plValue.controllingFieldValues = AVitem.Controlling_Event_Type_Names;//lstControllingValues;

                pt.picklistValues.add(plValue);
             }                    
            
            customField.picklist = pt ;
            List<MetadataService.SaveResult> results =
                service.updateMetadata(
                    new MetadataService.Metadata[] { customField });
                    handleSaveResults(results[0]);
                    
                    
                   List<RecordType> recordTypeList = [SELECT developername,Name FROM RecordType WHERE SObjectType = 'EM_Event_vod__c'] ;
                                       
                    
                    //MetadataService.Metadata[] rtlist = new MetadataService.Metadata[]{};
                    
                    PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
                    string supportedrecordtypes=regSettings.PW_Event_Record_Types_For_Integration__c;
                    
                    //string supportedrecordtypes='Speaker_Program_w_Approval;Speaker_Program_wo_Approval';
                    
                    for(RecordType r : recordTypeList ){
                    if(supportedrecordtypes.Contains(r.developername))
                        {
                            MetadataService.RecordType rt = new MetadataService.RecordType();
                            rt.fullName='EM_Event_vod__c.'+r.developername;
                            rt.label=r.Name;
                            rt.active= true;
                            //rt.businessProcess= 'first lead process';
                            
                            MetadataService.RecordTypePicklistValue mrt = new MetadataService.RecordTypePicklistValue ();
                            mrt.picklist = 'PW_AV_REP_Will_Provide__c';                       
                              mrt.values = pt.picklistValues;
                              
                            rt.picklistValues = new list <MetadataService.RecordTypePicklistValue>{mrt};
                           List<MetadataService.SaveResult> resultsrec= service.updateMetadata( new MetadataService.Metadata[]{rt});
                           handleSaveResults(resultsrec[0]);
                        }
                    }
    } 
    
    
}