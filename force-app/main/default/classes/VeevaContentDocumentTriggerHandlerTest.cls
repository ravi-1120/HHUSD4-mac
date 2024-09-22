@isTest
private with sharing class VeevaContentDocumentTriggerHandlerTest {

    private static String submitErr = 'Error: You do not have permission to perform this action. This record is in Submitted status and cannot be modified.';
    private static String lockedErr = 'You do not have permission to edit this record.';
    private static String lockedDeleteErr = 'You do not have permission to delete this record.';

    @testSetup static void createAccount() {
        insert (new Account(Name = 'FileObjAcct'));
    }

    @isTest
    private static void testDeleteFile() {
        VeevaContentDocumentTriggerHandler handler = new VeevaContentDocumentTriggerHandler();

        //submitted
        ContentDocument submittedDoc = createDoc(true, false);
        handler.preTrigger(null, null, null, new Map<Id, ContentDocument>{submittedDoc.Id=>submittedDoc});
        handler.beforeDelete();
        System.assertEquals(submitErr, submittedDoc.getErrors().get(0).getMessage());

        //not submitted and one record
        ContentDocument unlockedDoc = createDoc(false, false);
        handler.preTrigger(null, null, null, new Map<Id, ContentDocument>{unlockedDoc.Id=>unlockedDoc});
        handler.beforeDelete();
        System.assert(unlockedDoc.getErrors().size() == 0, 'Should be able to delete file attached to one record that is not submitted');
    }

    @isTest
    private static void testUploadNewVersion() {
        //submitted
        ContentDocument subDoc = createDoc(true, false);
        ContentVersion subVer = getNewContentVersion(subDoc.Id);
        Database.SaveResult subRes = Database.insert(subVer, false);
        System.assert(!subRes.success, 'Should not be able to upload new version to submitted records');

        //unlocked
        ContentDocument unlockedDoc = createDoc(false, false);
        ContentVersion unlockedVer = getNewContentVersion(unlockedDoc.Id);
        Database.SaveResult unlockedRes = Database.insert(unlockedVer, false);
        System.assert(unlockedRes.success, 'Should be able to upload new version to unlocked records');
    }

    @isTest
    private static void testUploadNewVersionOffline() {
        //submitted but created offline
        ContentDocument subDoc = createDoc(true, false);
        ContentVersion mobileSubVer = getNewContentVersion(subDoc.Id);
        mobileSubVer.Mobile_Id_vod__c = 'created_offline_id';
        Database.SaveResult subRes = Database.insert(mobileSubVer, false);
        System.assert(subRes.success, 'Should be able to upload new version to submitted records, if the new version was created offline');
    }

    @isTest
    private static void testEditSubmitUnownedFile() {
        //not file owner, submitted (should succeed)
        VeevaContentDocumentTriggerHandler handler = new VeevaContentDocumentTriggerHandler();
        ContentDocument subDoc = createDoc(true, false, createUser().Id);
        handler.preTrigger(new List<ContentDocument>{subDoc}, new List<ContentDocument>{subDoc}, null, null);
        Test.startTest();
        handler.beforeUpdate();
        Test.stopTest();
        System.assertEquals(0, subDoc.getErrors().size());
    }

    @isTest
    private static void testEditSaveUnownedFile() {
        VeevaContentDocumentTriggerHandler handler = new VeevaContentDocumentTriggerHandler();
        //not file owner, saved (should succeed)
        ContentDocument saveDoc = createDoc(false, false, createUser().Id);
        handler.preTrigger(new List<ContentDocument>{saveDoc}, new List<ContentDocument>{saveDoc}, null, null);
        Test.startTest();
        handler.beforeUpdate();
        Test.stopTest();
        System.assert(saveDoc.getErrors().isEmpty(), 'Should be able to edit file details for saved, unowned file');
    }

    @isTest
    private static void testEditSubmitOwnedFile() {
        VeevaContentDocumentTriggerHandler handler = new VeevaContentDocumentTriggerHandler();
        // file owner, submitted (should succeed)
        ContentDocument ownSubDoc = createDoc(false, false);
        handler.preTrigger(new List<ContentDocument>{ownSubDoc}, new List<ContentDocument>{ownSubDoc}, null, null);
        Test.startTest();
        handler.beforeUpdate();
        Test.stopTest();
        System.assert(ownSubDoc.getErrors().isEmpty(), 'Should be able to edit file details for submitted, owned file');

    }

    @isTest
    private static void testEditSubmitCollabFile() {
        VeevaContentDocumentTriggerHandler handler = new VeevaContentDocumentTriggerHandler();
        // collaborator, submitted (should succeed)
        ContentDocument collabDoc = createDoc(true, false, createUser().Id);
        ContentDocumentLink link = [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :collabDoc.Id AND LinkedEntityId = :UserInfo.getUserId()];
        update new ContentDocumentLink(Id=link.Id,ShareType='C');
        handler.preTrigger(new List<ContentDocument>{collabDoc}, new List<ContentDocument>{collabDoc}, null, null);
        Test.startTest();
        handler.beforeUpdate();
        Test.stopTest();
        System.assert(collabDoc.getErrors().isEmpty(), 'Should be able to edit file details for submitted, collaborated file');
    }

    @isTest
    private static void testDeleteEmLockedFile() {
        VeevaContentDocumentTriggerHandler handler = new VeevaContentDocumentTriggerHandler();

        ContentDocument lockedDoc = createEmDoc(true, null);
        handler.preTrigger(null, null, null, new Map<Id, ContentDocument>{lockedDoc.Id=>lockedDoc});
        Test.startTest();
        handler.beforeDelete();
        Test.stopTest();
        System.assertEquals(lockedDeleteErr, lockedDoc.getErrors().get(0).getMessage());
    }

    @isTest
    private static void testDeleteEmUnLockedFile() {
        VeevaContentDocumentTriggerHandler handler = new VeevaContentDocumentTriggerHandler();

        ContentDocument unlockedDoc = createEmDoc(false, null);
        handler.preTrigger(null, null, null, new Map<Id, ContentDocument>{unlockedDoc.Id=>unlockedDoc});
        Test.startTest();
        handler.beforeDelete();
        Test.stopTest();
        System.assert(unlockedDoc.getErrors().size() == 0, 'Should be able to delete file attached to one record that is not locked');
    }

    @isTest
    private static void testUploadNewVersionLockedEvent() {
        ContentDocument emDoc = createEmDoc(true, null);
        ContentVersion emSubVer = getNewContentVersion(emDoc.Id);
        Test.startTest();
        Database.SaveResult emSubRes = Database.insert(emSubVer, false);
        Test.stopTest();
        System.assert(!emSubRes.success, 'Should not be able to upload new version to locked records');
    }

    @isTest
    private static void testUploadNewVersionUnLockedEvent() {
        ContentDocument unlockedDoc = createEmDoc(false, null);
        ContentVersion unlockedVer = getNewContentVersion(unlockedDoc.Id);
        Test.startTest();
        Database.SaveResult unlockedRes = Database.insert(unlockedVer, false);
        Test.stopTest();
        System.assert(unlockedRes.success, 'Should be able to upload new version to unlocked records');
    }

    @isTest
    private static void testEditLockedEventFile() {
        VeevaContentDocumentTriggerHandler handler = new VeevaContentDocumentTriggerHandler();
        ContentDocument emDoc = createEmDoc(true, null);
        handler.preTrigger(new List<ContentDocument>{emDoc}, new List<ContentDocument>{emDoc}, null, null);
        Test.startTest();
        handler.beforeUpdate();
        Test.stopTest();
        System.assertEquals(lockedErr, emDoc.getErrors().get(0).getMessage());
    }

    @isTest
    private static void testEditUnLockedEventFile() {
        VeevaContentDocumentTriggerHandler handler = new VeevaContentDocumentTriggerHandler();
        ContentDocument emDoc = createEmDoc(false, null);
        handler.preTrigger(new List<ContentDocument>{emDoc}, new List<ContentDocument>{emDoc}, null, null);
        Test.startTest();
        handler.beforeUpdate();
        Test.stopTest();
        System.assert(emDoc.getErrors().size() == 0, 'Should be able to edit file attached to one record that is not locked');
    }

    private static ContentDocument createDoc(boolean submit, boolean multiRecord) {
        return createDoc(submit, multiRecord, null);
    }

    private static ContentDocument createDoc(boolean submit, boolean multiRecord, Id ownerId) {
        ContentDocument doc = createContentDocument(ownerId);
        Medical_Inquiry_vod__c medInq = createMedicalInquiry();
        createDocumentLink(doc.Id, medInq.Id);
        if (multiRecord) {
            Medical_Inquiry_vod__c medInq2 = createMedicalInquiry();
            createDocumentLink(doc.Id, medInq2.Id);
        }
        medInq.Status_vod__c = submit ? 'Submitted_vod' : 'Saved_vod';
        update medInq;

        return doc;
    }

    private static ContentDocument createEmDoc(boolean isLocked, Id ownerId) {
        ContentDocument doc = createContentDocument(ownerId);
        EM_Event_vod__c event = createEvent();
        createDocumentLink(doc.Id, event.Id);
        event.Lock_vod__c = isLocked;
        update event;
        return doc;
    }

    private static ContentDocument createContentDocument(Id ownerId) {
        ContentVersion version = getNewContentVersion(null);
        insert version;
        ContentVersion verWithDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

        if (ownerId != null) {
            update new ContentDocument(Id=verWithDocId.ContentDocumentId, OwnerId=ownerId);
        }

        return [SELECT Id, OwnerId, LatestPublishedVersionId FROM ContentDocument WHERE Id = :verWithDocId.ContentDocumentId];
    }

    private static ContentVersion getNewContentVersion(Id contentDocumentId) {
        ContentVersion version = new ContentVersion(
            Title = 'TestDocVersion',
            PathOnClient = 'TestDocVersion.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        if (contentDocumentId != null) {
            version.ContentDocumentId = contentDocumentId;
        }
        return version;
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
        return [SELECT Id FROM Account WHERE Name = 'FileObjAcct' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static ContentDocumentLink createDocumentLink(Id docId, Id entityId) {
        ContentDocumentLink link = new ContentDocumentLink(ContentDocumentId = docId, LinkedEntityId = entityId);
        insert link;
        return link;
    }

    private static User createUser() {
        Profile firstProfile = [SELECT Id FROM Profile LIMIT 1];
        User user = new User(LastName = 'Userton',
                           FirstName='User',
                           Alias = 'usus',
                           Email = 'user.user@user.user',
                           Username = Math.random() + '@' + Math.random(),
                           ProfileId = firstProfile.Id,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
        );
        insert user;
        return user;
    }

}