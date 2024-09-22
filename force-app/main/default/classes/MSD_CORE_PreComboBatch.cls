global class MSD_CORE_PreComboBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date dt = Date.valueOf(Label.Case_Batch_Date);
        
        Set<String> recordTypeNameSet = new Set<String>{'Interaction',
                                                        'Interaction - Closed'};
        
        if(Test.isRunningTest())
            return Database.getQueryLocator('select id, MSD_CORE_Pre_MDCP_Combo__c from Case limit 10');
        else
            return Database.getQueryLocator('select id, MSD_CORE_Pre_MDCP_Combo__c from Case where RecordType.Name in : recordTypeNameSet and MSD_CORE_AE_Present__c = true and MSD_CORE_PQC_Present__c = true and CreatedDate < : dt');
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Case> caseList = (List<Case>) scope;
        
        Set<String> recordTypeNameSet = new Set<String>{'Adverse Event',
                                                        'Adverse Event - Closed',
                                                        'Adverse Event - Submitted',
                                                        'Product Complaint',
                                                        'Product Complaint - Closed',
                                                        'Product Complaint - Submitted'};
        
        List<Case> caseRecordList = [select id, MSD_CORE_Pre_MDCP_Combo__c,
                                    (select id, MSD_CORE_Pre_MDCP_Combo__c from Cases
                                     where RecordType.Name in : recordTypeNameSet)
                                     from Case 
                                     where id in : caseList];
        
        List<Case> caseUpdateList = new List<Case>();
        
        for(Case c : caseRecordList)
        {
            c.MSD_CORE_Pre_MDCP_Combo__c = true;
        
            caseUpdateList.add(c);
            
            for(Case cc : c.Cases)
            {
                cc.MSD_CORE_Pre_MDCP_Combo__c = true;
            
                caseUpdateList.add(cc);
            }
        }
        
        if(caseUpdateList.size() > 0)
        {    
            Database.SaveResult[] srCaseList = Database.update(caseUpdateList, false);
            logError(srCaseList, caseUpdateList, true);
        }
    }
    
    global static void logError(Database.SaveResult[] srList, List<sObject> productInsertList, boolean isForCase)
    {
        Document doc = new Document();
            
        List<Document> docList = [select id, Name, ContentType, Body from Document where Name = 'CasePreComboIssueLog'];
        
        if(docList.size() > 0)
            doc = docList[0];
        else
        {
            doc.Name = 'CasePreComboIssueLog';
            doc.ContentType = 'text/plain';
            doc.FolderId = [select id from Folder where Name = 'AE Letters' limit 1].id;
        }
        
        String error = '';
        integer count = 0;
        
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                System.debug('Successfully inserted Prodduct. Product ID: ' + sr.getId());
            }
            else {
                    
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    error += (isForCase ? productInsertList[count].Id : productInsertList[count].get('MSD_CORE_Adverse_Event__c')) + ' === ' + err.getStatusCode() + ' === ' + err.getMessage() + ' === ' + err.getFields() + '\n\n';
                }
            }
            
            count++;
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