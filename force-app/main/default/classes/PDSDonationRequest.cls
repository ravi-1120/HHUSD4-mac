/*
* Class: PDSDonationRequest
* Author: Gopi Chintamaneni
* Created On: 04/22/2024
* Last Modified: 04/22/2024
*/
public class PDSDonationRequest {
    @AuraEnabled
    public String donationReqId {get;set;}
    @AuraEnabled
    public String recordTypeName {get;set;}
    @AuraEnabled
    public String destinationValue {get;set;}
    @AuraEnabled
    public String taxValue {get;set;}
    @AuraEnabled
    public String indicationValue {get;set;}
    @AuraEnabled
    public String applicationNumber {get;set;}
    @AuraEnabled
    public String doneeId {get;set;}
    @AuraEnabled
    public String donationType {get;set;}
    @AuraEnabled
    public String applicantName {get;set;}
    @AuraEnabled
    public String applicantIns {get;set;}
    @AuraEnabled
    public String approvalDate {get;set;}
    @AuraEnabled
    public String fwdAgent {get;set;}
    @AuraEnabled
    public String addInfoValue {get;set;}
    @AuraEnabled
    public String consignee {get;set;}
    @AuraEnabled
    public String finalRecipient {get;set;}
    @AuraEnabled
    public String shipNotify {get;set;}
    @AuraEnabled
    public String requestSubmitDate {get;set;}
    @AuraEnabled
    public String requestStatus {get;set;}
    @AuraEnabled
    public String shippingStatus {get;set;}
    @AuraEnabled
    public String approver {get;set;}
    @AuraEnabled
    public String reviewer {get;set;}
    @AuraEnabled
    public List<ProductLineItem> productLineItems {get;set;}
    @AuraEnabled
    public String proposalDocument {get;set;}
    @AuraEnabled
    public String proposalDocName {get;set;}
    @AuraEnabled
    public String approvalLetter {get;set;}
    @AuraEnabled
    public String approvalLetterName {get;set;}
    @AuraEnabled
    public String poNumber {get;set;}
    @AuraEnabled
    public Decimal totalValue {get;set;}
    @AuraEnabled
    public String minExpDate {get;set;}
    @AuraEnabled
    public String updateNotify {get;set;}
    @AuraEnabled
    public String proposalId {get;set;}

    public class ProductLineItem{
            @AuraEnabled
            public  String lineItemId {get;set;}
            @AuraEnabled
            public  String productId {get;set;}
            @AuraEnabled
            public  String country {get;set;}
            @AuraEnabled
            public  String shippingStatus {get;set;}
            @AuraEnabled
            public  Decimal tabletsReq {get;set;}
            @AuraEnabled
            public  String localPartner {get;set;}
            @AuraEnabled
            public  String batchNumber {get;set;}
            @AuraEnabled
            public  String expDate {get;set;}
            @AuraEnabled
            public  Decimal actualproductPrice {get;set;}
            @AuraEnabled
            public  Decimal actualSalePrice {get;set;} 
    }
}