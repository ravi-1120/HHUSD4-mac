///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Speaker_Qualificaiton_Rest_Api
///   Description:    This class is a rest api which will get called from outside salesforce
///   Author:         Nitesh Kodle                   
///   Notes:          Conatins methods to update of an speaker qualification details
///    Date: 24-11-2016
///   Revision History:
///-----------------------------------------------------------------

@RestResource(urlMapping='/SpeakerQualificaiton/*')
global with sharing class PW_SpeakerQualificaiton_Rest_Api
{
   @HttpPost
  global static ResponseHandler post(list<PW_SpeakerQualificaiton_Model> speakerQualificationList)
  { 
    
        String jsonString = JSON.serialize(speakerQualificationList);
        System.debug('SpeakerQualification Update Data Received From TP ' +jsonString);
        ResponseHandler  reshandler  = new ResponseHandler();//store the response
        List<RecordType> serviceRecordType =[Select Id from recordtype where SObjectType = 'EM_Speaker_Qualification_vod__c' and developername ='Speaker_Service_vod' limit 1];
        List<RecordType> trainingRecordtype =[Select Id from recordtype where SObjectType = 'EM_Speaker_Qualification_vod__c' and developername ='Speaker_Training_vod' limit 1];
        RestResponse res = RestContext.response;
        Savepoint savePointSQ;
        try      
        {
            
            
             savePointSQ= Database.setSavepoint();
             if(speakerQualificationList==null || speakerQualificationList.size()<=0)
             {
                reshandler.Code='200';
                reshandler.Message='Success: Speakerqualification list is empty';
                reshandler.Status='Sucess';
                return reshandler;
             }
        List<EM_Speaker_Qualification_vod__c> speakerTrainingsTopicContracts=[select id,PW_Row_ID__c,Speaker_vod__c,Qualification_vod__c,End_Date_vod__c,Start_Date_vod__c,LastModifiedDate  from EM_Speaker_Qualification_vod__c where Speaker_vod__r.PW_Speaker_ID__c =:speakerQualificationList[0].Tp_Speaker_ID];
        Map<string,EM_Speaker_Qualification_vod__c> mapQualification = new Map<string,EM_Speaker_Qualification_vod__c>();
        List<EM_Speaker_Qualification_vod__c> updateST=new List<EM_Speaker_Qualification_vod__c>();
        List<EM_Speaker_Qualification_vod__c> deleteST=new List<EM_Speaker_Qualification_vod__c>();
        List<EM_Speaker_Qualification_vod__c> insertST=new List<EM_Speaker_Qualification_vod__c>();
        
        List<EM_Speaker_vod__c> speakerListVeeva=[select id,PW_Speaker_ID__c from EM_Speaker_vod__c where PW_Speaker_ID__c != null and PW_Speaker_ID__c =:speakerQualificationList[0].Tp_Speaker_ID ];
        Map<string,EM_Speaker_vod__c> speakerMap=new Map<string,EM_Speaker_vod__c>();
        for(EM_Speaker_vod__c tempSpeaker:speakerListVeeva)
        {
           speakerMap.put(tempSpeaker.PW_Speaker_ID__c,tempSpeaker);
        
        }
        
        for(EM_Speaker_Qualification_vod__c training : speakerTrainingsTopicContracts)
        {   
            mapQualification.put(training.PW_Row_ID__c+training.Speaker_vod__c+training.Qualification_vod__c,training);
        
        }
            
         for(PW_SpeakerQualificaiton_Model speakerQualification : speakerQualificationList)
         {
            
            if(!speakerMap.containsKey(speakerQualification.Tp_Speaker_ID))
            {
                Throw new Jsonexception('Tp_SpeakerId not found');//throw exception in case no event has been passed
            
            }
            string speakerid=speakerMap.get(speakerQualification.Tp_Speaker_ID).id;
            
            string mapid=speakerQualification.PW_Row_ID+speakerid+speakerQualification.Qualification_vod;//speakerQualification.PW_Row_ID+speakerQualification.Speaker_vod+speakerQualification.Qualification_vod;
            EM_Speaker_Qualification_vod__c speakerTraining =mapQualification.get(mapid);
            
            if(speakerQualification.Qualification_type=='Topic')
            {
                      if(speakerTraining!=null)//   
                        {   
                        //List<EM_Speaker_Qualification_vod__c> speakerTrainings=[select id from EM_Speaker_Qualification_vod__c where PW_Row_ID__c=:speakerQualification.PW_Row_ID and Speaker_vod__c =: speakerQualification.Speaker_vod and Qualification_vod__c =: speakerQualification.Qualification_vod limit 1];
                                    if(speakerTraining.LastModifiedDate >  DateTime.valueOfGmt((speakerQualification.LastModifiedDate).replaceAll('/','-')) )   //------Newly Added
                                    {
                                     Throw new Pw_ApplicationException('Fail:Failed to Update since the record in Veeva is later than that of TouchPoint:::: VeevaSpkQualId: '+ speakerTraining.Id+' , QualType: '+speakerQualification.Qualification_type+' , TPRowId: '+speakerQualification.PW_Row_ID+' , VeevaLastModDate: '+speakerTraining.LastModifiedDate+' , TPLastModDate: '+speakerQualification.LastModifiedDate); 
                                    }
                                    else if(speakerQualification.isTrained)
                                    {
                                        
                                        
                                            
                                            speakerTraining.Start_Date_vod__c = Date.parse(speakerQualification.Start_Date_vod);
                                            speakerTraining.End_Date_vod__c = Date.parse(speakerQualification.End_Date_vod);
                                            updateST.add(speakerTraining);
                                      
                                        
                                    
                                    }
                                    else
                                    {
                                        
                                            deleteST.add(speakerTraining);
                                        
                                    }
                            }else 
                            {
                                            
                                    if(speakerQualification.isTrained)
                                    {
                                        
                                            EM_Speaker_Qualification_vod__c speakerQual = new EM_Speaker_Qualification_vod__c();
                                            speakerQual.PW_Row_ID__c =speakerQualification.PW_Row_ID;
                                            speakerQual.Qualification_vod__c =speakerQualification.Qualification_vod;
                                            speakerQual.Speaker_vod__c =speakerid;//speakerQualification.Speaker_vod;
                                            speakerQual.Start_Date_vod__c = Date.parse(speakerQualification.Start_Date_vod);
                                            speakerQual.End_Date_vod__c = Date.parse(speakerQualification.End_Date_vod);
                                            speakerQual.RecordTypeID=trainingRecordtype[0].id;
                                            insertST.add(speakerQual);
                                    }
                                       
                            
                            }
                 }
             
             
        
             if(speakerQualification.Qualification_type=='Compliance')
            {
                  if(speakerTraining!=null)//   
                    {   
                        //List<EM_Speaker_Qualification_vod__c> speakerTrainings=[select id from EM_Speaker_Qualification_vod__c where PW_Row_ID__c=:speakerQualification.PW_Row_ID and Speaker_vod__c =: speakerQualification.Speaker_vod and Qualification_vod__c =: speakerQualification.Qualification_vod limit 1];
                                if(speakerTraining.LastModifiedDate >  DateTime.valueOfGmt((speakerQualification.LastModifiedDate).replaceAll('/','-')) )
                                    {
                                     //Throw new Pw_ApplicationException('Fail:Failed to Update since the record in Veeva is later than that of TouchPoint'); 
                                      Throw new Pw_ApplicationException('Fail:Failed to Update since the record in Veeva is later than that of TouchPoint:::: VeevaSpkQualId: '+ speakerTraining.Id+' , QualType: '+speakerQualification.Qualification_type+' , TPRowId: '+speakerQualification.PW_Row_ID+' , VeevaLastModDate: '+speakerTraining.LastModifiedDate+' , TPLastModDate: '+speakerQualification.LastModifiedDate); 
                                    }
                                    else if(speakerQualification.isTrained)
                                    {
                                        
                                        
                                          
                                            speakerTraining.Start_Date_vod__c = Date.parse(speakerQualification.Start_Date_vod);
                                            speakerTraining.End_Date_vod__c = Date.parse(speakerQualification.End_Date_vod);
                                            updateST.add(speakerTraining);
                                      
                                        
                                    
                                    }
                                else
                                    {
                                        
                                            deleteST.add(speakerTraining);
                                        
                                    }
                    }else 
                    {
                            
                                    if(speakerQualification.isTrained)
                                    {
                                        
                                    EM_Speaker_Qualification_vod__c speakerQual = new EM_Speaker_Qualification_vod__c();
                                    speakerQual.PW_Row_ID__c =speakerQualification.PW_Row_ID;
                                    speakerQual.Qualification_vod__c =speakerQualification.Qualification_vod;
                                    speakerQual.Speaker_vod__c =speakerid;//speakerQualification.Speaker_vod;
                                    speakerQual.Start_Date_vod__c = Date.parse(speakerQualification.Start_Date_vod);
                                    speakerQual.End_Date_vod__c = Date.parse(speakerQualification.End_Date_vod);
                                    speakerQual.RecordTypeID=trainingRecordtype[0].id;
                                    insertST.add(speakerQual);
                                    }
                    
                    }
             }
         
        
         
         
         
         
             if(speakerQualification.Qualification_type=='Contract')
            {
                      if(speakerTraining!=null)//   
                        {   
                        //List<EM_Speaker_Qualification_vod__c> speakerTrainings=[select id from EM_Speaker_Qualification_vod__c where PW_Row_ID__c=:speakerQualification.PW_Row_ID and Speaker_vod__c =: speakerQualification.Speaker_vod and Qualification_vod__c =: speakerQualification.Qualification_vod limit 1];
                        
                      System.debug('ST NULL'); 
                                    if(speakerTraining.LastModifiedDate >  DateTime.valueOfGmt((speakerQualification.LastModifiedDate).replaceAll('/','-')) )
                                    {
                                    // Throw new Pw_ApplicationException('Fail:Failed to Update since the record in Veeva is later than that of TouchPoint'); 
                                     Throw new Pw_ApplicationException('Fail:Failed to Update since the record in Veeva is later than that of TouchPoint:::: VeevaSpkQualId: '+ speakerTraining.Id+' , QualType: '+speakerQualification.Qualification_type+' , TPRowId: '+speakerQualification.PW_Row_ID+' , VeevaLastModDate: '+speakerTraining.LastModifiedDate+' , TPLastModDate: '+speakerQualification.LastModifiedDate); 
                                    }
                                    else if(speakerQualification.contractStatus=='Received' ||speakerQualification.contractStatus== 'Fully Executed')
                                    {
                                        
                                          System.debug('ST Trained'); 
                                            
                                            speakerTraining.Start_Date_vod__c = Date.parse(speakerQualification.Start_Date_vod);
                                            speakerTraining.End_Date_vod__c = Date.parse(speakerQualification.End_Date_vod);
                                            speakerTraining.PW_Contract_Name__c=speakerQualification.PW_Contract_Name; // New for merck
                                            updateST.add(speakerTraining);
                                      
                                        
                                    
                                    }
                                    else
                                    {
                                          System.debug('ST Delets'); 
                                            deleteST.add(speakerTraining);
                                        
                                    }
                        }else 
                        {
                                     if(speakerQualification.contractStatus=='Received' ||speakerQualification.contractStatus== 'Fully Executed')
                                    {
                                          System.debug('ST Reciedved'); 
                                        EM_Speaker_Qualification_vod__c speakerQual = new EM_Speaker_Qualification_vod__c();
                                        speakerQual.PW_Row_ID__c =speakerQualification.PW_Row_ID;
                                        speakerQual.Qualification_vod__c =speakerQualification.Qualification_vod;
                                        speakerQual.Speaker_vod__c =speakerid;//speakerQualification.Speaker_vod;
                                        speakerQual.Start_Date_vod__c = Date.parse(speakerQualification.Start_Date_vod);
                                        speakerQual.End_Date_vod__c = Date.parse(speakerQualification.End_Date_vod);
                                        speakerQual.RecordTypeid=serviceRecordType[0].id;
                                        speakerQual.PW_Contract_Name__c=speakerQualification.PW_Contract_Name;  // New for merck
                                        insertST.add(speakerQual);
                                        System.debug('ST Reciedved END'+speakerQual); 
                                    }
                        
                        }
             }
        
}
         
         
         
         
         list<Database.Saveresult> insertSTResult= database.insert(insertST,true);
         list<Database.Saveresult> updateSTResult=database.update(updateST,true);
         list<DataBase.DeleteResult> deleteSTresult=database.delete(deleteST,true);
         
  
                     res.statusCode=200;
                     reshandler.Code='200';
                    //speakerProfile.Message='Success :speakerqualification created';
                    //speakerProfile.PW_Speaker_ID=createSpeakerProfile.getId();
                      reshandler.Message='Success: Speakerquaalification  ';
                      reshandler.Status='Sucess';

                      return reshandler;
         
         
         }
         catch(Exception e)
         {
            PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
            Database.rollback(savePointSQ);
            res.statusCode=500;
            System.debug('Exception message :' + e.getMessage());
             //failed
            reshandler.Message='Fail :'+e.getMessage();
            reshandler.Status='Fail'; 
           
            return reshandler;
         }  
  
  
 
  }
  
     global class ResponseHandler 
   {    
   
        public String Status {get; set;} 
        public String Message {get;set;}                
        public String Code {get; set;}    
       
      }
  
}