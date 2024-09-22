trigger VeevaAccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete) {
    VeevaTriggerHandler handler = new VeevaAccountTriggerHandler();
    handler.handleTrigger();
}