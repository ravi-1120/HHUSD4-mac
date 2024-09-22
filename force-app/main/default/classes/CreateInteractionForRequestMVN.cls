/*
* CreateInteractionForRequestMVN
* Created By: Roman Lerman
* Created Date: 3/4/2013
* Description: This class creates an interaction for an email-to-case request
*
* *** NOTE: Currently not used for the Merck implementation. ***
*/
public with sharing class CreateInteractionForRequestMVN implements TriggersMVN.HandlerInterface
{
    public void execute(List<Case> newCases) {
    	Map <Case, Case> requestToInteractionMap = new Map <Case, Case> ();

		String interactionRTMVN = Service_Cloud_Settings_MVN__c.getInstance().Interaction_Record_Type_MVN__c;
    	String requestRTMVN = Service_Cloud_Settings_MVN__c.getInstance().Request_Record_Type_MVN__c;

    	Set<String> rtNames = new SET<String>{interactionRTMVN, requestRTMVN};

    	Map<String, Id> rtNamesIds = new Map<String, Id>();

    	for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName in :rtNames]) {
            rtNamesIds.put(rt.DeveloperName, rt.Id);
        }

        List<String> groupIdentifiers = new List<String>();

        for (Case newRequest : newCases) {
        	if(String.isNotBlank(newRequest.Medical_Inquiry_Group_Identifier_MVN__c)){
				groupIdentifiers.add(newRequest.Medical_Inquiry_Group_Identifier_MVN__c);
			}
		}

		List<Case> existingInteractions = [select Id, Medical_Inquiry_Group_Identifier_MVN__c from Case
												where Medical_Inquiry_Group_Identifier_MVN__c in :groupIdentifiers AND RecordTypeId = :rtNamesIds.get(interactionRTMVN)];


		Map<String, Case> groupIdToInteraction = new Map<String, Case>();

		for(Case interaction : existingInteractions){
			groupIdToInteraction.put(interaction.Medical_Inquiry_Group_Identifier_MVN__c, interaction);
		}

		List<Case> interactionsToInsert = new List<Case>();



		for (Case newRequest : newCases) {

			if(newRequest.ParentId == null && newRequest.RecordTypeId == rtNamesIds.get(requestRTMVN)) {
				Case newInteraction = newRequest.clone(false, true);
				newInteraction.RecordTypeId = rtNamesIds.get(interactionRTMVN);
				requestToInteractionMap.put(newRequest, newInteraction);
				if(String.isNotBlank(newRequest.Medical_Inquiry_Group_Identifier_MVN__c)){
					if(groupIdToInteraction.get(newRequest.Medical_Inquiry_Group_Identifier_MVN__c) == null){
						groupIdToInteraction.put(newRequest.Medical_Inquiry_Group_Identifier_MVN__c, newInteraction);
					} else{
						continue;
					}
				}

				interactionsToInsert.add(newInteraction);

			}
		}

		if (!interactionsToInsert.isEmpty()) {
			Database.Insert(interactionsToInsert);
		}

		for (Case request : requestToInteractionMap.keySet()) {
			if(String.isNotBlank(request.Medical_Inquiry_Group_Identifier_MVN__c)){
				Case interaction = groupIdToInteraction.get(request.Medical_Inquiry_Group_Identifier_MVN__c);
				if(interaction != null){
					request.ParentId = interaction.Id;
				}
			} else{
				request.ParentId = requestToInteractionMap.get(request).id;
			}
		}
    }

    public void handle() {
    	execute((List<Case>) trigger.new);
    }
}