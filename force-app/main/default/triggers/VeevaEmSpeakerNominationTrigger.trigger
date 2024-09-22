trigger VeevaEmSpeakerNominationTrigger on EM_Speaker_Nomination_vod__c (before insert, before update, before delete, after insert, after update) {
	VeevaTriggerHandler handler = new VeevaEmSpeakerNominationTriggerHandler();
    handler.handleTrigger();
}