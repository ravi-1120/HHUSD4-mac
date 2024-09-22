///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_Call_Service_Bus_API
///   Description:    This class sends an email when an event callout fails
///   Author:         Anshuman Hazarika                  
///   Notes:          Conatins methods which will send email
///   Date: 18-12-2017
///   Revision History:
///-----------------------------------------------------------------
public class Pw_Send_Email_On_CalloutFailure{


    //This method checks whether the email functionality is set on/off for the org.If set to on calls the methods to generate email body and send an email.
    public static void CreateAndSendEmail(ID eventId, string errorMessage){
        
        system.debug('Inside method CreateAndSendEmail :'+eventId);
        //PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');

            
            string emailBody='';
            emailBody = GenerateEmailBody(eventId, errorMessage);
            SendEmail(emailBody,calloutsettings, eventId, 'Event');
        
    }
    
    public static void CreateAndSendEmailAttendee(ID attendeeId, string errorMessage){
        
        system.debug('Inside method CreateAndSendEmailAttendee :'+attendeeId);
        //PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');

            
            string emailBody='';
            emailBody = GenerateEmailBodyForAttendee(attendeeId, errorMessage);
            SendEmail(emailBody,calloutsettings, attendeeId, 'Attendee');
        
    }

    public static void CreateAndSendEmailAttachment(ID attacnmentid , string errorMessage){
        
        system.debug('Inside method CreateAndSendEmailAttendee :'+attacnmentid);
        //PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');

            
            string emailBody='';
            emailBody = GenerateEmailBodyForAttachment(attacnmentid, errorMessage);
            SendEmail(emailBody,calloutsettings, attacnmentid, 'Attachment' );
        
    }
    
    
    //This method generates email body from the event object.
    public static string GenerateEmailBody(Id eventId, string errorMessage){
        system.debug('Inside method GenerateEmailBody:'+eventId);
        Em_Event_vod__c event = [select Id,Owner.Name,owner.firstname,owner.lastname,Topic_vod__r.Name_vod__c,PW_Event_Type__c, Name, Start_Time_vod__c, PW_TP_Event_ID__c,
                                 createddate,PW_Local_Start_Date__c,PW_Local_Start_Time__c,PW_Time_Zone__c,Description_vod__c, Start_Date_vod__c, Start_Time_Local_vod__c, toLabel(Time_Zone_vod__c)NewTimeZoneLabel, toLabel(PW_Time_Zone__c)OldTimeZoneLabel, OwnerID  from EM_Event_vod__c where Id =: eventId];
                                 
        PW_StartTime_EndTime_TimeZone_Utility gettime = new PW_StartTime_EndTime_TimeZone_Utility(true, event);
        
        
        Date dt = gettime.GetLocalStartDate();
        
        string descp = (event.Description_vod__c!=null)?event.Description_vod__c:'';
        String body = 'Event was not sent to Touch Point because of the folllowing error:'+errorMessage+'<br/><br/>';
        body+='<table border = "0" cellpadding = "3" cellspacing="0">';
        body+=       '<tr>';
        body+=       '<td>Event Owner: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+event.owner.firstname+' , '+event.owner.lastname+'</td>';        
        body+=       '</tr>';                
        body+=       '<tr>';
        body+=       '<td>Topic: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+event.Topic_vod__r.Name_vod__c+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Program Type: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+event.PW_Event_Type__c+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Created Date: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+event.createddate.format('EEEE')+','+event.createddate.format('MM/dd/yyyy', UserInfo.getTimeZone().toString())+','+event.createddate.format('HH:mm a', UserInfo.getTimeZone().toString())+','+UserInfo.getTimeZone().getDisplayName()+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Start Date:: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('MM/dd/yyyy')+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Start Time: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+gettime.GetLocalStartTime()+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Time Zone: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+gettime.GetTimeZoneValue()+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Event Id: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+event.Id+'</td>';
        body+=       '</tr>';
        //body+=       '<tr>';
        //body+=       '<td>CL Notes: </td>';
        //body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        //body+=       '<td>'+descp+'</td>';
        //body+=       '</tr>';
        body+=  '</table>';
        return body;
    }
    
    
    //This method generates email body from the event object.
    public static string GenerateEmailBodyForAttendee(Id eventattendeeid, string errorMessage){
        system.debug('Inside method GenerateEmailBody:'+eventattendeeid);
        Event_Attendee_vod__c eventattendee = [SELECT id, First_Name_vod__c, Last_Name_vod__c, Medical_Event_vod__r.EM_Event_vod__r.name,Medical_Event_vod__r.EM_Event_vod__c, Account_vod__c, Contact_vod__c, User_vod__c, Status_vod__c   from Event_Attendee_vod__c where Id =: eventattendeeid ALL ROWS];
        String body = 'Attendee payload not sent to Touch Point because of the folllowing error:'+errorMessage+'<br/><br/>';
        body+='<table border = "0" cellpadding = "3" cellspacing="0">';
        body+=       '<tr>';
        body+=       '<td>First Name: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventattendee.First_Name_vod__c+'</td>';        
        body+=       '</tr>';                
        body+=       '<tr>';
        body+=       '<td>Last Name: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventattendee.Last_Name_vod__c+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Attendee Status: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventattendee.Status_vod__c+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Event Attendee ID: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventattendeeid+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td> Event Name: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventattendee.Medical_Event_vod__r.EM_Event_vod__r.name+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Event Id: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventattendee.Medical_Event_vod__r.EM_Event_vod__c+'</td>';
        body+=       '</tr>';    
        
        body+=  '</table>';
        return body;
    }
    
    //This method generates email body from the event object.
    public static string GenerateEmailBodyForAttachment(Id attachId , string errorMessage){
    
        system.debug('Inside method GenerateEmailBodyForAttachment:'+attachId );
        Attachment  eventattach = [SELECT Id,Name,ParentId FROM Attachment WHERE Id =: attachId ALL ROWS];
        String body = 'Attachment payload not sent to Touch Point because of the folllowing error:'+errorMessage+'<br/><br/>';
        
        body+='<table border = "0" cellpadding = "3" cellspacing="0">';
        body+=       '<tr>';
        body+=       '<td>Filename: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventattach.Name+'</td>';        
        body+=       '</tr>';                
        body+=       '<tr>';
        body+=       '<td>Event Id: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventattach.ParentId +'</td>';
        body+=       '</tr>';
                
        body+=  '</table>';
        return body;
    }
public static void CreateAndSendEmailEventTeamMember(ID eventTeamMemberId, string errorMessage){
        
        system.debug('Inside method CreateAndSendEmailEventTeamMember :'+eventTeamMemberId);
        //PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');

            
            string emailBody='';
            emailBody = GenerateEmailBodyForEventTeamMember(eventTeamMemberId, errorMessage);
            SendEmail(emailBody,calloutsettings, eventTeamMemberId, 'EventTeamMember');
        
    }
    
    
    public static string GenerateEmailBodyForEventTeamMember(Id eventTeamMemberId, string errorMessage){
        system.debug('Inside method GenerateEmailBodyForEventTeamMember:'+eventTeamMemberId);
        EM_Event_Team_Member_vod__c eventTeamMember = [SELECT Id,Role_vod__c,Team_Member_vod__c ,Team_Member_vod__r.Firstname ,Team_Member_vod__r.Lastname ,Team_Member_vod__r.EmployeeNumber FROM EM_Event_Team_Member_vod__c where id=: eventTeamMemberId ALL ROWS];
        String body = 'Event Team Member  payload not sent to Touch Point because of the folllowing error:'+errorMessage+'<br/><br/>';
        body+='<table border = "0" cellpadding = "3" cellspacing="0">';
        body+=       '<tr>';
        body+=       '<td>User First Name: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventTeamMember.Team_Member_vod__r.Firstname +'</td>';        
        body+=       '</tr>';                
        body+=       '<tr>';
        body+=       '<td>User Last Name: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventTeamMember.Team_Member_vod__r.Lastname +'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Team Member Role: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventTeamMember.Role_vod__c+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Event Team Member  ID: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventTeamMemberId+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td> User Id: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventTeamMember.Team_Member_vod__c+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Employee Number: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventTeamMember.Team_Member_vod__r.EmployeeNumber +'</td>';
        body+=       '</tr>';    
        
        body+=  '</table>';
        return body;
    }
    //------------------------------------------------------------------------------------------------------------------------
    public static void CreateAndSendEmailSpeakerQualification(ID speakerQualificationId, string errorMessage){
        
        system.debug('Inside method CreateAndSendEmailSpeakerQualification :'+speakerQualificationId);
        //PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');

            
            string emailBody='';
            emailBody = GenerateEmailBodyForSpeakerQualification(speakerQualificationId, errorMessage);
            SendEmail(emailBody,calloutsettings, speakerQualificationId, 'SpeakerQualification' );
        
    }
    
      public static string GenerateEmailBodyForSpeakerQualification(Id speakerQualificationId, string errorMessage){
        system.debug('Inside method GenerateEmailBodyForSpeakerQualification:'+speakerQualificationId);
        EM_Speaker_Qualification_vod__c speakerQualification = [SELECT Qualification_Name_vod__c,Start_Date_vod__c ,End_Date_vod__c,Speaker_vod__c,Speaker_vod__r.PW_Speaker_ID__c,Id,Name FROM EM_Speaker_Qualification_vod__c where id=: speakerQualificationId ALL ROWS];
        String body = 'Speaker Qualification  payload not sent to Touch Point because of the folllowing error:'+errorMessage+'<br/><br/>';
        body+='<table border = "0" cellpadding = "3" cellspacing="0">';
        body+=       '<tr>';
        body+=       '<td>Speaker Qualification Name: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+speakerQualification.Qualification_Name_vod__c +'</td>';        
        body+=       '</tr>';                
        body+=       '<tr>';
        body+=       '<td>Start Date: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+speakerQualification.Start_Date_vod__c +'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>End Date: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+speakerQualification.End_Date_vod__c+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Speaker Id: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+speakerQualification.Speaker_vod__c+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td> TP Speaker Id : </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+speakerQualification.Speaker_vod__r.PW_Speaker_ID__c+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>Speaker Qualification Id: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+speakerQualificationId +'</td>';
        body+=       '</tr>';    
        
        body+=  '</table>';
        return body;
    }
//----------------------------------------------------------------------------------------------------------------------    
public static void CreateAndSendEmailSpeakerStatus(ID speakerId, string errorMessage){
        
        system.debug('Inside method CreateAndSendEmailSpeakerStatus :'+speakerId);
        //PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');

            
            string emailBody='';
            emailBody = GenerateEmailBodyForSpeakerStatus(speakerId, errorMessage);
            SendEmail(emailBody,calloutsettings, speakerId, 'SpeakerStatus' );
        
    }
     public static string GenerateEmailBodyForSpeakerStatus(Id speakerId, string errorMessage){
        system.debug('Inside method GenerateEmailBodyForSpeakerStatus:'+speakerId);
        EM_Speaker_vod__c speaker = [SELECT Id,Name,PW_Speaker_ID__c,Status_vod__c FROM EM_Speaker_vod__c  where id=: speakerId ALL ROWS];
        String body = 'Speaker Status  payload not sent to Touch Point because of the folllowing error:'+errorMessage+'<br/><br/>';
        body+='<table border = "0" cellpadding = "3" cellspacing="0">';
        body+=       '<tr>';
        body+=       '<td>Speaker  Name: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+speaker.Name +'</td>';        
        body+=       '</tr>';                
        body+=       '<tr>';
        body+=       '<td>Speaker Id: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+speakerId +'</td>';
        body+=       '</tr>';   
        body+=       '<tr>';
        body+=       '<td>Speaker Status : </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+speaker.Status_vod__c+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td> TP Speaker Id : </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+speaker.PW_Speaker_ID__c+'</td>';
        body+=       '</tr>';
   
        
        body+=  '</table>';
        return body;
    }
//------------------------------------------------------------------------------------------------------
public static void CreateAndSendEmailEventStatus(ID eventId, string errorMessage){
        
        system.debug('Inside method CreateAndSendEmailEventStatus :'+eventId);
        //PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');

            
            string emailBody='';
            emailBody = GenerateEmailBodyForEventStatus(eventId, errorMessage);
            SendEmail(emailBody,calloutsettings, eventId, 'EventStatus');
        
    }
         public static string GenerateEmailBodyForEventStatus(Id eventId, string errorMessage){
        system.debug('Inside method GenerateEmailBodyForEventStatus:'+eventId);
        EM_Event_vod__c event = [select id,toLabel(Status_vod__c),Name from EM_Event_vod__c where id=: eventId ALL ROWS];
        String body = 'Event Status  payload not sent to Touch Point because of the folllowing error:'+errorMessage+'<br/><br/>';
        body+='<table border = "0" cellpadding = "3" cellspacing="0">';
        body+=       '<tr>';
        body+=       '<td>Event Id: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventId +'</td>';        
        body+=       '</tr>';                
        body+=       '<tr>';
        body+=       '<td>Event Name: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+event.Name +'</td>';
        body+=       '</tr>';   
        body+=       '<tr>';
        body+=       '<td>Event Status : </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+event.Status_vod__c+'</td>';
        body+=       '</tr>';
       
   
        
        body+=  '</table>';
        return body;
    }
    
    
    
//------------------------------------------------------------------------------------------------------
// Oct 2020
public static void CreateAndSendEmailEventUpdMsg(ID eventId, string errorMessage){
        
        system.debug('Inside method CreateAndSendEmailEventUpdMsg :'+eventId);
        //PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        Pw_Callout_Settings__c calloutsettings = Pw_Callout_Settings__c.getValues('callout');

            
            string emailBody='';
            emailBody = GenerateEmailBodyForEventUpdMsg(eventId, errorMessage);
            SendEmail(emailBody,calloutsettings, eventId, 'EventUPDMsg' );
        
    }
     public static string GenerateEmailBodyForEventUpdMsg(Id eventId, string errorMessage){
        system.debug('Inside method GenerateEmailBodyForEventStatus:'+eventId);
        EM_Event_vod__c event = [select id,toLabel(Status_vod__c),Name from EM_Event_vod__c where id=: eventId ALL ROWS];
        String body = 'Event Update MSG payload not sent to Touch Point because of the following error:'+errorMessage+'<br/><br/>';
        body+='<table border = "0" cellpadding = "3" cellspacing="0">';
        body+=       '<tr>';
        body+=       '<td>Event Id: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+eventId +'</td>';        
        body+=       '</tr>';                
        body+=       '<tr>';
        body+=       '<td>Event Name: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+event.Name +'</td>';
        body+=       '</tr>';   
        body+=       '<tr>';
        body+=       '<td>Event Status : </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+event.Status_vod__c+'</td>';
        body+=       '</tr>';
       
   
        
        body+=  '</table>';
        return body;
    }
    
    // This methods creates a standard email object, sets the properties of the object and calls standard sendemail function to send the email.
    public static void SendEmail(string emailBody,Pw_Callout_Settings__c calloutsettings, ID ModelID, String ModelName){
    
    try
    {
      system.debug('Inside method SendEmail:');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new string[]{};
        String[] ccAddresses = new string[]{};
        if(!string.isEMpty(calloutsettings.PW_To_Email__c))
            toAddresses = calloutsettings.PW_To_Email__c.split(';');
            
        if(!string.isEMpty(calloutsettings.PW_CC_Email__c))
            ccAddresses = calloutsettings.PW_CC_Email__c.split(';');
        mail.setToAddresses(toAddresses); 
        mail.setCCAddresses(ccAddresses);
        mail.setSubject(calloutsettings.callout_failure_subject__c);
        mail.setHTMLBody(emailBody);
        List<Messaging.SendEmailResult> results= Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        if (results[0].success)
        {
         System.debug('The email was sent successfully.');
         PW_Log_Into_CustomLogger.Log(String.ValueOf(results[0]),'Payload Failure Email Sent Successfully', Pw_Logger_Constants.GENERAL_EXCEPTION,emailBody, 0, UserInfo.getUserName(), ModelID, ModelName);
         
        }
        else
        {
         System.debug('The email failed to send: '     + results[0].errors[0].message);
         PW_Log_Into_CustomLogger.Log(String.ValueOf(results[0]),'Payload Failure Email Failed to send ', Pw_Logger_Constants.GENERAL_EXCEPTION,emailBody, 0, UserInfo.getUserName(), ModelID, ModelName);
         
        }       
        
     }
     catch(Exception Ex)
     {
     
         PW_Log_Into_CustomLogger.Log(ex.getStackTraceString(),'Payload Failure Email failed to send. Error: ' + ex.getMessage() , Pw_Logger_Constants.GENERAL_EXCEPTION,emailBody, 0, UserInfo.getUserName(), ModelID, ModelName);
     }
        
               
    }
    
}