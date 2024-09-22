public class MSD_CORE_KnowledgeController 
{
    public String controllerValue {get;set;}
    public String kid {get;set;}
    public String articleId {get;set;}
    public String userId {get;set;}
    public String x {get;set;}
    public List<Knowledge__kav> approveRecords {get;set;}
    
    public String getURL()
    {
        return URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    public String getMailURL()
    {
        List<AppDefinition> appList = [SELECT Id, DurableId, DeveloperName from AppDefinition where DeveloperName = 'Knowledge_Approval'];
                        
        String url = URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/app/'+appList[0].DurableId;
                        
        return url;
    }
    
    public String getStatus()
    {
        List<ProcessInstanceWorkItem> piList = [select id, ProcessInstance.Status from ProcessInstanceWorkItem
                                                where ProcessInstance.TargetObjectId =: articleId
                                                and ActorId =: userId
                                                order by CreatedDate desc];
        
        if(piList.size() > 0)
            return piList[0].ProcessInstance.Status;
        
        return null;
    }
   
    public List<Knowledge__kav> getKnowledgeList()
    {
        Set<String> knowledgeIds = new Set<String>();
        
        for(ProcessInstanceWorkItem piwi : [SELECT ProcessInstance.TargetObjectId FROM ProcessInstanceWorkItem 
                                             WHERE ProcessInstance.Status = 'Pending' 
                                             AND ActorId = : controllerValue
                                             AND CreatedDate <=: Date.today().addDays(-3)])
        {
            knowledgeIds.add(piwi.ProcessInstance.TargetObjectId);
        }
                                        
        List<Knowledge__kav> myItems = [SELECT Id, Title FROM Knowledge__kav where id in : knowledgeIds];
        
        return myItems;
    }
    
    public List<Knowledge__kav> getKnowledgeRecord(String recordId)
    {
        
        
                                      
        List<Knowledge__kav> myItems = [SELECT Id, Title FROM Knowledge__kav where id = :recordId];
        approveRecords=myItems;
        return myItems;
    }
    
    
    public List<Knowledge__kav> getKnowledgeExpirationList()
    {
        Set<String> knowledgeIds = new Set<String>();
        
        List<Knowledge__kav> myItems = [SELECT Id, Title FROM Knowledge__kav 
                                        where (AssignedToId =: controllerValue
                                        or MSD_CORE_Assigned_To__c =: controllerValue) 
                                        and MSD_CORE_ExpiryDate__c <=: (date.Today().addDays(30)) ];
  
        return myItems;
    }
    
    
    @AuraEnabled
    public static String getKnowledgeArticleId(String recordId)
    {
        return [SELECT Id, KnowledgeArticleId FROM Knowledge__kav 
                                        where id =: recordId].KnowledgeArticleId;
    }

    /* @AuraEnabled
    public static String  getRedirectingURLForPrintArticles(String recordId)
    {
        return [SELECT MSD_CORE_Redirect_URL_for_Print_Article__c
                FROM MSD_CORE_Knowledge_Redirect_URL__c].MSD_CORE_Redirect_URL_for_Print_Article__c;
    }*/
    
    @AuraEnabled
    public static String approveKnowledgeWithChanges(String targetObjectId, String comments, String status)
    {
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments(comments);
        Set<String> userIds = new Set<String>();
        
        if(status == 'Rejected'){
            req2.setAction('Reject'); //This is the action that is approve in your case, you can set it to Reject also
        }
        else
        {
            userIds.add(UserInfo.getUserId());
            req2.setAction('Approve'); //This is the action that is approve in your case, you can set it to Reject also
        }
        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        
        // Use the ID from the newly created item to specify the item to be worked  
            
        req2.setWorkitemId(getWorkItemId(targetObjectId));
        
        // Submit the request for approval  
        Approval.ProcessResult result2 =  Approval.process(req2);            
        
        String statusChk = 'In';
        
        for(ProcessInstance pi : [Select Id, Status, LastModifiedBy.Name, LastModifiedById
                                  from ProcessInstance
                                  where TargetObjectId =: targetObjectId
                                  order by LastModifiedDate desc])
        {
            //if(pi.Status == 'Approved')
            //{
            //}
            if(!userIds.contains(pi.LastModifiedById))
            {
                if(pi.Status == 'Pending')
                {
                    statusChk = 'Submitted for Approval';
                }
                else if(pi.Status == 'Rejected')
                {
                    statusChk = 'Rejected';
                    break;
                }
                userIds.add(pi.LastModifiedById);
            }
        }
        
        /*for(ProcessInstance pi : [Select Id, Status, LastModifiedBy.Name, LastModifiedById
                                  from ProcessInstance
                                  where TargetObjectId =: targetObjectId])
        {
            if(pi.Status == 'Rejected' && !userIds.contains(pi.LastModifiedById))
            {
                statusChk = 'Rejected';
                break;
            }
            else if(pi.Status == 'Pending')
            {
                statusChk = 'Submitted for Approval';
            }
        }*/
        
        
        if(statusChk == 'In')
            statusChk = 'Pending Final Approvals';
            
        system.debug('statusChk :::::' + statusChk);
        
        List<Knowledge__kav> kList = [select id, MSD_CORE_Assigned_To__c, Approvers__c, AssignedToId,
                                      MSD_CORE_Assigned_To__r.Email, AssignedTo.Email
                                      from Knowledge__kav 
                                      where id =: targetObjectId];
        
        if(kList.size() > 0)
        {
            Knowledge__kav k = new Knowledge__kav(id = targetObjectId,
                                                  MSD_CORE_ApprStatus__c = statusChk);                                   
            if(status == 'Approved')
            {
                k.MSD_CORE_ExpiryDate__c = date.today().addDays(364);                          
                k.MSD_CORE_Approval_Date__c = date.today();
                k.ApprovedUsers__c +=  UserInfo.getUserId();
            }
            
            if(kList[0].Approvers__c != null)
                k.Approvers__c = kList[0].Approvers__c.replace(UserInfo.getUserId(), '');
            
            update k;
            List<EmailTemplate> emailTemplateList;
            if(status == 'Approved'){
                emailTemplateList = [select id from EmailTemplate where DeveloperName = 'Approval_NotificationVF'];}
            if(status == 'Rejected'){
                emailTemplateList = [select id from EmailTemplate where DeveloperName = 'Reject_NotificationVF'];}
            String userId = kList[0].MSD_CORE_Assigned_To__c;
            String userEmail = kList[0].MSD_CORE_Assigned_To__r.Email;
            
            if(userId == null)
            {
                userId = kList[0].AssignedToId;
                userEmail = kList[0].AssignedTo.Email;
            }
            
            if(userId != null)
            {
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTemplateID(emailTemplateList[0].Id); 
                message.setSaveAsActivity(false); 
                message.setWhatId(k.Id); //This is important for the merge fields in template to work
                message.setTargetObjectId(userId);
                message.toAddresses = new String[] {userEmail};
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
        
        return 'Success';
    }
    
    
    public static Id getWorkItemId(Id targetObjectId)
    {
        Id retVal = null;

        for(ProcessInstanceWorkitem workItem  : [Select p.Id from ProcessInstanceWorkitem p
                                                 where p.ProcessInstance.TargetObjectId =: targetObjectId
                                                 and ActorId =: UserInfo.getUserId()])
           
        {
            retVal  =  workItem.Id;
        }

        return retVal;
    }
    
    
    @AuraEnabled
    public static boolean checkProcessInstance(Id targetObjectId)
    {
        List<ProcessInstanceWorkitem> workItemList = [Select p.Id from ProcessInstanceWorkitem p
                                                      where p.ProcessInstance.TargetObjectId =: targetObjectId
                                                      and ActorId =: UserInfo.getUserId()];
           
        if(workItemList.size() > 0){
            return true;
        }

        return false;
    }
    
    
    public static List<ProcessInstanceWorkitem> getWorkItemIdWithoutCurrentUser(Id targetObjectId)
    {
        
        return [Select Id, ProcessInstance.Status, ActorId 
                from ProcessInstanceWorkitem
                where ProcessInstance.TargetObjectId =: targetObjectId
                and Id !=: getWorkItemId(targetObjectId)];
    }
    
    @AuraEnabled
    public static boolean articleActions(String articleId)
    {
        List<Knowledge__kav> knowledgeList = [SELECT Id, MSD_CORE_Assigned_To__c, AssignedToId FROM Knowledge__kav 
                                              where id =: articleId];
        
        if(knowledgeList.size() > 0 && knowledgeList[0].AssignedToId != null && knowledgeList[0].MSD_CORE_Assigned_To__c != knowledgeList[0].AssignedToId)
        {
            knowledgeList[0].MSD_CORE_Assigned_To__c = knowledgeList[0].AssignedToId;
            update knowledgeList;
            
            return true;
        }
                             
        return false;
    }
    
    public static String publishArticle(String articleVersionId)
    {
        List<Knowledge__kav> kList = [select Title, RecordType.DeveloperName, KnowledgeArticleId, MSD_CORE_GenCatgry__c, PublishStatus, MSD_CORE_Subtype__c from knowledge__kav
                                      where Id =: articleVersionId];
        
        if(kList.size() > 0)
        {
            String articleId = kList[0].KnowledgeArticleId;
            
            kList = [select Title, RecordType.DeveloperName, KnowledgeArticleId, MSD_CORE_GenCatgry__c, PublishStatus, MSD_CORE_Subtype__c from knowledge__kav
                      where KnowledgeArticleId =: articleId];
            
            KbManagement.PublishingService.publishArticle(articleId, true);
        }
        else{
            return 'No record';
        }        
        
        return 'Success';
    }
    
    @AuraEnabled
    public static boolean approveArtiles(String articleId)
    {
        List<Knowledge__kav> knowledgeList = [SELECT Id, MSD_CORE_ApprStatus__c FROM Knowledge__kav 
                                              where id =: articleId];
        
        if(knowledgeList.size() > 0)
        {
            for(Knowledge__kav k : knowledgeList)
            {
                k.MSD_CORE_ApprStatus__c = 'Approved';
            }
            
            update knowledgeList;
            
            return true;
        }
                             
        return false;
    }



}