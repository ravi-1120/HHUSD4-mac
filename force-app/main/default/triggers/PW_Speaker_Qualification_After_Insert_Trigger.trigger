trigger PW_Speaker_Qualification_After_Insert_Trigger on EM_Speaker_Qualification_vod__c (after insert) {
   
System.Debug('Speaker Qualification after Insert trigger');
public String triggerEvent='';
    if (Trigger.isInsert)
    {       
        PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
        {        
        
        System.Debug('Speaker Qualification created with robot user :'+UserInfo.getUserName());
        return;
        }

        triggerEvent='INSERT'; 
        
        for (EM_Speaker_Qualification_vod__c  speakerQualification : Trigger.new) 
        {
           
              try{ 
                          system.debug('Speaker Qualification Id:'+ speakerQualification.id);
                          PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
                          Id  speakerContract= regSettings.PW_Contract_Id__c;
                          Id  speakerCompliance= regSettings.PW_Compliance_Id__c;

                         if(( speakerQualification.Qualification_vod__c != speakerContract) && (speakerQualification.Qualification_vod__c != speakerCompliance ))
                         {                         
                                    System.Debug('Speaker Qualification  after trigger called for id ='+speakerQualification.id);                
                                    Pw_Call_Service_Bus_API.MakeCalloutInsertSpeakerQualification(speakerQualification.id,triggerEvent);
                                    System.Debug('SpeakerQualification after trigger ');
                              
                                
                        }else{
                          System.Debug('Speaker Qualification Id should Not'+speakerQualification.Qualification_vod__c);

                        }
              } // try
              catch(Exception e){
                        
                        PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                        
                        System.Debug('Speaker Qualification  insert after trigger exception');  
                        System.Debug('exception'+e);             
                        system.debug('An error has occurred upon Speaker Qualification insert.Please contact Support for further assistance.');
                    } 
        } //-------For
        
    }
}