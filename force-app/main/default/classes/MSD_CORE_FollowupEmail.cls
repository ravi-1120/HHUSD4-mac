public with sharing class MSD_CORE_FollowupEmail implements TriggersMVN.HandlerInterface{
    public void handle() { 
        List<EmailMessage> messages = Trigger.new;
        List<String> emailTempDevNames = new List<String>{'External_Other_Company_AE_Email_1','External_Other_Company_AE_Email_2'};
        Map<String,EmailTemplate> emailTempMap = new Map<String,EmailTemplate>();    
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        for(EmailTemplate e : [Select Id,name,Subject,Description,HtmlValue,DeveloperName,Body,BrandTemplateId  from EmailTemplate where DeveloperName in :emailTempDevNames and IsActive = true])
        {
            emailTempMap.put(e.DeveloperName,e);
        }
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'service_center@merck.com' limit 1];
        
        Contact con = [select id from Contact limit 1];
        
        for(EmailMessage m : messages) 
        {
            String subject = m.Subject;
            if(!emailTempMap.isEmpty() && emailTempMap.size() == 2)
            {
                EmailTemplate mainEmailTemplate = emailTempMap.get(emailTempDevNames[0]);
                EmailTemplate followupEmailTemplate = emailTempMap.get(emailTempDevNames[1]);
                
                if(!String.isBlank(m.ParentId) && followupEmailTemplate != null && con != null && m.EmailTemplateId == mainEmailTemplate.Id && m.EmailTemplateId != followupEmailTemplate.Id )
                {
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.setUseSignature(false); 
                    message.setBccSender(false); 
                    message.setSaveAsActivity(true);
                    if ( owea.size() > 0 ) 
                    {
                        message.setOrgWideEmailAddressId(owea.get(0).Id);
                    }  
                    message.toAddresses = new String[] {m.ToAddress};
                    message.setWhatId(m.ParentId); //This is important for the merge fields in template to work
                    message.setTemplateID(followupEmailTemplate.Id); 
                    message.setTargetObjectId(con.Id); //This is important to send with  template
                    message.setTreatTargetObjectAsRecipient(false);
                    msgList.add(message);
                }
            }
        }
        
        if(msgList.size() > 0)
        {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(msgList);
            
            if (results[0].success) 
            {
                System.debug('The email was sent successfully.');
            } else {
                System.debug('The email failed to send: ' +  results[0].errors[0].message);
            }
        }
    }
}