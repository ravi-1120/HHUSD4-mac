/*
* CreateCasesForMedicalInquiryMVN
* Created By: Kai Chen
* Created Date: 7/28/2013
* Updated By: Rick Locke
* Updated Date: 5/28/2014
* Description: This class creates an interaction and request for a medical inquiry
*
* *** NOTE: Currently not used for the Merck implementation. ***
*/
public class CreateCasesForMedicalInquiryMVN implements TriggersMVN.HandlerInterface
{
    private static Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
    private static Id requestRecordTypeId {get;set;}

    static {
        for (Id recordTypeId : UtilitiesMVN.typeMap.keySet()) {
            if (UtilitiesMVN.typeMap.get(recordTypeId).DeveloperName == settings.Request_Record_Type_MVN__c) {
                requestRecordTypeId = recordTypeId;
            }
            if (requestRecordTypeId != null) {
                break;
            }
        }
    }

    public void handle() {
        List<Medical_Inquiry_vod__c> inquiries = new List<Medical_Inquiry_vod__c>();
        Map<Id, Medical_Inquiry_vod__c> oldInquiries = new Map<Id, Medical_Inquiry_vod__c>();

        if(Trigger.isInsert) {
            inquiries = (List<Medical_Inquiry_vod__c>) trigger.new;
        }
        else if(Trigger.isUpdate) {
            inquiries = (List<Medical_Inquiry_vod__c>) trigger.new;
            oldInquiries = (Map<Id, Medical_Inquiry_vod__c>) trigger.oldMap;
        }

        List<Case> requestsToCreate = new List<Case>();

        Map<Id, Medical_Inquiry_vod__c> inquiriesMap = new Map<Id, Medical_Inquiry_vod__c>(inquiries);

        Map<Id, Medical_Inquiry_vod__c> relatedCases = new Map<Id, Medical_Inquiry_vod__c>([select Id, (select Id from Cases__r) from Medical_Inquiry_vod__c where Id in :inquiriesMap.keySet()]);

        List<Medical_Inquiry_vod__c> eligibleInquiries = new List<Medical_Inquiry_vod__c>();

        Map<String, Id> productNameToIdMap = new Map<String, Id>();

        for (Product_vod__c p : [SELECT Id, Name FROM Product_vod__c]){
            productNameToIdMap.put(p.Name, p.Id);
        }

        //Only concerned with inquiries that are not related to a case and has a submitted status
        if(Trigger.isInsert) {
            for(Medical_Inquiry_vod__c inquiry : inquiries){
                if(inquiry.Status_vod__c == settings.Medical_Inquiry_Submitted_Status_MVN__c 
                    && relatedCases.get(inquiry.Id).Cases__r.isEmpty()){
                        eligibleInquiries.add(inquiry);
                }
            }
        }
        else if(Trigger.isUpdate) {
            for(Medical_Inquiry_vod__c inquiry : inquiries){
                if(oldInquiries.get(inquiry.Id).Status_vod__c != settings.Medical_Inquiry_Submitted_Status_MVN__c 
                    && inquiry.Status_vod__c == settings.Medical_Inquiry_Submitted_Status_MVN__c
                    && relatedCases.get(inquiry.Id).Cases__r.isEmpty()){
                    eligibleInquiries.add(inquiry);
                }
            }
        }



        List<Medical_Inquiry_vod__c> inquiriesWithoutFedId = new List<Medical_Inquiry_vod__c>();

        //Get fed id to inquiries
        Map<String, Id> federationIdToInquiryMap = new Map<String, Id>();

        for (Medical_Inquiry_vod__c newInquiry : eligibleInquiries){
            if (String.isBlank(newInquiry.Federation_Id_MVN__c)){
                inquiriesWithoutFedId.add(newInquiry);
            } else {
                federationIdToInquiryMap.put(newInquiry.Federation_Id_MVN__c, newInquiry.Id);
            }
        }
        //Get users for inquiries
        map<Id, Id> inquiryUserMap = new Map<Id, Id>();
        for (Medical_Inquiry_vod__c mi : inquiriesWithoutFedId){
            Id userId = UserInfo.getUserId();
            inquiryUserMap.put(mi.Id, userId);
        }

        //get users to fed id
        map<Id, String> userIdToFederationIdMap = new Map<Id, String>();
        for (User u : [SELECT FederationIdentifier FROM User WHERE Id in : inquiryUserMap.values()]){
            if(!String.isBlank(u.FederationIdentifier)){
                userIdToFederationIdMap.put(u.Id, u.FederationIdentifier);
            }
        }

        //Fill in the remainder of the fed ids to inquiries
        for(Medical_Inquiry_vod__c mi : inquiriesWithoutFedId){
            Id userId = inquiryUserMap.get(mi.Id);
            if(userId != null && userIdToFederationIdMap.get(userId) != null){
                federationIdToInquiryMap.put(userIdToFederationIdMap.get(userId), mi.Id);
            }
        }

        //Now ready to get the account (sales rep) Ids to inquireies
        Map<Id, Id> inquieryIdToAccountIdMap = new Map<Id, Id>();
        for (Account a : [SELECT Id, External_ID_vod__c FROM Account WHERE External_ID_vod__c in :federationIdToInquiryMap.keySet()]){
            inquieryIdToAccountIdMap.put(federationIdToInquiryMap.get( a.External_ID_vod__c), a.Id);
        }

        Map<Id, Id> inquiryContactIdMap = inquiryAccountIdToContactIdMapBuilder(eligibleInquiries);

        for(Medical_Inquiry_vod__c newInquiry : eligibleInquiries){
            Case request = caseBuilder(newInquiry, inquiryContactIdMap);
            request.RecordTypeId = requestRecordTypeId;
            request.Referred_By_MVN__c = inquieryIdToAccountIdMap.get(newInquiry.Id);
            request.Product_MVN__c = productNameToIdMap.get(newInquiry.Product__c);
            if(String.isNotBlank(newInquiry.Group_Identifier_vod__c)){
                request.Medical_Inquiry_Group_Identifier_MVN__c = newInquiry.Group_Identifier_vod__c;
            }
            requestsToCreate.add(request);
        }

        insert requestsToCreate;  

    }

    public map<Id, Id> inquiryAccountIdToContactIdMapBuilder(List<Medical_Inquiry_vod__c> inquiries){
        
        map<Id, Id> result = new map<Id, Id>();
        List<Id> accountVodIds = new List<Id>();

        for (Medical_Inquiry_vod__c inquiry : inquiries) {
            accountVodIds.add(inquiry.Account_vod__c);
        }

        for (Account account : [select Id, PersonContactId from Account where Id = :accountVodIds]) {
            result.put(account.Id, account.PersonContactId);
        }

        return result;
    }

    //common code when building cases
    public Case caseBuilder(Medical_Inquiry_vod__c inquiry, map<Id, Id> inquiryContactIdMap) {
        Case result = new Case();
        result.Medical_Inquiry_MVN__c = inquiry.Id;
        result.AccountId = inquiry.Account_vod__c;
        result.Details_MVN__c = inquiry.Inquiry_Text__c;
        result.ContactId = inquiryContactIdMap.get(inquiry.Account_vod__c);
        result.Origin = settings.Medical_Inquiry_Source_MVN__c;
        String deliveryMethod = inquiry.Delivery_Method_vod__c;
        if(inquiry.Delivery_Method_vod__c == null || Case_Delivery_Method_Map_MVN__c.getValues(deliveryMethod) == null) {
            result.MSD_CORE_Global_MedInfo_Delivery_Method__c = inquiry.Delivery_Method_vod__c;
        } else {
            result.MSD_CORE_Global_MedInfo_Delivery_Method__c = Case_Delivery_Method_Map_MVN__c.getValues(deliveryMethod).Case_Translation_MVN__c;          
        } 

        return result;
    }
}