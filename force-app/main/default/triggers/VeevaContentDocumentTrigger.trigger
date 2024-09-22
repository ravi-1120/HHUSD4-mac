trigger VeevaContentDocumentTrigger on ContentDocument (before delete, after delete, before update) {
    new VeevaContentDocumentTriggerHandler().handleTrigger();
}