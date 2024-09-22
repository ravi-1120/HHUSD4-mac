public class MRK_GetBlankAttendeesPartyID {
    
    public void GetBlankAttendeesPartyID(){
         
        Map<id,List<EM_Attendee_vod__c>> eventAttendeeMap = new Map<id,List<EM_Attendee_vod__c>>();
      	Map<Id, EM_Event_vod__c> eventIdMap = new Map<Id,EM_Event_vod__c>();
    	Map<id, String> eventOwnerEmailMap = new Map<id,String>();
        Map<id, String> eventOwnerNameMap = new Map<id,String>();
 		Map<id, String> eventIDvodMap = new Map<id,String>();
		Map<Id, String> managerMap = new Map<Id, String>();
		Map<Id, Id> ownerMap = new Map<Id, Id>();
        String teamEmail = 'ghhveeva_msoteam@merck.com';
  		List<EM_Attendee_vod__c> Exlist =new List<EM_Attendee_vod__c>();
		Set<Id> OwnerIds = new Set<Id>();
		

		List<EM_Event_vod__c> evnt = [Select id,Name,Owner.Name, Owner.Email,createddate,MSD_CORE_End_Date__c,OwnerId
									  from EM_Event_vod__c 
									  where Status_vod__c ='Closed_vod' 
									  AND  RecordType.name = 'MSD_CORE_Events_Without_Speakers' 
									  and MSD_CORE_End_Date__c >= LAST_N_DAYS:30 
									  AND MSD_CORE_End_Date__c < LAST_N_DAYS:29];

        for(EM_Event_vod__c ev: evnt)
        {
            eventIdMap.put(ev.id,ev);
			ownerMap.put(ev.id,ev.OwnerId);
			OwnerIds.add(ev.OwnerId);
        }
		
		for(User usr: [SELECT id,Manager.Id,Manager.Email FROM user WHERE Id IN :OwnerIds])
		{
			if(!managerMap.containsKey(usr.id)) {
				managerMap.put(usr.id,usr.Manager.Email);
			}
		}
    
       for(EM_Attendee_vod__c atn :[SELECT id, Name, Attendee_Name_vod__c, Attendee_Type_vod__c, Account_vod__r.External_ID_vod__c, 
										Event_vod__r.Owner.Name, Account_vod__r.Name, Account_vod__c, Event_vod__c, Event_vod__r.Owner.Email, Event_vod__r.MSD_CORE_Event_Id__c,Event_vod__r.Event_Display_Name_vod__c,Event_vod__r.Name  
                                     FROM EM_Attendee_vod__c WHERE Event_vod__r.RecordType.name = 'MSD_CORE_Events_Without_Speakers' 
                                     and Event_vod__r.Status_vod__c = 'Closed_vod'and Account_vod__r.Merck_ID_MRK__c = null and 
                                     Attendee_Type_vod__c = 'Account' and Event_vod__c IN:eventIdMap.keyset()]){
            
                if(eventAttendeeMap.containsKey(atn.Event_vod__c)){
                    system.debug('Contains () atn.Event_vod__c'+atn.Event_vod__c);
                    eventAttendeeMap.get(atn.Event_vod__c).add(atn); // add
                    eventOwnerEmailMap.put(atn.Event_vod__c, atn.Event_vod__r.Owner.Email);
                	eventOwnerNameMap.put(atn.Event_vod__c, atn.Event_vod__r.Owner.Name);
                    eventIDvodMap.put(atn.Event_vod__c, atn.Event_vod__r.MSD_CORE_Event_Id__c);
                    
                }else{
                    eventAttendeeMap.put(atn.Event_vod__c,new list<EM_Attendee_vod__c>{atn});// Map
                    eventOwnerEmailMap.put(atn.Event_vod__c, atn.Event_vod__r.Owner.Email);
                	eventOwnerNameMap.put(atn.Event_vod__c, atn.Event_vod__r.Owner.Name);
                    eventIDvodMap.put(atn.Event_vod__c, atn.Event_vod__r.MSD_CORE_Event_Id__c);
                }
        }
       
       List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
       string emailBody = '<!DOCTYPE html><html><head><style>body, table { font-family: Calibri,sans-serif; border-collapse: collapse; width: 100%;}th { border: 1px solid #dddddd; text-align: left; padding: 8px; background:#00857c; color:white;}td { border: 1px solid #dddddd; text-align: left; padding: 8px;}</style></head>';

        
        For(Id evnId:eventAttendeeMap.keySet())
        { 	
            string emailtable = '';
            List<EM_Attendee_vod__c> atnlist = eventAttendeeMap.get(evnId);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            string body = '<body><p>Hi '+eventOwnerNameMap.get(evnId)+'</p><p>You recently added one or more new person accounts to your Veeva CRM database that are not matching with our Customer Master information. This person account is causing an error on an FFM event where they were added as an attendee.    Please follow the below steps to update the Master Id for the person account. Once your request is submitted, the AMS Team will follow-up with you and instruct you on the next steps.<br/><br/><u><b>Steps:</b></u></p><p><span style="color:red;font-weight:bold">Submit a Service Now request by taping this link:</span>  <a href="https://merckprodsn.service-now.com/sp?id=sc_cat_item_guide&sys_id=96c054f31b67e0102cf841d7b04bcbb2">Service Now URL </a></p><p style="text-align:center;">Select the following options when filling out the request: </p><ul><li>Application as <span style="color:red;font-weight:bold">"Veeva CRM"</span></li><li>Request Type as <span style="color:red;font-weight:bold">"US"</span></li><li>Related module - <span style="color:red;font-weight:bold">"EM Events"</span></li><li>Type of Request - <span style="color:red;font-weight:bold">"FFM Requests/Issues"</span></li><li>Description: <span style="color:red;font-weight:bold">"Please update the master Id for the attendees in the following Events &lt;&lt;Event IDs&gt;&gt;"</span></li></ul><p><b><i>Note: Please replace the &lt;&lt;Event IDs&gt;&gt; with all the Event IDs in the below table.</i></b></p><table> <tr> <th>Event ID</th> <th>Event Name</th> <th>Attendee ID</th> <th>Attendee Name</th></tr>';
			
            for(EM_Attendee_vod__c alist : atnlist)
            {
                
                emailtable += '<tr><td>'+alist.Event_vod__r.MSD_CORE_Event_Id__c+'</td> <td>'+alist.Event_vod__r.Name+'</td> <td>'+alist.Name+'</td> <td>'+alist.Attendee_Name_vod__c+'</td></tr>';
            }
            system.debug('emailtable: '+emailtable);
            List<String> toAddress = new List<String>{eventOwnerEmailMap.get(evnId)};
            String[] ccAddresses = new list<string> {teamEmail,managerMap.get(ownerMap.get(evnId))};
            mail.setSubject('FFM Event - '+eventIdMap.get(evnId).Name+ ' is added with attendees without the Master ID');
            mail.setToAddresses(toAddress);
            mail.setCcAddresses( ccAddresses);
            mail.setHtmlBody(emailBody + body +emailtable+'</table><p> Thanks,<br/>Veeva Support Team</p></body></html>'); 
            mails.add(mail);
            }
       
       	If(mails!=null)
        {
        Messaging.sendEmail(mails);
        
        }
       }
    
	}