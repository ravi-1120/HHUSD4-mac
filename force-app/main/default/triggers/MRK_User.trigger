trigger MRK_User on User (after delete, after insert, after update, before delete, before insert, before update) {
    MRK_TriggerFactory.process(User.sObjectType);
}