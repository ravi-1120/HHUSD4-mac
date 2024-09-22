/*
 *  FulfillmentMVN
 *  Created By:     Kai Amundsen
 *  Created Date:   5/7/2014
 *  Description:    This is a generic Fulfillment trigger used for calling any Fulfillment logic
 *
 *  *** NOTE: Currently not used for the Merck implementation. ***
 *
 *  *** NOTE: Fulfillment records are not currently being created ***
 *		      so this logic should not fire.
 */
trigger FulfillmentMVN on Fulfillment_MVN__c (after insert, after update) {
	new TriggersMVN()
		.bind(TriggersMVN.Evt.afterinsert, new CreateLineItemsTriggerMVN())
	    .bind(TriggersMVN.Evt.afterupdate, new ReopenParentCaseWhenFulfillReopenedMVN())
	    .manage();
}