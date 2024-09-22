/*
* FulfillmentRecordTypeControllerMVN
* Created By: Roman Lerman
* Created Date: 3/1/2013
* Description: This class displays the record type of the Fulfillment on the Fulfillment detail page
*
* *** NOTE: Currently not used for the Merck implementation. ***
*/
public with sharing class FulfillmentRecordTypeControllerMVN {

    public String recordTypeName{get; private set;}

    public FulfillmentRecordTypeControllerMVN (ApexPages.StandardController controller){
        recordTypeName = [select toLabel(RecordType.Name) from Fulfillment_MVN__c where Id = :controller.getRecord().Id].RecordType.Name;
    }
}