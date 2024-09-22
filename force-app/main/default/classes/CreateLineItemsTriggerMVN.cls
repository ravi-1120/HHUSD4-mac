/*
* CreateLineItemsTriggerMVN
* Created By: Kai Amundsen
* Created Date: June 12, 2014
* Description: This trigger handler is used to copy all of the Cases associated
*			   with an Interaction to the Fulfillment.  It is used to report
*			   on the Cases that a Fulfillment is responding to.
*
* *** NOTE: Currently not used for the Merck implementation. ***
*/
public with sharing class CreateLineItemsTriggerMVN implements TriggersMVN.HandlerInterface {

	public void handle() {
		Set<Id> interactionIds = new Set<Id>();
		Map<Id,List<Id>> fulfillmentMap = new Map<Id,List<Id>>();
		for(Fulfillment_MVN__c ful : (List<Fulfillment_MVN__c>) Trigger.new) {
			interactionIds.add(ful.Case_MVN__c);
			if(fulfillmentMap.containsKey(ful.Case_MVN__c)) {
				fulfillmentMap.get(ful.Case_MVN__c).add(ful.Id);
			} else {
				fulfillmentMap.put(ful.Case_MVN__c,new List<Id>{ful.Id});
			}
		}
		System.debug(interactionIds);

		List<Case> requests = [select Id,ParentId from Case where ParentID in :interactionIds and RecordTypeId = :TestDataFactoryMVN.requestRecordTypeId];
		System.debug(requests);

		List<Fulfillment_Line_Item_MVN__c> lineItems = new List<Fulfillment_Line_Item_MVN__c>();
		for(Case c : requests) {
			for(Id fulId : fulfillmentMap.get(c.ParentId)) {
				Fulfillment_Line_Item_MVN__c fli = new Fulfillment_Line_Item_MVN__c();
				fli.Case_MVN__c = c.Id;
				fli.Fulfillment_MVN__c = fulId;
				System.debug(fli);
				lineItems.add(fli);
			}
		}

		insert lineItems;
	}
}