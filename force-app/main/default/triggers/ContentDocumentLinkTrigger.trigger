/**
 * Component Name:      ContentDocumentLinkTrigger
 * Created By:          Ravi Modi (Focal CXM)
 * Description:         Used for updating permission of ContentDocumentLink
 * Test Class:          ContentDocumentLinkTriggerHandlerTest
 */

trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert , after insert) {
    ContentDocumentLinkTriggerHandler handler = new ContentDocumentLinkTriggerHandler(trigger.new, trigger.isInsert);
    if(trigger.isBefore){
        if(trigger.isInsert){
            handler.beforeInsertEvent();
        }
    }
    if(trigger.isAfter){
        if(trigger.isInsert){
            handler.afterInsertEvent();
        }
    }
}