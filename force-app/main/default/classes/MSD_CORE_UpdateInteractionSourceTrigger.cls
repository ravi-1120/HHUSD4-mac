/*
* MSD_CORE_UpdateInteractionSourceTrigger
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This class specifies the Source on Interactions
*                created via Email-to-Case (the source represents
*                a concrete origin like a specific phone number or
*                social media site).
*/
public with sharing class MSD_CORE_UpdateInteractionSourceTrigger implements TriggersMVN.HandlerInterface{
     public void handle() {
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
        List<EmailMessage> messages = Trigger.new; 

        Set<Id> parentIds = new Set<Id>(); 
        Set<String> externalIds = new Set<String>(); 
        for(EmailMessage m : messages) {
            parentIds.add(m.ParentId); 
            externalIds.add(m.ToAddress); 
        }

        List<Case> interactions = [SELECT Id, 
                                            MSD_CORE_Source__c, 
                                            (SELECT Id, ToAddress FROM EmailMessages) 
                                        FROM Case WHERE RecordType.DeveloperName =: settings.Interaction_Record_Type_MVN__c 
                                        AND Id IN :parentIds AND Origin =: settings.MSD_CORE_Case_Origin_Email__c]; 
                                        
        Map<String, Id> sourceExtToId = new Map<String, Id>(); 
        for(MSD_CORE_Source__c s : [SELECT Id, MSD_CORE_External_Id__c 
                                        FROM MSD_CORE_Source__c 
                                        WHERE MSD_CORE_External_Id__c IN :externalIds
                                        AND MSD_CORE_Active__c = true]) {
            sourceExtToId.put(s.MSD_CORE_External_Id__c, s.Id);
        }

        for(Case interaction : interactions) {
            if(interaction.EmailMessages.size() == 1) {
                if(sourceExtToId.get(interaction.EmailMessages[0].ToAddress) != null) {
                    interaction.MSD_CORE_Source__c = sourceExtToId.get(interaction.EmailMessages[0].ToAddress); 
                }
            }
        }

        if(interactions.size() > 0) {
            update interactions;
        }
    }
}