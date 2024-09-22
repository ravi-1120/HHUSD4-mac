/*
 * MultiselectController synchronizes the values of the hidden elements to the
 * SelectOption lists.
 */
public class MultiselectController {
    // SelectOption lists for public consumption
    public SelectOption[] leftOptions { get; set; }
    public SelectOption[] rightOptions { get; set; }
    public List<Knowledge__kav> knowledgeList {get;set;}
    public String comment {get;set;}
    public String selectedOp{get;set;}
    public List<Id> memIds {get;set;}
      
    
    public MultiselectController()
    {
        leftOptions = new List<SelectOption>();
        rightOptions = new List<SelectOption>();
        
        queryUser();
    }
    
    public void queryUser()
    {   
        Map<String,User> userMap = new Map<String,User>();
        Map<String,User> userMapSorted = new Map<String,User>();
        Set<ID> pUserIDs = new Set<ID>();
        List<String> orderingList = new List<String>();
        
        for(PermissionSetAssignment puid :[SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Author_Manager'])
        {
         	pUserIDs.add(puid.AssigneeId);   
        }
        
        for( User u : [SELECT id,Name 
                       FROM User 
                       WHERE (isActive = true AND Profile.Name = 'Knowledge Community User') or (id in :pUserIDs) 
                       order by Name
                       limit 500])
        {
            userMap.put(u.Name.toUpperCase()+'|'+u.Id, u);
        }
        orderingList.addAll(userMap.keyset());
        orderingList.sort();
        for ( Integer i= 0;i < orderingList.size(); i++)
        {
            userMapSorted.put(orderingList[i],userMap.get(orderingList[i]));
        }
 
        for(User c : userMapSorted.values())
        {
            leftOptions.add(new SelectOption(c.Id,c.Name));
        } 
    }
    
    // Parse &-separated values and labels from value and 
    // put them in option
    private void setOptions(SelectOption[] options, String value) {
        options.clear();
        String[] parts = value.split('&');
        for (Integer i=0; i<parts.size()/2; i++) {
            options.add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
              EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
        }
    }
    
    public void submitAndProcessApprovalRequest() {
        try
        {
            knowledgeList = [select id, Title,PublishStatus, ArticleNumber,ApprovedUsers__c, Approvers__c, MSD_CORE_ApprStatus__c, VersionNumber, RecordType.Name 
                             from Knowledge__kav 
                             where id in : memIds];
                        
            if(rightOptions.size() > 0 && knowledgeList.size() > 0)
            {
                // Create an approval request for the account
                List<Id> userIds = new List<Id>();
                for(SelectOption so : rightOptions)
                {
                    userIds.add(so.getValue());
                }
                
                for(Knowledge__kav a : knowledgeList)
                {
                    a.Approvers__c = String.join(userIds, ';');
                    a.ApprovedUsers__c = '';
                }
                
                update knowledgeList;
                
                String htmlBody = '<p style="font-family: sans-serif;">Hello,<br/><br/>The following article(s) are awaiting your review. Please click on the article name to be brought to the article management app to view the draft article.<br/><br/>';
                
                htmlBody += '<table style="border: 1px solid #ccc;" cellspacing="0" cellpadding="0"><tr><th style="border: 1px solid #ccc; text-align:left; padding: 0 5px;"> Sr No </th> <th style="border: 1px solid #ccc; text-align:left; padding: 0 5px;"> Title </th> </tr>';
                Integer acount = 0;
                
                List<AppDefinition> appList = [SELECT Id, DurableId, DeveloperName from AppDefinition where DeveloperName = 'Knowledge_Approval'];
                        
                String url = URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/app/'+appList[0].DurableId;
                
                for(Knowledge__kav a : knowledgeList)
                {
                    acount++;
                    List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        
                    for (Id approverId : userIds) {
                        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                        req1.setComments(comment);
                        req1.setObjectId(a.id);
                        
                        // Submit on behalf of a specific submitter
                        req1.setSubmitterId(UserInfo.getUserId()); 
                        
                        // Submit the record to specific process and skip the criteria evaluation
                        req1.setProcessDefinitionNameOrId('Knowledge_Approval');
                        req1.setSkipEntryCriteria(true);
                        req1.setNextApproverIds(new List<Id>{approverId});
        
                        requests.add(req1);
                    }
                    
                    List<Approval.ProcessResult> results = Approval.process(requests);
                    
                    
                    htmlBody += '<tr><td style="border: 1px solid #ccc; padding: 0 5px;">' + acount + '.</td>';
                    
                    htmlBody += '<td style="border: 1px solid #ccc; padding: 0 5px;"><a href="'+ url +'" target="_blank">'+ a.Title +'</a></td></tr>';
                }
                
                List<Approval.UnlockResult> ulrList = Approval.unlock(knowledgeList, false);
                
                // Iterate through each returned result
                for(Approval.UnlockResult ur : ulrList) {
                    if (ur.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully unlocked account with ID: ' + ur.getId());
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : ur.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Account fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                
                htmlBody += '</table><br/><br/>Thanks,<br/> ' + UserInfo.getName() + '</p>';
                
                List<EmailTemplate> emailTemplateList = [select id from EmailTemplate where DeveloperName = 'Approval_Notification'];
                List<User> users = [select id, Email from User where id in : userIds];
                System.debug('emailtemplate picked');
                System.debug(users);
                for(User u : users)
                {
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    //message.setTemplateID(emailTemplateList[0].Id); 
                    message.setSaveAsActivity(false); 
                    message.subject = 'Article(s) Are Pending Your Review';
                    //message.setTargetObjectId(u.Id); //This is important for the merge fields in template to work
                    message.toAddresses = new String[] {u.Email};
                    message.htmlBody = htmlBody;
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
        }
        catch(Exception ex)
        {
            
        }
    }
    
    public void moveToRight()
    {
        List<String> selectedOpList = selectedOp.split('-');
        
        List<SelectOption> lOptions = new List<SelectOption>();
        List<SelectOption> rOptions = new List<SelectOption>();
        for(SelectOption so : leftOptions)
        {
            if(selectedOpList.contains(so.getValue()))
            {
                rOptions.add(so);
            }
            else
            {
                lOptions.add(so);
            }
        }
        
        leftOptions = new List<SelectOption>();
        
        leftOptions.addAll(lOptions);
        rightOptions.addAll(rOptions);
    }
    
    public void moveToLeft()
    {
        List<String> selectedOpList = selectedOp.split('-');
        List<SelectOption> lOptions = new List<SelectOption>();
        List<SelectOption> rOptions = new List<SelectOption>();
        for(SelectOption so : rightOptions)
        {
            if(selectedOpList.contains(so.getValue()))
            {
                lOptions.add(so);
            }
            else
            {
                rOptions.add(so);
            }
        }
        
        rightOptions = new List<SelectOption>();
        
        leftOptions.addAll(lOptions);
        rightOptions.addAll(rOptions);
    }
}