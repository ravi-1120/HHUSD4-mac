/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @triggerName - MRK_Communication_Event_After_Insert_Update.trigger
* @description - Trigger for Communication Event
* @createdate - Sept 17th, 2013
*
*/

trigger MRK_Communication_Event_After_Insert_Update on Communication_Event_MRK__c (after insert, after update) {

	/**
	 * to facilitate global search, update communication event search keywords on change
	 */

	Map<Id,Communication_Event_MRK__c> commEventMapToUpdate = new Map<Id,Communication_Event_MRK__c>();
	List<Communication_Event_MRK__c> commEventListToUpdate = new List<Communication_Event_MRK__c>();


	for (Id commEventId : Trigger.newMap.keySet()) {
		Communication_Event_MRK__c newCommEvent = Trigger.newMap.get(commEventId);
	
		// check if update is needed
		if ( (newCommEvent.Search_Keywords_MRK__c == null || newCommEvent.Search_Keywords_MRK__c == '') || (newCommEvent.Search_Keywords_MRK__c != MRK_CommunicationServices.getKeywordsStringForCommunicationEvent(newCommEvent)) ) {
			commEventMapToUpdate.put(newCommEvent.Id, newCommEvent);
		}

	}

	// update comm eventss if needed
	if (!commEventMapToUpdate.isEmpty()) {
		// retrieve writable versions for update
		for (Communication_Event_MRK__c c : [select Id, Search_Keywords_MRK__c from Communication_Event_MRK__c where Id IN :commEventMapToUpdate.keySet()]) {
			Communication_Event_MRK__c newCommEvent = commEventMapToUpdate.get(c.Id);

			// update update search keywords
			c.Search_Keywords_MRK__c = MRK_CommunicationServices.getKeywordsStringForCommunicationEvent(newCommEvent);

			// add to update list
			commEventListToUpdate.add(c);
		}

		// perform updates
		update commEventListToUpdate;
	}

}