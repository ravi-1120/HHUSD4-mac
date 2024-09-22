trigger PW_EM_EVENT_AFTER_UPD on EM_Event_vod__c (after update) {
    
         System.Debug(' Event With Submitted Status outside if');

    //Added By Anshuman
     if (Trigger.isUpdate)
    {
    
    
    
        PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        boolean isRobotUser=false;
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
        {        
        
        System.Debug('Event Updated with robot user :'+UserInfo.getUserName());
        isRobotUser =true;
        }
       if(isRobotUser == false) 
       {
            PW_Proccess_Event_Update.proccessEventUpdate(Trigger.New,Trigger.Old,
            Trigger.newMap,Trigger.oldMap);
            
            PW_Proccess_Event_Update.proccessEventUpdMsg(Trigger.New,Trigger.Old,
            Trigger.newMap,Trigger.oldMap);
       }

       PW_Proccess_Event_Update.proccessEventStatusUpdate(Trigger.New,Trigger.Old,
            Trigger.newMap,Trigger.oldMap);        
        
    }     
}