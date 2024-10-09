/*
* Class: PDS_DonationRequestController
* Test Class: PDS_DonationRequestControllerTest
* Description: Handles creation of donation request from PDS Portal
* Author: Gopi Chintamaneni
* Created On: 04/18/2024
* Last Modified: 05/27/2024
*/
 public without sharing class PDS_DonationRequestController {

    public class DonationRequestWrapper {
        @AuraEnabled public PDS_Donation_Request__c donationRequest;
        @AuraEnabled public List<Id> productLineItemIds;
        @AuraEnabled public Map<Id, List<Id>> productToLineItemsMap;
        
        public DonationRequestWrapper(PDS_Donation_Request__c donationRequest, List<Id> productLineItemIds, Map<Id, List<Id>> productToLineItemsMap) {
            this.donationRequest = donationRequest;
            this.productLineItemIds = productLineItemIds;
            this.productToLineItemsMap = productToLineItemsMap;
        }
    }
    
    @AuraEnabled
    public static DonationRequestWrapper submitDonationRequest(String requestString) {
        PDS_Donation_Request__c donationRequest = new PDS_Donation_Request__c();
        List<PDS_Product_Line_Item__c> lineItemsToInsert = new List<PDS_Product_Line_Item__c>();
        List<Id> productLineItemIds = new List<Id>();
        Map<Id, List<Id>> productToLineItemsMap = new Map<Id, List<Id>>();
        DonationRequestWrapper resultWrapper;

        try {
            PDSDonationRequest req = (PDSDonationRequest)JSON.deserialize(requestString, PDSDonationRequest.class);

            // Get Record Type Id based on Record Type Name
            Id recordTypeId = getRecordTypeIdByName(req.recordTypeName, 'PDS_Donation_Request__c');

            // Get User Ids based on usernames
            Id reviewerId = getUserIdByUsername(req.reviewer);
            Id approverId = getUserIdByUsername(req.approver);
            Id requestorId = UserInfo.getUserId();

            //Program Id
            PDS_Program__c programRecord = [SELECT Id FROM PDS_Program__c WHERE Name = :req.recordTypeName LIMIT 1];
            Id programId = programRecord != null ? programRecord.Id : null;

            Boolean isTaxIncluded = req.taxValue != null && req.taxValue.toLowerCase() == 'yes';

            // Create or update PDS_Donation_Request__c object
            PDS_Donation_Request__c donationObj = new PDS_Donation_Request__c();
            donationObj.RecordTypeId = recordTypeId;
            if (String.isNotBlank(req.donationReqId)) donationObj.Id = req.donationReqId;
            if (String.isNotBlank(req.doneeId)) donationObj.PDS_Donee__c = req.doneeId;
            if (String.isNotBlank(req.applicationNumber)) donationObj.PDS_Application_Number__c = req.applicationNumber;
            if (String.isNotBlank(req.applicantName)) donationObj.PDS_Applicant_Name__c = req.applicantName;
            if (String.isNotBlank(req.donationType)) donationObj.PDS_Donation_Type__c = req.donationType;
            if (String.isNotBlank(req.addInfoValue)) donationObj.PDS_Additional_Information__c = req.addInfoValue;
            if (String.isNotBlank(req.requestStatus)) donationObj.PDS_Donation_Request_Status__c = req.requestStatus;
            if (String.isNotBlank(req.shippingStatus)) donationObj.PDS_Shipping_Status__c = req.shippingStatus;
            if (String.isNotBlank(req.destinationValue)) donationObj.PDS_Destination__c = req.destinationValue;
            if (String.isNotBlank(req.poNumber)) donationObj.PDS_PO_Number__c = req.poNumber;
            if (reviewerId != null) donationObj.PDS_Reviewer__c = reviewerId;
            if (approverId != null) donationObj.PDS_Approver__c = approverId;
            if (requestorId != null) donationObj.PDS_Requestor__c = requestorId;
            if (String.isNotBlank(req.applicantIns)) donationObj.PDS_Applicant_Institution__c = req.applicantIns;
            donationObj.PDS_Tax_Report_Inclusion__c = isTaxIncluded;
            if (String.isNotBlank(req.indicationValue)) donationObj.PDS_Indication__c = req.indicationValue;
           if (String.isNotBlank(req.consignee)) donationObj.PDS_Consignee__c = req.consignee;
           if (String.isNotBlank(req.finalRecipient)) donationObj.PDS_Final_Recipient__c = req.finalRecipient;
            if (String.isNotBlank(req.fwdAgent)) donationObj.PDS_Forwarding_Agent__c = req.fwdAgent;
            if (programId != null) donationObj.PDS_Program__c = programId;
            if (String.isNotBlank(req.requestSubmitDate)) donationObj.PDS_Request_Submit_Date__c = Date.valueOf(req.requestSubmitDate);
            if (String.isNotBlank(req.approvalDate)) donationObj.PDS_Approval_Date__c = Date.valueOf(req.approvalDate);
            if (String.isNotBlank(req.shipNotify)) donationObj.PDS_Ship_Notify__c = req.shipNotify;
            if (String.valueOf(req.totalValue) != null) donationObj.PDS_Total_Donation_Value__c = req.totalValue;
            if (String.isNotBlank(req.minExpDate)) donationObj.PDS_Minimum_Expiration_Dating__c = req.minExpDate;
            if (String.isNotBlank(req.updateNotify)) donationObj.PDS_Update_Summary__c = req.updateNotify;
            if (String.isNotBlank(req.proposalId)) donationObj.PDS_Proposal__c = req.proposalId;
            //donationObj.PDS_Open_For_ReAllocation__c = false;

            // Insert the record
            upsert donationObj;

            // Handle Product Line Items if provided
            if (donationObj.Id != null && req.productLineItems != null && !req.productLineItems.isEmpty()) {
                Id recordTypeIdLineItem = getRecordTypeIdByName(req.recordTypeName, 'PDS_Product_Line_Item__c');
                System.debug('Entered Product Line Items: ');
                for (PDSDonationRequest.ProductLineItem item : req.productLineItems) {
                    if (item.tabletsReq != null && item.productId != null && item.country != null) {
                        System.debug('Entered Product Line Items1: ');
                        PDS_Product_Line_Item__c lineItem = new PDS_Product_Line_Item__c(
                            RecordTypeId = recordTypeIdLineItem,
                            PDS_Donation_Request__c = donationObj.Id,
                            PDS_Shipping_Status__c = req.shippingStatus,
                            PDS_Product__c = item.productId,
                            PDS_Country__c = item.country,
                            PDS_Local_Partner__c = item.localPartner,
                            PDS_Actual_Product_Cost__c = item.actualproductPrice,
                            PDS_Actual_Unit_Sale_Price__c = item.actualSalePrice
                        );
                        if(req.recordTypeName == 'MMOP'){
                            if (String.valueOf(item.tabletsReq) != null) lineItem.PDS_Quantity_Requested__c = item.tabletsReq;
                            if (String.isNotBlank(item.expDate)) lineItem.PDS_Expiration_Date__c = parseDate(item.expDate);
                            if (String.isNotBlank(item.batchNumber)) lineItem.PDS_Batch_Number__c = item.batchNumber;
                        }else{
                            lineItem.PDS_Tablets_Requested__c = item.tabletsReq;
                        }
                        if (String.isNotBlank(item.lineItemId)) lineItem.Id = item.lineItemId;
                        lineItemsToInsert.add(lineItem);
                    }
                }

                // Insert product price
                if(req.recordTypeName == 'MDP' && req.productLineItems.size() > 0){
                    String prodId = req.productLineItems[0].productId;

                    PDS_Product__c product = [SELECT Id, PDS_Actual_Product_Cost__c, PDS_Actual_Unit_Sale_Price__c FROM PDS_Product__c WHERE Id = :prodId LIMIT 1];
                    if(product != null){
                        lineItemsToInsert[0].PDS_Actual_Product_Cost__c = product.PDS_Actual_Product_Cost__c;
                        lineItemsToInsert[0].PDS_Actual_Unit_Sale_Price__c = product.PDS_Actual_Unit_Sale_Price__c;
                    }
                }

                // Upsert Product Line Items
               List<PDS_Product_Line_Item__c> lineItemsToDelete = [SELECT Id FROM PDS_Product_Line_Item__c WHERE CreatedBy.Profile.Name = 'PDS Taskforce' AND PDS_Donation_Request__c = :donationObj.Id];

                try {
                    upsert lineItemsToInsert;
                    
                    if (!lineItemsToDelete.isEmpty()) {
                        try {
                            delete lineItemsToDelete;
                        } catch (DmlException e) {
                            System.debug('Error deleting line items: ' + e.getMessage());
                        }
                    }
                } catch (DmlException e) {
                    System.debug('Error upserting line items: ' + e.getMessage());
                }
            }

            // Retrieve created record
            donationRequest = [SELECT Id, Name FROM PDS_Donation_Request__c WHERE Id = :donationObj.id LIMIT 1];

            // Attach documents if provided
            String currentYear = String.valueOf(System.today().year());
            String authNumber = donationRequest.Name;
            String approvalNameFormat = currentYear + ' ' + authNumber + ' (Application)';
            String approvalLetterFormat = currentYear + ' ' + authNumber + ' (Approval Letter)';
            if(req.recordTypeName == 'MMOP'){
                String doneeName = (String.isNotBlank(req.doneeId)) ? ' ' + getAccountName(req.doneeId) : '';
                approvalNameFormat = currentYear + ' - ' + authNumber + doneeName + ' (Proposal)';
            }

            if (String.isNotBlank(req.proposalDocument)) {
                String result = PDS_Utility.attachRecordDocuments(donationObj.id, req.proposalDocument, approvalNameFormat, req.proposalDocName);
            }
            if (String.isNotBlank(req.approvalLetter)) {
                String result = PDS_Utility.attachRecordDocuments(donationObj.id, req.approvalLetter, approvalLetterFormat, req.approvalLetterName);
            }

            resultWrapper = new DonationRequestWrapper(donationObj, productLineItemIds, productToLineItemsMap);

        } catch (DmlException e) {
            System.debug('DML Exception: ' + e.getMessage());
            throw new AuraHandledException('DML Exception: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error creating or updating donation request: ' + e.getMessage());
        }
        return resultWrapper;
    }



    private static Id getUserIdByUsername(String username) {
        Id userId;
        try {
            User user = [SELECT Id FROM User WHERE Username = :username LIMIT 1];
            if (user != null) {
                userId = user.Id;
            }
        } catch (Exception e) {
            System.debug('Error retrieving User Id: ' + e.getMessage());
        }
        return userId;
    }

    public static Date parseDate(String dateString) {
        if (dateString != null && dateString.contains('/')) {
            List<String> dateParts = dateString.split('/');
            if (dateParts.size() == 3) {
                Integer year = Integer.valueOf(dateParts[2]);
                Integer month = Integer.valueOf(dateParts[0]);
                Integer day = Integer.valueOf(dateParts[1]);
                return Date.newInstance(year, month, day);
            }
        } else if(dateString != null && dateString.contains('-')){
            List<String> dateParts = dateString.split('-');
            if (dateParts.size() == 3) {
                Integer year = Integer.valueOf(dateParts[0]);
                Integer month = Integer.valueOf(dateParts[1]);
                Integer day = Integer.valueOf(dateParts[2]);
                return Date.newInstance(year, month, day);
            }
        }
        return null;
    }

    public static String getAccountName(String accountId) {
        String accountName;
        
        Account accountData = [SELECT Name, FirstName, LastName, IsPersonAccount,Formatted_Name_vod__c FROM Account WHERE Id = :accountId LIMIT 1];
        
        if (accountData != null) {
            if (accountData.IsPersonAccount) {
                accountName = accountData.FirstName + ' ' + accountData.LastName;
            } else {
                accountName = accountData.Formatted_Name_vod__c;
            }
        }
        
        return accountName;
    }
    
    private static Id getRecordTypeIdByName(String recordTypeName, String objectApiName) {
        Id recordTypeId;
        try {
            RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = :objectApiName AND Name = :recordTypeName LIMIT 1];
            if (rt != null) {
                recordTypeId = rt.Id;
            }
        } catch (Exception e) {
            System.debug('Error retrieving Record Type Id: ' + e.getMessage());
        }
        return recordTypeId;
    } 
    
    @AuraEnabled
    public static List<Map<String, String>> getDoneeOptions(String programName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try{
            List<PDS_Program_Access__c> doneeObj = [SELECT Id, PDS_Donee__r.id, PDS_Donee__r.name,PDS_Donee__r.Formatted_Name_vod__c, PDS_Program__r.name, PDS_Is_Active__c FROM PDS_Program_Access__c WHERE PDS_Program__r.name = :programName AND PDS_Is_Active__c = true];
            
            for (PDS_Program_Access__c obj : doneeObj) {
                Map<String, String> option = new Map<String, String>();
                // option.put('label', obj.PDS_Donee__r.name);
                option.put('label', obj.PDS_Donee__r.Formatted_Name_vod__c);
                option.put('value', obj.PDS_Donee__r.id);
                options.add(option);
            }
        }catch(Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
        
        return options;
    }

    @AuraEnabled
    public static List<Map<String, String>> getProductDetails(String productId) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            List<PDS_Product__c> products = [SELECT Id, Name, PDS_Is_Active__c, PDS_Product_Size__c FROM PDS_Product__c WHERE Id = :productId AND PDS_Is_Active__c = true];

            for (PDS_Product__c product : products) {
                Map<String, String> option = new Map<String, String>();
                option.put('value', product.Id);
                option.put('label', product.Name + ' - ' + product.PDS_Product_Size__c);
                options.add(option);
            }
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        return options;
    }

    @AuraEnabled
    public static PDSDonationRequest getDonationRequestDetails(Id donationRequestId) {
        PDSDonationRequest donationRequestData = new PDSDonationRequest();
        try {
            PDS_Donation_Request__c donationRequest = [SELECT Id, Name, PDS_Destination__c, PDS_Tax_Report_Inclusion__c, PDS_Indication__c, 
                                                       PDS_Application_Number__c, PDS_Donee__c, PDS_Donation_Type__c, PDS_Applicant_Name__c, PDS_Applicant_Institution__c, 
                                                       PDS_Approval_Date__c, PDS_Forwarding_Agent__c, PDS_Additional_Information__c, PDS_Consignee__c, PDS_Final_Recipient__c, 
                                                       PDS_Ship_Notify__c, PDS_Request_Submit_Date__c, PDS_Donation_Request_Status__c, PDS_Shipping_Status__c, 
                                                       PDS_Reviewer__c, PDS_Approver__c, PDS_Minimum_Expiration_Dating__c, PDS_PO_Number__c,
                                                       PDS_Total_Donation_Value__c, PDS_Proposal__c
                                                       FROM PDS_Donation_Request__c
                                                       WHERE Id = :donationRequestId
                                                       LIMIT 1];

            donationRequestData.donationReqId = donationRequest.Id;
            //donationRequestData.recordTypeName = donationRequest.RecordTypeName__c;
            donationRequestData.destinationValue = donationRequest.PDS_Destination__c;
            donationRequestData.taxValue = donationRequest.PDS_Tax_Report_Inclusion__c ? 'Yes' : 'No';
            donationRequestData.indicationValue = donationRequest.PDS_Indication__c;
            donationRequestData.applicationNumber = donationRequest.PDS_Application_Number__c;
            donationRequestData.doneeId = donationRequest.PDS_Donee__c;
            donationRequestData.donationType = donationRequest.PDS_Donation_Type__c;
            donationRequestData.applicantName = donationRequest.PDS_Applicant_Name__c;
            donationRequestData.applicantIns = donationRequest.PDS_Applicant_Institution__c;
            donationRequestData.approvalDate = String.valueOf(donationRequest.PDS_Approval_Date__c);
            donationRequestData.fwdAgent = donationRequest.PDS_Forwarding_Agent__c;
            donationRequestData.addInfoValue = donationRequest.PDS_Additional_Information__c;
            donationRequestData.consignee = donationRequest.PDS_Consignee__c;
            donationRequestData.finalRecipient = donationRequest.PDS_Final_Recipient__c;
            donationRequestData.shipNotify = donationRequest.PDS_Ship_Notify__c;
            donationRequestData.requestSubmitDate = String.valueOf(donationRequest.PDS_Request_Submit_Date__c);
            donationRequestData.requestStatus = donationRequest.PDS_Donation_Request_Status__c;
            donationRequestData.shippingStatus = donationRequest.PDS_Shipping_Status__c;
            donationRequestData.approver = donationRequest.PDS_Approver__c;
            donationRequestData.reviewer = donationRequest.PDS_Reviewer__c;
            donationRequestData.minExpDate = donationRequest.PDS_Minimum_Expiration_Dating__c;
            donationRequestData.poNumber = donationRequest.PDS_PO_Number__c;
            donationRequestData.totalValue = donationRequest.PDS_Total_Donation_Value__c;
            donationRequestData.proposalId = donationRequest.PDS_Proposal__c;
            

            List<ContentDocumentLink> fileTitles = new List<ContentDocumentLink>();
            fileTitles = [SELECT ContentDocument.Title FROM ContentDocumentLink 
                        WHERE LinkedEntityId = :donationRequest.Id
                        AND (ContentDocument.Title LIKE '%Approval Letter%' OR ContentDocument.Title LIKE '%Application%' OR ContentDocument.Title LIKE '%Proposal%')];

            for (ContentDocumentLink link : fileTitles) {
                String title = link.ContentDocument.Title;
                if (title.contains('Approval Letter')) {
                    donationRequestData.approvalLetterName = title;
                } else {
                    donationRequestData.proposalDocName = title;
                }
            }


            List<PDS_Product_Line_Item__c> productLineItems = [SELECT Id, Name, RecordType.Name, PDS_Product__c, PDS_Quantity_Requested__c, 
                                                                PDS_Local_Partner__c, PDS_Country__c, PDS_Shipping_Status__c, 
                                                                PDS_Tablets_Requested__c, PDS_Batch_Number__c, PDS_Expiration_Date__c,
                                                                PDS_Actual_Unit_Sale_Price__c, PDS_Actual_Product_Cost__c
                                                                FROM PDS_Product_Line_Item__c
                                                                WHERE PDS_Donation_Request__c = :donationRequestId AND PDS_Shipping_Status__c != 'Cancelled'];

            if (!productLineItems.isEmpty()) {
                donationRequestData.productLineItems = new List<PDSDonationRequest.ProductLineItem>();
                for (PDS_Product_Line_Item__c lineItem : productLineItems) {
                    PDSDonationRequest.ProductLineItem productLineItem = new PDSDonationRequest.ProductLineItem();
                    productLineItem.lineItemId = lineItem.Id;
                    productLineItem.productId = lineItem.PDS_Product__c;
                    if(lineItem.RecordType.Name == 'MDP'){
                        productLineItem.tabletsReq = lineItem.PDS_Tablets_Requested__c;
                    }else{
                        productLineItem.tabletsReq = lineItem.PDS_Quantity_Requested__c;
                    }
                    productLineItem.country = lineItem.PDS_Country__c;
                    productLineItem.shippingStatus = lineItem.PDS_Shipping_Status__c;
                    productLineItem.localPartner = lineItem.PDS_Local_Partner__c;
                    productLineItem.batchNumber = lineItem.PDS_Batch_Number__c;
                    productLineItem.actualproductPrice = lineItem.PDS_Actual_Product_Cost__c;
                    productLineItem.actualSalePrice = lineItem.PDS_Actual_Unit_Sale_Price__c;
                    productLineItem.expDate = String.valueOf(lineItem.PDS_Expiration_Date__c);
                    donationRequestData.productLineItems.add(productLineItem);
                }
            }
        } catch(Exception e) {
            System.debug('getDonationRequestDetails Exception: ' + e.getMessage());
        }
        return donationRequestData;
    }

    @AuraEnabled
    public static String processApproval(String status, String recordId) {
        try {
            String appStatus = '';
            List<ProcessInstanceWorkitem> workitems = [
                SELECT Id, ProcessInstance.Status, ActorId 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :recordId 
                AND ProcessInstance.Status = 'Pending'
                LIMIT 1
            ];

            if (status != 'reject' && status != 'approve') {
                throw new AuraHandledException('Invalid Status1: ' + status);
            }

            if (workitems.isEmpty()) {
                appStatus = 'processed';
            }else{
                ProcessInstanceWorkitem workitem = workitems[0];
                User approver = [SELECT Username FROM User WHERE Id = :workitem.ActorId LIMIT 1];

                List<MEDs_Approval_Mapping__mdt> mappingRecord = [SELECT Username__c, Email_Service_Address__c FROM MEDs_Approval_Mapping__mdt WHERE Username__c = :approver.Username LIMIT 1];
                
                if (mappingRecord.isEmpty()) {
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkItemId(workitem.Id);

                    if (status == 'approve') {
                        req.setAction('Approve');
                    } else if (status == 'reject') {
                        req.setAction('Reject');
                    } else {
                        throw new AuraHandledException('Invalid Status: ' + status);
                    }
    
                    Approval.ProcessResult result = Approval.process(req);
                }else{
                    String approverEmail = mappingRecord[0].Email_Service_Address__c;
                    PDS_Application_Setting__mdt[] pdsSettings = [select id,PDS_OrgWideEmailAddress__c,DeveloperName from PDS_Application_Setting__mdt where DeveloperName='MDP_Flow_Settings'];
                    String orgwideadd = pdsSettings[0].PDS_OrgWideEmailAddress__c;
                    OrgWideEmailAddress[] owea = [Select Id from OrgWideEmailAddress where Address =:orgwideadd];

                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { approverEmail });
                    email.setSubject(status);
                    email.setPlainTextBody(workitem.Id);
                    if ( owea.size() > 0 ) {
                        email.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                }    
                appStatus = status;
            }

            return appStatus;
        } catch (AuraHandledException e) {
            System.debug('AuraHandledException: ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }

}