global class MSD_CORE_ScheduleExpirationNotifications implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        List<Knowledge__kav> kList = [SELECT Id, Title, AssignedToId, MSD_CORE_Assigned_To__c FROM Knowledge__kav 
                                        where MSD_CORE_ExpiryDate__c <=: (date.Today().addDays(30)) ]; 
    
        if(kList.size() > 0)
        {
            Set<String> userIds = new Set<String>();
            for(Knowledge__kav k : kList)
            {
                if(k.AssignedToId != null)
                    userIds.add(k.AssignedToId);
                if(k.MSD_CORE_Assigned_To__c != null)
                    userIds.add(k.MSD_CORE_Assigned_To__c);
            }
            
            system.debug('userIds :::::' + userIds);
            
            MSD_CORE_ExpirationNotificationsBatch b = new MSD_CORE_ExpirationNotificationsBatch(userIds);
            Database.executeBatch(b, 1);
            
            /*List<EmailTemplate> emailTemplateList = [select id from EmailTemplate where DeveloperName = 'Article_expiration_notification'];
            for(User user : [select id, email from user where id in : userIds])
            {
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTemplateID(emailTemplateList[0].Id); 
                message.setSaveAsActivity(false); 
                message.setTargetObjectId(user.Id);
                message.toAddresses = new String[] {user.Email};
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                
                if (results[0].success) 
                {
                    System.debug('The email was sent successfully.');
                } else {
                    System.debug('The email failed to send: ' +  results[0].errors[0].message);
                }
            }*/
        }
    }
}