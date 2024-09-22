global class MSD_CORE_ProductBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date dt = Date.valueOf(Label.Case_Batch_Date);
        
        Set<String> recordTypeNameSet = new Set<String>{'Adverse Event',
                                                        'Adverse Event - Closed',
                                                        'Adverse Event - Submitted',
                                                        'Product Complaint',
                                                        'Product Complaint - Closed',
                                                        'Product Complaint - Submitted'};
        
        if(Test.isRunningTest())
            return Database.getQueryLocator('select id from Case limit 10');
        else
            return Database.getQueryLocator('select id from Case where RecordType.Name in : recordTypeNameSet and CreatedDate < : dt');
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Case> caseList = (List<Case>) scope;
        
        List<Case> caseRecordList = [select id, RecordType.Name, Product_MVN__c, MSD_CORE_Product_Consent__c, MSD_CORE_Product_Quantity__c,
                                     MSD_CORE_Product_Return_Date__c,MSD_CORE_PQC_Hazardous_Product__c, MSD_CORE_PQC_Lot_Numbers__c,
                                     MSD_CORE_Date_Product_Requested__c, AE_Start_Date_MVN__c, MSD_CORE_Date_PQC_first_identified__c,
                                     MSD_CORE_AE_Description__c, MSD_CORE_PQC_Description__c, MSD_CORE_Serial_Number__c,
                                     MSD_CORE_Unique_Identifier__c, MSD_CORE_Model_Number__c, MSD_CORE_Catalog_Number__c,
                                     MSD_CORE_Event_Case_Type__c,
                                    (select id, MSD_CORE_Component_Type__c, MSD_CORE_Lot_Number__c, 
                                     MSD_CORE_Obtain__c, MSD_CORE_Product__c, MSD_CORE_Product_Expiration_Date__c,
                                     MSD_CORE_Product_Quantity__c
                                     from Lot_Numbers__r),
                                    (select id from AE_Products__r where MSD_CORE_Primary_Product__c = true)
                                     from Case 
                                     where id in : caseList];
    
        
        List<MSD_CORE_AE_Product__c> productInsertList = new List<MSD_CORE_AE_Product__c>();
        
        boolean primaryProduct = true;
        
        List<Case> caseUpdateList = new List<Case>();
        
        for(Case c : caseRecordList)
        {
            if(c.MSD_CORE_Date_PQC_first_identified__c != null)
                c.AE_Start_Date_MVN__c = c.MSD_CORE_Date_PQC_first_identified__c;
            
            if(c.MSD_CORE_PQC_Description__c != null)
                c.MSD_CORE_AE_Description__c = c.MSD_CORE_PQC_Description__c;
            
            c.MSD_CORE_Event_Case_Type__c = c.RecordType.Name.contains('Product Complaint') ? 'PQC Only' : 'AE Only';
            
            caseUpdateList.add(c);
                
            if(c.AE_Products__r.size() > 0)
                primaryProduct = false;
            
            if(c.Product_MVN__c != null)
            {
                MSD_CORE_AE_Product__c product = new MSD_CORE_AE_Product__c(MSD_CORE_Adverse_Event__c = c.Id,
                                                                 MSD_CORE_Product_Lookup__c = c.Product_MVN__c,
                                                                 MSD_CORE_Serial_Number__c = c.MSD_CORE_Serial_Number__c,
                                                                 MSD_CORE_Unique_Identifier__c = c.MSD_CORE_Unique_Identifier__c,
                                                                 MSD_CORE_Model_Number__c = c.MSD_CORE_Model_Number__c,
                                                                 MSD_CORE_Catalog_Number__c = c.MSD_CORE_Catalog_Number__c,
                                                                 MSD_CORE_Hazardous_Product__c = c.MSD_CORE_PQC_Hazardous_Product__c,
                                                                 MSD_CORE_Product_Return_Date__c = c.MSD_CORE_Product_Return_Date__c,
                                                                 MSD_CORE_Related_to__c = c.RecordType.Name.contains('Product Complaint') ? 'PQC' : 'AE');
                
                if(c.Lot_Numbers__r.size() > 0)
                {
                    for(MSD_CORE_Lot_Number__c lotRec : c.Lot_Numbers__r)
                    {
                        MSD_CORE_AE_Product__c lotProduct = product.clone(false, false);
                        
                        lotProduct.MSD_CORE_Lot_Number__c = lotRec.MSD_CORE_Lot_Number__c;
                        lotProduct.MSD_CORE_Obtain__c = lotRec.MSD_CORE_Obtain__c;
                        lotProduct.MSD_CORE_Expiration_Date__c = convertStringToDate(lotRec.MSD_CORE_Product_Expiration_Date__c);
                        lotProduct.MSD_CORE_Product_Qty__c = lotRec.MSD_CORE_Product_Quantity__c;
                        lotProduct.MSD_CORE_Primary_Product__c = primaryProduct;
                        
                        primaryProduct = false;
                        
                        productInsertList.add(lotProduct);
                    }
                }
                else
                {
                    product.MSD_CORE_Primary_Product__c = primaryProduct;
                    
                    productInsertList.add(product);
                }
            }
            
            primaryProduct = true;
        }
        
        if(productInsertList.size() > 0)
        {    
            Database.SaveResult[] srList = Database.insert(productInsertList, false);
            logError(srList, productInsertList, false);
        }
        
        if(caseUpdateList.size() > 0)
        {    
            Database.SaveResult[] srCaseList = Database.update(caseUpdateList , false);
            logError(srCaseList, caseUpdateList, true);
        }
    }
    
    global static void logError(Database.SaveResult[] srList, List<sObject> productInsertList, boolean isForCase)
    {
        Document doc = new Document();
            
        List<Document> docList = [select id, Name, ContentType, Body from Document where Name = 'CaseProductIssueLog'];
        
        if(docList.size() > 0)
            doc = docList[0];
        else
        {
            doc.Name = 'CaseProductIssueLog';
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