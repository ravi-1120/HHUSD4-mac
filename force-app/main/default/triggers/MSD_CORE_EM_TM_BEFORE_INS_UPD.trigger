/* 
 * Trigger: MSD_CORE_Create_EM_Attendee
 * 
 * Trigger created to handle the following Requirement:
 * USEVEN-R-0167 - The system shall automatically add event organizers as attendees for a given event. 
 * 
 * Author: Kevin Brace
 * 
 * Change Log: 
 * KRB 6/6/2019 - Initial Version
*/

trigger MSD_CORE_EM_TM_BEFORE_INS_UPD on EM_Event_Team_Member_vod__c (before insert, before update) {
    
    PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
    if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
    {     
       System.Debug('Event Attendee updated with robot user :'+UserInfo.getUserName());
       return;
    }
   
    if (Trigger.isInsert){
       List<Id> eventIdList =new List<Id>();
       Set<Id> eventIdSet =new Set<Id>();
       Map<Id,EM_Event_vod__c> eventMap=new Map<Id,EM_Event_vod__c>();
       Map<Id, Schema.RecordTypeInfo> eventRtMap = EM_Event_vod__c.SObjectType.getDescribe().getRecordTypeInfosByID();
       Map<Id, Schema.RecordTypeInfo> attendeeRtMap = EM_Attendee_vod__c.SObjectType.getDescribe().getRecordTypeInfosByID();
       List<EM_Attendee_vod__c> AttendeesForInsert = new List<EM_Attendee_vod__c>();

       //Load up a list of Event Ids associated to Team Member Records that meet the Criteria...
       for(EM_Event_Team_Member_vod__c emTeamMember:trigger.new){
       
          if(emTeamMember.Role_vod__c == 'MSD_CORE_Pushed Organizer' ||
             emTeamMember.Role_vod__c == 'MSD_CORE_Pushed Cohost' ||
             emTeamMember.Role_vod__c == 'Organizer_vod' ||
             emTeamMember.Role_vod__c == 'Cohost_vod'){
             eventIdSet.add(emTeamMember.Event_vod__c);
          }
       }
   
       if(!eventIdSet.isEmpty()){
       
          for(Id eventId : eventIdSet){
             eventIdList.add(eventId);
          }
       
          //Pull all the Event Records that will be required for Processing...
          eventMap=new Map<Id,EM_Event_vod__c>([Select Id, RecordType.Name, Status_vod__c 
                                             FROM   EM_Event_vod__c 
                                             WHERE  RecordType.Name IN ('MSD_CORE_Events_Without_Speakers', 'MSD_CORE_Child_Home_Office_Event', 'MSD_CORE_Clinical_Liaison_Event' )
                                             AND    Status_vod__c = 'MSD_CORE_Planned'
                                             AND    Id in: eventIdList]);

         //Start the Processing
         if(!eventMap.isEmpty()){
          
            for(EM_Event_Team_Member_vod__c teamMember:trigger.new){
              if(teamMember.Role_vod__c == 'MSD_CORE_Pushed Organizer' ||
                 teamMember.Role_vod__c == 'MSD_CORE_Pushed Cohost' ||
                 teamMember.Role_vod__c == 'Organizer_vod' ||
                 teamMember.Role_vod__c == 'Organizer_vod' && 
                 eventMap.containsKey(teamMember.Event_vod__c)){
                                   
                 MSD_CORE_Events_Future_Calls_Util.insertEMAttendee(teamMember.Event_vod__c, teamMember.Team_Member_vod__c, Schema.SObjectType.EM_Attendee_vod__c.getRecordTypeInfosByDeveloperName().get('Attendee_vod').getRecordTypeId());    
             }
          }
       }                          
    } 
  }  
}