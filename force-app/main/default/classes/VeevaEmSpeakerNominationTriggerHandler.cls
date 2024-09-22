public without sharing class VeevaEmSpeakerNominationTriggerHandler extends VeevaTriggerHandler {

    private static final String EXISTING_SPEAKER_NOMINATION_KEY = 'EVENT_MANAGEMENT;;EXISTING_SPEAKER_NOMINATION';
    private static final String EXISTING_SPEAKER_NOMINATION_MESSAGE = 'New nomination is pending for this Account. Please review the speaker profile.';
    private static final String EXISTING_SPEAKER_PROFILE_KEY = 'EVENT_MANAGEMENT;;EXISTING_SPEAKER_PROFILE';
    private static final String EXISTING_SPEAKER_PROFILE_MESSAGE = 'There is already a speaker profile for this Account. You cannot submit a new nomination for an existing speaker profile.';
    private static final String LOCKED_RECORD_MESSAGE = 'Record is locked.';
    // Use lowercase field names since getDescribe fields are returned as lowercase
    private static final Set<String> ACCOUNT_QUERY_FIELDS = new Set<String>{'id', 'firstName', 'lastName', 'persontitle'};
    private static final Set<String> SPEAKER_QUERY_FIELDS = new Set<String>{'id', 'account_vod__c', 'status_vod__c'};
    private static final Set<String> EXCLUDED_SPEAKER_FIELDS_STAMP = new Set<String>{'address_vod__c', 'status_vod__c'};

    private static Map<String, String> veevaMessageMap;
    private static Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();
    private static Map<String, SObjectField> accountFieldMap = globalDescribe.get('Account').getDescribe().fields.getMap();
    private static Map<String, SObjectField> speakerFieldMap = globalDescribe.get('EM_Speaker_vod__c').getDescribe().fields.getMap();
    private static Map<String, SObjectField> speakerNominationFieldMap = globalDescribe.get('EM_Speaker_Nomination_vod__c').getDescribe().fields.getMap();
    private static ID newSpeakerRecordTypeId = globalDescribe.get('EM_Speaker_Nomination_vod__c').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Speaker_vod').getRecordTypeId();

    private List<EM_Speaker_Nomination_vod__c> newNominations = new List<EM_Speaker_Nomination_vod__c>();
    private List<EM_Speaker_Nomination_vod__c> oldNominations = new List<EM_Speaker_Nomination_vod__c>();
    private Map<ID, EM_Speaker_Nomination_vod__c> newNominationsMap = new Map<ID, EM_Speaker_Nomination_vod__c>();
    private Map<ID, EM_Speaker_Nomination_vod__c> oldNominationsMap = new Map<ID, EM_Speaker_Nomination_vod__c>();

    private Map<ID, Account> accountsMap = new Map<ID, Account>();
    private Map<ID, EM_Speaker_vod__c> speakersMap = new Map<ID, EM_Speaker_vod__c>();
    private Map<ID, ID> accountIdToSpeakerId = new Map<ID, ID>();
    private Map<ID, EM_Speaker_vod__c> nominationToNewSpeakerMap = new Map<ID, EM_Speaker_vod__c>();
    private Map<ID, Address_vod__c> addressMap = new Map<ID, Address_vod__c>();
    private List<EM_Speaker_vod__c> speakersToUpdate = new List<EM_Speaker_vod__c>();

    protected override String sObjectType() {
        return 'EM_Speaker_Nomination_vod__c';
    }

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newNominations = (List<EM_Speaker_Nomination_vod__c>) triggerNew;
        this.oldNominations = (List<EM_Speaker_Nomination_vod__c>) triggerOld;
        this.newNominationsMap = (Map<ID, EM_Speaker_Nomination_vod__c>) triggerNewMap;
        this.oldNominationsMap = (Map<ID, EM_Speaker_Nomination_vod__c>) triggerOldMap;
    }

    protected override void beforeInsert() {
        handleBeforeUpsert();
    }

    protected override void beforeUpdate() {
        handleBeforeUpsert();
    }

    protected override void afterInsert() {
        handleAfterUpsert();
    }

    protected override void afterUpdate() {
        handleAfterUpsert();
    }

    protected override void beforeDelete() {
        for (ID oldNominationId : oldNominationsMap.keySet()) {
            handleLock(oldNominationId);
        }
    }

    private void handleBeforeUpsert() {
        retrieveRelatedRecords();
        for (ID newNominationId : newNominationsMap.keySet()) {
            handleLock(newNominationId);
            handleStamping(newNominationId);
            handleValidation(newNominationId);
            handleSubmissionFlow(newNominationId);
        }
    }

    private void handleAfterUpsert() {
        retrieveRelatedAddresses();
        for (ID newNominationId : newNominationsMap.keySet()) {
            handleSubmissionFlow(newNominationId);
            handleSpeakerStatusUpdate(newNominationId);
        }
        handleNewSpeakerInsert();
        if (!speakersToUpdate.isEmpty()) {
            update speakersToUpdate;
        }
    }

    private void retrieveRelatedRecords() {
        Set<ID> accountIds = new Set<ID>();
        Set<ID> speakerIds = new Set<ID>();
        for (EM_Speaker_Nomination_vod__c newNomination : newNominations) {
            if (newNomination.Account_vod__c != null) {
                accountIds.add(newNomination.Account_vod__c);
            }
            if (newNomination.Speaker_vod__c != null) {
                speakerIds.add(newNomination.Speaker_vod__c);
            }
        }

        if (!accountIds.isEmpty()) {
            Set<String> accountQueryFields = new Set<String>(ACCOUNT_QUERY_FIELDS);
            for (String accountField : accountFieldMap.keySet()) {
                if (speakerNominationFieldMap.containsKey(accountField) && accountFieldMap.get(accountField).getDescribe().isCustom()) {
                    accountQueryFields.add(accountField);
                }
            }
            List<Account> accounts = Database.query('SELECT ' + String.join(new List<String>(accountQueryFields), ',') + ' FROM Account WHERE Id IN :accountIds');
            accountsMap = new Map<ID, Account>(accounts);
        }

        if (!speakerIds.isEmpty() || !accountIds.isEmpty()) {
            Set<String> speakerQueryFields = new Set<String>(SPEAKER_QUERY_FIELDS);
            for (String speakerField : speakerFieldMap.keySet()) {
                if (speakerNominationFieldMap.containsKey(speakerField) && speakerFieldMap.get(speakerField).getDescribe().isCustom()) {
                    speakerQueryFields.add(speakerField);
                }
            }
            List<EM_Speaker_vod__c> speakers = Database.query('SELECT ' + String.join(new List<String>(speakerQueryFields), ',') + ' FROM EM_Speaker_vod__c WHERE Id IN :speakerIds OR Account_vod__c IN :accountIds');
            speakersMap = new Map<ID, EM_Speaker_vod__c>(speakers);

            for (EM_Speaker_vod__c speaker : speakers) {
                if (speaker.Account_vod__c != null && !accountIdToSpeakerId.containsKey(speaker.Account_vod__c)) {
                    accountIdToSpeakerId.put(speaker.Account_vod__c, speaker.Id);
                }
            }
        }
    }

    private void retrieveRelatedAddresses() {
        Set<ID> addressIds = new Set<ID>();
        for (EM_Speaker_Nomination_vod__c newNomination : newNominations) {
            if (newNomination.Address_vod__c != null && newNomination.RecordTypeId == newSpeakerRecordTypeId && isSubmissionFlow(newNomination.Id)) {
                addressIds.add(newNomination.Address_vod__c);
            }
        }
        if (!addressIds.isEmpty()) {
            addressMap = new Map<ID, Address_vod__c>([SELECT Id, Name, Address_line_2_vod__c, City_vod__c, toLabel(State_vod__c), Zip_vod__c FROM Address_vod__c WHERE Id IN :addressIds]);
        }
    }

    private void handleLock(ID nominationId) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            EM_Speaker_Nomination_vod__c newNomination = newNominationsMap.get(nominationId);
            if (newNomination.Override_Lock_vod__c == TRUE) {
                newNomination.Override_Lock_vod__c = FALSE;
            } else if (isNominationLocked(newNomination) && oldNominationsMap.containsKey(nominationId)) {
                EM_Speaker_Nomination_vod__c oldNomination = oldNominationsMap.get(nominationId);
                if (isNominationLocked(oldNomination)) {
                    newNomination.addError(LOCKED_RECORD_MESSAGE);
                }
            }
            if (newNomination.Status_vod__c == 'Approved_vod' && isNominationFieldChanged(nominationId, 'Status_vod__c')) {
                newNomination.Lock_vod__c = TRUE;
            }
        } else if (Trigger.isDelete) {
            EM_Speaker_Nomination_vod__c oldNomination = oldNominationsMap.get(nominationId);
            if (isNominationLocked(oldNomination)) {
                oldNomination.addError(LOCKED_RECORD_MESSAGE);
            }
        }
    }

    private void handleValidation(ID nominationId) {
        EM_Speaker_Nomination_vod__c newNomination = newNominationsMap.get(nominationId);
        if (newNomination.RecordTypeId == newSpeakerRecordTypeId && newNomination.Account_vod__c != null
                && newNomination.Speaker_vod__c == null && accountIdToSpeakerId.containsKey(newNomination.Account_vod__c)
                && (Trigger.isInsert || isNominationFieldChanged(nominationId, 'Account_vod__c') || isSubmissionFlow(nominationId))) {
            EM_Speaker_vod__c speaker = speakersMap.get(accountIdToSpeakerId.get(newNomination.Account_vod__c));
            if (speaker.Status_vod__c == 'Nominated_vod' || speaker.Status_vod__c == 'Approved_vod') {
                newNomination.addError(getVeevaMessage(EXISTING_SPEAKER_NOMINATION_KEY, EXISTING_SPEAKER_NOMINATION_MESSAGE));
            } else {
                newNomination.addError(getVeevaMessage(EXISTING_SPEAKER_PROFILE_KEY, EXISTING_SPEAKER_PROFILE_MESSAGE));
            }
        }
    }

    private void handleStamping(ID nominationId) {
        EM_Speaker_Nomination_vod__c newNomination = newNominationsMap.get(nominationId);
        if (Trigger.isInsert) {
            if (newNomination.Speaker_vod__c != null) {
                stampSpeakerFields(newNomination);
            } else if (newNomination.Account_vod__c != null) {
                stampAccountFields(newNomination);
            }
        } else if (Trigger.isUpdate) {
            if (newNomination.Speaker_vod__c == null && isNominationFieldChanged(nominationId, 'Speaker_vod__c') && newNomination.Account_vod__c != null) {
                ID accountId = newNomination.Account_vod__c;
                stampSpeakerFields(newNomination);
                newNomination.Account_vod__c = accountId;
                stampAccountFields(newNomination);
            } else if (isNominationFieldChanged(nominationId, 'Speaker_vod__c')) {
                stampSpeakerFields(newNomination);
            } else if (newNomination.Speaker_vod__c == null && isNominationFieldChanged(nominationId, 'Account_vod__c')) {
                stampAccountFields(newNomination);
            }
        }
    }

    private void stampSpeakerFields(EM_Speaker_Nomination_vod__c newNomination) {
        EM_Speaker_vod__c speaker = speakersMap.get(newNomination.Speaker_vod__c);
        for (String speakerField : speakerFieldMap.keySet()) {
            if (speakerNominationFieldMap.containsKey(speakerField) && speakerFieldMap.get(speakerField).getDescribe().isCustom()
                    && !speakerNominationFieldMap.get(speakerField).getDescribe().isCalculated()
                    && !EXCLUDED_SPEAKER_FIELDS_STAMP.contains(speakerField)) {
                newNomination.put(speakerField, getFieldValue(speaker, speakerField));
            }
        }
    }

    private void stampAccountFields(EM_Speaker_Nomination_vod__c newNomination) {
        Account account = accountsMap.get(newNomination.Account_vod__c);
        for (String accountField : accountFieldMap.keySet()) {
            String fieldToStamp = '';
            if (accountField == 'PersonTitle') {
                fieldToStamp = 'Title_vod__c';
            } else if (accountField == 'FirstName') {
                fieldToStamp = 'First_Name_vod__c';
            } else if (accountField == 'LastName') {
                fieldToStamp = 'Last_Name_vod__c';
            } else if (speakerNominationFieldMap.containsKey(accountField) && accountFieldMap.get(accountField).getDescribe().isCustom()
                    && !speakerNominationFieldMap.get(accountField).getDescribe().isCalculated()) {
                fieldToStamp = accountField;
            }
            if (String.isNotBlank(fieldToStamp)) {
                newNomination.put(fieldToStamp, getFieldValue(account, accountField));
            }
        }
    }

    private Object getFieldValue(SObject record, String fieldName) {
        Object fieldValue = null;
        if (record != null) {
            fieldValue = record.get(fieldName);
        }
        return fieldValue;
    }

    private void handleSubmissionFlow(ID nominationId) {
        EM_Speaker_Nomination_vod__c newNomination = newNominationsMap.get(nominationId);
        if (isSubmissionFlow(nominationId) && !newNomination.hasErrors()) {
            if (Trigger.isBefore && newNomination.Status_vod__c == 'Submitted_vod') {
                newNomination.Lock_vod__c = TRUE;
            } else if (Trigger.isAfter && newNomination.RecordTypeId == newSpeakerRecordTypeId && newNomination.Speaker_vod__c == null) {
                EM_Speaker_vod__c newSpeaker = new EM_Speaker_vod__c();
                newSpeaker.Status_vod__c = 'Nominated_vod';
                for (String speakerField : speakerFieldMap.keySet()) {
                    if (speakerField == 'Address_vod__c') {
                        Address_vod__c address = addressMap.get(newNomination.Address_vod__c);
                        if (address != null) {
                            newSpeaker.Address_vod__c = getFormattedAddress(address);
                        }
                    } else if (speakerField == 'Name' && newNomination.Account_vod__c == null) {
                        newSpeaker.Name = getFormattedSpeakerName(newNomination);
                    } else if (speakerNominationFieldMap.containsKey(speakerField) && speakerFieldMap.get(speakerField).getDescribe().isCustom()
                               && !speakerFieldMap.get(speakerField).getDescribe().isCalculated()
                               && !EXCLUDED_SPEAKER_FIELDS_STAMP.contains(speakerField)) {
                        newSpeaker.put(speakerField, newNomination.get(speakerField));
                    }
                }
                nominationToNewSpeakerMap.put(newNomination.Id, newSpeaker);
            }
        }
    }

    private void handleNewSpeakerInsert() {
        if (!nominationToNewSpeakerMap.isEmpty()) {
            insert nominationToNewSpeakerMap.values();
            List<EM_Speaker_Nomination_vod__c> nominationsToUpdate = new List<EM_Speaker_Nomination_vod__c>();
            for (ID nominationId : nominationToNewSpeakerMap.keySet()) {
                EM_Speaker_Nomination_vod__c nominationToUpdate = new EM_Speaker_Nomination_vod__c();
                nominationToUpdate.Id = nominationId;
                nominationToUpdate.Speaker_vod__c = nominationToNewSpeakerMap.get(nominationId).Id;
                nominationToUpdate.Override_Lock_vod__c = TRUE;
                nominationsToUpdate.add(nominationToUpdate);
            }
            if (!nominationsToUpdate.isEmpty()) {
                update nominationsToUpdate;
            }
        }
    }

    private void handleSpeakerStatusUpdate(ID nominationId) {
        EM_Speaker_Nomination_vod__c newNomination = newNominationsMap.get(nominationId);
        if (newNomination.Speaker_vod__c != null && isNominationFieldChanged(nominationId, 'Status_vod__c')
                && (newNomination.Status_vod__c == 'Approved_vod' || newNomination.Status_vod__c == 'Rejected_vod')) {
            EM_Speaker_vod__c speaker = new EM_Speaker_vod__c();
            speaker.Id = newNomination.Speaker_vod__c;
            speaker.Status_vod__c = newNomination.Status_vod__c;
            speakersToUpdate.add(speaker);
        }
    }

    private boolean isNominationFieldChanged(String nominationId, String fieldName) {
        boolean fieldChanged = TRUE;
        EM_Speaker_Nomination_vod__c newNomination = newNominationsMap.get(nominationId);
        EM_Speaker_Nomination_vod__c oldNomination = oldNominationsMap.get(nominationId);
        if (newNomination != null && oldNomination != null) {
            fieldChanged = newNomination.get(fieldName) != oldNomination.get(fieldName);
        }
        return fieldChanged;
    }

    private boolean isNominationLocked(EM_Speaker_Nomination_vod__c nomination) {
        return nomination.Lock_vod__c;
    }

    private boolean isSubmissionFlow(ID nominationId) {
        EM_Speaker_Nomination_vod__c newNomination = newNominationsMap.get(nominationId);
        return (newNomination.Status_vod__c == 'Submitted_vod' || newNomination.Status_vod__c == 'Pending_Approval_vod')
                && (Trigger.isInsert || (Trigger.isUpdate && isNominationFieldChanged(nominationId, 'Status_vod__c')));
    }

    private String getVeevaMessage(String messageKey, String defaultMessage) {
        if (veevaMessageMap == null) {
            List<String> messageKeyList = new List<String>();
            messageKeyList.add(EXISTING_SPEAKER_PROFILE_KEY);
            messageKeyList.add(EXISTING_SPEAKER_NOMINATION_KEY);
            veevaMessageMap = VOD_VEEVA_MESSAGE.getVeevaMessages(messageKeyList);
        }
        String message = veevaMessageMap.get(messageKey);
        if (message == null) {
            String[] splitKey = messageKey.split(';;', 2);
            message = VOD_VEEVA_MESSAGE.getMsgWithDefault(splitKey[0], splitKey[1], defaultMessage);
            veevaMessageMap.put(messageKey, message);
        }
        return message;
    }

    private String getFormattedAddress(Address_vod__c address) {
        String formattedAddress = '';
        if (address.Name != null) {
            formattedAddress += address.Name;
        }
        if (address.Address_line_2_vod__c != null) {
            formattedAddress += ' ' + address.Address_line_2_vod__c;
        }
        if (address.City_vod__c != null) {
            formattedAddress += ' ' + address.City_vod__c;
        }
        if (address.State_vod__c != null) {
            formattedAddress += ', ' + address.State_vod__c;
        }
        if (address.Zip_vod__c != null) {
            formattedAddress += ' ' + address.Zip_vod__c;
        }
        return formattedAddress;
    }

    private String getFormattedSpeakerName(EM_Speaker_Nomination_vod__c nomination) {
        String formattedName = '';
        if (nomination.Last_Name_vod__c != null) {
            formattedName += nomination.Last_Name_vod__c;
        }
        if (nomination.First_Name_vod__c != null) {
            if (String.isNotEmpty(formattedName)) {
                formattedName += ', ';
            }
            formattedName += nomination.First_Name_vod__c;
        }
        return formattedName;
    }
}