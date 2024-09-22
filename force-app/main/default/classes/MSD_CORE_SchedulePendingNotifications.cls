global class MSD_CORE_SchedulePendingNotifications implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        List<ProcessInstanceWorkItem> kList = [SELECT Id, ActorId, ProcessInstance.TargetObjectId 
                                      FROM ProcessInstanceWorkItem 
                                      WHERE ProcessInstance.Status = 'Pending'
                                      AND CreatedDate <=: Date.today().addDays(-3)]; 
    
        if(kList.size() > 0)
        {
            Set<String> userIds = new Set<String>();
            for(ProcessInstanceWorkItem k : kList)
            {
                if(k.ActorId != null)
                    userIds.add(k.ActorId);
            }
            
            system.debug('userIds :::::' + userIds);
            
            MSD_CORE_PendingNotificationsBatch b = new MSD_CORE_PendingNotificationsBatch(userIds);
            Database.executeBatch(b, 1);
            
            /*List<EmailTemplate> emailTemplateList = [select id from EmailTemplate where DeveloperName = 'Pending_Approval_Notification'];
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