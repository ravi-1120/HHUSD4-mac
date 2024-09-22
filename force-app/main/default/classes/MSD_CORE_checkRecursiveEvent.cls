public Class MSD_CORE_checkRecursiveEvent{
    private static boolean run = true;
  private static EM_Event_vod__c oldEvent = new EM_Event_vod__c();
  
    public static boolean runOnce(EM_Event_vod__c evnt1){
    if(oldEvent == null){
      oldEvent = evnt1;
    }    
    if(run){
      run=false;
      return true;
    }else{
      return run;
    }
    }
  
  public static void isUpdate(EM_Event_vod__c evnt){
    //if(oldEvent.End_Time_vod__c != evnt.End_Time_vod__c || oldEvent.Start_Time_vod__c != evnt.Start_Time_vod__c || oldEvent.MSD_Core_Event_Subtype__c != evnt.MSD_Core_Event_Subtype__c || oldEvent.Name != evnt.Name || oldEvent.MSD_CORE_Event_Type__c != evnt.MSD_CORE_Event_Type__c || oldEvent.MSD_Core_Multi_Market__c != evnt.MSD_Core_Multi_Market__c || oldEvent.Status_vod__c != evnt.Status_vod__c || oldEvent.MSD_CORE_EVENT_CANCELED__c != evnt.MSD_CORE_EVENT_CANCELED__c){
      if(oldEvent.End_Time_vod__c != evnt.End_Time_vod__c){
      run = true;
    }
  }
}