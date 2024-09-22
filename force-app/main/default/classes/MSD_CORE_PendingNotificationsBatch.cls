global class MSD_CORE_PendingNotificationsBatch implements Database.Batchable<sObject>{

    global final Set<String> userIds;

    global MSD_CORE_PendingNotificationsBatch(Set<String> uIds){
        userIds = uIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('select id, email from user where id in : userIds');
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<EmailTemplate> emailTemplateList = [select id from EmailTemplate where DeveloperName = 'Pending_Approval_Notification'];
        for(User user : (List<User>) scope)
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
        }
    }
    
    global void finish(Database.BatchableContext BC){
    
    }
}