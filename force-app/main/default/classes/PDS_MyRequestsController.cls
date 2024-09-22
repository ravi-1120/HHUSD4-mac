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
           
        String soql = 'SELECT Id, Name, PDS_Donee__c, PDS_Donee__r.Name, PDS_Donation_Type__c, ' +
                    'PDS_Donation_Request_Status__c, PDS_Shipping_Status__c, PDS_Destination__c, ' +
                    'PDS_Donation_Request_Date__c,PDS_Request_Submit_Date__c,RecordType.Name,PDS_Application_Number__c,PDS_Proposal__r.Name, ' +
                    '(SELECT Id, Name, PDS_Country__c FROM Product_Line_Items__r) ' +
                    'FROM PDS_Donation_Request__c WHERE (PDS_Requestor__c =:userId OR PDS_Donee__c IN :accountIds)';
        
        if (!String.isBlank(searchText)) {
            soql += ' AND (Name LIKE :searchStr OR PDS_Donee__r.Name LIKE :searchStr)';
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

}