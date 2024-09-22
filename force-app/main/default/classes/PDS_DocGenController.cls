/*
* Class: PDS_DocGenController
* Test Class: PDS_DocGenControllerTest
* Description: Handles the generation of PDS documents and attaching them to donation request records.
* Author: Gopi Chintamaneni
* Created On: 03/01/2024
* Last Modified: 03/25/2024
* Version: Initial
*/
public with sharing class PDS_DocGenController {
    
    @InvocableMethod(label = 'Generate Documents for Donation Request Record'
                     description = 'Generates multiple documents based on the status and attaches it to a record')
    public static void generatePDF(List < DocumentProperties > docGenRequests) {
        try {
            DocumentProperties docGenRequest = docGenRequests[0];
            
            List < ContentVersion > contentVersionsToInsert = new List < ContentVersion > ();
            List < ContentDocumentLink > contentDocumentLinksToInsert = new List < ContentDocumentLink > ();
            List < String > vfPageNames;
            
            PDS_Donation_Request__c requestRecord = [SELECT Id, Name, PDS_Request_Submit_Date__c, PDS_Donation_Request_Status__c         
                                                     , RecordType.Name FROM PDS_Donation_Request__c
                                                     WHERE Id =: docGenRequest.recordId];
            
            String requestCountry = '';
            List<PDS_Product_Line_Item__c> productLineItems = [SELECT PDS_Country__c FROM PDS_Product_Line_Item__c WHERE PDS_Donation_Request__c = :requestRecord.Id LIMIT 1];
            
            if (!productLineItems.isEmpty()) {
                requestCountry = productLineItems[0].PDS_Country__c;
            }
            
            if (requestRecord != null) {
                String requestStatus = requestRecord.PDS_Donation_Request_Status__c;
                Date donationApprovalDate = requestRecord.PDS_Request_Submit_Date__c;

                //Names of the docs to be generated            
                if (docGenRequest.docNames.contains(',')) {
                    vfPageNames = docGenRequest.docNames.split(',');
                } else {
                    vfPageNames = new List < String > {
                        docGenRequest.docNames
                    };
                }
                
                // DocTypes are used to define the type and Title of the document
                List < String > docTypes;
                if (docGenRequest.docType.contains(',')) {
                    docTypes = docGenRequest.docType.split(',');
                } else {
                    docTypes = new List < String > {
                        docGenRequest.docType
                    };
                }
                
                // Generate Documents from VF Pages
                for (Integer i = 0; i < vfPageNames.size(); i++) {
                    String docType = (i < docTypes.size()) ? docTypes[i].trim() : '';
                    
                    // Generate document title
                    String documentTitle = String.valueOf(donationApprovalDate.year()) + ' - ' + requestRecord.Name;
                    if(requestRecord.RecordType.Name == 'MDP'){
                        documentTitle += ' ' + requestCountry;
                    }
                    if(docType.contains('(Donation Request)')){
                        documentTitle += ' ' + docType + '.xls';
                    }else{
                        documentTitle += ' ' + docType + '.pdf';
                    }
                    
                    PageReference pageRef = new PageReference('/apex/' + vfPageNames[i]);
                    pageRef.getParameters().put('id', docGenRequest.recordId);
                    Blob documentBlob = docType.contains('(Donation Request)') ? pageRef.getContent() : pageRef.getContentAsPDF();
                    
                    // Create ContentVersion
                    ContentVersion contentVersion = new ContentVersion();
                    contentVersion.VersionData = documentBlob;
                    contentVersion.Title = documentTitle;
                    contentVersion.PathOnClient = documentTitle;
                    contentVersionsToInsert.add(contentVersion);
                }
            }
            
            PDS_DocGenController.deleteExistingDocs(docGenRequest.recordId, docGenRequest.docType);
            if (!contentVersionsToInsert.isEmpty()) {
                insert contentVersionsToInsert;
            }

            // Create ContentDocumentLink to associate ContentDocument with the request record
            for (ContentVersion contentVersion: contentVersionsToInsert) {
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.ContentDocumentId = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId =: contentVersion.Id].Id;
                contentDocumentLink.LinkedEntityId = requestRecord.Id;
                contentDocumentLink.Visibility = 'AllUsers';
                contentDocumentLinksToInsert.add(contentDocumentLink);
            }
            insert contentDocumentLinksToInsert;
            
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage());
        }
    }
    
    public static void deleteExistingDocs(String recordId, String docType){
        // Collect ContentDocumentIds and ContentDocumentLinkIds to delete
        Set<Id> contentDocumentIdsToDelete = new Set<Id>();
        Set<Id> contentDocumentLinkIdsToDelete = new Set<Id>();
        
        List<String> multiDocs = new List<String>();
        if (docType.contains(',')) {
            for (String title : docType.split(',')) {
                String extractedValue = title.substringBetween('(', ')');
                multiDocs.add('ContentDocument.Title LIKE \'%(' + extractedValue.trim() + ')%\'');
            }
        } else {
            String extractedValue = docType.substringBetween('(', ')');
            multiDocs.add('ContentDocument.Title LIKE \'%(' + extractedValue.trim() + ')%\'');
        }
        
        String query = 'SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = \'' + recordId + '\' AND (' + String.join(multiDocs, ' OR ') + ')';
        
        List<ContentDocumentLink> contentDocumentLinks = Database.query(query);
        for (ContentDocumentLink cdl : contentDocumentLinks) {
            contentDocumentIdsToDelete.add(cdl.ContentDocumentId);
            contentDocumentLinkIdsToDelete.add(cdl.Id);
        }
        
        System.debug('Content Docs ' + contentDocumentIdsToDelete.size());
        System.debug('ContentLink Docs ' + contentDocumentLinkIdsToDelete.size());
        
        // Delete associated ContentDocumentLinks
        if (!contentDocumentLinkIdsToDelete.isEmpty()) {
            delete [SELECT Id FROM ContentDocumentLink WHERE Id IN :contentDocumentLinkIdsToDelete];
        }
        
        // Delete associated ContentDocuments, which will automatically delete associated ContentVersions
        if (!contentDocumentIdsToDelete.isEmpty()) {
            delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIdsToDelete];
        }
    }

    
    public class DocumentProperties {
        @InvocableVariable(label = 'Record Id'
                           description = 'The Id of the record to attach the document to'
                           required = true)
        public String recordId;
        @InvocableVariable(label = 'Document Names'
                           description = 'Names of the documents to be generated'
                           required = true)
        public String docNames;
        @InvocableVariable(label = 'Document Type'
                           description = 'Type of the document generated'
                           required = true)
        public String docType;   
    }
    
    public PDS_Donation_Request__c requestRecord{get;set;}
    public String requestRecordId{get;set;}
    public List<PDS_Product_Line_Item__c> productLineItems { get;set; }
    public String certBody{get;set;}
    public String authNumContent {get;set;}
    public String approvalMemoContent {get;set;}
    public String airwayBill {get;set;}
    public Decimal approvedQuantity{get;set;}
    public Decimal shippedQuantity{get;set;}
    public String lineItemCountry {get;set;}
    public String formattedDonationValue {get;set;}
    public String productName {get;set;}
    public Decimal productUnitPrice {get;set;}
    public String productSize {get;set;}
    public Decimal totalSIC {get;set;}
    public Decimal totalMarketValue {get;set;}
    public String totalMarketValueStringPart {get;set;}
    public String totalSICString {get;set;}
    public String productUnitPriceString {get;set;}
    public String quantityAndSIC { get; set; }
    public Set<String> uniqueCountries { get; set; }
    public Boolean lineItems {get;set;}
    public String certBodyAA{get;set;}
    public Decimal actualUnitSalePrice{get;set;}
    public String actualUnitSalePriceStringPart{get;set;}
    
    public PDS_Contact__c doneeAddress {get;set;}
    
    public PDS_DocGenController(){
        
        requestRecordId = ApexPages.currentPage().getParameters().get('id');
        if(requestRecordId!=null && String.isNotBlank(requestRecordId)) {
            requestRecord = [SELECT Id, Name, PDS_Donation_Request_Status__c,PDS_Donee__c,
                             PDS_Donee__r.Name, PDS_Requestor__r.Name,PDS_Application_Number__c ,
                             PDS_Ship_Notify__r.Name,PDS_Ship_Notify__r.PDS_Shipping_Postal_Code__c, PDS_Ship_Notify__r.PDS_Shipping_Street__c,
                             PDS_Ship_Notify__r.PDS_Email__c, PDS_Ship_Notify__r.PDS_Phone__c,CreatedDate,PDS_Approver__r.Title, PDS_Approver__r.CompanyName,
                             PDS_Approver__r.Name,PDS_Approver__r.StayInTouchSignature, PDS_Reviewer__r.Name,PDS_Final_Recipient__r.Name,PDS_Final_Recipient__r.PDS_Shipping_Postal_Code__c,
                             PDS_Ship_Notify__r.Account__r.Name ,PDS_Final_Recipient__r.PDS_Shipping_Street__c, PDS_Final_Recipient__r.PDS_Email__c,PDS_Final_Recipient__r.PDS_Phone__c,
                             PDS_Final_Recipient__r.Account__r.Name, PDS_Attention__c, PDS_Final_Recipient__r.PDS_Shipping_Country__c, PDS_Final_Recipient__r.PDS_Shipping_State__c,
                             PDS_Final_Recipient__r.PDS_Shipping_City__c, PDS_Consignee__r.Name, PDS_Consignee__r.PDS_Shipping_Street__c,
                             PDS_Consignee__r.PDS_Shipping_Postal_Code__c, PDS_Consignee__r.PDS_Shipping_City__c, PDS_Consignee__r.PDS_Shipping_State__c, PDS_Consignee__r.PDS_Shipping_Country__c, 
                             PDS_Consignee__r.PDS_Email__c, PDS_Consignee__r.PDS_Phone__c, PDS_Donee__r.MSD_CORE_Primary_City__c, PDS_Donee__r.Phone,
                             PDS_Donee__r.MSD_CORE_Primary_State__c, PDS_Donee__r.MSD_CORE_Primary_Zip__c, PDS_Donee__r.MSD_CORE_Primary_Address_Line_1__c,
                             PDS_Donee__r.MSD_CORE_USMA_Email__c, PDS_Donee__r.Fax, PDS_Donee__r.MSD_CORE_Country_Code__c, PDS_Forwarding_Agent__c, PDS_Additional_Information__c, 
                             PDS_Customer_Order_Number__c, PDS_U_S_Invoice_Number__c, PDS_Indication__c 
                             FROM PDS_Donation_Request__c
                             WHERE Id = :requestRecordId];
            
            if (requestRecord != null) {
      			List<PDS_Contact__c> doneeAddresses = [SELECT Id, Name,PDS_Address_Type__c,PDS_Address_2__c,PDS_Address_3__c,PDS_Attention__c,PDS_Department_Unit__c,PDS_Email__c,PDS_Email_Address_2__c,PDS_Email_Address_3__c,
                                    PDS_Fax_Number__c,PDS_Phone__c,PDS_Shipping_City__c,PDS_Shipping_Country__c,PDS_Shipping_Postal_Code__c,PDS_Shipping_State__c,PDS_Shipping_Street__c,Account__r.Name
                                    FROM PDS_Contact__c 
                                    WHERE Account__c = :requestRecord.PDS_Donee__c AND PDS_Address_Type__c='Primary' AND PDS_IsActive__c = true];
               if (!doneeAddresses.isEmpty()) {
                    doneeAddress = doneeAddresses[0];
                }
                
                String doneeName = requestRecord.PDS_Donee__r.Name;
                //String doneeName = (requestRecord.PDS_Donee__r != null) ? requestRecord.PDS_Donee__r.Name : null;
                String authNum = requestRecord.Name;
                productLineItems = [SELECT Id, Name, PDS_Donation_Request__r.PDS_Donee__r.Name, PDS_Quantity_Unit__c,
                                    PDS_Local_Partner__c, PDS_Quantity_Requested__c, PDS_Country__c, PDS_Quantity_Approved__c, PDS_Ship_Date__c, PDS_Total_SIC__c, PDS_Total_Market_Value__c, 
                                    PDS_Product__r.Name, PDS_Product__r.PDS_SAP_Code__c, PDS_Product__r.PDS_NDC_Number__c, PDS_Product__r.PDS_Actual_Unit_Sale_Price__c, 
                                    PDS_Quantity_Shipped__c, PDS_Product__r.PDS_Product_Size__c, PDS_Product__r.PDS_Actual_Product_Cost__c, PDS_Product__r.PDS_Product_Number__c 
                                    FROM PDS_Product_Line_Item__c WHERE PDS_Donation_Request__c = :requestRecord.Id ORDER BY LastModifiedDate DESC];
                System.debug('productLineItems' +productLineItems);
                System.debug('requestRecord.Id' +requestRecord.Id);
                if (productLineItems != null) {
                    
                    actualUnitSalePrice = productLineItems[0].PDS_Product__r.PDS_Actual_Unit_Sale_Price__c;
					String actualUnitSalePriceString1 = String.valueOf(actualUnitSalePrice);
					String actualUnitSalePriceDecimalPart = '';

					Integer actualUnitSalePriceDecimalIndex = actualUnitSalePriceString1.indexOf('.');
					if (actualUnitSalePriceDecimalIndex != -1) {
    					actualUnitSalePriceDecimalPart = '.' + actualUnitSalePriceString1.substring(actualUnitSalePriceDecimalIndex + 1);
						}
					actualUnitSalePriceStringPart = actualUnitSalePrice.format() + actualUnitSalePriceDecimalPart;
                    
                    
                    totalMarketValue = productLineItems[0].PDS_Total_Market_Value__c;
                    
                    String totalMarketValue1 = String.valueOf(totalMarketValue);
					String totalMarketValueDecimalPart = '';

					Integer totalMarketValueDecimalIndex = totalMarketValue1.indexOf('.');
					if (totalMarketValueDecimalIndex != -1) {
					    totalMarketValueDecimalPart = '.' + totalMarketValue1.substring(totalMarketValueDecimalIndex + 1);
						}
					totalMarketValueStringPart = totalMarketValue.format() + totalMarketValueDecimalPart;
                    
                    
                    lineItemCountry = productLineItems[0].PDS_Country__c;
                    productName = productLineItems[0].PDS_Product__r.Name;
                    //totalSIC = productLineItems[0].PDS_Total_SIC__c;
                    approvedQuantity = productLineItems[0].PDS_Quantity_Approved__c;
                    shippedQuantity = productLineItems[0].PDS_Quantity_Shipped__c;
                    productUnitPrice = productLineItems[0].PDS_Product__r.PDS_Actual_Product_Cost__c;
                    
                    String productUnitPriceString1 = String.valueOf(productUnitPrice);
					String productUnitPriceDecimalPart = '';

					Integer productUnitPriceDecimalIndex = productUnitPriceString1.indexOf('.');
					if (productUnitPriceDecimalIndex != -1) {
					    productUnitPriceDecimalPart = '.' + productUnitPriceString1.substring(productUnitPriceDecimalIndex + 1);
						}
					productUnitPriceString = productUnitPrice.format() + productUnitPriceDecimalPart;
                    
                    productSize = productLineItems[0].PDS_Product__r.PDS_Product_Size__c;
                    totalSIC = productLineItems[0].PDS_Total_SIC__c;

                    String totalSICString1 = String.valueOf(totalSIC);
                    String decimalPart = '';

                    Integer decimalIndex = totalSICString1.indexOf('.');
                    if (decimalIndex != -1) {
                        decimalPart = '.'+totalSICString1.substring(decimalIndex + 1);
                    }
                    totalSICString = totalSIC.format() + decimalPart;

                    if (approvedQuantity != null && totalSIC != null) {
                        quantityAndSIC = String.valueOf(approvedQuantity) + ' - Value US $' + String.valueOf(totalSICString);
                    } else if (approvedQuantity != null) {
                        quantityAndSIC = String.valueOf(approvedQuantity);
                    } else if (totalSIC != null) {
                        quantityAndSIC = 'Value $' + String.valueOf(totalSIC);
                    } else {
                        quantityAndSIC = '';
                    }
                    lineItems = productLineItems.size() <= 1;
                    System.debug('lineItems'+lineItems);
                    System.debug('uniqueCountries'+uniqueCountries);
                    //processCountries();
                    //Certificate
                    certBody = getCertBody(productName, doneeName, lineItemCountry);
                    authNumContent = getauthNum(authNum);
                    //AACertificate
                    
                    List<String> cb = new List<String>{doneeName};   
                    certBodyAA = String.format(System.label.PDS_AACertBody,cb);
                    
                    //Approval Memo
                    List<String> params = new List<String>{productName, doneeName, lineItemCountry, totalSICString};
                    approvalMemoContent = String.format(System.label.PDS_AMemo_Content, params);
                }
                //AirwayBill Memo
                List<Map<String, String>> picklistValues = PDS_Utility.getPicklistValues('PDS_Donation_Request__c', 'PDS_Indication__c');
                String indicationLabel = '';
                for (Map<String, String> picklistValue : picklistValues) {
                    if (picklistValue.get('value') == requestRecord.PDS_Indication__c) {
                        indicationLabel = picklistValue.get('label');
                        break;
                    } 
                }
                List<String> AirwayBillParams = new List<String>{indicationLabel};
                airwayBill = String.format(System.label.PDS_ASMemo_AirWayValue, AirwayBillParams);
                //List<String> AirwayBillParams = new List<String>{requestRecord.PDS_Indication__c};
                //airwayBill = String.format(System.label.PDS_ASMemo_AirWayValue, AirwayBillParams);
            
                //Total Donation Value
                Decimal totalDonationValue = 0;

                for(PDS_Product_Line_Item__c record : productLineItems) {
                    totalDonationValue += record.PDS_Total_Market_Value__c != null ? record.PDS_Total_Market_Value__c : 0;
                }
                
                String totalDonationValueString1 = String.valueOf(totalDonationValue);
                String totalDonationValueDecimalPart = '';
                
                Integer totalDonationValueDecimalIndex = totalDonationValueString1.indexOf('.');
				if (totalDonationValueDecimalIndex != -1) {
    				totalDonationValueDecimalPart = '.' + totalDonationValueString1.substring(totalDonationValueDecimalIndex + 1);
				}
                
                formattedDonationValue = totalDonationValue.format() + totalDonationValueDecimalPart;
            }
        }
    }
    private String getcertBody(String productName, String doneeName, String country) {
        List<String> params = new List<String>{productName,doneeName,country};
            return String.format(System.label.PDS_Cert_Body, params);
    }
    private String getauthNum(String authNum) {
        List<String> authnumParams = new List<String>{authNum};
            return String.format(System.label.PDS_Cert_Sign, authnumParams);
    } 
}