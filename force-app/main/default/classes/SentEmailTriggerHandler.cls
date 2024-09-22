public without sharing class SentEmailTriggerHandler extends VeevaTriggerHandler {

    private static VEEVA_KeyMessageAccessChecker keyMsgChecker = new VEEVA_KeyMessageAccessChecker();
    private static RecordType emRecordTypes = [SELECT Id FROM RecordType WHERE SobjectType='Sent_Email_vod__c' AND DeveloperName = 'Events_Management_vod'];
    @testVisible
    private static List<Message_vod__c> veevaMessages = [Select Name, Text_vod__c From Message_vod__c WHERE Name in ('APP_EMAIL_PENDING_STATUS_CHANGE_ERROR', 'APP_EMAIL_REJECTED_STATUS_CHANGE_ERROR') AND Category_vod__c='ApprovedEmail' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];

    // map of new status to allowed old statuses. If a new status is not specified, all old statuses are allowed.
    private static Map<String, Set<String>> NEW_STATUS_TO_ALLOWED_OLD = new Map<String, Set<String>>{
        'Scheduled_vod' => new Set<String>{'Draft_vod', 'Scheduled_vod', 'Approved_vod'},
        'Pending_vod' => new Set<String>{'Draft_vod', 'Scheduled_vod', 'Pending_vod'},
        'Discarded_vod' => new Set<String>{'Draft_vod', 'Scheduled_vod', 'Group_vod'},
        'Draft_vod' => new Set<String>{'Draft_vod'}
    };

    private static String MAIL_NOT_SENT_WITHIN_TWO_WEEKS_ERROR = 'Unable to process email in 14 days';

    private List<Sent_Email_vod__c> oldEmails = new List<Sent_Email_vod__c>();
    private List<Sent_Email_vod__c> newEmails = new List<Sent_Email_vod__c>();
    private Map<Id, Sent_Email_vod__c> oldEmailsMap = new Map<Id, Sent_Email_vod__c>();
    private Map<Id, Sent_Email_vod__c> newEmailsMap = new Map<Id, Sent_Email_vod__c>();

    @testVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.newEmails = (List<Sent_Email_vod__c>) triggerNew;
        this.oldEmails = (List<Sent_Email_vod__c>) triggerOld;
        this.newEmailsMap = (Map<Id, Sent_Email_vod__c>) triggerNewMap;
        this.oldEmailsMap = (Map<Id, Sent_Email_vod__c>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'Sent_Email_vod__c';
    }

    protected override void beforeInsert() {
        // Filter emails without Draft_vod or Discarded_vod status
        List<Sent_Email_vod__c> filteredEmails = filterEmailsForInsertProcess();

        if (!filteredEmails.isEmpty()) {
            processFilteredNewInserts(filteredEmails);
        }
    }

    protected override void afterInsert() {
        // Categorize emails
        List<Sent_Email_vod__c> discardedEmails = new List<Sent_Email_vod__c>();
        List<Sent_Email_vod__c> filteredEmails = new List<Sent_Email_vod__c>();
        List<Sent_Email_vod__c> emailsEligibleForSentDocCreation = new List<Sent_Email_vod__c>();
        List<Sent_Email_vod__c> emailsForSentEmailBuilderCellCreation = new List<Sent_Email_vod__c>();

        for (Sent_Email_vod__c email: newEmails){
            if (!isDraftEmail(email)) {
                if (isDiscardedEmail(email)) {
                    discardedEmails.add(email);
                } else {
                    filteredEmails.add(email);
                }

                Sent_Email_vod__c oldEmail = oldEmailsMap.get(email.Id);
                if(canCreateSentDocument(email, oldEmail)) {
                    emailsEligibleForSentDocCreation.add(email);
                }

                if (shouldCreateSentEmailBuilderCells(email, oldEmail)) {
                    emailsForSentEmailBuilderCellCreation.add(email);
                }
            }
        }

        // Handle emails in Discarded_vod status
        if (!discardedEmails.isEmpty()) {
            deleteSentEmails(discardedEmails);
        }

        // Handle emails without Draft_vod or Discarded_vod status
        if (!filteredEmails.isEmpty()) {
            postProcessFilteredNewInserts(filteredEmails);
        }

        if(!emailsEligibleForSentDocCreation.isEmpty()) {
            createSentFragmentsForSavedEmails(emailsEligibleForSentDocCreation);
        }

        if (!emailsForSentEmailBuilderCellCreation.isEmpty()) {
            createSentEmailBuilderCells(emailsForSentEmailBuilderCellCreation);
        }
    }

    protected override void beforeUpdate() {
        // Categorize emails
        List<Sent_Email_vod__c> draftEmails = new List<Sent_Email_vod__c>();
        List<Sent_Email_vod__c> scheduledOrPendingEmails = new List<Sent_Email_vod__c>();
        List<Sent_Email_vod__c> discardedEmails = new List<Sent_Email_vod__c>();
        List<Sent_Email_vod__c> filteredEmails = new List<Sent_Email_vod__c>();
        List<Sent_Email_vod__c> savedDraftEmails = new List<Sent_Email_vod__c>();
        List<Sent_Email_vod__c> filteredEmailsOld = new List<Sent_Email_vod__c>();
        List<Sent_Email_vod__c> emailsEligibleForSentDocCreation = new List<Sent_Email_vod__c>();
        List<Sent_Email_vod__c> emailsForSentEmailBuilderCellCreation = new List<Sent_Email_vod__c>();

        for (Sent_Email_vod__c email : newEmails) {
            Sent_Email_vod__c old = oldEmailsMap.get(email.Id);
            if (isDraftEmail(email)) {
                draftEmails.add(email);
            } else if (isScheduledEmail(email) || isPendingEmail(email)) {
               scheduledOrPendingEmails.add(email);
            } else if (isDiscardedEmail(email)) {
                discardedEmails.add(email);
            } else if (isSavedEmail(email)) {
                if (isDraftEmail(old)) {
                   savedDraftEmails.add(email);
                } else {
                    filteredEmails.add(email);
                    filteredEmailsOld.add(old);
                }
            } else {
               filteredEmails.add(email);
               filteredEmailsOld.add(oldEmailsMap.get(email.Id));
            }

            if(canCreateSentDocument(email, old)) {
                emailsEligibleForSentDocCreation.add(email);
            }

            if (shouldCreateSentEmailBuilderCells(email, old)) {
                emailsForSentEmailBuilderCellCreation.add(email);
            }
        }

        if(!emailsEligibleForSentDocCreation.isEmpty()) {
            createSentFragmentsForSavedEmails(emailsEligibleForSentDocCreation);
        }

        if (!emailsForSentEmailBuilderCellCreation.isEmpty()) {
            createSentEmailBuilderCells(emailsForSentEmailBuilderCellCreation);
        }

        // Handle draft email updates
        handleSyncErrorForUpdates(draftEmails, oldEmailsMap);

        // Handle discarded email updates
        handleSyncErrorForUpdates(discardedEmails, oldEmailsMap);

        // Handle scheduled email updates
        if (!scheduledOrPendingEmails.isEmpty() || !savedDraftEmails.isEmpty()) {
            List<Sent_Email_vod__c> scheduledDraftEmails = new List<Sent_Email_vod__c>();
            List<Sent_Email_vod__c> fromScheduled = new List<Sent_Email_vod__c>();
            for (Sent_Email_vod__c email : scheduledOrPendingEmails) {
               Sent_Email_vod__c old = oldEmailsMap.get(email.Id);
               if (!isUpdateAllowed(email, old)) {
                   email.addError('Failed to update Sent_Email_vod__c object due to invalid value for status field. Old status is ' +
                       old.Status_vod__c + '. New status is ' + email.Status_vod__c + '.');
               } else if (isDraftEmail(old)) { // Old status is Draft_vod
                    scheduledDraftEmails.add(email);
               } else { // Old status is Scheduled_vod
                   fromScheduled.add(email);
               }
           }

           // Handle saved or scheduled email from a draft email
           handleScheduledSavedFromDraft(scheduledDraftEmails, savedDraftEmails);

           // Handle updating scheduled
           handleUpdateScheduled(fromScheduled);
        }

        // Handle other email updates
        handleRegularEmailUpdates(filteredEmails, filteredEmailsOld);
    }

    protected override void afterUpdate() {
        // Filter emails with Discarded_vod status
        List<Sent_Email_vod__c> discardedEmails = new List<Sent_Email_vod__c>();
        for(Sent_Email_vod__c email: newEmails) {
            if (isDiscardedEmail(email)) {
                discardedEmails.add(email);
            }
        }

        if (!discardedEmails.isEmpty()) {
            deleteSentEmails(discardedEmails);
        }
    }

    private void handleRegularEmailUpdates(List<Sent_Email_vod__c> filteredEmails, List<Sent_Email_vod__c> filteredEmailsOld) {
        if (!filteredEmails.isEmpty()) {

            // Update Entity Ref
            copyRefIdToLookup(filteredEmails);

            for (Sent_Email_vod__c email : filteredEmails) {
                Sent_Email_vod__c old = oldEmailsMap.get(email.Id);

                Boolean approved = isApprovedEmail(email);
                Boolean skippedSave = isSkippedSaveUpdate(email, old);

                // Fix invalid status and update sent email object
                applyUpdateRules(email, old);

                // Handle Review Emails
                handleReviewEmails(email.Status_vod__c, email, datetime.now(), UserInfo.getUserId());
            }

            VeevaCountryHelper.updateCountryFields(Sent_Email_vod__c.getSObjectType(), Sent_Email_vod__c.OwnerId, Sent_Email_vod__c.Account_vod__c, true, filteredEmails, filteredEmailsOld);
        }
    }

    private Boolean isSkippedSaveUpdate(Sent_Email_vod__c email, Sent_Email_vod__c old) {
        return isScheduledEmail(old) && (isSentEmail(email) || isDeliveredEmail(email));
    }

    private void createSentFragmentsForSavedEmails(List<Sent_Email_vod__c> emails) {
        Set<Id> allFragmentIds = new Set<Id>();

        for (Sent_Email_vod__c se: emails) {
            extractFragmentId(se, allFragmentIds);
        }

        Boolean allowMapKeyMsg = isAllowMapKeyMessage('Sent_Fragment_vod__c', keyMsgChecker);
        ApprovedDocumentKeyMessageWrapper keyMessageWrapper = getDocumentsKeyMessage(allFragmentIds);

        createSentFragments(emails, allowMapKeyMsg, keyMessageWrapper.approvedDocuments, keyMessageWrapper.keyMessages);
    }

    private void handleUpdateScheduled(List<Sent_Email_vod__c> fromScheduled) {
        if (!fromScheduled.isEmpty()) {
            // Update Entity Ref
            copyRefIdToLookup(fromScheduled);

            // Update Country Related Data
            VeevaCountryHelper.updateCountryFields(Sent_Email_vod__c.getSObjectType(), Sent_Email_vod__c.OwnerId, Sent_Email_vod__c.Account_vod__c, false, fromScheduled, null);
        }
    }

    private void handleScheduledSavedFromDraft(List<Sent_Email_vod__c> scheduledDraftEmails, List<Sent_Email_vod__c> savedDraftEmails) {
        List<Sent_Email_vod__c> fromDrafts = new List<Sent_Email_vod__c>();
        fromDrafts.addAll(scheduledDraftEmails);
        fromDrafts.addAll(savedDraftEmails);

        if (!fromDrafts.isEmpty()) {
            // Update Entity Ref
            copyRefIdToLookup(fromDrafts);

            // Doc/Account/User Access Check
            SentEmailsPropertyWrapper sentEmailsPropertyWrapper = checkSentEmailsProperties(fromDrafts);

            // TM Access Check
            SentEmailsTerritoryWrapper sentEmailsTerritoryWrapper = checkUserAccountTerritories(sentEmailsPropertyWrapper.owners, sentEmailsPropertyWrapper.accounts.keySet());

            // Key Message Access Check For Sent_Email_vod__c
            Boolean allowMapKeyMsg = isAllowMapKeyMessage('Sent_Email_vod__c', keyMsgChecker);
            ApprovedDocumentKeyMessageWrapper keyMessageWrapper =
                getDocumentsKeyMessage(sentEmailsPropertyWrapper.approvedDocuments.keySet());

            // Update Sent Email Object
            updateScheduledDrafts(fromDrafts, sentEmailsPropertyWrapper, keyMessageWrapper, allowMapKeyMsg, sentEmailsTerritoryWrapper);

            // Update Country Related Data
            VeevaCountryHelper.updateCountryFields(Sent_Email_vod__c.getSObjectType(), Sent_Email_vod__c.OwnerId, Sent_Email_vod__c.Account_vod__c, false, fromDrafts, null);
        }
    }

    private void updateScheduledDrafts(List<Sent_Email_vod__c> fromDrafts, SentEmailsPropertyWrapper sentEmailsPropertyWrapper,
        ApprovedDocumentKeyMessageWrapper keyMessageWrapper, Boolean allowMapKeyMsg, SentEmailsTerritoryWrapper sentEmailsTerritoryWrapper) {
        for (Sent_Email_vod__c se : fromDrafts){
            //if the template is not accessible
            handleUnaccessibleTemplate(se, sentEmailsPropertyWrapper);
            // Update key message if available in template
            updateEmailKeyMessage(se, keyMessageWrapper, allowMapKeyMsg);

            Id accountID = se.Account_vod__c;
            if(sentEmailsPropertyWrapper.accounts.get(accountID) == false) {
                failEamilForUnaccessibleAccount(se, accountID);
            }

            //if we can set the territory and there is no territory already
            updateEmailTerritoryFields(se, sentEmailsTerritoryWrapper);
        }
    }

    private void extractFragmentId(Sent_Email_vod__c se, Set<Id> allFragmentIds) {
        String fragments = se.Email_Fragments_vod__c;
        if(fragments != null) {
            List<String> idStrs = fragments.split(',');
            for (String idStr : idStrs) {
                try {
                    Id fragId = Id.valueOf(idStr);
                    allFragmentIds.add(fragId);
                } catch (Exception e) {
                    continue;
                }
            }
        }
    }

    private void postProcessFilteredNewInserts(List<Sent_Email_vod__c> filteredEmails) {
        // if the email is of type "Events_Management_vod" store all event id and template id
        Map<Id, Set<Id>> eventIdToTemplateIdsMap = new Map<Id, Set<Id>>();
        Set<Id> allTemplateIds = new Set<Id>();
        Set<Id> allFragmentIds = new Set<Id>();

        // build all the necessary maps and sets
        extractEmailDataForPostInsert(filteredEmails, eventIdToTemplateIdsMap, allTemplateIds, allFragmentIds);

        // Update EM Related Fields
        updateEMRelatedFields(eventIdToTemplateIdsMap, allTemplateIds);
    }

    private void updateEMRelatedFields(Map<Id, Set<Id>> eventIdToTemplateIdsMap, Set<Id> allTemplateIds) {
        if(eventIdToTemplateIdsMap.size() > 0) { // if at lease one sent email is sent from event
            try {
                // store all event materials that need to be updated
                List<EM_Event_Material_vod__c> toUpdate = new List<EM_Event_Material_vod__c>();

                // get all event materials where event_vod_c is in the list eventIds and email_template_vod__c is in eventTemplateIds
                Set<Id> allEventIds = eventIdToTemplateIdsMap.keySet();
                List<EM_Event_Material_vod__c> materials = [SELECT Id, Event_vod__c, Email_Template_vod__c, Material_Used_vod__c FROM EM_Event_Material_vod__c WHERE Event_vod__c IN: allEventIds AND Email_Template_vod__c IN: allTemplateIds];

                if(materials != null){
                    // loop through all materials and update the matching ones
                    for(EM_Event_Material_vod__c mat : materials) {
                        if(eventIdToTemplateIdsMap.get(mat.Event_vod__c).contains(mat.Email_Template_vod__c)) {
                            mat.Material_Used_vod__c = true;
                            toUpdate.add(mat);
                        }
                    }
                }

                // update
                update toUpdate;
            }
            catch (Exception e){
                System.debug(':::Fail to update EM_Event_Material_vod__c.Material_Used_vod__c');
            }
        }
    }

    private void extractEmailDataForPostInsert(List<Sent_Email_vod__c> filteredEmails, Map<Id, Set<Id>> eventIdToTemplateIdsMap,
        Set<Id> allTemplateIds, Set<Id> allFragmentIds) {
        Id emRecordTypeId = getEmRecordTypeId();
        for (Sent_Email_vod__c se : filteredEmails){
            retrieveEmailApprovedDocData(se, allTemplateIds, allFragmentIds);
            retrieveEmailEventData(se, eventIdToTemplateIdsMap, emRecordTypeId);
        }
    }

    private void retrieveEmailEventData(Sent_Email_vod__c se, Map<Id, Set<Id>> eventIdToTemplateIdsMap, Id emRecordTypeId) {
        if(emRecordTypeId != null && se.RecordTypeId == emRecordTypeId) {
            // build the event-id-to-template-id map
            // these fields must be there if this Sent Email is of type Event_Management_vod
            if(eventIdToTemplateIdsMap.containsKey(se.Event_vod__c)) {
                // existing event, put the template in the template id set (will not store duplicate)
                eventIdToTemplateIdsMap.get(se.Event_vod__c).add(se.Approved_Email_Template_vod__c);
            }
            else {
                // new event, put template id in new set and store the entry in the map
                Set<Id> newTemplateIdList = new Set<Id>();
                newTemplateIdList.add(se.Approved_Email_Template_vod__c);
                eventIdToTemplateIdsMap.put(se.Event_vod__c, newTemplateIdList);
            }
        }
    }

    private void retrieveEmailApprovedDocData(Sent_Email_vod__c se, Set<Id> allTemplateIds, Set<Id> allFragmentIds) {
         // get all template id
         allTemplateIds.add(se.Approved_Email_Template_vod__c);
         // get all fragment ids
         String fragments = se.Email_Fragments_vod__c;
         if(fragments != null) {
             List<String> idStrs = fragments.split(',');
             for (String idStr : idStrs) {
                 try {
                     Id fragId = Id.valueOf(idStr);
                     allFragmentIds.add(fragId);
                 } catch (Exception e) {
                     continue;
                 }
             }
         }
    }

    private Id getEmRecordTypeId() {
        return (emRecordTypes != null) ? emRecordTypes.Id : null;
    }

    private List<Sent_Email_vod__c> filterEmailsForInsertProcess() {
        List<Sent_Email_vod__c> filteredEmails = new List<Sent_Email_vod__c>();

        for (Sent_Email_vod__c email: newEmails){
            if (!(isDraftEmail(email) || isDiscardedEmail(email))) {
                filteredEmails.add(email);
            }
        }

        return filteredEmails;
    }

    private void processFilteredNewInserts(List<Sent_Email_vod__c> filteredEmails) {
        // Update Entity Ref
        copyRefIdToLookup(filteredEmails);

        // Doc/Account/User Access Check
        SentEmailsPropertyWrapper sentEmailsPropertyWrapper = checkSentEmailsProperties(filteredEmails);

        // TM Access Check
        SentEmailsTerritoryWrapper sentEmailsTerritoryWrapper = checkUserAccountTerritories(sentEmailsPropertyWrapper.owners, sentEmailsPropertyWrapper.accounts.keySet());

        // Key Message Access Check
        Boolean allowMapKeyMsg = isAllowMapKeyMessage('Sent_Email_vod__c', keyMsgChecker);
        ApprovedDocumentKeyMessageWrapper keyMessageWrapper = getDocumentsKeyMessage(sentEmailsPropertyWrapper.approvedDocuments.keySet());

        // Update Sent Email Objects
        updateSentEmailForNewRecords(filteredEmails, sentEmailsPropertyWrapper, keyMessageWrapper, allowMapKeyMsg, sentEmailsTerritoryWrapper);

        // Update Country Related Data
        VeevaCountryHelper.updateCountryFields(Sent_Email_vod__c.getSObjectType(), Sent_Email_vod__c.OwnerId, Sent_Email_vod__c.Account_vod__c, false, filteredEmails, null);
    }

    private void updateSentEmailForNewRecords(List<Sent_Email_vod__c> emails, SentEmailsPropertyWrapper sentEmailsPropertyWrapper,
        ApprovedDocumentKeyMessageWrapper keyMessageWrapper, Boolean allowMapKeyMsg, SentEmailsTerritoryWrapper sentEmailsTerritoryWrapper) {
        for (Sent_Email_vod__c se : emails){
            //if the template is not accessible
            handleUnaccessibleTemplate(se, sentEmailsPropertyWrapper);

            // Update key message if available in template
            updateEmailKeyMessage(se, keyMessageWrapper, allowMapKeyMsg);

            // if user or account is not accessible
            handleInaccessibleUserAccount(se, sentEmailsPropertyWrapper);

            //if we can set the territory and there is no territory already
            updateEmailTerritoryFields(se, sentEmailsTerritoryWrapper);
        }
    }

    private void handleUnaccessibleTemplate(Sent_Email_vod__c se, SentEmailsPropertyWrapper sentEmailsPropertyWrapper) {
        Id templateID = se.Approved_Email_Template_vod__c;
        //if the template is not accessible
        if(sentEmailsPropertyWrapper.approvedDocuments.get(templateID) == false){
            se.Failure_Msg_vod__c= 'Failed to send because template with the ID '+se.Approved_Email_Template_vod__c + ' could not be accessed';
            se.Approved_Email_Template_vod__c = null;
            se.Status_vod__c = 'Failed_vod';
        }
    }

    private void updateEmailKeyMessage(Sent_Email_vod__c se, ApprovedDocumentKeyMessageWrapper keyMessageWrapper,
        Boolean allowMapKeyMsg) {
        Id templateID = se.Approved_Email_Template_vod__c;

        if (allowMapKeyMsg) {
            Approved_Document_vod__c template = keyMessageWrapper.approvedDocuments.get(templateID);
            if (template != null && template.Key_Message_vod__c != null) {
                // Check FLS for key message
                Id keyMsgId = template.Key_Message_vod__c;
                Key_Message_vod__c keyMsg = keyMessageWrapper.keyMessages.get(keyMsgId);
                if (keyMsg != null) {
                    se.Key_Message_vod__c = keyMsgId;
                }
            }
        }
    }

    private void handleInaccessibleUserAccount(Sent_Email_vod__c se, SentEmailsPropertyWrapper sentEmailsPropertyWrapper) {
        Id emRecordTypeId = getEmRecordTypeId();
        Id accountID = se.Account_vod__c;
        Id toUserID = se.User_vod__c;
        if(emRecordTypeId != null && se.RecordTypeId == emRecordTypeId) {
            // for EM we can send email to both User and Account
            if(accountID != null && sentEmailsPropertyWrapper.accounts.get(accountID) == false) {
                failEamilForUnaccessibleAccount(se, accountID);
            } else if (toUserID != null && sentEmailsPropertyWrapper.toUsers.get(toUserID) == false) {
                failEmailForUnaccessibleUser(se, toUserID);
            } else if(accountID != null && toUserID != null) {
                failEmailForUnaccessibleUserAccount(se);
            }
        } else if(sentEmailsPropertyWrapper.accounts.get(accountID) == false) {
            failEamilForUnaccessibleAccount(se, accountID);
        }
    }

    private void failEmailForUnaccessibleUserAccount(Sent_Email_vod__c se) {
        se.Failure_Msg_vod__c= 'Failed to send because of missing Account or User lookup';
        se.Status_vod__c = 'Failed_vod';
    }

    private void failEmailForUnaccessibleUser(Sent_Email_vod__c se, Id toUserID) {
        se.Failure_Msg_vod__c= 'Failed to send because User with the ID ' + toUserID  + ' could not be accessed';
        se.User_vod__c = null;
        se.Status_vod__c = 'Failed_vod';
    }

    private void failEamilForUnaccessibleAccount(Sent_Email_vod__c se, Id accountID) {
        se.Failure_Msg_vod__c= 'Failed to send because Account with the ID ' + accountID  + ' could not be accessed';
        se.Account_vod__c = null;
        se.Status_vod__c = 'Failed_vod';
    }

    private void updateEmailTerritoryFields(Sent_Email_vod__c se, SentEmailsTerritoryWrapper sentEmailsTerritoryWrapper) {
        if(sentEmailsTerritoryWrapper.setTerritory && se.Territory_vod__c == Null){
            String userOrGroupId = null;
            Id accountID = se.Account_vod__c;
            if(accountID != null && !sentEmailsTerritoryWrapper.accountShares.isEmpty()) {
                // for Account recipient, find the AccountShare object for this email's account
                for(AccountShare acctShare: sentEmailsTerritoryWrapper.accountShares){
                    if(accountID.equals(acctShare.AccountId)){
                        userOrGroupId = acctShare.UserOrGroupId;
                        break;
                    }
                }
            }
            //if we have a group ID then get the territory for that group
            if(userOrGroupId != null){
                for(Group g: sentEmailsTerritoryWrapper.groups.values()){
                    if(userOrGroupId.equals(g.Id)){
                        String terrId = g.relatedId;
                        String terrName = sentEmailsTerritoryWrapper.territories.get(terrId).get('Name');
                        se.Territory_vod__c = terrName;
                        break;
                    }
                }
            }
            //otherwise just get the territory for this user
            else{
                for(Map<String, String> userTerr : sentEmailsTerritoryWrapper.userTerrs.values()) {
                    Map<String, String> terr = sentEmailsTerritoryWrapper.territories.get(userTerr.get('territoryId'));
                    if(se.OwnerId.equals(userTerr.get('UserId')) && terr != null){
                        se.Territory_vod__c = terr.get('Name');
                        break;
                    }
                }
            }
        }
    }

    private void copyRefIdToLookup(List<Sent_Email_vod__c> emails) {
        VOD_Utils.copyRefIdToLookup('Entity_Reference_Id_vod__c', 'Account_vod__c', Schema.Account.SObjectType, emails);
    }

    @TestVisible
    private static void createSentFragments(List<Sent_Email_vod__c> emails, Boolean allowMapKeyMsg, Map<Id, Approved_Document_vod__c> fragmentMap,
        Map<Id, Key_Message_vod__c> keyMsgMap) {
        // created new Sent_Fragment_vod objects that lookup to the email template and email fragments sent out
        List<Sent_Fragment_vod__c> sentDocuments = new List<Sent_Fragment_vod__c>();
        Map<String,Id> recordTypes = getSentFragmentRecordTypeIds();
        Id sentVeevaDistributionRecordTypeId = recordTypes.get('Sent_Veeva_Distribution_vod');
        Id sentVeevaContentRecordTypeId = recordTypes.get('Sent_Veeva_Content_vod');
        for (Sent_Email_vod__c se : emails){
            sentDocuments.addAll(trackSentEmailFragments(se, allowMapKeyMsg, fragmentMap, keyMsgMap));
             // record type is not available, skip
            if(sentVeevaDistributionRecordTypeId != null) {
                sentDocuments.addAll(trackSentVeevaDistributions(se, sentVeevaDistributionRecordTypeId));   
            }
            if( sentVeevaContentRecordTypeId!= null){
                Sent_Fragment_vod__c veevaDynamicContentGenerated = trackSentVeevaDynamicContentGenerated(se,sentVeevaContentRecordTypeId);
                if(veevaDynamicContentGenerated != null ){
                    sentDocuments.add(veevaDynamicContentGenerated);
                }
            }
        }

        if(!sentDocuments.isEmpty()) {
            try {
                insert sentDocuments;
            } catch( Exception e ) {
                System.debug(':::Fail to insert Sent_Fragment_vod__c objects, cause: ' + e.getMessage());
            }
        }
    }

    private static void createSentEmailBuilderCells(List<Sent_Email_vod__c> sentEmails) {
        List<Sent_Email_Builder_Cell_vod__c> sentEmailBuilderCells = new List<Sent_Email_Builder_Cell_vod__c>();
        Map<ID, List<Map<String, String>>> emailBuilderCellValuesBySentEmail = getEmailBuilderCellValues(sentEmails);
        Map<ID, Email_Builder_Cell_vod__c> emailBuilderCells = retrieveEmailBuilderCells(emailBuilderCellValuesBySentEmail);


        for (Sent_Email_vod__c sentEmail : sentEmails) {
            List<Map<String, String>> emailCells = emailBuilderCellValuesBySentEmail.get(sentEmail.ID);

            Integer insertedOrder = 1;

            for (Map<String, String> emailCell : emailCells) {
                Id emailBuilderCellId = (Id) emailCell.get('id');
                Email_Builder_Cell_vod__c emailBuilderCell = emailBuilderCells.get(emailBuilderCellId);
                Sent_Email_Builder_Cell_vod__c sentEmailBuilderCell = new Sent_Email_Builder_Cell_vod__c();
                sentEmailBuilderCell.Email_Builder_Cell_vod__c = emailBuilderCellId;
                sentEmailBuilderCell.Sent_Email_vod__c = sentEmail.ID;
                sentEmailBuilderCell.Inserted_Order_vod__c = String.valueOf(insertedOrder);

                if (emailBuilderCell.Type_vod__c == 'Document_vod') {
                    sentEmailBuilderCell.Approved_Document_vod__c = emailBuilderCell.Approved_Document_vod__c;
                }

                insertedOrder++;
                sentEmailBuilderCells.add(sentEmailBuilderCell);
            }
        }

        if (!sentEmailBuilderCells.isEmpty()) {
            Database.SaveResult[] results = Database.insert(sentEmailBuilderCells, true);
            for (Database.SaveResult saveResult : results) {
                if (!saveResult.isSuccess()) {
                    for(Database.Error err : saveResult.getErrors()) {
            			System.debug(':::Failed to insert Sent_Email_Builder_Cell_vod, Status Code: ' + err.getStatusCode() + ' Message: ' + err.getMessage());
        			}
                }
            }
        }
    }

    private static Map<ID, List<Map<String, String>>> getEmailBuilderCellValues(List<Sent_Email_vod__c> sentEmails) {
        Map<ID, List<Map<String, String>>> emailBuilderCellValuesBySentEmail = new Map<ID, List<Map<String, String>>>();

        for (Sent_Email_vod__c sentEmail : sentEmails) {
            String emailValues = sentEmail.Email_Builder_Values_vod__c;
            Map<String, List<Map<String, String>>> emailValuesMap = (Map<String, List<Map<String, String>>>) JSON.deserialize(emailValues, Map<String, List<Map<String, String>>>.class);
            List<Map<String, String>> emailCells = emailValuesMap.get('emailBuilderCells');

            emailBuilderCellValuesBySentEmail.put(sentEmail.ID, emailCells);
        }

        return emailBuilderCellValuesBySentEmail;
    }

    private static Map<ID, Email_Builder_Cell_vod__c> retrieveEmailBuilderCells(Map<ID, List<Map<String, String>>> emailBuilderCellValuesBySentEmail) {
        Set<ID> emailBuilderCellIds = new Set<ID>();

        for (ID sentEmailId : emailBuilderCellValuesBySentEmail.keySet()) {
            List<Map<String, String>> cells = emailBuilderCellValuesBySentEmail.get(sentEmailId);
            for (Map<String, String> cell : cells) {
                emailBuilderCellIds.add((Id) cell.get('id'));
            }
        }

        List<Email_Builder_Cell_vod__c> emailBuilderCells = [SELECT ID, Approved_Document_vod__c, Type_vod__c FROM Email_Builder_Cell_vod__c WHERE ID in :emailBuilderCellIds];

        return new Map<ID, Email_Builder_Cell_vod__c>(emailBuilderCells);
    }

    private static List<Sent_Fragment_vod__c> trackSentEmailFragments(Sent_Email_vod__c se, Boolean allowMapKeyMsg,
                                                                        Map<Id, Approved_Document_vod__c> fragmentMap,
                                                                        Map<Id, Key_Message_vod__c> keyMsgMap) {
        List<Sent_Fragment_vod__c> sentEmailFragments = new List<Sent_Fragment_vod__c>();
        String fragments = se.Email_Fragments_vod__c;
        if(String.isNotBlank(fragments)) {
            String[] fragmentList = fragments.split(',');
            for(String fragmentId: fragmentList) {
                try {
                    Sent_Fragment_vod__c fragment = initSentDocument(se);
                    fragment.Sent_Fragment_vod__c = fragmentId;
                    Approved_Document_vod__c apprDoc = fragmentMap.get(fragmentId);
                    // Update key message if available in fragment
                    if (allowMapKeyMsg) {
                        if (apprDoc.Key_Message_vod__c != NULL) {
                            Id keyMsgId = apprDoc.Key_Message_vod__c;
                            Key_Message_vod__c keyMsg = keyMsgMap.get(keyMsgId);
                            if (keyMsg != null) {
                                fragment.Key_Message_vod__c = keyMsgId;
                            }
                        }
                    }
                    // Set Sent_Veeva_Content_vod if It's auto-published fragment.
                    if (Schema.SObjectType.Veeva_Content_vod__c.isAccessible() && Schema.SObjectType.Approved_Document_vod__c.fields.Veeva_Content_vod__c.isAccessible()) {
                        fragment.Sent_Veeva_Content_vod__c = apprDoc.Veeva_Content_vod__c;
                    }
                    sentEmailFragments.add(fragment);
                } catch( Exception e ) {
                    continue;
                }
            }
        }
        return sentEmailFragments;
    }

    private static List<Sent_Fragment_vod__c> trackSentVeevaDistributions(Sent_Email_vod__c se, Id recordTypeId) {
        List<Sent_Fragment_vod__c> sentVeevaDistributions = new List<Sent_Fragment_vod__c>();
        String veevaDistributions = se.Veeva_Distributions_vod__c;
        if(String.isNotBlank(veevaDistributions)) {
            String[] veevaDistributionList = veevaDistributions.split(',');
            for(String veevaDistributionId: veevaDistributionList) {
                try {
                    Sent_Fragment_vod__c veevaDistribution = initSentDocument(se);
                    veevaDistribution.Sent_Veeva_Distribution_vod__c = veevaDistributionId;
                    veevaDistribution.RecordTypeId = recordTypeId;
                    sentVeevaDistributions.add(veevaDistribution);
                } catch( Exception e ) {
                    continue;
                }
            }
        }
        return sentVeevaDistributions;
    }

    private static Sent_Fragment_vod__c trackSentVeevaDynamicContentGenerated(Sent_Email_vod__c se, Id recordTypeId) {
        String veevaContent = se.Veeva_Content_vod__c;
        if(String.isNotBlank(veevaContent)) {
            Sent_Fragment_vod__c sentVeevaContent = initSentDocument(se);
            sentVeevaContent.RecordTypeId = recordTypeId;
            sentVeevaContent.Sent_Veeva_Content_vod__c = se.Veeva_Content_vod__c;
            return sentVeevaContent;
        }
        return null;
    }

    private static Map<String,Id> getSentFragmentRecordTypeIds() {
        RecordType[] recordType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Sent_Fragment_vod__c' AND (DeveloperName = 'Sent_Veeva_Distribution_vod' OR DeveloperName='Sent_Veeva_Content_vod') AND IsActive = true];
        
        Map<String,Id> recordsMap = new Map<String,Id>();
        if (recordType.size() == 0){
            return null;
        }else{
            for(RecordType record: recordType){
                recordsMap.put(record.DeveloperName,record.Id);
            }
        }
        return recordsMap;
    }

    private static Sent_Fragment_vod__c initSentDocument(Sent_Email_vod__c se) {
        Sent_Fragment_vod__c sentDocument = new Sent_Fragment_vod__c();
        sentDocument.Email_Template_vod__c = se.Approved_Email_Template_vod__c;
        sentDocument.Sent_Email_vod__c = se.Id;
        sentDocument.Account_vod__c = se.Account_vod__c;
        return sentDocument;
    }

    @TestVisible
    private static Boolean canCreateSentDocument(Sent_Email_vod__c newEmail, Sent_Email_vod__c oldEmail) {
        if(newEmail != null) {
            // Scenario 1: Email get new status as Sent_vod
            // [1] Email has status Sent now
            // [2] Previous status, if available, is not Sent/ Delivered
            //      (Delivered status is possible when Mailgun Delivered is handled before MC update email to Sent status)
            // Scenario 2: Email get new status as Delivered, but it's not updating from a Sent status
            // [1] Email has status Delivered now
            // [2] Previous status, if available, is not Sent/ Delivered
            Boolean isNewlySentOrDelivered = isEmailStatusSentOrDelivered(newEmail);
            Boolean oldStatusIsNotSentOrDelivered = oldEmail == null || !isEmailStatusSentOrDelivered(oldEmail);
            return isNewlySentOrDelivered && oldStatusIsNotSentOrDelivered;
        }
        return false;
    }

    /*
    * Sent_Email_Builder_Cell_vod need to be created for each Email_Builder_Cell_vod included in a Sent_Email_vod that was created by Email Builder.
    * If an email was successfully sent/delivered AND the previous status is NOT sent/delivered AND Sent_Email_vod.Email_Builder_Values_vod__c is populated, then
    * Sent_Email_Builder_Cell_vod will be created
    *
    */
    private static Boolean shouldCreateSentEmailBuilderCells(Sent_Email_vod__c newEmail, Sent_Email_vod__c oldEmail) {
        if(newEmail != null) {
            Boolean isSentOrDelivered = isEmailStatusSentOrDelivered(newEmail);
            Boolean oldStatusIsNotSentOrDelivered = oldEmail == null || !isEmailStatusSentOrDelivered(oldEmail);
            return isSentOrDelivered && oldStatusIsNotSentOrDelivered && newEmail.Email_Builder_Values_vod__c != null;
        }

        return false;
    }

    private static Boolean isEmailStatusSentOrDelivered(Sent_Email_vod__c email) {
        return isSentEmail(email) || isDeliveredEmail(email);
    }

    @TestVisible
    private static ApprovedDocumentKeyMessageWrapper getDocumentsKeyMessage(Set<Id> docIds) {
        ApprovedDocumentKeyMessageWrapper wrapper = new ApprovedDocumentKeyMessageWrapper();
         // get all the templates
         if (Schema.SObjectType.Veeva_Content_vod__c.isAccessible() && Schema.SObjectType.Approved_Document_vod__c.fields.Veeva_Content_vod__c.isAccessible()) {
            wrapper.approvedDocuments = new Map<Id, Approved_Document_vod__c>([SELECT Id, Key_Message_vod__c, Key_Message_vod__r.Name, Veeva_Content_vod__c FROM Approved_Document_vod__c WHERE Id =: docIds]);
         } else {
            wrapper.approvedDocuments = new Map<Id, Approved_Document_vod__c>([SELECT Id, Key_Message_vod__c, Key_Message_vod__r.Name FROM Approved_Document_vod__c WHERE Id =: docIds]);
         }
        // get all the key messages in the templatess
        Map<Id, Key_Message_vod__c> keyMsgMap = new Map<Id, Key_Message_vod__c>();
        for(Approved_Document_vod__c doc : wrapper.approvedDocuments.values()) {
            keyMsgMap.put(doc.Key_Message_vod__c, doc.Key_Message_vod__r);
        }
        wrapper.keyMessages = keyMsgMap;
        return wrapper;
    }

    @TestVisible
    private static Boolean isAllowMapKeyMessage(String targetObj, VEEVA_KeyMessageAccessChecker keyMsgChecker) {
        Map<String, Boolean> keyMsgAccessMap = keyMsgChecker.getUserAccessToKeyMessageForAE();
        return keyMsgAccessMap.get('Approved_Document_vod__c') && keyMsgAccessMap.get(targetObj);
    }

    @TestVisible
    private class ApprovedDocumentKeyMessageWrapper {
        public Map<Id, Approved_Document_vod__c> approvedDocuments {
            get {
                if (approvedDocuments == null) {
                    approvedDocuments = new Map<Id, Approved_Document_vod__c>();
                }
                return approvedDocuments;
            }
            set;
        }

        public Map<Id, Key_Message_vod__c> keyMessages {
            get {
                if (keyMessages == null) {
                    keyMessages = new Map<Id, Key_Message_vod__c>();
                }
                return keyMessages;
            }
            set;
        }
    }

    @TestVisible
    private class SentEmailsTerritoryWrapper {
        public boolean setTerritory {
            get {
                if (setTerritory == null) {
                    setTerritory = false;
                }
                return setTerritory;
            }
            set;
        }

        public Map<Id, Group> groups {
            get {
                if (groups == null) {
                    groups = new Map<Id,Group>();
                }
                return groups;
            }
            set;
        }

        public Map<Id, Map<String, String>> userTerrs {
            get {
                if (userTerrs == null) {
                    userTerrs = new Map<Id, Map<String, String>>();
                }
                return userTerrs;
            }
            set;
        }

        public Map<Id, Map<String, String>> territories {
            get {
                if (territories == null) {
                    territories = new Map<Id, Map<String, String>>();
                }
                return territories;
            }
            set;
        }

        public List<AccountShare> accountShares {
            get {
                if (accountShares == null) {
                    accountShares = new List<AccountShare>();
                }
                return accountShares;
            }
            set;
        }

    }

    @TestVisible
    private static SentEmailsTerritoryWrapper checkUserAccountTerritories(Set<Id> users, Set<Id> accounts) {
        SentEmailsTerritoryWrapper wrapper = new SentEmailsTerritoryWrapper();
        if(Schema.sObjectType.Sent_Email_vod__c.fields.Territory_vod__c.isCreateable()){
            wrapper.setTerritory = true;
            Set<Id> territory2Ids = new Set<Id>();
            wrapper.userTerrs = TerritoryManagementFactory.getInstance().getUserTerritories(users, null);
            for(Map<String, String> ut : wrapper.userTerrs.values()){
                //TERRITORY_MAP in TerritoryManagement handles TerritoryId & Territory2Id mapping
                territory2Ids.add(ut.get('territoryId'));
            }
            wrapper.territories = TerritoryManagementFactory.getInstance().getTerritories(territory2Ids);
            wrapper.groups = new Map<Id, Group>([SELECT Id, relatedId FROM Group where relatedId IN : wrapper.territories.keySet()]);
            wrapper.accountShares = [SELECT UserOrGroupId, AccountId FROM AccountShare WHERE UserOrGroupId IN :wrapper.groups.keySet() AND AccountId IN :accounts];
        }
        return wrapper;
    }

    // The order of this Enum values is used in update process. Changes the order will affect existing updating logic
    @TestVisible
    private enum EmailStatus {
        Draft_vod, Scheduled_vod, Saved_vod, Pending_vod, Pending_Approval_vod, Approved_vod, Sent_vod,
        Failed_vod, Delivered_vod, Dropped_vod, Bounced_vod, Marked_Spam_vod, Unsubscribed_vod, Group_vod,
        Rejected_vod, Discarded_vod
    }

    @TestVisible
    private static String buildErrorMessage(String messageName, String defaultErrorText) {
        String errorText = defaultErrorText;
        for (Message_vod__c message : veevaMessages) {
            if (message.Name == messageName) {
                errorText = message.Text_vod__c;
                break;
            }
        }
        return errorText;
    }

    @TestVisible
    private static void handleReviewEmails(String status, Sent_Email_vod__c email, DateTime now, String userId) {
        if (status == 'Approved_vod') {
            //stamp Review_Datetime_vod__c and Reviewer_vod__c for Approved/Rejected emails
            if (email.Review_Datetime_vod__c == null) {
                email.Review_Datetime_vod__c = now;
            }
            if (email.Reviewer_vod__c == null) {
                email.Reviewer_vod__c = userId;
            }
            //if email has scheduled send datetime, make it scheduled status. Otherwise put in Saved status
            if (email.Scheduled_Send_Datetime_vod__c != null) {
                email.Status_vod__c = 'Scheduled_vod';
            } else {
                email.Status_vod__c = 'Saved_vod';
            }
        }

        if (status == 'Rejected_vod') {
            //stamp Review_Datetime_vod__c and Reviewer_vod__c for Approved/Rejected emails
            if (email.Review_Datetime_vod__c == null) {
                email.Review_Datetime_vod__c = now;
            }
            if (email.Reviewer_vod__c == null) {
                email.Reviewer_vod__c = userId;
            }
        }
    }

    @TestVisible
    private static void deleteSentEmails(List<Sent_Email_vod__c> emails) {
        Map<Id, Sent_Email_vod__c> toDelete = new Map<Id, Sent_Email_vod__c>();
        for (Sent_Email_vod__c email : emails) {
            toDelete.put(email.Id, email);
        }

        Database.DeleteResult[] res = Database.delete(new List<Id>(toDelete.keySet()), false);
        for (Database.DeleteResult dr : res) {
            if (!dr.isSuccess()) {
                Sent_Email_vod__c email = toDelete.get(dr.getId());
                String errorMsg = 'Failed to delete record.';
                if (!dr.getErrors().isEmpty()) {
                    Database.Error err = dr.getErrors()[0];
                    errorMsg = errorMsg + ' ' + err.getMessage();
                }
                email.Failure_Msg_vod__c = errorMsg;
            }
        }
    }

    @TestVisible
    private static boolean isIncorrectReviewProcess(String oldStatus, String newStatus) {
        return oldStatus == EmailStatus.Pending_Approval_vod.name() && (newStatus != EmailStatus.Approved_vod.name() && newStatus  != EmailStatus.Rejected_vod.name() && newStatus != EmailStatus.Pending_Approval_vod.name());
    }

    @TestVisible
    private static boolean isDraftEmail(Sent_Email_vod__c email) {
        return isDesiredStatus(email, EmailStatus.Draft_vod);
    }

    @TestVisible
    private static boolean isDiscardedEmail(Sent_Email_vod__c email) {
        return isDesiredStatus(email, EmailStatus.Discarded_vod);
    }

    @TestVisible
    private static boolean isScheduledEmail(Sent_Email_vod__c email) {
        return isDesiredStatus(email, EmailStatus.Scheduled_vod);
    }

    @TestVisible
    private static boolean isGroupEmail(Sent_Email_vod__c email) {
        return isDesiredStatus(email, EmailStatus.Group_vod);
    }

    @TestVisible
    private static boolean isPendingEmail(Sent_Email_vod__c email) {
        return isDesiredStatus(email, EmailStatus.Pending_vod);
    }

    @TestVisible
    private static boolean isSavedEmail(Sent_Email_vod__c email) {
        return isDesiredStatus(email, EmailStatus.Saved_vod);
    }

    @TestVisible
    private static boolean isApprovedEmail(Sent_Email_vod__c email) {
        return isDesiredStatus(email, EmailStatus.Approved_vod);
    }

    @TestVisible
    private static boolean isSentEmail(Sent_Email_vod__c email) {
        return isDesiredStatus(email, EmailStatus.Sent_vod);
    }

    @TestVisible
    private static boolean isDeliveredEmail(Sent_Email_vod__c email) {
        return isDesiredStatus(email, EmailStatus.Delivered_vod);
    }

    @TestVisible
    private static boolean isUpdateAllowed(Sent_Email_vod__c newVal, Sent_Email_vod__c oldVal) {
        Set<String> allowedSourceStates = NEW_STATUS_TO_ALLOWED_OLD.get(newVal.Status_vod__c);
        return allowedSourceStates == null || allowedSourceStates.contains(oldVal.Status_vod__c);
    }

    @TestVisible
    private static void handleSyncErrorForUpdates(List<Sent_Email_vod__c> emails, Map<Id, Sent_Email_vod__c> oldEmailsMap) {
        if (!emails.isEmpty()) {
            for (Sent_Email_vod__c email : emails) {
                Sent_Email_vod__c old = oldEmailsMap.get(email.Id);
                if (!isUpdateAllowed(email, old)) {
                    email.addError('Failed to update Sent_Email_vod__c object due to invalid value for status field. Old status is ' +
                    old.Status_vod__c + '. New status is ' + email.Status_vod__c + '.');
                }
            }
        }
    }

    @TestVisible
    private static void applyUpdateRules(Sent_Email_vod__c newVal, Sent_Email_vod__c oldVal) {
        String newStatus = newVal.Status_vod__c;
        String oldStatus = oldVal.Status_vod__c;
        EmailStatus newStatusE;
        EmailStatus oldStatusE;
        //go through and find the enum value for each status
        for(EmailStatus e: EmailStatus.values()){
            if(e.name() == newStatus){
                newStatusE = e;
            }
            if(e.name() == oldStatus){
                oldStatusE = e;
            }
        }
        //if this new status comes before the old status in our enum, keep the old status
        if(newStatusE.ordinal() < oldStatusE.ordinal()){
            newVal.Status_vod__c = oldStatus;
        }

        //clear message when status is set to Sent or Delivered
        if(newVal.Status_vod__c == EmailStatus.Sent_vod.name() || newVal.Status_vod__c == EmailStatus.Delivered_vod.name()) {
            newVal.Failure_Msg_vod__c = null;
        }

        //do not overwrite sent date if value already exists
        DateTime newSentDate = newVal.Email_Sent_Date_vod__c;
        Datetime oldSentDate = oldVal.Email_Sent_Date_vod__c;
        if (newSentDate == null && oldSentDate != null) {
            newVal.Email_Sent_Date_vod__c = oldSentDate;
        }

         //error message if changing status from Pending_Approval to anything besides Approved_vod or Rejected_vod
         if (isIncorrectReviewProcess(oldStatus, newStatus))  {
            newVal.Status_vod__c = EmailStatus.Pending_Approval_vod.name();
            newVal.addError(buildErrorMessage('APP_EMAIL_PENDING_STATUS_CHANGE_ERROR', 'Pending Approval emails can only be Approved or Rejected.'));
        }

        //error message if user trying to update rejected status
        if (oldStatus == EmailStatus.Rejected_vod.name() && oldStatus != newStatus) {
            newVal.Status_vod__c = EmailStatus.Rejected_vod.name();
            newVal.addError(buildErrorMessage('APP_EMAIL_REJECTED_STATUS_CHANGE_ERROR', 'You cannot change the status of a rejected email.'));
        }

        //do not overwrite original error message when setting 14 day limit error message
        if (String.isNotBlank(oldVal.Failure_Msg_vod__c) && MAIL_NOT_SENT_WITHIN_TWO_WEEKS_ERROR.equals(newVal.Failure_Msg_vod__c)) {
            String combinedErrorMessage = newVal.Failure_Msg_vod__c + ': ' + oldVal.Failure_Msg_vod__c;
            if (combinedErrorMessage.length() <= Schema.SObjectType.Sent_Email_vod__c.Fields.Failure_Msg_vod__c.length) {
                newVal.Failure_Msg_vod__c = combinedErrorMessage;
            }
        }
    }

    private static boolean isDesiredStatus(Sent_Email_vod__c email, EmailStatus status) {
        return email.Status_vod__c == status.name();
    }

    @TestVisible
    private static SentEmailsPropertyWrapper checkSentEmailsProperties(List<Sent_Email_vod__c> emails) {
        SentEmailsPropertyWrapper wrapper = new SentEmailsPropertyWrapper();
        VEEVA_ApprovedDocumentAccessChecker checker = new VEEVA_ApprovedDocumentAccessChecker();
        Set<Id> docIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> toUserIds = new Set<Id>(); // for EM, we can send email to Users
        for (Sent_Email_vod__c email : emails){
            docIds.add(email.Approved_Email_Template_vod__c);
            if (email.Account_vod__c != null) {
                accountIds.add(email.Account_vod__c);
            }
            if (email.User_vod__c != null) {
                toUserIds.add(email.User_vod__c);
            }
            wrapper.owners.add(email.OwnerId);
        }

        wrapper.approvedDocuments = checker.userHasAccessToApprovedDocuments(docIds);
        wrapper.toUsers = checker.userHasAccessToUsers(toUserIds);
        DescribeFieldResult entityRefFLS = Schema.Sent_Email_vod__c.SObjectType.getDescribe().fields.getMap().get('Entity_Reference_Id_vod__c').getDescribe();
        if (entityRefFLS != null && entityRefFLS.isUpdateable()) {
            //outside territory feature enabled, allow all accounts
            for (String accountId : accountIds) {
                wrapper.accounts.put(accountId, true);
            }
        } else {
            wrapper.accounts = checker.userHasAccessToAccounts(accountIds);
        }
        return wrapper;
    }

    @TestVisible
    private class SentEmailsPropertyWrapper {
        public Map<Id, Boolean> approvedDocuments {
            get {
                if (approvedDocuments == null) {
                    approvedDocuments = new Map<Id, Boolean>();
                }
                return approvedDocuments;
            }
            set;
        }

        public Map<Id, Boolean> accounts {
            get {
                if (accounts == null) {
                    accounts = new Map<Id, Boolean>();
                }
                return accounts;
            }
            set;
        }

        public Map<Id, Boolean> toUsers {
            get {
                if (toUsers == null) {
                    toUsers = new Map<Id, Boolean>();
                }
                return toUsers;
            }
            set;
        }

        public Set<Id> owners {
            get {
                if (owners == null) {
                    owners = new Set<Id>();
                }
                return owners;
            }
            set;
        }
    }
}