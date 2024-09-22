trigger VeevaEmSpeakerCapTrigger on EM_Speaker_Cap_vod__c  (before insert, before update, before delete, after insert, after update, after delete) {
    VeevaTriggerHandler handler = new VeevaEmSpeakerCapTriggerHandler();
    handler.handleTrigger();
}