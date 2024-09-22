trigger MRK_Account_Plan on Account_Plan_vod__c (after delete, after insert, after update, before delete, before insert, before update) {
    MRK_TriggerFactory.process(Account_Plan_vod__c.sObjectType);
}