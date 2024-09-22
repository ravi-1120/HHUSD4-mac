trigger PW_Speaker_Status_Update_Trigger on EM_Speaker_vod__c (after update) {
    
System.Debug('Speaker after update trigger');

    if (Trigger.isUpdate)
    {       
        
        for (EM_Speaker_vod__c  speaker : Trigger.new) 
        {

					  /*  if(speaker.PW_IsUpdatedBy_RestAPI_Flag__c )
						{
								speaker.PW_IsUpdatedBy_RestAPI_Flag__c =false;
					            continue;					
						}*/
						//New Start
						if(PW_SpeakerProfile_Rest_Api.IsUpdatedeByRestApi)
						{
						continue;
						}
						//New End
			            EM_Speaker_vod__c oldSpeaker= Trigger.oldMap.get(speaker.id);
			            system.debug('Speaker New Status :'+ speaker.Status_vod__c);
			            system.debug('Speaker Old Status :'+ oldSpeaker.Status_vod__c);
                      // if(speaker.Status_vod__c  !=  oldSpeaker.Status_vod__c  && (speaker.PW_Speaker_ID__c != null || speaker.PW_Speaker_ID__c != ''))
                       if(speaker.Status_vod__c  !=  oldSpeaker.Status_vod__c  && !(string.IsEmpty(speaker.PW_Speaker_ID__c )))
			            {
			           
						            try{           
						                System.Debug('Speaker Insert after trigger called for id ='+speaker.id);      
                                        System.Debug('Speaker Insert after trigger called for id ='+speaker.PW_Speaker_ID__c);    
						                Pw_Call_Service_Bus_API.MakeCalloutUpdateSpeakerStatus(speaker.id ,speaker.Status_vod__c,speaker.PW_Speaker_ID__c ,string.valueOfGmt(speaker.LastModifiedDate));
						                System.Debug('Speaker Update before trigger ');
						            }
						            catch(Exception e){
						                
						                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
						                
						                System.Debug('Speaker Status update before trigger exception');  
						                System.Debug('exception'+e);                
						               
						                system.debug('An error has occurred upon Speaker Status Update before Trigger.Please contact Support for further assistance.');
						            }

			            } //----------  if(speaker.Status_vod__c  !=  oldSpeaker.Status_vod__c)
			            else{
                            system.debug('In Else Speaker New Status :'+ speaker.Status_vod__c);
			                system.debug('In Else Speaker Old Status :'+ oldSpeaker.Status_vod__c);
			                system.debug('In Else Speaker PW_Speaker_ID__c :'+ speaker.PW_Speaker_ID__c);
			                 system.debug(' Either Old status or  new status donot  same  and PW_Speaker_ID__c not null');	                  

			            }
        }   //------------For Loop
        
    }      //------------For If
}