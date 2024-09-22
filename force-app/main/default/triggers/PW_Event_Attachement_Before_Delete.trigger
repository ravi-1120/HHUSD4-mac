trigger PW_Event_Attachement_Before_Delete on Attachment (before delete) {
        
    System.Debug('Event Attachment delete before trigger');
    
    //Added By Khushbu
    if (Trigger.isdelete)
    {
       
        PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
        {
            System.Debug('Event Attachment created with robot user :'+UserInfo.getUserName());
            return;
        }
        
        Set<Id> eventIdSet = new Set<Id>();
        for (Attachment eventAttachment : Trigger.old) {
            if(eventAttachment.ParentId.getSObjectType().getDescribe().getName() =='EM_Event_vod__c'){
                eventIdSet.add(eventAttachment.ParentId);
            }
        }
        
        PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
        pwFilterRT.filterEventRecordTypes(eventIdSet);
        
        
        Map<Id,EM_Event_vod__c> eventMap = new Map<Id,EM_Event_vod__c>([Select Id,Status_vod__c from EM_Event_vod__c where Id In : eventIdSet]);
        List<User> userList = [Select Id,EmployeeNumber from User where Id=: UserInfo.getUserId()];
        string employeeNumber='';
        if(userList!=null && userList.size()>0)
            employeeNumber = userList[0].EmployeeNumber;

        for (Attachment eventAttachment : Trigger.old) 
        {
            system.debug('Event Attachment ID :'+ eventAttachment.id);
            try{
                System.Debug('Event Attachment delete before trigger called for parent id ='+ eventAttachment.ParentId.getSObjectType().getDescribe().getName());
                // && eventMap.get(eventAttachment.ParentId).Status_vod__c == 'Confirmed' - Status Condition
                if(eventAttachment.ParentId.getSObjectType().getDescribe().getName() =='EM_Event_vod__c' && eventMap.containsKey(eventAttachment.ParentId) ){
               
                    if(!pwFilterRT.checkRecordTypeForEvent(eventAttachment.ParentId))
                           continue ;
               
                    System.Debug('Event Attachment delete before trigger called for id ='+ eventAttachment.id); 
                    System.Debug('Event Attachment User Firstname and Lastname ='+ UserInfo.getFirstname()+' '+UserInfo.getLastname()); 
                    Pw_Call_Service_Bus_API.MakeCalloutDeleteAttachment(eventAttachment.id, eventAttachment.ParentId,UserInfo.getFirstname(),UserInfo.getLastname(),employeeNumber);
                    
                    System.Debug('Event Attachment delete before trigger Sucessfull Completion');
                }
            }
            catch(Exception e){
                
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                System.Debug(' Event Attachment delete before trigger exception');  
                System.Debug('Exception Details'+e);  
                PW_Contact__c pwcontact=PW_Contact__c.getValues('PWContactInfo');
                eventAttachment.addError('An error has occurred upon inserting event attendee.Please contact '+pwcontact.pw_name__c+' at  '+pwcontact.PW_Mobile__c+' for further assistance.');                    
                system.debug('An error has occurred upon inserting event attendee.Please contact '+pwcontact.pw_name__c+' at  '+pwcontact.PW_Mobile__c+' for further assistance.');
            }
        }        
    }
    
    
}