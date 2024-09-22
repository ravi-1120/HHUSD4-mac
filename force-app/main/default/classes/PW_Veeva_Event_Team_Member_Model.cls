global class PW_Veeva_Event_Team_Member_Model {
    
    public Id EventID {get;set;}
    public String EventType {get;set;}
    public Id Record_Type_Id {get;set;}  
    //  public List<PW_Event_Team_Member_Model> EventTeamMembersList {get;set;}  
    public PW_Event_Team_Member_Model EventTeamMember {get;set;}  //----Change
    private  String eventStatus {get;set;} 
    
    public boolean initializeEventTeamMember(id eventTeamMemberId ,EM_Event_Team_Member_vod__c eventTeamMember_vod)
    {
        
        
        List<EM_Event_vod__c>	EventListOfTeamMember=[select id, Status_vod__c,PW_Event_Type__c,RecordTypeId from EM_Event_vod__c  where id=:eventTeamMember_vod.Event_vod__c];
        List<User>	UserListOfTeamMember=[select id, userName,EmployeeNumber from User  where id=:eventTeamMember_vod.Team_Member_vod__c];
        if(EventListOfTeamMember.size() >0  || UserListOfTeamMember.size()>0)
        {
            EventID = eventTeamMember_vod.Event_vod__c;						
            eventStatus=EventListOfTeamMember[0].Status_vod__c;
            EventType =EventListOfTeamMember[0].PW_Event_Type__c;
            Record_Type_Id =EventListOfTeamMember[0].RecordTypeId;
            EventTeamMember =new PW_Event_Team_Member_Model();
            EventTeamMember.Employee_number=UserListOfTeamMember[0].EmployeeNumber;
            EventTeamMember.User_Name=UserListOfTeamMember[0].userName;
            EventTeamMember.Role = eventTeamMember_vod.Role_vod__c;
            return true;
        }else {
            return false;
        }
    }
    public boolean isEventStatusValidToSendTeamMember(){
        PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        if(regSettings.PW_Send_EventTeamMember_Statuses__c == null)
        {
            return false;
        }
        else if(regSettings.PW_Send_EventTeamMember_Statuses__c.contains(eventStatus))
        {           
            return true;
        }
        else
        {
            return false;
        }
        
    }
}