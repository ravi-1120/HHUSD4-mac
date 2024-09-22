public class MRK_FFMEventAttachmentVerify {
public void EventVerify(){
    List<EM_Event_vod__c> events = [SELECT Id,Name,MSD_CORE_Event_Id__c,Start_Time_vod__c,Owner.alias,Owner.firstname,Owner.email,PW_Location_Type__c,
	                                (SELECT Id FROM ContentDocumentLinks)
                                    FROM EM_Event_vod__c  
                                    WHERE RecordType.name = 'MSD_CORE_Events_Without_Speakers' 
                                    AND PW_Location_Type__c IN ('Remote','Hospital','Office','Clinic') 
                                    AND  Start_Time_vod__c = LAST_N_DAYS:35 
                                    AND  Start_Time_vod__c < LAST_N_DAYS:20 
                                    AND Status_vod__c = 'Closed_vod'
                                    ORDER BY Start_Time_vod__c ASC];
    Map<Id, EM_Event_vod__c> mpevents = new Map<Id, EM_Event_vod__c>(events);
    Set<Id> eventIds = (mpevents).keySet();
	Set<Id> eventIdsAtt = new Set<Id>();
	Set<Id> eventIdswcd = new Set<Id>();
    Map<String, Integer> attCounts = new Map<String, Integer>();
    Integer count = 1;
	for(EM_Event_vod__c event: events)
    {
        if(!event.ContentDocumentLinks.isEmpty()) {
           eventIdswcd.add(event.Id);
        } 
    }
    for(Attachment att: [SELECT parentId, Id from Attachment where parent.type ='EM_Event_vod__c' and parentId IN :eventIds])
    {
        if(attCounts.containsKey(att.parentId)) {
            attCounts.put(att.parentId,attCounts.get(att.parentId)+1);
        }else{
		     eventIdsAtt.add(att.parentId);
             attCounts.put(att.parentId,count);	 
        }
    }
    if(eventIdswcd.size()>0)
    {
    for(ContentDocumentLink cdl: [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :eventIdswcd])
    {
        if(attCounts.containsKey(cdl.LinkedEntityId)) {
            attCounts.put(cdl.LinkedEntityId,attCounts.get(cdl.LinkedEntityId)+1);
        }else{
		     eventIdsAtt.add(cdl.LinkedEntityId);
             attCounts.put(cdl.LinkedEntityId,count);	 
        }
    }
    }
	Set<Id> result = eventIds.clone();
	result.removeall(eventIdsAtt);
	for (Id eventIdwoAtt : result)
	{
	 attCounts.put(eventIdwoAtt,0);	 
	}
    Messaging.SingleEmailMessage[] msg = new Messaging.SingleEmailMessage[]{};
    for(String key : attCounts.keySet())
    {
       String eventid = key;
       Integer attcount = attCounts.get(key);
       EM_Event_vod__c event = mpevents.get(eventid);
       Boolean isError = false;
       isError = ((event.PW_Location_Type__c == 'Remote' && attcount <2) || (event.PW_Location_Type__c !='Remote' && attcount <2)) ? true : false;
       if(isError){
        System.debug(event.Name+' not having required attachments.'+ ' | Owner Name: '+event.owner.firstname+ ' | Owner Email:' +event.owner.email);
        
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String[] toAddresses = new list<string> {event.owner.email};  //event.owner.email
        String[] ccAddresses = new list<string> {'veeva_campaigns@merck.com'};
        String subject = event.Name+' not having required attachments';
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        email.setCcAddresses( ccAddresses );
        email.setHtmlBody('<html> <head> <meta http-equiv=Content-Type content="text/html; charset=us-ascii"> <style>p.MsoNormal,li.MsoNormal,div.MsoNormal{margin:0;font-size:11.0pt;font-family:"Calibri",sans-serif}p.MsoListParagraph,li.MsoListParagraph,div.MsoListParagraph{mso-style-priority:34;margin-top:0;margin-right:0;margin-bottom:0;margin-left:.5in;font-size:11.0pt;font-family:"Calibri",sans-serif}div.WordSection1{page:WordSection1}ol{margin-bottom:0}ul</style> </head> <body style="word-wrap:break-word"> <div class=WordSection1> <p class=MsoNormal> Dear '+event.Owner.firstname+': </p> <p class=MsoNormal> The below closed Veeva Event appears to be inconsistent with compliance requirements, as it does not have the correct number of required attachments.&nbsp; Please access the event in Veeva and correct. </p> <p class=MsoNormal> &nbsp; </p> <p class=MsoNormal> If you included all required documentation in one attachment, no further action is required. </p> <p class=MsoNormal> &nbsp; </p> <table border=0 cellspacing=0 cellpadding=0 style="width:100%;border-collapse:collapse"> <tr> <td valign=top style="width:25%;border:solid white 1.0pt;border-bottom:solid white 3.0pt;background:#00857c;padding:.05in .1in .05in .1in"> <p class=MsoNormal> <b>Event Name</b> </p> </td> <td valign=top style="width:20%;border-top:solid white 1.0pt;border-left:none;border-bottom:solid white 3.0pt;border-right:solid white 1.0pt;background:#00857c;padding:.05in .1in .05in .1in"> <p class=MsoNormal> <b><span style="color:black">Event Id</span></b> </p> </td> <td valign=top style="width:15%;border-top:solid white 1.0pt;border-left:none;border-bottom:solid white 3.0pt;border-right:solid white 1.0pt;background:#00857c;padding:.05in .1in .05in .1in"> <p class=MsoNormal> <b><span style="color:black">Start Date</span></b> </p> </td> <td valign=top style="width:15%;border-top:solid white 1.0pt;border-left:none;border-bottom:solid white 3.0pt;border-right:solid white 1.0pt;background:#00857c;padding:.05in .1in .05in .1in"> <p class=MsoNormal> <b><span style="color:black">Event Type</span></b> </p> </td> <td valign=top style="width:20%;border-top:solid white 1.0pt;border-left:none;border-bottom:solid white 3.0pt;border-right:solid white 1.0pt;background:#00857c;padding:.05in .1in .05in .1in"> <p class=MsoNormal> <b><span style="color:black">Current Attachment Count</span></b> </p> </td> </tr> <tr> <td valign=top style="border:solid white 1.0pt;border-top:0;background:#cbd9d7;padding:.05in .1in .05in .1in"> <p class=MsoNormal> <span style="color:black">'+event.Name+'</span> </p> </td> <td valign=top style="border-top:0;border-left:none;border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:#cbd9d7;padding:.05in .1in .05in .1in"> <p class=MsoNormal> <span style="color:black">'+event.MSD_CORE_Event_Id__c+'</span> </p> </td> <td valign=top style="border-top:0;border-left:none;border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:#cbd9d7;padding:.05in .1in .05in .1in"> <p class=MsoNormal> <span style="color:black">'+event.Start_Time_vod__c.format('dd-MMM-yyyy')+'</span> </p> </td> <td valign=top style="border-top:0;border-left:none;border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:#cbd9d7;padding:.05in .1in .05in .1in"> <p class=MsoNormal> <span style="color:black">'+event.PW_Location_Type__c+'</span> </p> </td> <td valign=top style="border-top:0;border-left:none;border-bottom:solid white 1.0pt;border-right:solid white 1.0pt;background:#cbd9d7;padding:.05in .1in .05in .1in"> <p class=MsoNormal> <span style="color:black">'+attcount+'</span> </p> </td> </tr> </table> <p class=MsoNormal> &nbsp; </p> <p class=MsoNormal> Note: </p> <ul style="margin-top:0in" type=disc> <li class=MsoListParagraph style="margin-left:-.25in;mso-list:l1 level1 lfo3">In-Person and Virtual FFMs require at least 2 attachments: FFM Sign-in Sheet and all Itemized Receipt(s). </li> <li class=MsoNormal style="margin-left:-.25in;mso-list:l1 level1 lfo3">If a Virtual FFM required the use of telephone (no video), a CTL Acknowledgement email will need to be attached to the vFFM. </li><li class=MsoNormal style="margin-left:-.25in;mso-list:l1 level1 lfo3">To add attachments to a Closed FFM/vFFM your CTL will need to Unlock the event.</li><li class=MsoNormal style="margin-left:-.25in;mso-list:l1 level1 lfo3">If you have provided the appropriate attachments to this Closed event, please disregard this email. </li> </ul> <p class=MsoNormal> &nbsp; </p> <p class=MsoNormal> Do not reply to this email.&nbsp; This mailbox is not monitored.&nbsp; For assistance, please contact Field 1<sup>st</sup>&nbsp; at 877-FIELD-1 ST Option 2 (877-343-5317). </p> <p class=MsoNormal> &nbsp; </p> </div> </body></html>');
        msg.add(email);
       } 
    }
     Messaging.SendEmailResult [] r = Messaging.sendEmail(msg); 
    }
}