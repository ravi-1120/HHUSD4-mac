trigger PW_Event_ContentDocumentLink_Before_Delete on ContentDocumentLink (before delete) {

    System.Debug('Event ContentDocumentLink before delete trigger ');
    
    
    if(Trigger.isdelete){
          
        PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
        {
            System.Debug('ContentDocumentLink object deleted with robot user :'+UserInfo.getUserName());
            return;
        }
        
        Set<Id> eventIdSet = new Set<Id>();
        for (ContentDocumentLink eventAttachment : Trigger.old) {
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

        for (ContentDocumentLink eventAttachment : Trigger.old) 
        {
            system.debug('Event ContentDocumentLink ID :'+ eventAttachment.id + '->' + eventAttachment.ContentDocumentId);
            try{
                System.Debug('Event ContentDocumentLink Before Delete trigger called for parent id ='+ eventAttachment.LinkedEntityId.getSObjectType().getDescribe().getName());
               
                if(eventAttachment.LinkedEntityId.getSObjectType().getDescribe().getName() =='EM_Event_vod__c'){
               
                     if(!pwFilterRT.checkRecordTypeForEvent(eventAttachment.LinkedEntityId))
                           continue ;
                    
					System.Debug('Event Attachment User Firstname and Lastname ='+ UserInfo.getFirstname()+' '+UserInfo.getLastname()); 
                    
                   
                        System.Debug('Event ContentDocumentLink before delete trigger called for id ='+ eventAttachment.id + '->' + eventAttachment.ContentDocumentId);
                        Pw_Call_Service_Bus_API.MakeCalloutDeleteAttachment(eventAttachment.ContentDocumentId, eventAttachment.LinkedEntityId,UserInfo.getFirstname(),UserInfo.getLastname(),employeeNumber);
                    
                   
                    
                    System.Debug('Event Attachment Before Delete trigger Sucessfull Completion');
                }
            }
            catch(Exception e){
                
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                
                
                eventAttachment.addError('An error has occurred. Please contact support for further assistance');
            }
        }        
    }
    
}