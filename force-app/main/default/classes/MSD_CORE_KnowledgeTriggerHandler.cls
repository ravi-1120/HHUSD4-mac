public class MSD_CORE_KnowledgeTriggerHandler 
{
    public static boolean executeTrigger = true;   
    public static void copyFromTemplate(List<Knowledge__kav> newList)
    {
        Set<String> templateNameSet = new Set<String>();
        map<String, Knowledge__kav> templateMap = new Map<String, Knowledge__kav>();
        
        map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>([select id, Name from RecordType where sObjectType = 'Knowledge__kav']);
        
        for(Knowledge__kav k : newList)
        {
            if(recordTypeMap.containskey(k.RecordTypeId))
                templateNameSet.add(recordTypeMap.get(k.RecordTypeId).Name + ' Template');
        }
        
        if(templateNameSet.size() > 0)
        {
            Schema.DescribeSObjectResult r = Knowledge__kav.sObjectType.getDescribe();
            
            List<String> apiNames =  new list<String>();
            
            for(string apiName : r.fields.getMap().keySet()){
                if(r.fields.getMap().get(apiName).getDescribe().isUpdateable() && 
                   (r.fields.getMap().get(apiName).getDescribe().getType()+'' == 'STRING' || 
                    r.fields.getMap().get(apiName).getDescribe().getType()+'' == 'TEXTAREA'))
                    apiNames.add(apiName);
            }
            
            for(Knowledge__kav template : database.query('select ' + String.join(apiNames, ',') + ' from Knowledge__kav where Title in : templateNameSet'))
            {
                templateMap.put(template.Title, template);
            }
            
            for(Knowledge__kav k : newList)
            {
                if(recordTypeMap.containskey(k.RecordTypeId) && templateMap.containskey(recordTypeMap.get(k.RecordTypeId).Name + ' Template'))
                {
                    Knowledge__kav template = templateMap.get(recordTypeMap.get(k.RecordTypeId).Name + ' Template');
                    
                    for(string apiName : apiNames){
                        
                        if(k.get(apiName) == null && template.get(apiName) != null)
                        {
                            String vl = (String) template.get(apiName);
                            //k.put(apiName, vl.replaceAll('<span style="color: red;"[^>]*>(.*?)</span>','').replaceAll('<span style="color: #e74c3c;"[^>]*>(.*?)</span>','').replaceAll('<span style="color: #c0392b;"[^>]*>(.*?)</span>',''));
                            k.put(apiName, vl);
                        }
                    }
                }
            }
        }
    }
    
    
    public static void updateOwner(List<Knowledge__kav> newList)
    {
        for(Knowledge__kav k : newList)
        {
            if(k.OwnerId != k.AssignedToId)
                k.Title = k.AssignedToId;
        }
    }
    
    
    public static boolean emailSent = false;
    public static void alertTemplateChange(List<Knowledge__kav> articlelist, Map<Id, Knowledge__kav> oldoppmap)
    {
        if(MSD_CORE_KnowledgeTriggerHandler.emailSent == false)
        {
            Id devRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('Template').getRecordTypeId();
            list<string> str = new list<string>();
            MSD_CORE_KnowledgeTriggerHandler.emailSent = true;
            if(articlelist.size() > 0)
            {
                if(articlelist[0].RecordTypeId == devRecordTypeId)
                {
                    String ArticleTitle = articlelist[0].Title;
                    Integer index = ArticleTitle.lastIndexOf(' ');
                    String RecordType = ArticleTitle.substring(0,index);
                    // Id RecordTyp = Schema.Knowledge__kav.getRecordTypeInfosByName(RecordType).get().getRecordTypeId();
            
                    List<Knowledge__kav> kList = [select id, MSD_CORE_Assigned_To__r.Email, AssignedTo.Email from Knowledge__kav where RecordType.Name =: RecordType];
                     for(Knowledge__kav a : kList){
                    str.add(a.MSD_CORE_Assigned_To__r.Email);
                    }
                    set<string>strSet = new set<string>(str);
                    system.debug('content is'+strset);
                    strSet.remove('');
                    strSet.remove(null);
                    str = new list<string>(strSet);
                    Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
                    Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('Knowledge__kav');
                    Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
                    
                    Map<String,Schema.FieldSet> fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap();
                    
                    Schema.DescribeSObjectResult r = Knowledge__kav.sObjectType.getDescribe();
                    List<String> apiNames =  new list<String>();
                    
                    for(Schema.SObjectField apiName : r.fields.getMap().values()){
                        Schema.DescribeFieldResult field = apiName.getDescribe();
                        
                        if(field.isUpdateable() && articlelist[0].get(field.getName()) != oldoppmap.get(articlelist[0].Id).get(field.getName()))
                            apiNames.add(field.getLabel());
                    }
                    
                    if(apiNames.size() > 0)
                    {
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.toAddresses = str;
                            message.optOutPolicy = 'FILTER';
                        message.subject = 'Article(s) impacted by template update.';
                       
                        List<AppDefinition> appList = [SELECT Id, DurableId, DeveloperName from AppDefinition where DeveloperName = 'Knowledge'];
                        
                        String url = URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/app/'+appList[0].DurableId;
                        
                        String htmlBody = 'The following template has been updated. Please make the necessary changes when you review and update your articles. <br/><br/><b>' +'<a href="'+url+'">'+ articlelist[0].Title+'</a>' + '</b><br/><br/>';
                        
                        htmlBody += 'Fields updated <br/>';
                                                
                        for(String s : apiNames)
                        {
                            htmlBody += '<b>' + s + '</b><br/>';
                        }
                        
                         message.htmlbody = htmlBody;
                                                
                        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
                            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                        
                        if (results[0].success) 
                        {
                            System.debug('The email was sent successfully.');
                        } else 
                        {
                            System.debug('The email failed to send: ' + results[0].errors[0].message);
                        }
                    }
                }
            }
        }
    }
    
    
    public  static void createComments(List<Knowledge__kav> newList){
        executeTrigger = false;
        System.debug(newList);   
        List<MSD_CORE_Comments__c> listCommentsoutput = new List<MSD_CORE_Comments__c>(); 
        For (Knowledge__kav k : newList){
            If(k.MSD_CORE_General_Cmnt__c != Null){
                MSD_CORE_Comments__c comment = new MSD_CORE_Comments__c();
                comment.MSD_CORE_Comment__c = k.MSD_CORE_General_Cmnt__c; 
                comment.MSD_CORE_Type__c = 'Generic Comment';
                comment.MSD_CORE_Knowledge__c = k.Id;
                insert comment; 
                listCommentsoutput = [SELECT CreatedBy.Name,MSD_CORE_Comment__c, CreatedDate
                                      FROM MSD_CORE_Comments__c
                                      WHERE MSD_CORE_Type__c = 'Generic Comment' and MSD_CORE_Knowledge__c = :k.Id];
                k.MSD_CORE_General_Cmnt_Conversation__c = '';
                for(MSD_CORE_Comments__c lco : listCommentsoutput ){
                    k.MSD_CORE_General_Cmnt_Conversation__c = k.MSD_CORE_General_Cmnt_Conversation__c + '<br/>'+ lco.CreatedBy.Name+ ' - ' + lco.MSD_CORE_Comment__c + ' - '+ lco.CreatedDate.format('MM/dd/yyyy hh:mm a'); 
                }
                k.MSD_CORE_General_Cmnt__c = '';
            }           
            If(k.MSD_CORE_After_Call_Work_Cmnt__c != Null ){
                MSD_CORE_Comments__c comment = new MSD_CORE_Comments__c();
                comment.MSD_CORE_Comment__c = k.MSD_CORE_After_Call_Work_Cmnt__c; 
                comment.MSD_CORE_Type__c = 'After Call Work';
                comment.MSD_CORE_Knowledge__c = k.Id;
                insert comment; 
                listCommentsoutput = [SELECT CreatedBy.Name,MSD_CORE_Comment__c, CreatedDate
                                      FROM MSD_CORE_Comments__c
                                      WHERE MSD_CORE_Type__c = 'After Call Work' and MSD_CORE_Knowledge__c = :k.Id];
                k.MSD_CORE_AfterCallWork_Cmnt_Conversation__c = '';
                for(MSD_CORE_Comments__c lco : listCommentsoutput ){
                    k.MSD_CORE_AfterCallWork_Cmnt_Conversation__c    =  k.MSD_CORE_AfterCallWork_Cmnt_Conversation__c   + '<br/>' +  lco.CreatedBy.Name+ ' - ' + lco.MSD_CORE_Comment__c + ' - '+ lco.CreatedDate.format('MM/dd/yyyy hh:mm a');
                }
                k.MSD_CORE_After_Call_Work_Cmnt__c = '';
                
            }
            If(k.MSD_CORE_Information_Cmnt__c != Null){
                MSD_CORE_Comments__c comment = new MSD_CORE_Comments__c();
                comment.MSD_CORE_Comment__c = k.MSD_CORE_Information_Cmnt__c; 
                comment.MSD_CORE_Type__c = 'Inform';
                comment.MSD_CORE_Knowledge__c = k.Id;
                insert comment; 
                listCommentsoutput = [SELECT CreatedBy.Name, MSD_CORE_Comment__c, CreatedDate 
                                      FROM MSD_CORE_Comments__c
                                      WHERE MSD_CORE_Type__c = 'Inform' and MSD_CORE_Knowledge__c = :k.Id];
                k.MSD_CORE_Information_Cmnt_Conversation__c = '';
                for(MSD_CORE_Comments__c lco : listCommentsoutput ){                    
                    k.MSD_CORE_Information_Cmnt_Conversation__c = k.MSD_CORE_Information_Cmnt_Conversation__c   + '<br/>' + lco.CreatedBy.Name+ ' - ' + lco.MSD_CORE_Comment__c + ' - ' + lco.CreatedDate.format('MM/dd/yyyy hh:mm a');
                }
                k.MSD_CORE_Information_Cmnt__c = '';
            }
            
            If(k.MSD_CORE_Preview_Cmnt__c != Null){
                MSD_CORE_Comments__c comment = new MSD_CORE_Comments__c();
                comment.MSD_CORE_Comment__c = k.MSD_CORE_Preview_Cmnt__c; 
                comment.MSD_CORE_Type__c = 'Preview';
                comment.MSD_CORE_Knowledge__c = k.Id;
                insert comment; 
                listCommentsoutput = [SELECT CreatedBy.Name,MSD_CORE_Comment__c, CreatedDate 
                                      FROM MSD_CORE_Comments__c
                                      WHERE MSD_CORE_Type__c = 'Preview' and MSD_CORE_Knowledge__c = :k.Id];
                k.MSD_CORE_Preview_Cmnt_Conversation__c = '';
                for(MSD_CORE_Comments__c lco : listCommentsoutput ){                   
                    k.MSD_CORE_Preview_Cmnt_Conversation__c = k.MSD_CORE_Preview_Cmnt_Conversation__c + '<br/>' + lco.CreatedBy.Name+ ' - ' + lco.MSD_CORE_Comment__c + ' - ' + lco.CreatedDate.format('MM/dd/yyyy hh:mm a');
                }
                k.MSD_CORE_Preview_Cmnt__c = '';                  
            }
            If(k.MSD_CORE_Questions_Comment__c != Null){
                MSD_CORE_Comments__c comment = new MSD_CORE_Comments__c();
                comment.MSD_CORE_Comment__c = k.MSD_CORE_Questions_Comment__c; 
                comment.MSD_CORE_Type__c = 'Questions';
                comment.MSD_CORE_Knowledge__c = k.Id;
                insert comment; 
                listCommentsoutput = [SELECT CreatedBy.Name,MSD_CORE_Comment__c, CreatedDate
                                      FROM MSD_CORE_Comments__c
                                      WHERE MSD_CORE_Type__c = 'Questions' and MSD_CORE_Knowledge__c = :k.Id];
                k.MSD_CORE_Qstn_Cmnt_Convo__c = '';
                for(MSD_CORE_Comments__c lco : listCommentsoutput ){                    
                    k.MSD_CORE_Qstn_Cmnt_Convo__c = k.MSD_CORE_Qstn_Cmnt_Convo__c   + '<br/>' +  lco.CreatedBy.Name+ ' - ' + lco.MSD_CORE_Comment__c + ' - ' + lco.CreatedDate.format('MM/dd/yyyy hh:mm a');
                }
                k.MSD_CORE_Questions_Comment__c = '';
            }
            If(k.MSD_CORE_Instruction_Comment__c != Null){
                MSD_CORE_Comments__c comment = new MSD_CORE_Comments__c();
                comment.MSD_CORE_Comment__c = k.MSD_CORE_Instruction_Comment__c; 
                comment.MSD_CORE_Type__c = 'Instruction/Background';
                comment.MSD_CORE_Knowledge__c = k.Id;
                insert comment; 
                listCommentsoutput = [SELECT CreatedBy.Name,MSD_CORE_Comment__c, CreatedDate
                                      FROM MSD_CORE_Comments__c
                                      WHERE MSD_CORE_Type__c = 'Instruction/Background' and MSD_CORE_Knowledge__c = :k.Id];
                k.MSD_CORE_Instruct_Cmnt_Conversation__c = '';
                for(MSD_CORE_Comments__c lco : listCommentsoutput ){                    
                    k.MSD_CORE_Instruct_Cmnt_Conversation__c = k.MSD_CORE_Instruct_Cmnt_Conversation__c + '<br/>' + lco.CreatedBy.Name+ ' - ' + lco.MSD_CORE_Comment__c + ' - ' +lco.CreatedDate.format('MM/dd/yyyy hh:mm a');
                }
                k.MSD_CORE_Instruction_Comment__c = '';
            }
            
        }
        executeTrigger = true;
    }
    
      public  static void assingOldVersionToCase(List<Knowledge__kav> newList){
        Map<Knowledge__kav, Case> csMap = new Map<Knowledge__kav, Case>();
        
        if(newList.size() > 0)
        {
            List<Knowledge__kav> kList = [select id, Language, VersionNumber, Title, KnowledgeArticleID
                                          from Knowledge__kav 
                                          where KnowledgeArticleId =: newList[0].KnowledgeArticleId
                                          and id !=: newList[0].Id];
                                          //and PublishStatus = 'Published'];
            
            if(kList.size() > 0)
            {
                Set<String> caseIds = new Set<String>();
                Set<String> exisCaseIds = new Set<String>();
                for(Knowledge__kav k : kList)
                {
                    caseIds.add(k.Id);
                }
                
                for(Case c : [select id, MSD_CORE_External_Id__c from Case where MSD_CORE_External_Id__c in : caseIds])
                {
                    exisCaseIds.add(c.MSD_CORE_External_Id__c);
                }
                
                for(Knowledge__kav k : kList)
                {
                    if(!exisCaseIds.contains(k.Id))
                    {
                        Case cs = new Case(MSD_CORE_External_Id__c = k.Id,
                                           Customer_Type_MVN__c = 'CONSUMER',
                                           MSD_CORE_Is_Archive_Article_Case__c = True,
                                           Origin = 'Phone',
                                           Status = 'Cancelled',
                                           RecordTypeId = [select id from RecordType where sObjectType = 'Case' and DeveloperName = 'Interaction_Closed_MVN'].Id);
                        
                        csMap.put(k, cs);
                    }
                }
                
                if(csMap.size() > 0)
                {
                    UtilitiesMVN.isAnonymizing = true;
                    
                    insert csMap.values();
                    
                    system.debug('csMap.values() :::::' + csMap.values()[0].Id);
                    
                    List<Case_Document_MVN__c> cdList = new List<Case_Document_MVN__c>();
                    for(Knowledge__kav key : csMap.keyset())
                    {
                        Case_Document_MVN__c cd = new Case_Document_MVN__c(Case_MVN__c = csMap.get(key).Id,
                                                                           Document_Language_MVN__c = key.Language,
                                                                           Document_ID_MVN__c = key.Id,
                                                                           Document_Major_Version_MVN__c = key.VersionNumber+'',
                                                                           Document_Title_MVN__c = key.Title,
                                                                           Knowledge_Article_Version_ID_MVN__c = key.Id,
                                                                           MSD_CORE_External_Id__c = (key.Id + '' + key.KnowledgeArticleID));
                        cdList.add(cd);
                    }
                    
                    if(cdList.size() > 0)
                        insert cdList;
                }
            }
        }
    }
    
    
    public  static void updateAssignedTo(List<Knowledge__kav> newList, Map<Id, Knowledge__kav> oldmap){
        for(Knowledge__kav k : newList)
        {
            if(k.AssignedToId != null)
                k.MSD_CORE_Assigned_To__c = k.AssignedToId;
        }
    }
    
      
    public static void updateApprovalStatus(List<Knowledge__kav> newList){
        
        for(knowledge__kav k : newList){
            k.MSD_CORE_ApprStatus__c = 'Pending Submission  ';
        }
    }
}