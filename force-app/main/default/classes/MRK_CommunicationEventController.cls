/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_CommunicationEventController.cls
* @description - Communication Event Controller
* @createdate - Oct 16th, 2013
*
*/

public class MRK_CommunicationEventController {

	private Map<string,string> pageParams = ApexPages.currentPage().getParameters();

	public MRK_CommunicationEventController() {
		
	}

	public PageReference redirectToEventForUser() {
		PageReference pr = null;
		String objId = pageParams.get('id');

		if (objId != null) {
			List<Event> eventList = [select Id, WhatId, Communication_Event_Version_MRK__c from Event where RecordTypeId = :MRK_CommunicationServices.communicationEventRecordTypeId and WhatId = :objId and OwnerId = :UserInfo.getUserId()];
			if (eventList.size() > 0) {
				pr = new PageReference('/' + eventList[0].Id);			
				pr.setRedirect(true);
			}			
		}

		// invalid ID, event not targeted to user, etc.
		// show user generate message
		if (pr == null) {
			objId = ((objId == null) ? 'unknown' : objId);
			String messageTemplate = MRK_Setting.getString(MRK_CommunicationServices.SETTING_NAME, 'communication event not available message template');
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, string.format(messageTemplate, new String[]{objId}) ));
		}

		return pr;
	}

	public Map<String, Object> getSettings() {
		return MRK_Setting.getValues(MRK_CommunicationServices.SETTING_NAME);
	}

}