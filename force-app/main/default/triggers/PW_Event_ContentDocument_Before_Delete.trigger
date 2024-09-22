trigger PW_Event_ContentDocument_Before_Delete on ContentDocument (before delete) {

    System.Debug('Event ContentDocument before delete trigger ');
    
    
    if(Trigger.isdelete){
          
        PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
        {
            System.Debug('ContentDocument object deleted with robot user :'+UserInfo.getUserName());
            return;
        }
        
        Set<Id> eventIdSet = new Set<Id>();
		Map<ID, ContentDocumentLink > mapOfContentDocIdsAndContentDocLinkObj = new Map<ID, ContentDocumentLink >();
		
		 
		for(ContentDocumentLink Lnk : [select ContentDocumentId,LinkedEntityId from ContentDocumentLink where ContentDocumentId IN :trigger.oldMap.keySet()])
		{
			if(Lnk.LinkedEntityId!=null && Lnk.LinkedEntityId.getSObjectType().getDescribe().getName() =='EM_Event_vod__c')
			{
				mapOfContentDocIdsAndContentDocLinkObj.put(Lnk.ContentDocumentId, Lnk);
				eventIdSet.add(Lnk.LinkedEntityId);
			}
			
		}
        
        
        PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
        pwFilterRT.filterEventRecordTypes(eventIdSet);
        
        
       
        List<User> userList = [Select Id,EmployeeNumber from User where Id=: UserInfo.getUserId()];
        string employeeNumber='';
        if(userList!=null && userList.size()>0)
            employeeNumber = userList[0].EmployeeNumber;

        for (ContentDocument eventAttachment : Trigger.old) 
        {
			if(mapOfContentDocIdsAndContentDocLinkObj.get(eventAttachment.id)==null)
			{
				continue;
			}
			ID eventID = mapOfContentDocIdsAndContentDocLinkObj.get(eventAttachment.id).LinkedEntityId;
			
            system.debug('Event ContentDocument ID :'+ eventAttachment.id );
            try{
                System.Debug('Event ContentDocument Before Delete trigger called for parent id ='+ eventID);
               
                if(eventID.getSObjectType().getDescribe().getName() =='EM_Event_vod__c'){
               
                     if(!pwFilterRT.checkRecordTypeForEvent(eventID))
                           continue ;
                    
					System.Debug('Event Attachment User Firstname and Lastname ='+ UserInfo.getFirstname()+' '+UserInfo.getLastname()); 
                    
                   
                        System.Debug('Event ContentDocument before delete trigger called for id ='+ eventAttachment.id + 'parent ->' + eventID);
                        Pw_Call_Service_Bus_API.MakeCalloutDeleteAttachment(eventAttachment.Id, eventID,UserInfo.getFirstname(),UserInfo.getLastname(),employeeNumber);
                    
                   
                    
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