/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @triggerName - MRK_Communication_After_Insert_Update.trigger
* @description - Trigger for Communication
* @createdate - Sept 17th, 2013
*
*/

trigger MRK_Communication_After_Insert_Update on Communication_MRK__c (after insert, after update) {

	/**
	 * to facilitate global search, update communication search keywords on change
	 */

	Map<Id,Communication_MRK__c> commMapToUpdate = new Map<Id,Communication_MRK__c>();
	List<Communication_MRK__c> commListToUpdate = new List<Communication_MRK__c>();


	for (Id commId : Trigger.newMap.keySet()) {
		Communication_MRK__c newComm = Trigger.newMap.get(commId);
	
		// check if update is needed
		if ( (newComm.Search_Keywords_MRK__c == null || newComm.Search_Keywords_MRK__c == '') || (newComm.Search_Keywords_MRK__c != MRK_CommunicationServices.getKeywordsStringForCommunication(newComm)) ) {
			commMapToUpdate.put(newComm.Id, newComm);
		}

	}

	// update comms if needed
	if (!commMapToUpdate.isEmpty()) {
		// retrieve writable versions for update
		for (Communication_MRK__c c : [select Id, Search_Keywords_MRK__c from Communication_MRK__c where Id IN :commMapToUpdate.keySet()]) {
			Communication_MRK__c newComm = commMapToUpdate.get(c.Id);

			// update update search keywords
			c.Search_Keywords_MRK__c = MRK_CommunicationServices.getKeywordsStringForCommunication(newComm);

			// add to update list
			commListToUpdate.add(c);
		}

		// perform updates
		update commListToUpdate;
	}

	

}