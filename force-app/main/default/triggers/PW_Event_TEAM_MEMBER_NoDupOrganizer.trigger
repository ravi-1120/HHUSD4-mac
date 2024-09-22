trigger PW_Event_TEAM_MEMBER_NoDupOrganizer on EM_Event_Team_Member_vod__c (before insert, before update) {

    PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
    if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
    {     
        System.Debug('Event Attendee updated with robot user :'+UserInfo.getUserName());
        return;
    }

    for (EM_Event_Team_Member_vod__c etm: Trigger.new) {
        if (etm.Role_vod__c.containsIgnoreCase('Organizer')) {
            List<EM_Event_Team_Member_vod__c> otherOrganizers = [select Id from EM_Event_Team_Member_vod__c where Event_vod__c=:etm.Event_vod__c and Id!=:etm.Id and Role_vod__c like '%Organizer%' limit 1];
            if (otherOrganizers.size() > 0 )
            etm.addError('Only one organizer is permitted per event');
        }
    }
}