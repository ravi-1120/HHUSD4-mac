public class MRK_SpecialtyDCRReport {
    public void runReport(){
    List<Data_Change_Request_Line_vod__c> dclrs = [SELECT Data_Change_Request_vod__c,Field_API_Name_vod__c,Field_Name_vod__c,Id,Name,New_Value_vod__c,Old_Value_vod__c,OwnerId FROM Data_Change_Request_Line_vod__c WHERE Field_Name_vod__c = 'Specialty' AND CreatedDate = YESTERDAY AND Display_Order__c = null];
	Set<Id> dcrIds = new Set<Id>();
    Set<Id> userIds = new Set<Id>();
    List<User> users = new List<User> ();
    Map<Id, User> mapusers = new Map<Id, User>();
    Map<Id, Data_Change_Request_Line_vod__c> mapdclrs = new Map<Id, Data_Change_Request_Line_vod__c>();
    string header = 'DCR#,DCR CreatedDate,Source,Created By,Sales Team,Account Name,Master ID,Old Specialty,New Specialty,Requestor Notes\n ';
    string finalstr = header ;
	for(Data_Change_Request_Line_vod__c dclr: dclrs)
    {
        if(!dcrIds.contains(dclr.Data_Change_Request_vod__c)) {
            dcrIds.add(dclr.Data_Change_Request_vod__c);
            mapdclrs.put(dclr.Data_Change_Request_vod__c,dclr);
            if(!userIds.contains(dclr.OwnerId))
            {
               userIds.add(dclr.OwnerId); 
            }
        }
    }
    
  users = [Select Id,MSD_CORE_Sales_Team_Name__c FROM User WHERE Id IN :userIds];     
  mapusers.putAll(users);
  string emailBody = '<!DOCTYPE html><html><head><style>body, table { font-family: Calibri,sans-serif; border-collapse: collapse; width: 100%;}th { border: 1px solid #dddddd; text-align: left; padding: 8px; background:#00857c; color:white;}td { border: 1px solid #dddddd; text-align: left; padding: 8px;}</style></head><body><p>Hi Team</p><p>Please find the below table for the Specialty DCR request created yesterday.</p><table> <tr> <th>DCR#</th> <th>DCR CreatedDate</th> <th>Source</th> <th>Created By</th> <th>Sales Team</th> <th>Account Name</th> <th>Master ID</th> <th>Old Specialty</th> <th>New Specialty</th><th>Requestor Notes</th></tr>';
  string emailtable = '';
  for(Data_Change_Request_vod__c dcr: [SELECT Id,Name,Account_vod__r.Name,Account_vod__r.Merck_ID_MRK__c,CreatedDate,Application_Source__c,Owner.Name,OwnerId,Notes_vod__c from Data_Change_Request_vod__c where Id IN :dcrIds])
  {   
      user usr = mapusers.get(dcr.OwnerId);
      Data_Change_Request_Line_vod__c dclr = mapdclrs.get(dcr.Id);
      string OldValue = dclr.Old_Value_vod__c == null ? '' : dclr.Old_Value_vod__c;
      string NewValue = dclr.New_Value_vod__c == null ? '' : dclr.New_Value_vod__c;
      string Notes = dcr.Notes_vod__c == null ? '' : dcr.Notes_vod__c;
      string recordString = dcr.Name +','+dcr.CreatedDate+','+dcr.Application_Source__c+','+dcr.Owner.Name+','+usr.MSD_CORE_Sales_Team_Name__c+','+dcr.Account_vod__r.Name+','+dcr.Account_vod__r.Merck_ID_MRK__c+',"'+OldValue+'","'+NewValue+'","'+Notes+'"'+'\n';
      finalstr = finalstr + recordString;	
      string recordhtml = '<tr><td>'+dcr.Name+'</td> <td>'+dcr.CreatedDate+'</td> <td>'+dcr.Application_Source__c+'</td> <td>'+dcr.Owner.Name+'</td><td>'+usr.MSD_CORE_Sales_Team_Name__c+'</td><td>'+dcr.Account_vod__r.Name+'</td><td>'+dcr.Account_vod__r.Merck_ID_MRK__c+'</td> <td>'+OldValue+'</td><td>'+NewValue+'</td><td>'+Notes+'</td></tr>';	  
      emailtable = emailtable + recordhtml;	  	  
  }
  
  Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
  blob csvBlob = Blob.valueOf(finalstr);
  string csvname= 'DCR Specialty Report_'+Datetime.now().format('yyyy_MM_dd')+'.csv';
  csvAttc.setFileName(csvname);
  csvAttc.setBody(csvBlob);
  Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
  String[] toAddresses = new list<string> {'PRCGDGS-Field@merck.com'};
  String[] ccAddresses = new list<string> {'GHHVeeva_MSOTeam@merck.com'};
  String subject ='Daily Specialty DCR Report generated on '+Datetime.now().format('dd-MM-YYYY');
  email.setSubject(subject);
  email.setToAddresses( toAddresses );
  email.setCcAddresses( ccAddresses );
  email.setHtmlBody(emailBody+emailtable+'</table><p> Thanks,<br/>Veeva Support Team</p></body></html>');
  email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
  Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});           
  }
}