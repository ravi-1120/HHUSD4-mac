Public with sharing class PDS_EmailController{
    
    @InvocableMethod(label = 'PDS send email with attachements'
                     description = 'Handles sending emails with attachments based on the request status')
    public static void sendEmailWithAttachment(List < emailProperties > emailProperties) {
        Id recordId = emailProperties[0].recordId;
        String toAddList = emailProperties[0].emailList;
        String docList = emailProperties[0].docList;
        Boolean emailService = emailProperties[0].emailService;
        String emailName = emailProperties[0].emailTemplateName;
        try{
            System.debug('emailName ' + emailName);
            //Retrieve doc names from metadata to be attached in email
            PDS_Application_Setting__mdt[] pdsSettings = [select id,PDS_EmailService_Address__c,DeveloperName from PDS_Application_Setting__mdt where DeveloperName='MDP_Flow_Settings'];
            
            List<String> multiDocs = new List<String>();
            
            if (docList.contains(',')) {
                for (String title : docList.split(',')) {
                    multiDocs.add('ContentDocument.Title LIKE \'%' + title.trim() + '%\'');
                }
            } else {
                multiDocs.add('ContentDocument.Title LIKE \'%' + docList.trim() + '%\'');
            }
            
            String query = 'SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = \'' + recordId + '\' AND (' + String.join(multiDocs, ' OR ') + ') ORDER BY ContentDocument.LastModifiedDate DESC';
            
            List<ContentDocumentLink> contentDocumentLinks = Database.query(query);
            System.debug('contentDocumentLinks'+contentDocumentLinks);
            
            if (!contentDocumentLinks.isEmpty()) {
                Set<Id> contentDocumentIds = new Set<Id>();
                for (ContentDocumentLink link : contentDocumentLinks) {
                    contentDocumentIds.add(link.ContentDocumentId);
                }
                
                // Query ContentVersions related to the ContentDocumentIds
                List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds];
                
                PDS_Donation_Request__c request = [SELECT Id, Name, RecordType.Name, PDS_Approver__c, PDS_Approver__r.Name, PDS_Reviewer__r.Name, PDS_Approver__r.Email, PDS_Total_Donation_Value__c, PDS_Donation_Request_Status__c, PDS_Donee__r.Name,PDS_Customer_Order_Number__c,PDS_Application_Number__c,
                                                   (SELECT PDS_Country__c FROM Product_Line_Items__r) 
                                                   FROM PDS_Donation_Request__c WHERE Id =: recordId LIMIT 1];

                Set<String> countryNames = new Set<String>();
                Set<String> productNames = new Set<String>();

                List<PDS_Product_Line_Item__c> productLineItems = [SELECT Id, PDS_Country__c, PDS_Product__r.Name, PDS_Total_Market_Value__c
                                                                FROM PDS_Product_Line_Item__c
                                                                WHERE PDS_Donation_Request__c = :recordId];

                for (PDS_Product_Line_Item__c item : productLineItems) {
                    if (item.PDS_Country__c != null) {
                        countryNames.add(item.PDS_Country__c);
                    }
                    if (item.PDS_Product__r != null && item.PDS_Product__r.Name != null) {
                        productNames.add(item.PDS_Product__r.Name);
                    }
                }

                String countryNamesStr = countryNames.size() == 1 ? new List<String>(countryNames)[0] : String.join(new List<String>(countryNames), ', ');
                String productNamesStr = productNames.size() == 1 ? new List<String>(productNames)[0] : String.join(new List<String>(productNames), ', ');
                
                /*List<ProcessInstanceWorkitem> pi = [SELECT Id, ActorId, ProcessInstance.Status FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: recordId AND ProcessInstance.Status = 'Pending']; 
                String processInstanceStepURL = Label.PDS_ApprovalProcessURL;
                String approvalProcessURL;
                if(!pi.isEmpty()){
                    approvalProcessURL = processInstanceStepURL +pi[0].Id;
                }*/
                
                //Send an email if there are documents available
                if (!contentVersions.isEmpty()) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                    System.debug('To Emails Flow ' + toAddList);
                    List < String > toAddresses;
                    if (toAddList.contains(',')) {
                        toAddresses = toAddList.split(',');
                    } else {
                        toAddresses = new List < String > {toAddList};
                            }
                    System.debug('To Emails ' + toAddresses);
                    
                    email.setToAddresses(toAddresses);
                    String emailBody = '';
                    //Email Header
                    emailBody +='<table width="70%" cellpadding="10" cellspacing="0" border="0" style="background: #F4FAF8; color:white;font-family: Arial; font-size: 12px;font-weight: 400; text-align: center;">'+
                        '<tr><td><table width="100%" cellpadding="0" cellspacing="5" border="0" style="text-align: center;">'+
                        '<tr><td><img src="https://msdlogin--pdsdev.sandbox.file.force.com/servlet/servlet.ImageServer?id=015RL000001vbIP&oid=00DRL000001MxFN&lastMod=1716188728000" width="20%" height="20%"/></td></tr>'+
                        '</table></td></tr></table>';
                    
                    if(emailName == 'Process Shipping'){
                        // email.setSubject('Request for shipment processing, Auth # '+request.Name);
                        email.setSubject('MECTIZAN: '+ request.PDS_Customer_Order_Number__c +', Application #'+request.PDS_Application_Number__c+','+' '+ countryNamesStr); //E2EAD-316
                        String country = request.Product_Line_Items__r.size() > 0 ? request.Product_Line_Items__r[0].PDS_Country__c : '[]';
                        emailBody +='<table width="70%" style="background: #fff; font-family: Arial; font-size: 14px;font-weight: 400; text-align: left;" cellpadding="20" cellspacing="0" border="0">'+
                            '<tr><td>'+
                            '<table cellpadding="0" cellspacing="12" border="0">'+
                            '<tr><td>Hello everyone,</td></tr>'+
                            '<tr><td>Please find attached documents per the approved  MECTIZAN donation for '+country+'. The name of the donee is '+request.PDS_Donee__r.Name+'.</td></tr>'+
                            '<tr><td>Best regards,<br/>MEDs Automated Notification System</td></tr>'+
                            '</table>'+
                            '</td></tr>'+
                            '</table>';
                    }else if(emailName == 'Approval'){
                        Decimal totalValue;
                        if(request.RecordType.Name == 'MDP'){
                            email.setSubject('Proposed Donation- Auth # '+request.Name);
                            totalValue = productLineItems.size() > 0 ? productLineItems[0].PDS_Total_Market_Value__c : 0;
                        }else{
                            email.setSubject('Request Approval - Auth # '+request.Name);
                            totalValue = request.PDS_Total_Donation_Value__c;
                            //totalValue = request.PDS_Total_Donation_Values__c;
                        }
                        String totalValueString1 = String.valueOf(totalValue);
						String totalValueDecimalPart = '';

						Integer totalValueDecimalIndex = totalValueString1.indexOf('.');
						if (totalValueDecimalIndex != -1) {
						    totalValueDecimalPart = '.' + totalValueString1.substring(totalValueDecimalIndex + 1);
						}
						String formattedTotalValue = totalValue.format() + totalValueDecimalPart;
                       	  
                        
                        String emailButtons = '<table border="0" cellpadding="0" cellspacing="0">' +
                        '<tr>' +
                            '<td align="center">' +
                                '<table border="0" cellpadding="0" cellspacing="0" width="60" style="max-width: 60px; height: 30px;">' +
                                    '<tr style="background-color: #00857C;">' +
                                        '<td style="background-color: #00857C; height: 30px;">' +
                                            '<a href="' + System.label.PDS_Portal_URL + '/donation-request/approval-process?status=approve&prid=' + recordId + '" ' +
                                            'style="display: inline-block; color: #FFFFFF; text-decoration: none; font-size: 14px; line-height: 16px; font-weight: 700; letter-spacing: 0.861539px; background-color: #00857C; padding: 6px; border-radius: 5px; font-family: Arial; text-align: center; border: solid 1px #00857C;">' +
                                            'Approve' +
                                            '</a>' +
                                        '</td>' +
                                    '</tr>' +
                                '</table>' +
                            '</td>' +
                            '<td style="width: 10px;">&nbsp;</td>' +
                            '<td align="center">' +
                                '<table border="0" cellpadding="0" cellspacing="0" width="60" style="max-width: 60px; height: 30px;">' +
                                    '<tr style="background-color: #DB1E28;">' +
                                        '<td style="background-color: #DB1E28; height: 30px;">' +
                                            '<a href="' + System.label.PDS_Portal_URL + '/donation-request/approval-process?status=reject&prid=' + recordId + '" ' +
                                            'style="display: inline-block; color: #FFFFFF; text-decoration: none; font-size: 14px; line-height: 16px; font-weight: 700; letter-spacing: 0.861539px; background-color: #DB1E28; padding: 6px; border-radius: 5px; font-family: Arial; text-align: center; border: solid 1px #DB1E28;">' +
                                            'Reject' +
                                            '</a>' +
                                        '</td>' +
                                    '</tr>' +
                                '</table>' +
                            '</td>' +
                        '</tr>' +
                    '</table>';


                        
                    emailBody +='<table width="70%" style="background: #fff; font-family: Arial; font-size: 14px;font-weight: 400; text-align: left;" cellpadding="20" cellspacing="0" border="0">'+
                        '<tr><td>'+
                        '<table cellpadding="0" cellspacing="12" border="0">'+
                        '<tr><td>Hello ' + request.PDS_Approver__r.Name +',</td></tr>'+
                        '<tr><td>Your approval is requested to process the donation of <strong>'+productNamesStr+'</strong> products, as shown on the attached no-charge invoice to <strong>'+request.PDS_Donee__r.Name+'</strong>, for use in <strong>'+countryNamesStr+'</strong>. Total cost of the material is <strong>US $'+formattedTotalValue+'</strong>.</td></tr>'+
                        '<tr><td>'+emailButtons+'</td></tr>'+
                        '<tr><td>Best regards,<br/>'+request.PDS_Reviewer__r.Name+'</td></tr>'+
                        '</table>'+
                        '</td></tr>'+
                        '</table>';
                        
                    }else{
                        email.setSubject('('+request.Name+')');
                        emailBody = '<Placeholder body>';
                    }
                    
                    //Email Footer
                    emailBody +='<table width="70%" style="background: #00857C;  color:white;font-family: Arial; font-size: 12px;font-weight: 400; text-align: left;" cellpadding="10" cellspacing="0" border="0">'+
                        '<tr><td>'+
                        '<table cellpadding="0" cellspacing="5" border="0">'+
                        '<tr><td><img src="https://msdlogin--pdsdev.sandbox.file.force.com/servlet/servlet.ImageServer?id=015RL000001vfKQ&oid=00DRL000001MxFN&lastMod=1716266678000" width="100" height="35"/></td></tr>'+
                        '<tr><td style="color:white;">Copyright © 2024 Merck & Co., Inc., Rahway, NJ USA, and its affiliates. All rights reserved.</td></tr>'+
                        '</table>'+
                        '</td></tr>'+
                        '</table>';
                    
                    email.setHtmlBody(emailBody);
                    
                    //Add reply to address when enabling approve via email functionality
                    if(emailService != false){
                        email.setReplyTo(pdsSettings[0].PDS_EmailService_Address__c);   
                    }
                    
                    for (ContentVersion contentVersion : contentVersions) {
                        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                        emailAttachment.setFileName(contentVersion.Title);
                        emailAttachment.setBody(contentVersion.VersionData);
                        emailAttachments.add(emailAttachment);
                    }
                    
                    //Add all attachments to email
                    email.setFileAttachments(emailAttachments);
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                    if (results[0].isSuccess()) {
                        System.debug('Email sent successfully.');
                    } else {
                        System.debug('Failed to send email: ' + results[0].getErrors()[0].getMessage());
                    }
                } else {
                    System.debug('No ContentVersion found for the ContentDocumentId.');
                }     
            }      
        } Catch(Exception e){
            System.debug('Email Error Message: ' + e.getMessage());
        }      
    }
    
    public class emailProperties {
        @InvocableVariable(label = 'Record Id'
                           description = 'The Id of the record to attach the document to'
                           required = true)
        public Id recordId;
        @InvocableVariable(label = 'Flow Type'
                           description = 'Type of the donation request flow'
                           required = true)
        public String flowType;
        @InvocableVariable(label = 'Email List'
                           description = 'List of emails seperated by comma'
                           required = true)
        public String emailList;
        @InvocableVariable(label = 'Document List'
                           description = 'List of documents to be attached'
                           required = true)
        public String docList; 
        @InvocableVariable(label = 'Email Service'
                           description = 'let user approve request by email reply'
                           required = true)
        public Boolean emailService;
        @InvocableVariable(label = 'Email Template'
                           description = 'Name of the email template to be used'
                           required = false)
        public String emailTemplateName; 
    }
    
    
    
    
}