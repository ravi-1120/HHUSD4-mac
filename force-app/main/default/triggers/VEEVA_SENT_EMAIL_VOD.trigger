trigger VEEVA_SENT_EMAIL_VOD on Sent_Email_vod__c (before insert, after insert, before update, after update) {
    VeevaTriggerHandler handler = new SentEmailTriggerHandler();
    handler.handleTrigger();
}