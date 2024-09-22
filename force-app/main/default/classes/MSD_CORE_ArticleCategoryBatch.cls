global class MSD_CORE_ArticleCategoryBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String rtName = 'MSD_CORE_Review';
        String lng = 'en_US';
        String PublishStatus = 'Archived';
        
       return Database.getQueryLocator('select Title, RecordType.DeveloperName, KnowledgeArticleId, MSD_CORE_GenCatgry__c, PublishStatus, MSD_CORE_Subtype__c, (SELECT Id, DataCategoryName FROM DataCategorySelections) from knowledge__kav where IsLatestVersion = true and RecordType.DeveloperName !=: rtName AND Language =: lng and PublishStatus !=: PublishStatus order by Title');
             
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<knowledge__kav> knowledgeList = (List<knowledge__kav>) scope;
        
        Map<String, String> knowledgeRTMap = new Map<String, String>();
        Map<String, String> knowledgeRTOnlineMap = new Map<String, String>();
        
        for(knowledge__kav k : knowledgeList)
        {
            String rtName = '';
            for(knowledge__DataCategorySelection s : k.DataCategorySelections)
            {
                if(s.DataCategoryName == 'MSD_CORE_NSC')
                {
                    rtName += 'NSC;';
                }
                if(s.DataCategoryName == 'MSD_CORE_PCC')
                {
                    rtName += 'PCC;';
                }
                if(s.DataCategoryName == 'MSD_CORE_RMPDC')
                {
                    rtName += 'RMPDC;';
                }
            }
            
            knowledgeRTMap.put(k.Id + '~' + k.Title, rtName);
            knowledgeRTOnlineMap.put(k.KnowledgeArticleId, rtName);
        }
        
        Map<String, String> knowledgeRTErrorMap = new Map<String, String>();
        
        if(knowledgeRTMap.size() > 0)
        {   
            for(String sr : knowledgeRTOnlineMap.keyset())
            {
                String articleId = sr;
                String rtName = knowledgeRTOnlineMap.get(sr);
                
                try
                {
                    if(rtName != null && rtName.trim().length() > 0)
                    {
                        String id = KbManagement.PublishingService.editOnlineArticle (articleId, true);
                        
                        Knowledge__kav k = new Knowledge__kav(id = id,
                                                              MSD_CORE_KnwlArtCat__c = rtName);
                            
                        update k;
                        
                        KbManagement.PublishingService.publishArticle(articleId, true);
                        
                        system.debug('k :::::' + k.Id);
                    }
                }
                catch(Exception ex)
                {
                    knowledgeRTErrorMap.put(sr, ex.getMessage());
                }
            } 
        }
        
        if(knowledgeRTErrorMap.size() > 0)
            logError(knowledgeRTErrorMap);
    }
    
    global static void logError(Map<String, String> knowledgeRTMap)
    {
        Document doc = new Document();
            
        List<Document> docList = [select id, Name, ContentType, Body from Document where Name = 'ArticleRecordTypeLog2'];
        
        if(docList.size() > 0)
            doc = docList[0];
        else
        {
            doc.Name = 'ArticleRecordTypeLog2';
            doc.ContentType = 'text/plain';
            doc.FolderId = [select id from Folder where Name = 'AE Letters' limit 1].id;
        }
        
        String error = '';
        
        for (String sr : knowledgeRTMap.keyset()) {
            error += sr + '~' + knowledgeRTMap.get(sr) + '\n';
        }
        
        if(doc.Body != null)
            doc.Body = Blob.valueOf(doc.Body.toString() + error);
        else
            doc.Body = Blob.valueOf(error);
    
        
        upsert doc;
    }
    
    global static String convertStringToDate(Date dt)
    {
        if(dt != null)
        {
            return dt.month()+'/'+dt.day()+'/'+dt.year();
        }
        
        return null;
    }
    
    global void finish(Database.BatchableContext BC){
    
    }
}