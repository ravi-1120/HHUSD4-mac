global class MSD_CORE_ArticleRecordTypeBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String rtName = 'MSD_CORE_Review';
        String lng = 'en_US';
        String PublishStatus = 'Archived';
        
       return Database.getQueryLocator('select Title, RecordType.DeveloperName, KnowledgeArticleId, MSD_CORE_GenCatgry__c, PublishStatus, MSD_CORE_Subtype__c, (SELECT Id, DataCategoryName FROM DataCategorySelections) from knowledge__kav where IsLatestVersion = true and RecordType.DeveloperName !=: rtName AND Language =: lng and PublishStatus !=: PublishStatus order by Title');
             
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<knowledge__kav> knowledgeList = (List<knowledge__kav>) scope;
        
        Map<String, String> knowledgeRTMap = new Map<String, String>();
        Map<String, String> knowledgeRTIdNameMap = new Map<String, String>();
        Map<String, String> knowledgeRTOnlineMap = new Map<String, String>();
        Map<String, String> knowledgeAKMap = new Map<String, String>();
        
        list<String> lstCSVLines;
        
        Map<String, String> knowledgeTypeMap = new Map<String, String>();
        Map<String, String> knowledgeCategoryMap = new Map<String, String>();
        Map<String, String> knowledgeRTNameMap = new Map<String, String>();
        
        for(Document d : [select id, Name, body from Document where Name = 'Type-Category.csv' or Name = 'RT-ASSIGNMENTS FOR ERRORS.csv'])
        {
            if(d.Name == 'Type-Category.csv')
            {
                lstCSVLines = d.body.toString().split('\n');
                
                for(Integer i = 1; i < lstCSVLines.size(); i++){
                    list<String> csvRowData = lstCSVLines[i].split(',');
                  
                    knowledgeTypeMap.put(String.valueOf(csvRowData[0]).trim(), String.valueOf(csvRowData[1]).trim());
                    knowledgeCategoryMap.put(String.valueOf(csvRowData[0]).trim(), String.valueOf(csvRowData[2]).trim());
                }
            }
            else 
            {
                lstCSVLines = d.body.toString().split('\n');
                
                for(Integer i = 1; i < lstCSVLines.size(); i++){
                    list<String> csvRowData = lstCSVLines[i].split(',');
                  
                    knowledgeRTNameMap.put(String.valueOf(csvRowData[0]).trim(), String.valueOf(csvRowData[2]).trim());
                }
            }
        }
        
        for(RecordType rt : [select id, Name from RecordType where sObjectType = 'Knowledge__kav'])
        {
            knowledgeRTIdNameMap.put(rt.Name, rt.Id);
        }
        
        for(knowledge__kav k : knowledgeList)
        {
            String rtName = '';
            String kCName = '';
            
            for(knowledge__DataCategorySelection s : k.DataCategorySelections)
            {
                if(s.DataCategoryName == 'MSD_CORE_NSC')
                {
                    kCName += 'NSC;';
                }
                if(s.DataCategoryName == 'MSD_CORE_PCC')
                {
                    kCName += 'PCC;';
                }
                if(s.DataCategoryName == 'MSD_CORE_RMPDC')
                {
                    kCName += 'RMPDC;';
                }
            }
            
            if(k.MSD_CORE_Subtype__c != 'Product/Medical Information' && k.MSD_CORE_Subtype__c != 'Product/Medical Information' && 
               !k.Title.startsWith('Addl Info'))
            {
                for(knowledge__DataCategorySelection s : k.DataCategorySelections)
                {
                    if(s.DataCategoryName == 'MSD_CORE_NSC')
                    {
                        rtName += knowledgeRTIdNameMap.get('NSC Standard');
                    }
                }
            }
            
            if(k.MSD_CORE_Subtype__c == 'Product/Medical Information' || k.MSD_CORE_Subtype__c == 'Product/Medical Information')
            {
                for(knowledge__DataCategorySelection s : k.DataCategorySelections)
                {
                    if(s.DataCategoryName == 'MSD_CORE_NSC')
                    {
                        rtName += knowledgeRTIdNameMap.get('NSC Medical');
                    }
                }
            }
            
            if(k.MSD_CORE_GenCatgry__c != 'Q&A Script' && 
               !k.Title.startsWith('Addl Info'))
            {
                for(knowledge__DataCategorySelection s : k.DataCategorySelections)
                {
                    if(s.DataCategoryName == 'MSD_CORE_PCC')
                    {
                        rtName += knowledgeRTIdNameMap.get('PCC Standard');
                    }
                }
            }
            
            if(k.MSD_CORE_GenCatgry__c == 'Q&A Script' && k.MSD_CORE_Subtype__c == 'Promotional')
            {
                for(knowledge__DataCategorySelection s : k.DataCategorySelections)
                {
                    if(s.DataCategoryName == 'MSD_CORE_PCC')
                    {
                        rtName += knowledgeRTIdNameMap.get('PCC FAQ');
                    }
                }
            }
            
            if(k.Title.startsWith('Addl Info'))
            {
                for(knowledge__DataCategorySelection s : k.DataCategorySelections)
                {
                    if(s.DataCategoryName == 'MSD_CORE_NSC')
                    {
                        rtName += knowledgeRTIdNameMap.get('NSC Addl Info');
                    }
                }
            }
            
            if(k.Title.startsWith('Quick Info'))
            {
                for(knowledge__DataCategorySelection s : k.DataCategorySelections)
                {
                    if(s.DataCategoryName == 'MSD_CORE_NSC')
                    {
                        rtName += knowledgeRTIdNameMap.get('NSC Quick Info');
                    }
                }
            }
            
            if(k.Title.startsWith('Addl Info'))
            {
                for(knowledge__DataCategorySelection s : k.DataCategorySelections)
                {
                    if(s.DataCategoryName == 'MSD_CORE_PCC')
                    {
                        rtName += knowledgeRTIdNameMap.get('PCC Addl Info');
                    }
                }
            }
            
            if(k.Title.startsWith('Quick Info'))
            {
                for(knowledge__DataCategorySelection s : k.DataCategorySelections)
                {
                    if(s.DataCategoryName == 'MSD_CORE_PCC')
                    {
                        rtName += knowledgeRTIdNameMap.get('PCC Quick Info');
                    }
                }
            }
            
            if(knowledgeRTNameMap.containskey(k.Title))
            {
                rtName = knowledgeRTIdNameMap.get(knowledgeRTNameMap.get(k.Title));
            }
            
            knowledgeRTMap.put(k.Id + '~' + k.Title, rtName);
            knowledgeRTOnlineMap.put(k.KnowledgeArticleId, rtName);
            knowledgeAKMap.put(k.KnowledgeArticleId, kCName);
            
            knowledgeTypeMap.put(k.KnowledgeArticleId, knowledgeTypeMap.get(k.Title));
            knowledgeCategoryMap.put(k.KnowledgeArticleId, knowledgeCategoryMap.get(k.Title));
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
                                                              RecordTypeId = rtName);
                        
                        if(knowledgeTypeMap.containskey(articleId))        
                            k.MSD_CORE_Case_Type__c = knowledgeTypeMap.get(articleId);                              
                        
                        if(knowledgeCategoryMap.containskey(articleId))        
                            k.MSD_CORE_Case_Category__c = knowledgeCategoryMap.get(articleId); 
                        
                        if(knowledgeAKMap.containskey(articleId))        
                            k.MSD_CORE_KnwlArtCat__c = knowledgeAKMap.get(articleId); 
                            
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
            
        List<Document> docList = [select id, Name, ContentType, Body from Document where Name = 'ArticleRecordTypeLog'];
        
        if(docList.size() > 0)
            doc = docList[0];
        else
        {
            doc.Name = 'ArticleRecordTypeLog';
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