/*
* Class: PDS_DashboardController
* Author: Rusheel
* Created On: 04/10/2024
* Last Modified: 06/17/2024
* Version: Initial
*/
public without sharing class PDS_DashboardController {
    @AuraEnabled
    public static String getRequestPage(String userid){
        String returnval = '';
        try {
            User usr = new User();
            usr = [SELECT Id, Name, AccountId FROM User WHERE Id =: userid AND Profile.Name = 'PDS Taskforce' ORDER BY LastmodifiedDate DESC LIMIT 1];
            System.debug('usr' +usr);
            String accountid = usr.AccountId;
            System.debug('accountid' +accountid);
            List<PDS_Program_Access__c> paccess = new List<PDS_Program_Access__c>();
            paccess = [Select Id,Name,PDS_Donee__c,PDS_Is_Active__c,PDS_Program__r.Name from PDS_Program_Access__c where PDS_Is_Active__c=true AND PDS_Donee__c =: accountid];
            System.debug('paccess' +paccess);
            if(paccess[0].PDS_Program__r.Name == 'MDP'){
                returnval = 'MDP';
            }else{
                returnval = 'MMOP';
            }
            return returnval;
        } 
        catch (Exception e) {
            System.debug('Error in getRequestPage: ' + e.getMessage());
            return 'Error';
        }
    }
    
    // @AuraEnabled(cacheable=true)
    // public static List<RelatedMMOPProducts> getRelatedProducts(String donationType) {
    //     List<RelatedMMOPProducts> productDetails = new List<RelatedMMOPProducts>();
    //     List<PDS_Proposal__c> proposals = [SELECT Id, Name, (SELECT PDS_Available_Quantity__c, PDS_Batch_Number__c, PDS_Expiration_Date__c, PDS_Product__r.Name, PDS_Product__r.PDS_Actual_Unit_Sale_Price__c, PDS_Product__r.PDS_NDC_Number__c,PDS_Product__r.PDS_Cold_Chain__c,PDS_Product__r.PDS_SAP_Code__c, PDS_Product__r.Id FROM Related_Products__r)
    //                                        FROM PDS_Proposal__c
    //                                        WHERE PDS_Donation_Type__c = :donationType AND PDS_Status__c ='Submitted'];
    
    //     for (PDS_Proposal__c proposal : proposals) {
    //         for (PDS_Related_Product__c relatedProduct : proposal.Related_Products__r) {
    //             RelatedMMOPProducts productWrapper = new RelatedMMOPProducts();
    //             productWrapper.productId = relatedProduct.PDS_Product__r.Id;
    //             productWrapper.productName = relatedProduct.PDS_Product__r.Name;
    //             productWrapper.productSap = relatedProduct.PDS_Product__r.PDS_SAP_Code__c;
    //             productWrapper.productPrice = relatedProduct.PDS_Product__r.PDS_Actual_Unit_Sale_Price__c;
    //             productWrapper.batchNumber = relatedProduct.PDS_Batch_Number__c;
    //             productWrapper.expDate = relatedProduct.PDS_Expiration_Date__c;
    //             productWrapper.availableQty = relatedProduct.PDS_Available_Quantity__c;
    //             productWrapper.ndcNumber = relatedProduct.PDS_Product__r.PDS_NDC_Number__c;
    //             productWrapper.isColdChain = relatedProduct.PDS_Product__r.PDS_Cold_Chain__c;
    //             productDetails.add(productWrapper);
    //         }
    //     }
    //     return productDetails;
    // }
    @AuraEnabled(cacheable=true)
    public static List<RelatedMMOPProducts> getRelatedProducts(String donationType,String proposalId) {
        List<RelatedMMOPProducts> productDetails = new List<RelatedMMOPProducts>();
        List<PDS_Proposal__c> proposals = [SELECT Id, Name, (SELECT PDS_Available_Quantity__c, PDS_Batch_Number__c, PDS_Expiration_Date__c, PDS_Product__r.Name, PDS_Product__r.PDS_Actual_Unit_Sale_Price__c, PDS_Product__r.PDS_Actual_Product_Cost__c, PDS_Product__r.PDS_NDC_Number__c,PDS_Product__r.PDS_Cold_Chain__c,PDS_Product__r.PDS_SAP_Code__c, PDS_Product__r.Id FROM Related_Products__r)
                                           FROM PDS_Proposal__c
                                           WHERE Id =:proposalId AND PDS_Donation_Type__c=:donationType AND PDS_Status__c ='Submitted'];
        
        
        List<PDS_Related_Product__c> allRelatedProducts = new List<PDS_Related_Product__c>();
        for (PDS_Proposal__c proposal : proposals) {
            allRelatedProducts.addAll(proposal.Related_Products__r);
        }
        allRelatedProducts.sort(new ComparatorProductName());
        for (PDS_Related_Product__c relatedProduct : allRelatedProducts) {
            RelatedMMOPProducts productWrapper = new RelatedMMOPProducts();
            productWrapper.productId = relatedProduct.PDS_Product__r.Id;
            productWrapper.productName = relatedProduct.PDS_Product__r.Name;
            productWrapper.productSap = relatedProduct.PDS_Product__r.PDS_SAP_Code__c;
            productWrapper.productPrice = relatedProduct.PDS_Product__r.PDS_Actual_Unit_Sale_Price__c;
            productWrapper.actualProductPrice = relatedProduct.PDS_Product__r.PDS_Actual_Product_Cost__c;
            productWrapper.batchNumber = relatedProduct.PDS_Batch_Number__c;
            productWrapper.expDate = relatedProduct.PDS_Expiration_Date__c;
            productWrapper.availableQty = relatedProduct.PDS_Available_Quantity__c;
            productWrapper.ndcNumber = relatedProduct.PDS_Product__r.PDS_NDC_Number__c;
            productWrapper.isColdChain = relatedProduct.PDS_Product__r.PDS_Cold_Chain__c;
            productDetails.add(productWrapper);
        }
        System.debug('productDetails'+productDetails);
        return productDetails;
    }
    public class ComparatorProductName implements Comparator<PDS_Related_Product__c> {
        public Integer compare(PDS_Related_Product__c a, PDS_Related_Product__c b) {
            return a.PDS_Product__r.Name.toLowerCase().compareTo(b.PDS_Product__r.Name.toLowerCase());
        }
    } 
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRelatedDonationTypes(String userId) {
        List<Map<String, String>> donationTypes = new List<Map<String, String>>();
        
        // Query the User record
        User usr = [SELECT Id, AccountId FROM User WHERE Id = :userId AND Profile.Name = 'PDS Taskforce' LIMIT 1];
        System.debug('User Query: ' + usr);
        
        // Query the Proposal Access records related to the user's account
        List<PDS_Proposal_Access__c> proposalAccessList = [SELECT Proposal__c, Proposal__r.PDS_Donation_Type__c,Proposal__r.PDS_Program__c,
                                                           Proposal__r.PDS_Status__c,Proposal__r.Name
                                                           FROM PDS_Proposal_Access__c 
                                                           WHERE Donee__c = :usr.AccountId 
                                                           AND Proposal__c IN (SELECT Id FROM PDS_Proposal__c WHERE PDS_Status__c = 'Submitted') ORDER BY Proposal__r.Name];
        System.debug('Proposal Access Query: ' + proposalAccessList);
        
        // Extract the Donation Type values from the queried records
        for (PDS_Proposal_Access__c proposalAccess : proposalAccessList) {
            if (proposalAccess.Proposal__c != null && proposalAccess.Proposal__r.PDS_Donation_Type__c != null) {
                Map<String, String> donationTypeMap = new Map<String, String>();
                donationTypeMap.put('proposalId', proposalAccess.Proposal__c);
                donationTypeMap.put('donationType', proposalAccess.Proposal__r.PDS_Donation_Type__c);
                donationTypeMap.put('donationName', proposalAccess.Proposal__r.Name);
                donationTypes.add(donationTypeMap);
            }
        }
        System.debug('donationTypes'+donationTypes);
        return donationTypes;
    }
    
    public class RelatedMMOPProducts {
        @AuraEnabled
        public String productId { get; set; }
        @AuraEnabled
        public String productName { get; set; }
        @AuraEnabled
        public String productSap { get; set; }
        @AuraEnabled
        public Decimal productPrice { get; set; }  
        @AuraEnabled
        public Decimal actualProductPrice { get; set; }  
        @AuraEnabled
        public String batchNumber { get; set; }
        @AuraEnabled
        public Date expDate { get; set; }
        @AuraEnabled
        public Decimal availableQty { get; set; }
        @AuraEnabled
        public String ndcNumber { get; set; }
        @AuraEnabled
        public Boolean isColdChain { get; set; }   
    }

    @InvocableMethod(label = 'Generate and Send Proposal Notification'
                     description = 'Notification to MEDs user')
    public static void generateProposalNotification(List < EmailProperties > emailPropertiesList) {

        EmailTemplate emailTemplate = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate  WHERE DeveloperName = 'Proposal_Notification_Email' LIMIT 1];
        PDS_Application_Setting__mdt[] pdsSettings = [select id,PDS_OrgWideEmailAddress__c,DeveloperName from PDS_Application_Setting__mdt where DeveloperName='MDP_Flow_Settings'];
        String orgwideadd = pdsSettings[0].PDS_OrgWideEmailAddress__c;
        OrgWideEmailAddress[] owea = [Select Id from OrgWideEmailAddress where Address =:orgwideadd];
        String toAddList = emailPropertiesList[0].emailList;

        // Create the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
       // email.setTargetObjectId(emailPropertiesList[0].recordId);
       String emailBody = emailTemplate.HtmlValue
       .replace('{donee}', emailPropertiesList[0].DoneeName)
       .replace('{donationType}', emailPropertiesList[0].DonationType);
        email.setHtmlBody(emailBody);
        email.setSubject('Notification of New MEDs Proposal on the portal');

        if ( owea.size() > 0 ) {
            email.setOrgWideEmailAddressId(owea.get(0).Id);
        }

        List < String > toAddresses;
        if (toAddList.contains(',')) {
            toAddresses = toAddList.split(',');
        } else {
            toAddresses = new List < String > {toAddList};
        }
        System.debug('To Emails ' + toAddresses);
        
        email.setToAddresses(toAddresses);
        //email.setToAddresses(new String[] { emailPropertiesList[0].userEmail });

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        if (results[0].isSuccess()) {
            System.debug('Email sent successfully.');
        } else {
            System.debug('Failed to send email: ' + results[0].getErrors()[0].getMessage());
        }
    }

    public class EmailProperties {
        @InvocableVariable(label = 'DonationType'
                           description = 'Proposal DOnation Type'
                           required = true) 
        public String DonationType;
        @InvocableVariable(label = 'UserEmail'
                        description = 'Email address of the User'
                        required = false)
        public String userEmail;
        @InvocableVariable(label = 'DoneeName'
                        description = 'Current Donee Name'
                        required = true)
        public String DoneeName;
        @InvocableVariable(label = 'Email List'
                           description = 'List of emails seperated by comma'
                           required = false)
        public String emailList;
    }
}