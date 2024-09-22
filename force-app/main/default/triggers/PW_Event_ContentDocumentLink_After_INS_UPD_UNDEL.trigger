trigger PW_Event_ContentDocumentLink_After_INS_UPD_UNDEL on ContentDocumentLink (After insert,after undelete,after update) {
    
    System.Debug('Event ContentDocumentLink insert after trigger ');
    
    
    if(Trigger.isAfter){
          
        PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
        {
            System.Debug('ContentDocumentLink object created with robot user :'+UserInfo.getUserName());
            return;
        }
        
        Set<Id> eventIdSet = new Set<Id>();
        for (ContentDocumentLink eventAttachment : Trigger.new) {
            if(eventAttachment.LinkedEntityId.getSObjectType().getDescribe().getName() =='EM_Event_vod__c'){
                eventIdSet.add(eventAttachment.LinkedEntityId);
            }
        }
        
        PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
        pwFilterRT.filterEventRecordTypes(eventIdSet);
        
        
       
        List<User> userList = [Select Id,EmployeeNumber from User where Id=: UserInfo.getUserId()];
        string employeeNumber='';
        if(userList!=null && userList.size()>0)
            employeeNumber = userList[0].EmployeeNumber;

        for (ContentDocumentLink eventAttachment : Trigger.new) 
        {
            system.debug('Event ContentDocumentLink ID :'+ eventAttachment.id + '->' + eventAttachment.ContentDocumentId);
            try{
                System.Debug('Event ContentDocumentLink Insert after trigger called for parent id ='+ eventAttachment.LinkedEntityId.getSObjectType().getDescribe().getName());
               
                if(eventAttachment.LinkedEntityId.getSObjectType().getDescribe().getName() =='EM_Event_vod__c'){
               
                     if(!pwFilterRT.checkRecordTypeForEvent(eventAttachment.LinkedEntityId))
                           continue ;
                    
					System.Debug('Event Attachment User Firstname and Lastname ='+ UserInfo.getFirstname()+' '+UserInfo.getLastname()); 
                    
                    if (Trigger.isInsert || Trigger.isUndelete){
                        System.Debug('Event ContentDocumentLink Insert/Undelete after trigger called for id ='+ eventAttachment.id + '->' + eventAttachment.ContentDocumentId);
                        Pw_Call_Service_Bus_API.MakeCalloutAddAttachment(eventAttachment.ContentDocumentId, eventAttachment.LinkedEntityId,UserInfo.getFirstname(),UserInfo.getLastname(),employeeNumber);
                    }
                   
                    
                    System.Debug('Event Attachment Insert after trigger Sucessfull Completion');
                }
            }
            catch(Exception e){
                
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                
                
                eventAttachment.addError('An error has occurred. Please contact support for further assistance');
            }
        }        
    }

}