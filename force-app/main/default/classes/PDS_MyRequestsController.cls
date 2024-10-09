/*
* Class: PDS_MyRequestsController
* Test Class: PDS_MyRequestsControllerTest
* Description: Controller class for PDSMyRequests LWC
* Author: Raghvendra Rathore (Focal CXM)
* Created On: 04/18/2024
* Version: Initial
*/
public without sharing class PDS_MyRequestsController {
    /**
     * Name     :   filterRequests
     * Param 1  :   userId (String)
     * Param 2  :   Search text (String)
     * Param 3  :   Status (String)
     * Return   :   List of PDS_Donation_Request__c
     */
    @AuraEnabled
    public static List<PDS_Donation_Request__c> filterRequests(String userId, String searchText, String status,String dtype) {
        //String searchStr = '%' + searchText + '%';
        String searchStr = (searchText != null && searchText != '') ? '%' + searchText + '%' : null; 
        User usr = [Select Id,Name,ContactId FROM User Where Id =:userId];
        String conId = usr.ContactId;
        // String usrId = usr.Id;
    	List<PDS_Donee_Contact__c> doneeCon = [SELECT Id, Name, PDS_Donee__c, PDS_Contact__c FROM PDS_Donee_Contact__c WHERE PDS_Contact__c = :conId];
        Set<Id> accountIds = new Set<Id>();
        for (PDS_Donee_Contact__c donee : doneeCon) {
            if (donee.PDS_Donee__c != null) {
                accountIds.add(donee.PDS_Donee__c);
            }
        }
           
        String soql = 'SELECT Id, Name, PDS_Donee__c, PDS_Donee__r.Name,PDS_Donee__r.Formatted_Name_vod__c, PDS_Donation_Type__c, ' +
                    'PDS_Donation_Request_Status__c, PDS_Shipping_Status__c, PDS_Destination__c, ' +
                    'PDS_Donation_Request_Date__c,PDS_Request_Submit_Date__c,RecordType.Name,PDS_Application_Number__c,PDS_Proposal__r.Name,PDS_Open_For_ReAllocation__c, ' +
                    '(SELECT Id, Name, PDS_Country__c FROM Product_Line_Items__r) ' +
                    'FROM PDS_Donation_Request__c WHERE (PDS_Requestor__c =:userId OR PDS_Donee__c IN :accountIds)';
        
        if (!String.isBlank(searchText)) {
            soql += ' AND (Name LIKE :searchStr OR PDS_Donee__r.Formatted_Name_vod__c LIKE :searchStr)';
        }

        if (!String.isBlank(status)) {
            soql += ' AND PDS_Donation_Request_Status__c = :status';
        }
        if (!String.isBlank(dtype)) {
            soql += ' AND PDS_Donation_Type__c = :dtype';
        }
        soql += ' ORDER BY CreatedDate DESC';
        System.debug('soql' +soql);
       	return Database.query(soql);
    }
   @InvocableMethod(label = 'Generate and Send Consginee Notification'
                     description = 'Notification to MEDs Contact')
    public static void generateProposalNotification(List < EmailProperties > emailPropertiesList) {

        EmailTemplate emailTemplate = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate  WHERE DeveloperName = 'Consignee_Email' LIMIT 1];
        PDS_Application_Setting__mdt[] pdsSettings = [select id,PDS_OrgWideEmailAddress__c,DeveloperName from PDS_Application_Setting__mdt where DeveloperName='MDP_Flow_Settings'];
        String orgwideadd = pdsSettings[0].PDS_OrgWideEmailAddress__c;
        OrgWideEmailAddress[] owea = [Select Id from OrgWideEmailAddress where Address =:orgwideadd];
        String toAddList = emailPropertiesList[0].emailList;
        List<Document> doc = [Select Id,Name,DeveloperName from Document where DeveloperName = 'MEDs_Logo' Limit 1];
        String docId = doc[0].ID;
        String orgId = UserInfo.getOrganizationId();
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String imageUrl = baseUrl + '/servlet/servlet.ImageServer?id=' + docId + '&oid=' + orgId;
        System.debug('imageUrl' +imageUrl);
        List<Document> doc2 = [Select Id,Name,DeveloperName from Document where DeveloperName = 'MSD_Logo_White' Limit 1];
        String fdocId = doc2[0].ID;
        String footerImg = baseUrl + '/servlet/servlet.ImageServer?id=' + fdocId + '&oid=' + orgId;
        System.debug('footerImg-->' +footerImg);
        String encodedId = EncodingUtil.base64Encode(Blob.valueOf(emailPropertiesList[0].recId));
        String consigneeURL = System.label.PDS_Portal_URL + '/consignee' + '?id=' + encodedId;
        //String consingeeURL = System.label.PDS_Portal_URL+'/consignee'+'?id='+emailPropertiesList[0].recId;
        // Create the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
       // email.setTargetObjectId(emailPropertiesList[0].recordId);
       String emailBody = emailTemplate.HtmlValue
       .replace('{donee}', emailPropertiesList[0].DoneeName)
       .replace('{imgURL}',imageUrl)
       .replace('{footerUrl}',footerImg)
       .replace('{portalURL}',consigneeURL);
        email.setHtmlBody(emailBody);
        email.setSubject('Acknowledgement for Products Delivered');

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
        @InvocableVariable(label = 'UserEmail'
                        description = 'Email address of the User'
                        required = false)
        public String userEmail;
        @InvocableVariable(label = 'ConsigneeName'
                        description = 'Current Contact Name'
                        required = true)
        public String DoneeName;
        @InvocableVariable(label = 'Email List'
                           description = 'List of emails seperated by comma'
                           required = false)
        public String emailList;
        @InvocableVariable(label = 'Id'
                           description = 'Current Record Id'
                           required = false)
        public String recId;
    }
    @AuraEnabled
    public static string updateShipping(String requestid){
        String returnvalue = '';
        try {
            PDS_Donation_Request__c req = [SELECT ID, Name,PDS_Request_Resolution__c, PDS_Donation_Request_Status__c,PDS_Shipping_Status__c FROM PDS_Donation_Request__c WHERE ID =: requestid];
            req.PDS_Shipping_Status__c = 'Delivered';
            System.debug(LoggingLevel.WARN,'after req:'+req.PDS_Donation_Request_Status__c);
            update req;
            returnvalue = 'Shipment Delivered';
        } catch (Exception e) { returnvalue = e.getMessage();} 
        return returnvalue;
    }
}