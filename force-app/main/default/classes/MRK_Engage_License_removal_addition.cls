public class MRK_Engage_License_removal_addition Implements Schedulable{
    
    public void execute(SchedulableContext sc) {
        
	Engage_license_removal_for_inactive_users();   
    Engage_license_addition_for_active_users_Sales();
    Engage_license_addition_for_active_users_Medical();
        
    }
    
    Public void Engage_license_removal_for_inactive_users()
    {
        
        Try{
            User[] InactiveUsers = [SELECT Id, Engage_Group_Provisioning_Status_vod__c, Engage_Group_Request_vod__c, Engage_Group_vod__c, IsActive FROM User WHERE  IsActive = False AND Engage_Group_vod__c != null];
            System.debug ('USER ID ******************'+InactiveUsers);
            //System.debug('Previous Values:'+Engage_Group_Provisioning_Status_vod__c);
            if(!InactiveUsers.isempty()){
                
                for(User record: InactiveUsers) 
               	{
                    if (record.Engage_Group_Request_vod__c == Null){
            record.Engage_Group_Provisioning_Status_vod__c = 'Retry_Request_vod';
          }
          else{
            record.Engage_Group_Request_vod__c = null;
          }
          }
          //Insert Results and Handle Errors
          List<String> failedRecords = new List<String>();
                
                Database.SaveResult[] srList = Database.update(InactiveUsers, false); 
                system.debug('after DB result');
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully Deactivated User Engage License. USER ID: ' + sr.getId());
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            String failedRecord ='Record ID: '+sr.getId() +',Error: '+err.getMessage();
                            failedRecords.add(failedRecord);
                            System.debug('The following error has occurred.');
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('User fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                string emailtable = '';
                 Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                String allEmail = System.Label.Email_FailedRecords;
                List<String> toAddressList = allEmail.Split(',');
                   if (!failedRecords.isEmpty()) {
                String tableContent = '<p>Hi</p><p>The The Engage License Removal for the below records failed.<br/><br/></p><table style ="border-collapse:collapse; border: 1px solid black;"><tr><th style ="border: 1px solid black;padding:4px;">Record ID</th> <th style ="border: 1px solid black;padding:4px;">Error Message</th></tr>';
                for (String failedRecord : failedRecords) {
                    List<String> recordDetails = failedRecord.split(',');
                    tableContent += '<tr><td style ="border: 1px solid black; padding: 8px;">' + recordDetails[0].substring(recordDetails[0].indexOf(':') + 2) + '</td><td style ="border: 1px solid black; padding: 8px;">' + recordDetails[1].substring(recordDetails[1].indexOf(':') + 2) + '</td></tr>';
               }
                tableContent += '</table>';
                for(String toAddress :toAddressList)
                {
                String[] toAddresses = new String[]{toAddress}; // Add recipient email address
                email.setToAddresses(toAddresses);
                email.setSubject('Engage License Removal Failed Records Update Report');
                email.setHtmlBody(tableContent);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                }
               }
            }
            
            
        }Catch(Exception e){
            
            System.debug('you have an exceptional Error:' + e.getMessage());    
            
        }
    }
    
    Public void Engage_license_addition_for_active_users_Sales()
    {
        Map<Id,User> UserMap = new Map<Id,User>();
        
        Set<String> Sales_Profile = new Set<String>();
        String salesprof = System.Label.MRK_Sales_Profiles;
        List<String> Splitted_Sales_profiles =salesprof.Split(',');
       Sales_Profile.addAll(Splitted_Sales_profiles);
         System.debug('Sales_Profile'+Sales_Profile);
        
        Try{
            User[] activeUsers = [SELECT Id, Engage_Group_Provisioning_Status_vod__c, Engage_Group_Request_vod__c, Engage_Group_vod__c, IsActive FROM User WHERE IsActive = True AND Engage_Group_vod__c = null and Profile_Name_vod__c IN:Sales_Profile];
            System.debug ('USER ID ******************'+activeUsers);
            //System.debug('Previous Values:'+Engage_Group_Provisioning_Status_vod__c);
            
             
             List<User> all_user = new List<User>();
           
            if(!activeUsers.isempty()){
            
                for(User u : activeUsers)
                {
                    UserMap.put(u.id,u);
                }
               
                List<User> Sales_user_List = [SELECT Id, Engage_Group_Provisioning_Status_vod__c, Engage_Group_Request_vod__c, Engage_Group_vod__c, IsActive FROM User WHERE Id in:UserMap.keySet()];
                    if(!Sales_user_List.isempty()){
                for(User record: Sales_user_List) 
               	{
                    if (record.Engage_Group_Request_vod__c == Null){
                    record.Engage_Group_Request_vod__c ='Offline and Online Users No Desktop Sharing';
					 record.Engage_Group_Provisioning_Status_vod__c = 'Retry_Request_vod';
          }
          
                    all_user.add(record);
          }
                    }
             
                
          //Insert Results and Handle Errors
          List<String> failedRecords = new List<String>();
                Database.SaveResult[] srList = Database.update(all_user, false); 
                system.debug('after DB result');
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully Activated Sales User Engage License. USER ID: ' + sr.getId());
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            String failedRecord ='Record ID: '+sr.getId() +',Error: '+err.getMessage();
                            failedRecords.add(failedRecord);
                            System.debug('The following error has occurred.');
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('User fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                string emailtable = '';
                 Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                String allEmail = System.Label.Email_FailedRecords;
                List<String> toAddressList = allEmail.Split(',');
                   if (!failedRecords.isEmpty()) {
               String tableContent = '<p>Hi</p><p>The The Engage License Assignment for the below records failed.<br/><br/></p><table style ="border-collapse:collapse; border: 1px solid black;"><tr><th style ="border: 1px solid black;padding:4px;">Record ID</th> <th style ="border: 1px solid black;padding:4px;">Error Message</th></tr>';
                for (String failedRecord : failedRecords) {
                    List<String> recordDetails = failedRecord.split(',');
                    tableContent += '<tr><td style ="border: 1px solid black; padding: 8px;">' + recordDetails[0].substring(recordDetails[0].indexOf(':') + 2) + '</td><td style ="border: 1px solid black; padding: 8px;">' + recordDetails[1].substring(recordDetails[1].indexOf(':') + 2) + '</td></tr>';
               }
                tableContent += '</table>';
                for(String toAddress :toAddressList)
                {
                String[] toAddresses = new String[]{toAddress}; // Add recipient email address
                email.setToAddresses(toAddresses);
                email.setSubject('Engage License Assignment Failed Records Update Report (Sales Users)');
                email.setHtmlBody(tableContent);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                
               }
            }
            }
            
            
        }Catch(Exception e){
            
            System.debug('you have an exceptional Error:' + e.getMessage());    
            
        }
    }
    
    Public void Engage_license_addition_for_active_users_Medical()
    {
        Map<Id,User> UserMap = new Map<Id,User>();
        
        Set<String> Med_Profiles = new Set<String>();
        String CustomeLabelValuesMed_Profile = System.Label.MRK_Med_Profiles;
        List<String> Splitted_MEd_profiles =CustomeLabelValuesMed_Profile.Split(',');
       Med_Profiles.addAll(Splitted_MEd_profiles);
        System.debug('Medical_Profile'+Med_Profiles);
        
        Try{
            User[] activeUsers = [SELECT Id, Engage_Group_Provisioning_Status_vod__c, Engage_Group_Request_vod__c, Engage_Group_vod__c, IsActive FROM User WHERE IsActive = True AND Engage_Group_vod__c = null and Profile_Name_vod__c IN:Med_Profiles];
            System.debug ('USER ID ******************'+activeUsers);
            //System.debug('Previous Values:'+Engage_Group_Provisioning_Status_vod__c);
            
             
             List<User> all_user = new List<User>();
           
            if(!activeUsers.isempty()){
            
                for(User u : activeUsers)
                {
                    UserMap.put(u.id,u);
                }
               
                List<User> Sales_user_List = [SELECT Id, Engage_Group_Provisioning_Status_vod__c, Engage_Group_Request_vod__c, Engage_Group_vod__c, IsActive FROM User WHERE Id in:UserMap.keySet()];
                    if(!Sales_user_List.isempty()){
                for(User record: Sales_user_List) 
               	{
                    if (record.Engage_Group_Request_vod__c == Null){
                    record.Engage_Group_Request_vod__c ='Offline and Online Users';
					 record.Engage_Group_Provisioning_Status_vod__c = 'Retry_Request_vod';
          }
          
                    all_user.add(record);
          }
                    }
             
                
          //Insert Results and Handle Errors
          List<String> failedRecords = new List<String>();
                Database.SaveResult[] srList = Database.update(all_user, false); 
                system.debug('after DB result');
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully Activated Medical User Engage License. USER ID: ' + sr.getId());
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            String failedRecord ='Record ID: '+sr.getId() +',Error: '+err.getMessage();
                            failedRecords.add(failedRecord);
                            System.debug('The following error has occurred.');
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('User fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                   string emailtable = '';
                 Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                String allEmail = System.Label.Email_FailedRecords;
                List<String> toAddressList = allEmail.Split(',');
                   if (!failedRecords.isEmpty()) {
               String tableContent = '<p>Hi</p><p>The Engage License Assignment for the below records failed.<br/><br/></p><table style ="border-collapse:collapse; border: 1px solid black;"><tr><th style ="border: 1px solid black;padding:4px;">Record ID</th> <th style ="border: 1px solid black;padding:4px;">Error Message</th></tr>';
                for (String failedRecord : failedRecords) {
                    List<String> recordDetails = failedRecord.split(',');
                    tableContent += '<tr><td style ="border: 1px solid black; padding: 8px;">' + recordDetails[0].substring(recordDetails[0].indexOf(':') + 2) + '</td><td style ="border: 1px solid black; padding: 8px;">' + recordDetails[1].substring(recordDetails[1].indexOf(':') + 2) + '</td></tr>';
               }
                tableContent += '</table>';
                for(String toAddress :toAddressList)
                {
                String[] toAddresses = new String[]{toAddress}; // Add recipient email address
                email.setToAddresses(toAddresses);
                email.setSubject('Engage License Assignment Failed Records Update Report (Medical Users)');
                email.setHtmlBody(tableContent);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                
               }
            }
            }
            
            
        }Catch(Exception e){
            
            System.debug('you have an exceptional Error:' + e.getMessage());    
            
        }
    }

}