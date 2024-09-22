public class MSD_CORE_SubmitForApprovalController 
{
    public List<Knowledge__kav> knowledgeList {get;set;}
    public SelectOption[] userList {get;set;}
    public SelectOption[] selectedUserList {get;set;}
    public String comment {get;set;}
    public integer count {get;set;}
    public List<RecallApprovalWrapper> articleList {get;set;}
    public List<Id> memIds {get;set;}
    public String Errormsg {get;set;} 
    public String ProfileName {get; set;}
    Public String AppStatus {get; set;}
    
    public MSD_CORE_SubmitForApprovalController(ApexPages.StandardSetController controller)
    {	
        Errormsg = '';
        knowledgeList = new List<Knowledge__kav>();
        articleList = new List<RecallApprovalWrapper>();
        User PName =   [SELECT Profile_Name_vod__c FROM User WHERE ID =: UserInfo.getUserId()];
        ProfileName = PName.Profile_Name_vod__c;
        
        userList = new List<SelectOption>();
        selectedUserList = new List<SelectOption>();
        
        memIds = new List<Id>();
        for (Knowledge__kav mem : (List<Knowledge__kav>)controller.getSelected()){ 
            memIds.add(mem.Id);
        }
        
        if(ApexPages.currentPage().getParameters().get('id') != null)
            memIds.add(ApexPages.currentPage().getParameters().get('id'));
        
        knowledgeList = [select id, Title,PublishStatus, ArticleNumber, MSD_CORE_ApprStatus__c, VersionNumber, RecordType.Name 
                         from Knowledge__kav
                         where id in : memIds];
        
        /*for(Knowledge__kav kL: KnowledgeList ) {
            if(kL.PublishStatus == 'Published')
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Published Articles can not be send for Approval agian.'));
                }*/
        
        if (knowledgeList.size()>0){
            for(integer i=0; i<knowledgeList.size();) {
                System.debug(knowledgeList[i].PublishStatus);
                AppStatus = knowledgeList[i].MSD_CORE_ApprStatus__c;
                if(knowledgeList[i].PublishStatus == 'Online'){
                    knowledgeList.remove(i);
                    Errormsg = 'Yes'; 
                    
                    System.debug('removing');
                }
                i= i+1;
            }
        }
        ProcessInstanceWorkitem[] workItems = [ SELECT Id, ProcessInstance.TargetObjectId
                            FROM ProcessInstanceWorkitem 
                            WHERE ProcessInstance.TargetObjectId in : memIds
                            AND ProcessInstance.Status = 'Pending' ]; 
        
        List<String> artIds = new List<String>();
        for(ProcessInstanceWorkitem p : workItems)
        {
            artIds.add(p.ProcessInstance.TargetObjectId);
        }
        
        count = 0;
        for (Knowledge__kav mem : knowledgeList)
        { 
            if(artIds.contains(mem.Id))
            {
                articleList.add(new RecallApprovalWrapper(true, mem));
                count++;
            }
            else
                articleList.add(new RecallApprovalWrapper(false, mem));
        }
                            
        queryUser();
    }
    
    public void queryUser()
    {
        for (User c : [select id, Name from User order by Name limit 500]) {
            userList.add(new SelectOption(c.Id, c.Name));
        }
    }
    
    public void recallApprval()
    {
        List<MSD_CORE_Comments__c> commentList = new List<MSD_CORE_Comments__c>();
        
        for (Knowledge__kav mem : knowledgeList){ 
            ProcessInstanceWorkitem[] workItems = [ SELECT Id, ProcessInstance.TargetObjectId
                            FROM ProcessInstanceWorkitem 
                            WHERE ProcessInstance.TargetObjectId =: mem.Id
                            AND ProcessInstance.Status = 'Pending' ]; 
                            
            if(workItems.size() > 0)
            {
                for(ProcessInstanceWorkitem piwi : workItems)
                {
                    Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();  
                    pwr.setAction('Removed');
                    pwr.setWorkItemId(piwi.id);
                    
                    Approval.ProcessResult result = Approval.process(pwr);
                    
                    mem.MSD_CORE_ApprStatus__c = 'Pending Submission';
                    
                    if(comment != null && comment.length() > 0)
                    {
                        commentList.add(new MSD_CORE_Comments__c(MSD_CORE_Knowledge__c = mem.Id,
                                                                          MSD_CORE_Comment__c = comment,
                                                                          MSD_CORE_Type__c = 'Recall'));
                    }
                }
            }
        }
        
        if(commentList.size() > 0)
            insert commentList;
        
        if(knowledgeList.size() > 0)
            update knowledgeList;
    }
    
    public class RecallApprovalWrapper 
    {
        public boolean isValid {get;set;}
        public Knowledge__kav article {get;set;}
        
        public RecallApprovalWrapper(boolean isValid, Knowledge__kav article)
        {
            this.isValid = isValid;
            this.article = article;
        }
    }
    // commented linesss
}