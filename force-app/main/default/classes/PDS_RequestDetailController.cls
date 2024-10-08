public without sharing class PDS_RequestDetailController {
    
    @AuraEnabled
    public static PDS_Donation_Request__c getdonationreqdetails(String requestid){
        try {
            PDS_Donation_Request__c reqdata = [SELECT ID, Name,PDS_Additional_Information__c,PDS_Applicant_Institution__c,PDS_Applicant_Name__c,
                                               PDS_Application_Number__c,PDS_Approval_Date__c,PDS_Customer_Order_Number__c,PDS_Destination__c,
                                               PDS_Donation_Request_Date__c,PDS_Donation_Request_Status__c,PDS_Donation_Type__c,PDS_Donee__r.Name,PDS_Donee__r.Formatted_Name_vod__c,
                                               PDS_Forwarding_Agent__c,PDS_Indication__c,PDS_Minimum_Expiration_Dating__c,PDS_Packing_List_Received_Date__c,
                                               PDS_PO_Number__c,PDS_Quantity_Shipped__c,PDS_Request_Resolution__c,PDS_Request_Submit_Date__c,PDS_Open_For_ReAllocation__c,
                                               PDS_Tax_Doc_Received_Date__c,PDS_Tax_Report_Inclusion__c,PDS_U_S_Invoice_Number__c,RecordType.Name,PDS_Proposal__r.Name,PDS_Shipping_Status__c,
                                               (Select Id,Name,PDS_Additional_Information__c,PDS_Country__c,PDS_Local_Partner__c,
                                                PDS_Product__r.Name,PDS_Product__r.PDS_SAP_Code__c,PDS_Quantity_Approved__c,PDS_Quantity_Requested__c,PDS_Quantity_Shipped__c,
                                                PDS_Quantity_Unit__c,PDS_Ship_Date__c,PDS_Shipping_Status__c,PDS_Tablets_Requested__c,PDS_Batch_Number__c,PDS_Expiration_Date__c,
                                                PDS_Total_Market_Value__c,PDS_Total_SIC__c,PDS_Treatments_Approved__c,PDS_Treatments_Delivered__c,PDS_Product__r.PDS_Cold_Chain__c,PDS_Product__r.PDS_NDC_Number__c
                                                from Product_Line_Items__r WHERE PDS_Shipping_Status__c != 'Cancelled') FROM PDS_Donation_Request__c WHERE ID =: requestid];
        if (reqdata.PDS_Indication__c != null) {
            reqdata.PDS_Indication__c = translatePicklistValue('PDS_Donation_Request__c', 'PDS_Indication__c', reqdata.PDS_Indication__c);
        }
            System.debug(LoggingLevel.WARN,'reqdata' +reqdata);

            return reqdata;
        } catch (Exception e) { System.debug(LoggingLevel.WARN, 'error ===> '+ e.getMessage()); return null;}
    }
    
public static String translatePicklistValue(String objectApiName, String fieldApiName, String value) {
    try {
        List<Map<String, String>> picklistValues = PDS_Utility.getPicklistValues(objectApiName, fieldApiName);
        for (Map<String, String> entry : picklistValues) {
            if (entry.get('value') != null && entry.get('value').equals(value)) {
                return entry.get('label');
            }
        }
    } catch (Exception e) {
        System.debug(LoggingLevel.WARN, 'Error translating picklist value: ' + e.getMessage());
    }
    return value;
}
    @AuraEnabled
    public static Map<String, Object> getContentDocuments(String requestId) {
        Map<String, Object> fileDataMap = new Map<String, Object>();
        try {
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink link : [SELECT ContentDocumentId
                                            FROM ContentDocumentLink
                                            WHERE LinkedEntityId = :requestId]) {
                contentDocumentIds.add(link.ContentDocumentId);
            }

            Map<Id, String> contentDocumentTitles = new Map<Id, String>();
            Map<Id, String> contentDocumentFileTypes = new Map<Id, String>();

            for (ContentDocument doc : [SELECT Id, Title, FileType
                                        FROM ContentDocument
                                        WHERE Id IN :contentDocumentIds
                                        AND (Title LIKE '%Application%' OR Title LIKE '%Approval Letter%' OR Title LIKE '%Proposal%' OR Title LIKE '%Delivery receipt%' OR Title LIKE '%Tax receipt%')]) {
                contentDocumentTitles.put(doc.Id, doc.Title);
                contentDocumentFileTypes.put(doc.Id, doc.FileType);
            }

            for (ContentVersion version : [SELECT ContentDocumentId, VersionData
                                        FROM ContentVersion
                                        WHERE ContentDocumentId IN :contentDocumentIds]) {
                String fileName = contentDocumentTitles.get(version.ContentDocumentId);
                if (fileName != null) {
                    String versionData = 'data:application/octet-stream;base64,' + EncodingUtil.base64Encode(version.VersionData);
                    String fileType = contentDocumentFileTypes.get(version.ContentDocumentId);
                    Map<String, String> fileDetails = new Map<String, String>();
                    fileDetails.put('fileData', versionData);
                    fileDetails.put('fileType', fileType);
                    fileDataMap.put(fileName, fileDetails);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error: ' + e.getMessage());
        }
        return fileDataMap;
    }


    @AuraEnabled
    public static string cancelRequest(String requestid){
        String returnvalue = '';
        try {
            PDS_Donation_Request__c req = [SELECT ID, Name,PDS_Request_Resolution__c, PDS_Donation_Request_Status__c,PDS_Shipping_Status__c FROM PDS_Donation_Request__c WHERE ID =: requestid];
            System.debug(LoggingLevel.WARN,'before req : '+req.PDS_Donation_Request_Status__c);
            req.PDS_Request_Resolution__c = 'Canceled';
            req.PDS_Donation_Request_Status__c = 'Closed';
            // req.PDS_Shipping_Status__c = 'Pending';
            System.debug(LoggingLevel.WARN,'after req:'+req.PDS_Donation_Request_Status__c);
            update req;
            returnvalue = 'Request Cancelled';
        } catch (Exception e) { returnvalue = e.getMessage();} 
        return returnvalue;
    }
    
    @AuraEnabled
    public static void updateRecordStatus(Id recordId) {
        try {
            PDS_Donation_Request__c req = [SELECT ID, Name,PDS_Request_Resolution__c, PDS_Donation_Request_Status__c,PDS_Shipping_Status__c FROM PDS_Donation_Request__c WHERE ID =: recordId];
            req.PDS_Shipping_Status__c = 'Delivered';
            update req;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating record: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static string submitDeliveryDocuments(Map<string,String> donationReqDocuments){
      String result ='';
      try{
        String reqId = String.valueof(donationReqDocuments.get('id'));
        String doneName = String.valueof(donationReqDocuments.get('doneName'));
        String deliveryReceipt = String.valueOf(donationReqDocuments.get('deliveryReceipt'));
        String taxLetter = String.valueOf(donationReqDocuments.get('taxLetter'));
        String authNum = String.valueOf(donationReqDocuments.get('authorizationNumber'));
        String name ='';
        if (String.isNotBlank(deliveryReceipt)) {
            name = getDocumentName(reqId,authNum,doneName,'deliveryReceipt');
            result = PDS_Utility.attachRecordDocuments(reqId, deliveryReceipt, name, String.valueOf(donationReqDocuments.get('deliveryReceiptName')));
        }
        if (String.isNotBlank(taxLetter)) {
            name = getDocumentName(reqId,authNum,doneName,'taxLetter');
            result = PDS_Utility.attachRecordDocuments(reqId, taxLetter, name, String.valueOf(donationReqDocuments.get('taxLetterName')));
        }
      }
      catch (Exception e) {
        throw new AuraHandledException('Error updating record: ' + e.getMessage());
      }
      return result;
    }

    public static String getDocumentName(String reqId,String authNum,String doneName, String docType){
        String name ='';
        set<Id> contentDocumentIds = new set<Id>();
        String currentYear = String.valueOf(System.today().year());
        String currentMonth = System.today().month() >= 10 ? String.valueOf(System.today().month()) : '0'+String.valueOf(System.today().month());
        String currentDay = System.today().day() >= 10 ? String.valueOf(System.today().day()) : '0'+String.valueOf(System.today().day());
        List<AggregateResult> agrResult = new list<AggregateResult>();
        if(docType == 'deliveryReceipt'){
            agrResult = [SELECT count(Id) cnt FROM ContentDocumentLink WHERE LinkedEntityId =: reqId AND ContentDocument.Title LIKE '%Delivery receipt%'];
            if(agrResult[0].get('cnt') == 0){
                name = currentYear+' '+authNum+' '+currentMonth+'-'+currentDay+' '+doneName+' '+'(Delivery receipt)';
            }else{
                name = currentYear+' '+authNum+' '+currentMonth+'-'+currentDay+' '+doneName+' '+'(Delivery receipt)'+' '+agrResult[0].get('cnt');
            }
        }
        if(docType == 'taxLetter'){
          agrResult = [SELECT count(Id) cnt FROM ContentDocumentLink WHERE LinkedEntityId =: reqId AND ContentDocument.Title LIKE '%Tax receipt%'];
          if(agrResult[0].get('cnt') == 0){
              name = currentYear+' '+authNum+' '+currentMonth+'-'+currentDay+' '+doneName+' '+'(Tax receipt)';
          }else{
              name = currentYear+' '+authNum+' '+currentMonth+'-'+currentDay+' '+doneName+' '+'(Tax receipt)'+' '+agrResult[0].get('cnt');
          }
        }
        return name;
    }


}