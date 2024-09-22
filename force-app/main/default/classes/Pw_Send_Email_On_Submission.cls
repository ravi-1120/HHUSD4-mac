///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_Call_Service_Bus_API
///   Description:    This class sends an email when an event is submitted
///   Author:         Khushbu Khetan                  
///   Notes:          Conatins methods which will send email
///   Date: 18-12-2017
///   Revision History:
///-----------------------------------------------------------------
public class Pw_Send_Email_On_Submission {


    //This method checks whether the email functionality is set on/off for the org.If set to on calls the methods to generate email body and send an email.
    public static void CreateAndSendEmail(ID eventId){
        
        system.debug('Inside method CreateAndSendEmail :'+eventId);
        PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        if(regSettings.PW_Send_Email_on_Event_Submission__c){
            if(string.isEmpty(regSettings.PW_To_Email__c) && string.isEmpty(regSettings.PW_CC_Email__c ))
                return;
            
            string emailBody='';
            emailBody = GenerateEmailBody(eventId);
            emailBody+= GenerateSpeakerTable(eventId);
            SendEmail(emailBody,regSettings, eventID);
        }
    }
    
    //This method generates email body from the event object.
    public static string GenerateEmailBody(Id eventId){
        system.debug('Inside method GenerateEmailBody:'+eventId);
        Em_Event_vod__c event = [select Id,Owner.Name,owner.firstname,owner.lastname,Topic_vod__r.Name_vod__c,PW_Event_Type__c, Name, Start_Time_vod__c, PW_TP_Event_ID__c,
                                 createddate,PW_Local_Start_Date__c,PW_Local_Start_Time__c,PW_Time_Zone__c,Description_vod__c, Start_Date_vod__c, Start_Time_Local_vod__c, toLabel(Time_Zone_vod__c)NewTimeZoneLabel, toLabel(PW_Time_Zone__c)OldTimeZoneLabel, OwnerID  from EM_Event_vod__c where Id =: eventId];
                                 
        PW_StartTime_EndTime_TimeZone_Utility gettime = new PW_StartTime_EndTime_TimeZone_Utility(true, event);
        
        
        Date dt = gettime.GetLocalStartDate();

        string descp = (event.Description_vod__c!=null)?event.Description_vod__c:'';
        String body = 'A new event '+event.Name+' has been submitted to PW :<br/><br/>';
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
        body+=       '<td>Veeva Row Id: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+event.Id+'</td>';
        body+=       '</tr>';
        body+=       '<tr>';
        body+=       '<td>CL Notes: </td>';
        body+=       '<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>';
        body+=       '<td>'+descp+'</td>';
        body+=       '</tr>';
        body+=  '</table>';
        return body;
    }
    
    //This method generates email body for the speakers and gets data from the speaker object.
    public static string GenerateSpeakerTable(Id eventId){
    system.debug('Inside method GenerateSpeakerTable:'+eventId);
        string body ='';
        body+='<br/><br/>Speakers:<br/><br/>';
        body+='<table border = "1" cellpadding = "3" cellspacing="0">';
        body+=       '<tr>';
        body+=          '<th>PW ID</td>';
        body+=          '<th>Name</td>';  
        body+=          '<th>Priority</td>';
        body+=          '<th>Speaker Recruited</td>';
        body+=      '</tr>'   ;  
        
        List<EM_Event_Speaker_vod__c> eventSpeakerLst = [Select Speaker_vod__r.PW_Speaker_ID__c,Speaker_Name_vod__c,PW_Speaker_Priority__c,PW_Speaker_Recruited__c from EM_Event_Speaker_vod__c where Event_vod__c =: eventId];
        
        for(EM_Event_Speaker_vod__c speaker : eventSpeakerLst)
        {
            string pwId = (speaker.Speaker_vod__r.PW_Speaker_ID__c!=null)?speaker.Speaker_vod__r.PW_Speaker_ID__c:'';
            string priority = (speaker.PW_Speaker_Priority__c!=null)?speaker.PW_Speaker_Priority__c:'';
            string recruited = (speaker.PW_Speaker_Recruited__c)?'Yes':'No';
            body+=       '<tr>';
            body+=       '<td>'+pwId+'</td>';
            body+=       '<td>'+speaker.Speaker_Name_vod__c+'</td>';
            body+=       '<td>'+priority+'</td>';
            body+=       '<td>'+recruited+'</td>';
            body+=       '<tr>';
        }
        body+=  '</table>';
        return body;
    }
    
    // This methods creates a standard email object, sets the properties of the object and calls standard sendemail function to send the email.
    public static void SendEmail(string emailBody,PW_General_Settings__c regSettings, ID eventID){
    
    try
    {
         system.debug('Inside method SendEmail:');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new string[]{};
        String[] ccAddresses = new string[]{};
        if(!string.isEMpty(regSettings.PW_To_Email__c))
            toAddresses = regSettings.PW_To_Email__c.split(';');
            
        if(!string.isEMpty(regSettings.PW_CC_Email__c))
            ccAddresses = regSettings.PW_CC_Email__c.split(';');
        mail.setToAddresses(toAddresses); 
        mail.setCCAddresses(ccAddresses);
        mail.setSubject(regSettings.PW_Email_Subject__c);
        mail.setHTMLBody(emailBody);
        List<Messaging.SendEmailResult> results= Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        
        
        if (results[0].success)
        {
         System.debug('The email was sent successfully.');
         PW_Log_Into_CustomLogger.Log(String.ValueOf(results[0]),'Email Sent Successfully', Pw_Logger_Constants.GENERAL_EXCEPTION,emailBody, 0, UserInfo.getUserName(), eventID , 'NA');
         
        }
        else
        {
         System.debug('The email failed to send: '     + results[0].errors[0].message);
         PW_Log_Into_CustomLogger.Log(String.ValueOf(results[0]),'Email Failed to send ', Pw_Logger_Constants.GENERAL_EXCEPTION,emailBody, 0, UserInfo.getUserName(), eventID , 'NA');
         
        }   
        
     }
     catch(Exception ex)
     {
     
         PW_Log_Into_CustomLogger.Log(ex.getStackTraceString(),'Email Failed to send. Error: ' + ex.getMessage() , Pw_Logger_Constants.GENERAL_EXCEPTION,emailBody, 0, UserInfo.getUserName(), eventID , 'NA');
     }
     
               
    }
    
}