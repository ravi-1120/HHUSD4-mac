///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_SpeakerProfile_Rest_Api
///   Description:    This class is a rest api which will get called from outside salesforce
///   Author:         Nitesh Kodle                   
///   Notes:          Conatins methods to update of an Speaker Profile details
///    Date: 24-11-2016
///   Revision History:
///-----------------------------------------------------------------
@RestResource(urlMapping='/SpeakerProfile/*')
global with sharing class PW_SpeakerProfile_Rest_Api
{
    public static boolean IsUpdatedeByRestApi=false;     //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>For Merck
   @HttpPost
    global static ResponseHandler post(PW_SpeakerProfile_Model speakerProfile)
  {
       
        String jsonString = JSON.serialize(speakerProfile);
        System.debug('Attendee ID Update Data Received From TP ' +jsonString);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        RestResponse res = RestContext.response;
        try      
        {     list<EM_Speaker_vod__c> speaker=new list<EM_Speaker_vod__c>();
            
                 if(speakerProfile.PW_Speaker_ID==null||speakerProfile.PW_Speaker_ID=='')
                 {
                 
                 
                         res.statusCode=500;
                         reshandler.Code='500';
                         reshandler.Message=' Fail:PW_Speaker_ID Cannot be null or Empty';
                         reshandler.Status='Fail';
                        return reshandler;
                     
                 }
                    speaker=[select id, Account_vod__c,Address_vod__c,Annual_Cap_vod__c,Cap_Remaining_vod__c,PW_Client_ID__c,
                    Credentials_vod__c, External_ID_vod__c,First_Name_vod__c,Furigana_vod__c,Last_Name_vod__c,Middle_Name_vod__c,Nickname_vod__c,
                    PW_Speaker_ID__c,Speaker_Identifier_vod__c,Status_vod__c,Suffix_vod__c,Title_vod__c,Year_To_Date_Reset_Day_vod__c,
                    Year_To_Date_Reset_Month_vod__c,Year_to_Date_Spend_vod__c,Year_to_Date_Utilization_vod__c,PW_Presentation_Language__c,LastModifiedDate from EM_Speaker_vod__c where PW_Speaker_ID__c=:speakerProfile.PW_Speaker_ID];    // --LastModifiedDate added
                        
                    list<Account> speakerAccount=new list<Account>();  
                    
                        if(speakerProfile.PW_Client_ID!=null&&speakerProfile.PW_Client_ID!='')
                        {
                         speakerAccount =[select id,PW_Client_ID__c from Account where PW_Client_ID__c=:speakerProfile.PW_Client_ID];
                        }
  
                            if(speaker.size()>0)
                            {
                                EM_Speaker_vod__c updateSpeaker=speaker[0];
                                //-------------New Start
                                        if( updateSpeaker.LastModifiedDate > DateTime.valueOfGmt((speakerProfile.LastModifiedDate).replaceAll('/','-'))  )
                                        {                
                 
                                                 res.statusCode=500;
                                                 //reshandler.speakerProfileReponse=speakerProfile;
                                                
                                                 reshandler.Code='500';
                                                 reshandler.Message=' Fail:Failed to Update since the record in Veeva is later than that of TouchPoint.This message is outdated.';
                                                 reshandler.Status='Fail';
                                                return reshandler;
                     
                                       }
                                //-------------New End     
                                        if(speakerAccount.size()>0)
                                        {
                                            if(speakerProfile.PW_Client_ID_Required==true) // Jan 2021 release 
                                            {
                                                updateSpeaker.Account_vod__c= speakerAccount[0].Id;
                                            }
                                        }
                                        
                                        
                                            updateSpeaker.PW_Client_ID__c= speakerProfile.PW_Client_ID;
                                            updateSpeaker.First_Name_vod__c=speakerProfile.First_Name_vod;
                                            updateSpeaker.Last_Name_vod__c= speakerProfile.Last_Name_vod;
                                            updateSpeaker.Status_vod__c= speakerProfile.Status_vod;
                                            updateSpeaker.Address_vod__c=speakerProfile.Address_vod;
                                            updateSpeaker.Credentials_vod__c=speakerProfile.Credentials_vod;
                                            updateSpeaker.PW_Specialty__c=speakerProfile.PW_Speciality;
                                            updateSpeaker.Name=speakerProfile.Name;
                                            updateSpeaker.PW_Presentation_Language__c=speakerProfile.PW_Presentation_Language;
                                            updateSpeaker.PW_Speaker_Credentials__c=speakerProfile.PW_Speaker_Credentials;
                                           
                                            IsUpdatedeByRestApi=true;   //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>New
                                            Database.SaveResult updateSpeakerProfile=Database.update(updateSpeaker,false);
                                                       if(updateSpeakerProfile.isSuccess())
                                                        {   
                                                            PW_ProcessW9Information.DeleteAllW9ForASpeaker(updateSpeaker.Id); // April 2020 release
                                                            PW_ProcessW9Information.InsertW9List(speakerProfile.ListOfW9Info, updateSpeaker.Id ); // April 2020 release
                                                            speakerProfile.PW_Speaker_ID=updateSpeakerProfile.getId(); 
                                                            reshandler.Code='200';
                                                            res.statusCode=200;
                                                            reshandler.Message='Success: Speaker Updated';
                                                            reshandler.Status='Sucess';
                                                           
                                                           
                                                            
                                                        }
                                                        else
                                                        {   
                                                            
                                                             res.statusCode=500;
                                                             
                                                            speakerProfile.Message=updateSpeakerProfile.getErrors()[0].getMessage();
                                                             reshandler.Code='500';
                                                            reshandler.Message=' Fail:Speaker UpdateFailed : '+updateSpeakerProfile.getErrors()[0].getMessage();
                                                            reshandler.Status='Fail';
                                                           
                                                            
                                                            
                                                        }
                                            
                                            
                                        
                                        
                            }
                            else
                            {
                            
                                    
                                    
                                            EM_Speaker_vod__c newSpeaker=new EM_Speaker_vod__c();
                                            
                                            if(speakerProfile.PW_Client_ID_Required==false) // Jan 2021 release 
                                            {
                                                newSpeaker.PW_Client_ID__c= speakerProfile.PW_Client_ID;
                                            }
                                            else if(speakerAccount.size()>0) // Jan 2021 release 
                                            {
                                                newSpeaker.Account_vod__c= speakerAccount[0].id;
                                                newSpeaker.PW_Client_ID__c= speakerAccount[0].PW_Client_ID__c;
                                            }
                                            else // Jan 2021 release 
                                            {
                                                    speakerProfile.Message='Fail :Account doesnot exits';   
                                                    res.statusCode=500;
                                                    reshandler.Code='500';
                                                    reshandler.Message=' Fail :Account doesnot exists';
                                                    reshandler.Status='Fail';
                                                   
                                                   return reshandler;
                                            
                                            }
                                            
                                            
                                            newSpeaker.PW_Speaker_ID__c= speakerProfile.PW_Speaker_ID;
                                            newSpeaker.First_Name_vod__c=speakerProfile.First_Name_vod;
                                            newSpeaker.Last_Name_vod__c= speakerProfile.Last_Name_vod;
                                            newSpeaker.Status_vod__c= speakerProfile.Status_vod;
                                            newSpeaker.Address_vod__c=speakerProfile.Address_vod;
                                            newSpeaker.Credentials_vod__c=speakerProfile.Credentials_vod;
                                            newSpeaker.PW_Specialty__c=speakerProfile.PW_Speciality;
                                            newSpeaker.Name=speakerProfile.Name;
                                            newSpeaker.PW_Presentation_Language__c=speakerProfile.PW_Presentation_Language;
                                            newSpeaker.PW_Speaker_Credentials__c=speakerProfile.PW_Speaker_Credentials;
                                            
                                            Database.SaveResult createSpeakerProfile=Database.insert(newSpeaker,false);
                                                           if(createSpeakerProfile.isSuccess())
                                                            {
                                                                PW_ProcessW9Information.InsertW9List(speakerProfile.ListOfW9Info, createSpeakerProfile.getId() ); // April 2020 Release
                                                                 res.statusCode=200;
                                                                  reshandler.Code='200';
                                                                speakerProfile.Message='Success :speaker created';
                                                                speakerProfile.PW_Speaker_ID=createSpeakerProfile.getId();
                                                                 reshandler.Message='Success: Speaker created';
                                                                 reshandler.Status='Sucess';
                                                                 //reshandler.speakerProfileReponse=speakerProfile;
                                                                 
                                                            }
                                                            else
                                                            {     res.statusCode=200;
                                                                  reshandler.Code='500';
                                                                  speakerProfile.Message='Fail :speaker insert failed';
                                                                speakerProfile.Message=createSpeakerProfile.getErrors()[0].getMessage();
                                                                reshandler.Message=' Fail :speaker insert failed :'+createSpeakerProfile.getErrors()[0].getMessage();
                                                                reshandler.Status='Fail';
                                                                res.statusCode=500;                                           
                                                              
                                                                                                                            
                                                            }
                                    
                            
                            }
                            return reshandler;
            
            }
            catch(Exception e)
             {
                 PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');

                speakerProfile.Message='Exception message :' +e;
                res.statusCode=500;
                System.debug('Exception message :' + e);
                 //failed
                reshandler.Message='Update Fail :'+e;
                reshandler.Status='Fail'; 
                
                return reshandler;
             }   
        
       
  
  
  }   
    
     global class ResponseHandler 
   {    
   
        public String Status {get; set;} 
        public String Message {get;set;}                
        public String Code {get; set;}    
       //public  PW_SpeakerProfile_Model speakerProfileReponse{get; set;} 
      }
    
}