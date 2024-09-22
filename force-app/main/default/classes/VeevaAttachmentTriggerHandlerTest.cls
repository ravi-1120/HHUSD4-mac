@isTest
public with sharing class VeevaAttachmentTriggerHandlerTest {

    private static String submitErr = 'Error: You do not have permission to perform this action. This record is in Submitted status and cannot be modified.';
    private static String lockedErr = 'You do not have permission to edit this record.';
    private static String lockedDeleteErr = 'You do not have permission to delete this record.';

    @testSetup static void createAccount() {
        insert (new Account(Name = 'AttachmentAcct'));
    }

    @isTest
    private static void testDeleteAttachment() {
        VeevaAttachmentTriggerHandler handler = new VeevaAttachmentTriggerHandler();

        //submitted
        Medical_Inquiry_vod__c submitMedInq = createMedicalInquiry();
        Attachment submitAtt = new Attachment(ParentId = submitMedInq.Id, Name='Att', Body=Blob.valueOf('AttBody'));
        insert submitAtt;
        submitMedInq.Status_vod__c = 'Submitted_vod';
        update submitMedInq;

        handler.preTrigger(null, new List<Attachment>{submitAtt}, null, null);
        handler.beforeDelete();
        System.assertEquals(submitErr, submitAtt.getErrors().get(0).getMessage());


        //not submitted
        Medical_Inquiry_vod__c medInq = createMedicalInquiry();
        Attachment att = new Attachment(ParentId = medInq.Id, Name='Att', Body=Blob.valueOf('AttBody'));
        insert att;
        medInq.Status_vod__c = 'Saved_vod';
        update medInq;

        handler.preTrigger(null, new List<Attachment>{att}, null, null);
        handler.beforeDelete();
        System.assert(att.getErrors().size() == 0, 'Should be able to delete attachment of record that is not submitted');
    }

    @isTest
    private static void testDeleteLockedEventAttachment() {
        VeevaAttachmentTriggerHandler handler = new VeevaAttachmentTriggerHandler();

        EM_Event_vod__c lockedEvent = createEvent();
        Attachment attachment = new Attachment(ParentId = lockedEvent.Id, Name='Att', Body=Blob.valueOf('AttBody'));
        insert attachment;
        lockedEvent.Lock_vod__c = true;
        update lockedEvent;

        handler.preTrigger(null, new List<Attachment>{attachment}, null, null);
        Test.startTest();
        handler.beforeDelete();
        Test.stopTest();
        System.assertEquals(lockedDeleteErr, attachment.getErrors().get(0).getMessage());
    }

    @isTest
    private static void testDeleteUnLockedEventAttachment() {
        VeevaAttachmentTriggerHandler handler = new VeevaAttachmentTriggerHandler();

        EM_Event_vod__c event = createEvent();
        Attachment att = new Attachment(ParentId = event.Id, Name='Att', Body=Blob.valueOf('AttBody'));
        insert att;
        event.Lock_vod__c = false;
        update event;

        handler.preTrigger(null, new List<Attachment>{att}, null, null);
        Test.startTest();
        handler.beforeDelete();
        Test.stopTest();
        System.assert(att.getErrors().size() == 0, 'Should be able to delete attachment of record that is not locked');
    }

    @isTest
    private static void testEditLockedEventAttachment() {
        VeevaAttachmentTriggerHandler handler = new VeevaAttachmentTriggerHandler();

        EM_Event_vod__c lockedEvent = createEvent();
        Attachment attachment = new Attachment(ParentId = lockedEvent.Id, Name='Att', Body=Blob.valueOf('AttBody'));
        insert attachment;
        lockedEvent.Lock_vod__c = true;
        update lockedEvent;

        handler.preTrigger(new List<Attachment>{attachment}, new List<Attachment>{attachment}, null, null);
        Test.startTest();
        handler.beforeUpdate();
        Test.stopTest();
        System.assertEquals(lockedErr, attachment.getErrors().get(0).getMessage());
    }

    @isTest
    private static void testEditUnLockedEventAttachment() {
        VeevaAttachmentTriggerHandler handler = new VeevaAttachmentTriggerHandler();

        EM_Event_vod__c event = createEvent();
        Attachment att = new Attachment(ParentId = event.Id, Name='Att', Body=Blob.valueOf('AttBody'));
        insert att;
        event.Lock_vod__c = false;
        update event;

        handler.preTrigger(new List<Attachment>{att}, new List<Attachment>{att}, null, null);
        Test.startTest();
        handler.beforeUpdate();
        Test.stopTest();
        System.assert(att.getErrors().size() == 0, 'Should be able to edit attachment of record that is not locked');
    }

    private static Medical_Inquiry_vod__c createMedicalInquiry() {
        Medical_Inquiry_vod__c medInq = new Medical_Inquiry_vod__c(Account_vod__c = getTestAccount().Id);
        insert medInq;
        return medInq;
    }

    private static EM_Event_vod__c createEvent() {
        EM_Event_vod__c event = new EM_Event_vod__c();
        insert event;
        return event;
    }

    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'AttachmentAcct' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static String getEventMaterialRecordTypeId() {
        String requiredAttachmentRecordTypeId = '';
        RecordTypeInfo recordType = Schema.SObjectType.EM_Event_Material_vod__c.getRecordTypeInfosByDeveloperName().get('Required_Attachment_vod');
        if (recordType != null) {
            requiredAttachmentRecordTypeId = recordType.getRecordTypeId();
        }
        return requiredAttachmentRecordTypeId;
    }

	@isTest private static void testInsertEventMaterialAttachment() {
        EM_Event_Material_vod__c eventMaterial = createEventMaterial();
        Attachment attach = createAttachment(eventMaterial.Id);

        eventMaterial = [SELECT Id, Has_Attachment_vod__c FROM EM_Event_Material_vod__c WHERE Id = :eventMaterial.Id];
        System.assertEquals(eventMaterial.Has_Attachment_vod__c, 'Yes_vod');
    }

    @isTest private static void testDeleteEventMaterialAttachment() {
        EM_Event_Material_vod__c eventMaterial = createEventMaterial();
        Attachment attach = createAttachment(eventMaterial.Id);
        eventMaterial = [SELECT Id, Has_Attachment_vod__c FROM EM_Event_Material_vod__c WHERE Id = :eventMaterial.Id];
        System.assertEquals(eventMaterial.Has_Attachment_vod__c, 'Yes_vod');

        delete attach;

        eventMaterial = [SELECT Id, Has_Attachment_vod__c FROM EM_Event_Material_vod__c WHERE Id = :eventMaterial.Id];
        System.assertEquals(eventMaterial.Has_Attachment_vod__c, 'No_vod');
    }

    @isTest private static void testDeleteEventMaterialAttachmentWithContentDocument() {
        EM_Event_Material_vod__c eventMaterial = createEventMaterial();
        Attachment attach = createAttachment(eventMaterial.Id);
        ContentDocument doc = createContentDocument();
        ContentDocumentLink docLink = createDocumentLink(doc.Id, eventMaterial.Id);

        delete attach;

        eventMaterial = [SELECT Id, Has_Attachment_vod__c FROM EM_Event_Material_vod__c WHERE Id = :eventMaterial.Id];
        System.assertEquals(eventMaterial.Has_Attachment_vod__c, 'Yes_vod');
    }

    private static ContentDocument createContentDocument() {
        ContentVersion version = getNewContentVersion();
        insert version;
        ContentVersion verWithDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];
        return [SELECT Id FROM ContentDocument WHERE Id = :verWithDocId.ContentDocumentId];
    }

    private static ContentVersion getNewContentVersion() {
        ContentVersion version = new ContentVersion(
            Title = 'TestDocVersion',
            PathOnClient = 'TestDocVersion.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        return version;
    }

    private static EM_Event_Material_vod__c createEventMaterial() {
        EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(RecordTypeId = getEventMaterialRecordTypeId(), Has_Attachment_vod__c = 'No_vod');
        insert eventMaterial;
        return eventMaterial;
    }

    private static Attachment createAttachment(String parentId) {
        Attachment attach = new Attachment(Body = Blob.valueOf('test'), ParentId = parentId, Name = 'Test_Sign_In_Sheet');
        insert attach;
        return attach;
    }

    private static ContentDocumentLink createDocumentLink(Id docId, Id entityId) {
        ContentDocumentLink link = new ContentDocumentLink(ContentDocumentId = docId, LinkedEntityId = entityId);
        insert link;
        return link;
    }
}