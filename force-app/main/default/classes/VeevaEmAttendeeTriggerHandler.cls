public without sharing class VeevaEmAttendeeTriggerHandler extends VeevaTriggerHandler {

    private List<EM_Attendee_vod__c> newAttendees = new List<EM_Attendee_vod__c>();
    private List<EM_Attendee_vod__c> oldAttendees = new List<EM_Attendee_vod__c>();
    private Map<ID, EM_Attendee_vod__c> newAttendeesMap = new Map<ID, EM_Attendee_vod__c>();
    private Map<ID, EM_Attendee_vod__c> oldAttendeesMap = new Map<ID, EM_Attendee_vod__c>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newAttendees = (List<EM_Attendee_vod__c>) triggerNew;
        this.oldAttendees = (List<EM_Attendee_vod__c>) triggerOld;
        this.newAttendeesMap = (Map<ID, EM_Attendee_vod__c>) triggerNewMap;
        this.oldAttendeesMap = (Map<ID, EM_Attendee_vod__c>) triggerOldMap;
    }
    
    protected override boolean doRecursionCheck() {
        return true;
    }
    
    protected override String sObjectType() {
        return 'EM_Attendee_vod__c';
    }

    protected override void beforeInsert() {
        vodEmAttendeeLock();
        vodEmAttendeeBeforeInsUpd();
    }
    
    protected override void beforeUpdate() {
        vodEmAttendeeLock();
        vodEmAttendeeBeforeInsUpd();
    }
    
    protected override void beforeDelete() {
        vodEmAttendeeLock();
        vodEmAttendeeBeforeDel();
    }
    
    protected override void afterInsert() {
        vodEmAttendeeAfterInsertUpdate();
        vodEmAttendeeAfterInsUpd();
        vodEmAttendeeCountRollupInsert();
        sendToEngage(newAttendeesMap.keySet(), false, false);
    }
    
    protected override void afterUpdate() {
        vodEmAttendeeAfterInsertUpdate();
        vodEmAttendeeAfterInsUpd();
        vodEmAttendeeCountRollupUpdate();
        sendToEngage(newAttendeesMap.keySet(), false, true);
    }
    
    protected override void afterDelete() {
        vodEmAttendeeCountRollupDelete();
        sendToEngage(oldAttendeesMap.keySet(), true, false);
    }

    private void vodEmAttendeeLock() {
        Set<String> associatedEvents = new Set<String>();
        Set<String> lockedEvents = new Set<String>();

        if (Trigger.isInsert || Trigger.isUpdate) {
            for (EM_Attendee_vod__c attendee : newAttendees) {
                if (attendee.Event_vod__c != null) {
                    associatedEvents.add(attendee.Event_vod__c);
                }
            }
        } else {
            for (EM_Attendee_vod__c attendee : oldAttendees) {
                if (attendee.Event_vod__c != null) {
                    associatedEvents.add(attendee.Event_vod__c);
                }
            }
        }

        for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                    FROM EM_Event_vod__c
                                    WHERE Id IN :associatedEvents ]) {
            if (VOD_Utils.isEventLocked(event)) {
                lockedEvents.add(event.Id);
            }
        }

        if (Trigger.isInsert || Trigger.isUpdate) {
            VOD_EVENT_UTILS.eventsWithOverrideLockTrue = new List<ID>();
            for (EM_Attendee_vod__c attendee : newAttendees) {
                if (attendee.Override_Lock_vod__c == true) {
                    attendee.Override_Lock_vod__c = false;
                    //If attendee's Override_Lock_vod__c is true, put its event into VOD_EVENT_UTILS.eventsWithOverrideLockTrue 
                    //which will be used to update event in trigger VOD_EM_ATTENDEE_COUNT_ROLLUP_UPDATE
                    if (attendee.Event_vod__c != null) {
                        VOD_EVENT_UTILS.eventsWithOverrideLockTrue.add(attendee.Event_vod__c);
                    }
                } else if (attendee.Event_vod__c != null && lockedEvents.contains(attendee.Event_vod__c)) {
                    attendee.addError('Event is locked');
                }
            }
        } else {
            for (EM_Attendee_vod__c attendee : oldAttendees) {
                if (attendee.Event_vod__c != null && lockedEvents.contains(attendee.Event_vod__c)) {
                    attendee.addError('Event is locked');
                }
            }
        }
    }

    private void vodEmAttendeeBeforeDel() {
        VOD_Utils.setTriggerEmAttendee(true);
        if(!VOD_Utils.isTriggerEventAttendee()) {
            for (Event_Attendee_vod__c[] deleteAttStubs :[SELECT Id FROM Event_Attendee_vod__c 
                WHERE EM_Attendee_vod__c IN :oldAttendeesMap.keySet()]) {
                try {
                    delete deleteAttStubs;
                } catch (System.DmlException e) {
                    Integer numErrors = e.getNumDml();
                    String error = '';
                    for (Integer i = 0; i < numErrors; i++) {
                        Id thisId = e.getDmlId(i);
                        if (thisId != null)  {
                            error += e.getDmlMessage(i) +'\n';
                        }
                    }
                    
                    for (EM_Attendee_vod__c errorRec : oldAttendees) {
                        errorRec.Id.addError(error);    
                    }   
                    
                }
            }         
        }
    }

    private void vodEmAttendeeCountRollupDelete() {
        Set<ID> eventIds = new Set<ID>();
        for(EM_Attendee_vod__c attendee: oldAttendees) {
            if(attendee.Event_vod__c != null) {
                eventIds.add(attendee.Event_vod__c);
            }
        }
        
        //CRM-190304 The size of eventIds should be larger than 0
        if (eventIds.size() > 0) {
            List<EM_Event_vod__c> eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);
            
            if(eventsToUpdate.size() > 0) {
                update eventsToUpdate;
            }        
        }   
    }
    
    private void vodEmAttendeeBeforeInsUpd() {
        Set<ID> contactIds = new Set<ID>();
        Set<ID> userIds = new Set<ID>();
        Set<ID> accountIds = new Set<ID>();
        Set<ID> walkInIds = new Set<ID>();
        Set<ID> childAccountIds = new Set<ID>();
        for(EM_Attendee_vod__c attendee: newAttendees) {
            contactIds.add(attendee.Contact_vod__c);
            userIds.add(attendee.User_vod__c);
            stampCrossReferenceFields(attendee);
            
            if (attendee.Walk_In_Reference_ID_vod__c != null //not null
                && VOD_Utils.matchesSfdcId(attendee.Walk_In_Reference_ID_vod__c) //matches SFDC Id pattern regex
                && attendee.Walk_In_Reference_ID_vod__c.startsWith(Schema.SObjectType.Account.getKeyPrefix())) { //matches Account key prefix
                walkInIds.add(attendee.Walk_In_Reference_ID_vod__c);
            }
            accountIds.add(attendee.Account_vod__c);
            childAccountIds.add(attendee.Child_Account_vod__c);
        }
        
        Map<String, List<String>> emailMap = new Map<String, List<String>>();		          
        String[] types = new String[]{'Account','Address_vod__c', 'User'};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        for(Schema.DescribeSobjectResult res : results) {
            List<String> emailFields = new List<String>();
            SObjectType currType = res.getSObjectType();
            Map<String,Schema.SObjectField> mfields = currType.getDescribe().fields.getMap();
            for(Schema.SObjectField field: mfields.values()) {
                if(field.getDescribe().getType().equals(Schema.DisplayType.EMAIL)) {
                    emailFields.add(field.getDescribe().getName());
                }
            }
            emailMap.put(res.getName(), emailFields);
        }
        
        Map<Id, Child_Account_vod__c> childAccounts = new Map<Id, Child_Account_vod__c>();
        for (Child_Account_vod__c ca : [SELECT Id, Child_Account_vod__c, Parent_Account_vod__r.Id, Parent_Child_Name_vod__c, Parent_Account_vod__r.Name FROM Child_Account_vod__c WHERE Id in :childAccountIds]) {
            childAccounts.put(ca.Id, ca); //create child account map
            if (!accountIds.contains(ca.Child_Account_vod__c)) {
                accountIds.add(ca.Child_Account_vod__c); //add child account id's into the set
            }
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>([Select Id, FirstName, LastName, Name FROM Contact WHERE Id in :contactIds]);
        Map<Id, User> users = new Map<Id, User>([Select Id, FirstName, LastName, Name FROM User WHERE Id in :userIds]);
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Formatted_Name_vod__c, FirstName, LastName, PersonTitle, Credentials_vod__c, Name, Furigana_vod__c FROM Account WHERE Id in :accountIds]);
        Map<Id, Account> existingWalkInAccounts = new Map<Id, Account>([SELECT Id FROM Account WHERE Id in :walkInIds]);

        Events_Management_Settings_vod__c emSetting = Events_Management_Settings_vod__c.getOrgDefaults();
        Integer autoMatchMode = 1;

        if(emSetting.Attendee_Automatch_Mode_vod__c != null) {
            autoMatchMode = emSetting.Attendee_Automatch_Mode_vod__c.intValue();
        }

        EmReconciliationAutomatch autoMatchHelper = new EmReconciliationAutomatch(emailMap);
        if (Trigger.isInsert && autoMatchMode == 1) {
            autoMatchHelper.findMatches(newAttendees);
        }

        for (EM_Attendee_vod__c emAtt : newAttendees) {
            String lastName = '';
            String firstName = '';
            if (Trigger.isInsert && autoMatchMode == 1 && (emAtt.Walk_In_Status_vod__c == 'Needs_Reconciliation_vod' || emAtt.Online_Registration_Status_vod__c == 'Needs_Reconciliation_vod')) {
                if (emAtt.Last_Name_vod__c == null) {
                    continue;
                }
                SObject match = autoMatchHelper.findExactMatch(emAtt);

                if (match == null) {
                    // either no match or both account and user match found
                    if(emAtt.First_Name_vod__c != null) {
                        firstName = emAtt.First_Name_vod__c;
                    }
                    if(emAtt.Last_Name_vod__c != null) {
                        lastName = emAtt.Last_Name_vod__c;
                    }
                } else if (match instanceof Account) {
                    existingWalkInAccounts.put((ID) match.get('Id'), (Account) match);
                }

                if(match != null) {
                    if(match.get('LastName') != null) {
                        lastName = (String)match.get('LastName');
                    }
                    if(match.get('firstName') != null) {
                        firstName = (String)match.get('FirstName');
                    }
                }
            } else {
                if(emAtt.First_Name_vod__c != null) {
                    firstName = emAtt.First_Name_vod__c;
                }
                if(emAtt.Last_Name_vod__c != null) {
                    lastName = emAtt.Last_Name_vod__c;
                }
            }

            if(emAtt.Stub_Mobile_Id_vod__c == null) {
                emAtt.Stub_Mobile_Id_vod__c = GuidUtil.NewGuid();
            }

            if((emAtt.Walk_In_Status_vod__c == 'Reconciled_To_Existing_Account_vod' || emAtt.Walk_In_Status_vod__c == 'Reconciled_To_New_Account_vod' ||
                emAtt.Online_Registration_Status_vod__c == 'Reconciled_To_Existing_Account_vod' || emAtt.Online_Registration_Status_vod__c == 'Reconciled_To_New_Account_vod')
                && emAtt.Walk_In_Reference_ID_vod__c != null) {
                if (existingWalkInAccounts.get(emAtt.Walk_In_Reference_ID_vod__c) != null) {
                    //populate account lookup using walk in ref id, the account must be valid hence checking existingWalkInAccounts
                    emAtt.Account_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
                }
            } else if((emAtt.Walk_In_Status_vod__c == 'Reconciled_To_Existing_User_vod' || emAtt.Online_Registration_Status_vod__c == 'Reconciled_To_Existing_User_vod')  && emAtt.Walk_In_Reference_Id_vod__c != null) {
                emAtt.User_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
            } else if (emAtt.Walk_In_Status_vod__c == 'Needs_Reconciliation_vod' && (emAtt.Walk_In_Reference_Id_vod__c == null || emAtt.Walk_In_Reference_Id_vod__c == '')) {
                emAtt.User_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
                emAtt.Account_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
            }

            if (String.isNotEmpty(emAtt.Walk_In_Reference_ID_vod__c)) { //always clear this field
                emAtt.Walk_In_Reference_ID_vod__c = null;
            }

            String name = '';
            if(String.isNotBlank(lastName) || String.isNotBlank(firstName)) {
                name = lastName + ', ' + firstName;
            }

            if(emAtt.Child_Account_vod__c != null) {
                Child_Account_vod__c childAccount = childAccounts.get(emAtt.Child_Account_vod__c);
                if(childAccount != null) {
                    Account child = accounts.get(childAccount.Child_Account_vod__c);
                    emAtt.Child_Account_Id_vod__c = emAtt.Child_Account_vod__c;
                    if (child != null) {
                        if (emAtt.Account_vod__c == null) {
                            emAtt.Account_vod__c = child.Id;
                        }
                        name = childAccount.Parent_Child_Name_vod__c;
                        emAtt.First_Name_vod__c = child.FirstName;
                        emAtt.Last_Name_vod__c = child.LastName;
                        if(child.Furigana_vod__c != null) {
                            emAtt.Furigana_vod__c = child.Furigana_vod__c;
                        }
                    }
                    Account parentAccount = (Account)childAccount.getSObject('Parent_Account_vod__r');
                    if (parentAccount != null) {
                        emAtt.Location_Name_vod__c = parentAccount.Name;
                        emAtt.Location_Id_vod__c = parentAccount.Id;
                        emAtt.Location_vod__c =  emAtt.Location_Id_vod__c;
                    }
                }
            }

            if(emAtt.Account_vod__c != null && emAtt.Child_Account_vod__c == null) { //Child Account field must be null
                Account account = accounts.get(emAtt.Account_vod__c);
                if(account != null) {
                    if(account.Formatted_Name_vod__c != null) {
                    name = account.Formatted_Name_vod__c;
                    } else if(account.FirstName != null && account.LastName != null) {
                        name = account.LastName + ', ' + account.FirstName;
                    } else {
                        name = account.Name;
                    }
                    if (Trigger.isInsert) {
                        emAtt.Title_vod__c = account.PersonTitle;
                        emAtt.Credentials_vod__c = account.Credentials_vod__c;
                    }
                    
                    if (emAtt.Walk_In_Status_vod__c == null && emAtt.Online_Registration_Status_vod__c == null) {
                        if(account.Furigana_vod__c != null) {
                            emAtt.Furigana_vod__c = account.Furigana_vod__c;
                        }
                        emAtt.First_Name_vod__c = account.FirstName;
                        emAtt.Last_Name_vod__c = account.LastName;
                    }
                }
            }
            
            if(emAtt.Contact_vod__c != null) {
                Contact contact = contacts.get(emAtt.Contact_vod__c);
                if(contact != null) {
                    if(contact.FirstName != null && contact.LastName != null) {
                    name = contact.LastName + ', ' + contact.FirstName;
                    } else {
                        name = contact.Name;
                    }
                    if (emAtt.Walk_In_Status_vod__c == null && emAtt.Online_Registration_Status_vod__c == null) {
                        emAtt.First_Name_vod__c = contact.FirstName;
                        emAtt.Last_Name_vod__c = contact.LastName;
                    }
                }        
            }            
            
            if(emAtt.User_vod__c != null) {
                User user = users.get(emAtt.User_vod__c);
                if(user != null) {
                    if(user.FirstName != null && user.LastName != null) {
                    name = user.LastName + ', ' + user.FirstName;
                    } else {
                        name = user.Name;
                    }
                    if (emAtt.Walk_In_Status_vod__c == null && emAtt.Online_Registration_Status_vod__c == null) {
                        emAtt.First_Name_vod__c = user.FirstName;
                        emAtt.Last_Name_vod__c = user.LastName;
                    }
                }
            }

            Integer lastNameMaxLen = SObjectType.EM_Attendee_vod__c.Fields.Last_Name_vod__c.Length;
            if (emAtt.Last_Name_vod__c != null && emAtt.Last_Name_vod__c.length() > lastNameMaxLen) {
                emAtt.Last_Name_vod__c = emAtt.Last_Name_vod__c.substring(0, lastNameMaxLen);
            }

            if(name != null) {
                Integer nameMaxLen = SObjectType.EM_Attendee_vod__c.Fields.Attendee_Name_vod__c.Length;
                if (name.length() > nameMaxLen) {
                    name = name.substring(0, nameMaxLen);
                }
                emAtt.Attendee_Name_vod__c = name;
            }
        }
    }

    /**
     * Stamps Lookup Fields in System User mode to avoid cross reference error
     */
    private void stampCrossReferenceFields(EM_Attendee_vod__c attendee) {
        EM_Attendee_vod__c oldAttendee = oldAttendeesMap.get(attendee.Id);
        if (attendee.Entity_Reference_Id_vod__c != null) {
            attendee.Account_vod__c = attendee.Entity_Reference_Id_vod__c;
            attendee.Entity_Reference_Id_vod__c = null;
        }

        if (attendee.Location_Id_vod__c != null
            && (attendee.Location_Id_vod__c != oldAttendeesMap.get(attendee.Id)?.Location_Id_vod__c)
        ) {
            attendee.Location_vod__c = attendee.Location_Id_vod__c;
        }

        if (attendee.Child_Account_Id_vod__c != null
            && (attendee.Child_Account_Id_vod__c != oldAttendeesMap.get(attendee.Id)?.Child_Account_Id_vod__c)
        ) {
            attendee.Child_Account_vod__c = attendee.Child_Account_Id_vod__c;
        }
    }

    private void vodEmAttendeeAfterInsertUpdate() {
        if (VOD_Utils.hasObject('EM_Attendee_vod__Share')) {
            SObjectType attendeeShareType = Schema.getGlobalDescribe().get('EM_Attendee_vod__Share');
            List<SObject> newShares = new List<SObject>();
            Set<Id> eventIds = new Set<Id>();
            for (EM_Attendee_vod__c attendee : newAttendees) {
                if(attendee.Event_vod__c != null) {
                    eventIds.add(attendee.Event_vod__c);
                }
            }

            Set<String> groupNameSet = new Set<String>();
            List<EM_Event_Team_Member_vod__c> members = [SELECT Id, Event_vod__c, Team_Member_vod__c, Group_Name_vod__c FROM EM_Event_Team_Member_vod__c WHERE Event_vod__c IN : eventIds];
            for(EM_Event_Team_Member_vod__c member : members) {
                if(member.Group_Name_vod__c != null) {
                    groupNameSet.add(member.Group_Name_vod__c);
                }
            }

            Map<String, Id> groupNameToGroupId = new Map<String, Id>();
            for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNameSet]) {
                groupNameToGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
            }


            Map<Id, Set<Id>> eventToMembers = new Map<Id, Set<Id>>();
            for (EM_Event_Team_Member_vod__c member : members) {
                if (eventToMembers.get(member.Event_vod__c) == null) {
                    eventToMembers.put(member.Event_vod__c, new Set<Id>());
                }
                if(member.Team_Member_vod__c != null) {
                    eventToMembers.get(member.Event_vod__c).add(member.Team_Member_vod__c);
                } else if(member.Group_Name_vod__c != null) {
                    Id groupUserId = groupNameToGroupId.get(member.Group_Name_vod__c);
                    if(groupUserId != null) {
                        eventToMembers.get(member.Event_vod__c).add(groupUserId);
                    }
                }
            }

            if (Trigger.isUpdate) {
                Map<Id, EM_Attendee_vod__c> attendeeMap = new Map<Id, EM_Attendee_vod__c>();
                for (EM_Attendee_vod__c attendee : newAttendees) {
                    if (attendee.Event_vod__c != oldAttendeesMap.get(attendee.Id).Event_vod__c) {
                        attendeeMap.put(attendee.Id, attendee);
                    }
                }
                if (!attendeeMap.isEmpty()) {
                    Set<Id> attendeeSet = attendeeMap.keySet();
                    List<SObject> attendeeShares = Database.query('SELECT Id FROM EM_Attendee_vod__Share WHERE ParentId IN : attendeeSet');
                    List<Database.DeleteResult> results = Database.delete(attendeeShares, false);
                    for (Database.DeleteResult result: results) {
                        if (!result.isSuccess()) {
                        system.debug('Insert error: ' + result.getErrors()[0]);
                    }
                    }
                }

                for (Id attendeeId : attendeeMap.keySet()) {
                    EM_Attendee_vod__c attendee = attendeeMap.get(attendeeId);
                    if (eventToMembers.get(attendee.Event_vod__c) != null) {
                        for (Id memberId : eventToMembers.get(attendee.Event_vod__c)) {
                            SObject attendeeShare = attendeeShareType.newSObject();
                            attendeeShare.put('ParentId', attendeeId);
                            attendeeShare.put('UserOrGroupId', memberId);
                            attendeeShare.put('AccessLevel', 'edit');
                            attendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                            newShares.add(attendeeShare);
                        }
                    }
                }
            } else {
                for (EM_Attendee_vod__c attendee : newAttendees) {
                    if (eventToMembers.get(attendee.Event_vod__c) != null) {
                        for (Id memberId : eventToMembers.get(attendee.Event_vod__c)) {
                            SObject attendeeShare = attendeeShareType.newSObject();
                            attendeeShare.put('ParentId', attendee.Id);
                            attendeeShare.put('UserOrGroupId', memberId);
                            attendeeShare.put('AccessLevel', 'edit');
                            attendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                            newShares.add(attendeeShare);
                        }
                    }
                }
            }
            List<Database.SaveResult> results = Database.insert(newShares, false);
            for (Database.SaveResult result: results) {
                if (!result.isSuccess()) {
                    system.debug('Insert error: ' + result.getErrors()[0]);
                }
            }
        }
    }

    private void vodEmAttendeeAfterInsUpd() {
        if (!VOD_Utils.isTriggerEventAttendee()) {
            Map<String, String> statusMap = new Map<String, String>();
            statusMap.put('Invited_vod', 'Invited');
            statusMap.put('Accepted_vod', 'Accepted');
            statusMap.put('Rejected_vod', 'Rejected');
            statusMap.put('Attended_vod', 'Attended');

            Set<DescribeFieldResult> emFields = new Set<DescribeFieldResult>();
            Set<DescribeFieldResult> meFields = new Set<DescribeFieldResult>();
            String[] types = new String[]{'Event_Attendee_vod__c','EM_Attendee_vod__c'};
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);

            for(Schema.DescribeSobjectResult res : results) {
                Map<String,Schema.SObjectField> mfields = res.fields.getMap();
                for(Schema.SObjectField field: mfields.values()) {
                    DescribeFieldResult fDescribe = field.getDescribe();
                    if(fDescribe.isCustom() && !fDescribe.getName().endsWith('vod__c')) {
                        if(res.getName() == 'Event_Attendee_vod__c') {
                            meFields.add(fDescribe);
                        } else if(res.getName() == 'EM_Attendee_vod__c') {
                            emFields.add(fDescribe);
                        }
                    }
                }
            }
            Set<String> mappedFields = new Set<String>();
            for(DescribeFieldResult emDescribe: emFields) {
                for(DescribeFieldResult meDescribe: meFields) {
                    if(emDescribe.getName() == meDescribe.getName() && emDescribe.getType() == meDescribe.getType() &&
                    !(emDescribe.isCalculated() || meDescribe.isCalculated())) {
                        mappedFields.add(meDescribe.getName());
                        break;
                    }
                }
            }

            VOD_Utils.setTriggerEmAttendee(true);
            List<String> emEventIds = new List<String>();
            Map<String, EM_Attendee_vod__c> emAttMap = new Map<String, EM_Attendee_vod__c>();
            for (EM_Attendee_vod__c emAtt : newAttendees) {
                            if(emAtt.Event_vod__c != null) {
                        emEventIds.add(emAtt.Event_vod__c);
                            }
                emAttMap.put(emAtt.Id, emAtt);
            }


            Map<String,String> emEventsToMedEvents = new Map<String,String>();
            for (Medical_Event_vod__c eventStub : [SELECT Id, EM_Event_vod__c
                                                FROM Medical_Event_vod__c
                                                WHERE EM_Event_vod__c in :emEventIds]) {
                emEventsToMedEvents.put(eventStub.EM_Event_vod__c, eventStub.Id);
            }

            Map<String,Schema.RecordTypeInfo> eaRTMap = Event_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

            List<Event_Attendee_vod__c> attStubs = new List<Event_Attendee_vod__c>();
            if (Trigger.isInsert) {
                Map<ID,Schema.RecordTypeInfo> emRTMap = EM_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosById();
                for (EM_Attendee_vod__c emAtt : newAttendees) {
                    Event_Attendee_vod__c newStub = new Event_Attendee_vod__c(
                        Entity_Reference_Id_vod__c = emAtt.Entity_Reference_Id_vod__c,
                        Account_vod__c = emAtt.Account_vod__c,
                        Contact_vod__c = emAtt.Contact_vod__c,
                        User_vod__c = emAtt.User_vod__c,
                        Child_Account_Id_vod__c = emAtt.Child_Account_Id_vod__c,
                        Child_Account_vod__c = emAtt.Child_Account_vod__c,
                        Location_Id_vod__c = emAtt.Location_Id_vod__c,
                        Location_vod__c = emAtt.Location_vod__c,
                        Location_Name_vod__c = emAtt.Location_Name_vod__c,
                        Attendee_vod__c = emAtt.Attendee_Name_vod__c,
                        EM_Attendee_vod__c = emAtt.Id,
                        Meal_Opt_In_vod__c = emAtt.Meal_Opt_In_vod__c,
                        Mobile_Id_vod__c = emAtt.Stub_Mobile_Id_vod__c,
                        Medical_Event_vod__c = emEventsToMedEvents.get(emAtt.Event_vod__c),
                        Signature_vod__c = emAtt.Signature_vod__c,
                        Signature_Datetime_vod__c = emAtt.Signature_Datetime_vod__c,
                        Walk_In_Status_vod__c = emAtt.Walk_In_Status_vod__c,
                        Address_Line_1_vod__c = emAtt.Address_Line_1_vod__c,
                        Address_Line_2_vod__c = emAtt.Address_Line_2_vod__c,
                        City_vod__c = emAtt.City_vod__c,
                        Zip_vod__c = emAtt.Zip_vod__c,
                        Phone_vod__c = emAtt.Phone_vod__c,
                        Email_vod__c = emAtt.Email_vod__c,
                        Prescriber_vod__c = emAtt.Prescriber_vod__c,
                        First_Name_vod__c = emAtt.First_Name_vod__c,
                        Last_Name_vod__c = emAtt.Last_Name_vod__c,
                        Organization_vod__c = emAtt.Organization_vod__c,
                        Override_Lock_vod__c = true,
                        Walk_In_Type_vod__c = emAtt.Walk_In_Type_vod__c
                    );
                    RecordTypeInfo eaInfo;
                    if (emAtt.RecordTypeId != null && emRTMap.get(emAtt.RecordTypeId) != null) {
                        eaInfo = eaRTMap.get(emRTMap.get(emAtt.RecordTypeId).getDeveloperName());
                    }
                    
                    if(eaInfo != null && eaInfo.isAvailable()) {
                        newStub.RecordTypeId = eaInfo.getRecordTypeId();
                    }

                    if (statusMap.get(emAtt.Status_vod__c) != null) {
                        newStub.Status_vod__c = statusMap.get(emAtt.Status_vod__c);
                    } else {
                        newStub.Status_vod__c = emAtt.Status_vod__c;
                    }
                    for(String mfield: mappedFields) {
                        newStub.put(mfield, emAtt.get(mfield));
                    }
                    
                    attStubs.add(newStub);
                }
                if(attStubs.size() > 0) {
                    Database.Saveresult[] eventAttendeeResults = Database.insert(attStubs, false);
                    for (Integer i = 0; i < eventAttendeeResults.size(); i++) {
                    	Database.Saveresult saveResult = eventAttendeeResults[i];
                    	if(!saveResult.isSuccess()){
                            newAttendees.get(i).addError(saveResult.getErrors()[0].getMessage());
            			}
                    }
                }

                Map<String, String> idToStubMap = new Map<String,String>();

                for(Event_Attendee_vod__c stub: attStubs) {
                    for (EM_Attendee_vod__c emAtt : newAttendees) {
                        if(stub.EM_Attendee_vod__c == emAtt.Id) {
                            idtoStubMap.put(emAtt.Id, stub.Id);
                        }
                    }
                }

                VOD_EVENT_UTILS.updateAttendeeStub(idToStubMap);

            } else if (Trigger.isUpdate) {
                Set<Id> changedAttendeeIds = new Set<Id>();

                Set<String> changeFields = new Set<String>();
                changeFields.addAll(mappedFields);
                changeFields.add('Entity_Reference_Id_vod__c');
                changeFields.add('Account_vod__c');
                changeFields.add('Location_Id_vod__c');
                changeFields.add('Location_vod__c');
                changeFields.add('Child_Account_Id_vod__c');
                changeFields.add('Child_Account_vod__c');
                changeFields.add('Contact_vod__c');
                changeFields.add('Location_Name_vod__c');
                changeFields.add('Attendee_Name_vod__c');
                changeFields.add('Meal_Opt_In_vod__c');
                changeFields.add('Signature_vod__c');
                changeFields.add('Signature_Datetime_vod__c');
                changeFields.add('Walk_In_Status_vod__c');
                changeFields.add('Address_Line_1_vod__c');
                changeFields.add('Address_Line_2_vod__c');
                changeFields.add('City_vod__c');
                changeFields.add('Phone_vod__c');
                changeFields.add('Zip_vod__c');
                changeFields.add('Email_vod__c');
                changeFields.add('Prescriber_vod__c');
                changeFields.add('First_Name_vod__c');
                changeFields.add('Last_Name_vod__c');
                changeFields.add('Organization_vod__c');
                changeFields.add('RecordTypeId');
                changeFields.add('Status_vod__c');
                changeFields.add('Walk_In_Type_vod__c');

                for(EM_Attendee_vod__c oldAtt: oldAttendees) {
                    EM_Attendee_vod__c newAtt = newAttendeesMap.get(oldAtt.Id);
                    for(String field: changeFields){
                        if(newAtt.get(field) != oldAtt.get(field)) {
                            changedAttendeeIds.add(newAtt.Id);
                            break;
                        }
                    }
                }

                if(changedAttendeeIds.size() > 0) {
                    for (Event_Attendee_vod__c attStub : [SELECT Account_vod__c, Contact_vod__c, User_vod__c, Child_Account_vod__c, Attendee_vod__c,
                                                    Status_vod__c, EM_Attendee_vod__c, Meal_Opt_In_vod__c, Signature_vod__c,
                                                    Signature_Datetime_vod__c, Walk_In_Status_vod__c, Address_Line_1_vod__c,
                                                    Address_Line_2_vod__c, City_vod__c, Zip_vod__c, Phone_vod__c, Email_vod__c,
                                                    Prescriber_vod__c, First_Name_vod__c, Last_Name_vod__c, Entity_Reference_Id_vod__c,
                                                    Walk_In_Type_vod__c, Location_vod__c, Location_Id_vod__c, Child_Account_Id_vod__c, Location_Name_vod__c
                                                    FROM Event_Attendee_vod__c
                                                    WHERE EM_Attendee_vod__c IN :changedAttendeeIds]) {
                        EM_Attendee_vod__c emAtt = emAttMap.get(attStub.EM_Attendee_vod__c);
                        attStub.Entity_Reference_Id_vod__c = emAtt.Entity_Reference_Id_vod__c;
                        attStub.Account_vod__c = emAtt.Account_vod__c;
                        attStub.Contact_vod__c = emAtt.Contact_vod__c;
                        attStub.User_vod__c = emAtt.User_vod__c;
                        attStub.Location_vod__c = emAtt.Location_vod__c;
                        attStub.Location_Id_vod__c = emAtt.Location_Id_vod__c;
                        attStub.Location_Name_vod__c = emAtt.Location_Name_vod__c;
                        attStub.Child_Account_Id_vod__c = emAtt.Child_Account_Id_vod__c;
                        attStub.Child_Account_vod__c = emAtt.Child_Account_vod__c;
                        attStub.Attendee_vod__c = emAtt.Attendee_Name_vod__c;
                        attStub.EM_Attendee_vod__c = emAtt.Id;
                        attStub.Meal_Opt_In_vod__c = emAtt.Meal_Opt_In_vod__c;
                        attStub.Signature_vod__c = emAtt.Signature_vod__c;
                        attStub.Signature_Datetime_vod__c = emAtt.Signature_Datetime_vod__c;
                        attStub.Walk_In_Status_vod__c = emAtt.Walk_In_status_vod__c;
                        attStub.Address_Line_1_vod__c = emAtt.Address_Line_1_vod__c;
                        attStub.Address_Line_2_vod__c = emAtt.Address_Line_2_vod__c;
                        attStub.City_vod__c = emAtt.City_vod__c;
                        attStub.Phone_vod__c = emAtt.Phone_vod__c;
                        attStub.Zip_vod__c = emAtt.Zip_vod__c;
                        attStub.Email_vod__c = emAtt.Email_vod__c;
                        attStub.Prescriber_vod__c = emAtt.Prescriber_vod__c;
                        attStub.First_Name_vod__c = emAtt.First_Name_vod__c;
                        attStub.Last_Name_vod__c = emAtt.Last_Name_vod__c;
                        attStub.Organization_vod__c = emAtt.Organization_vod__c;
                        attStub.Override_Lock_vod__c = true;
                        attStub.Walk_In_Type_vod__c = emAtt.Walk_In_Type_vod__c;
                        if (emAtt.RecordType != null && eaRTMap.get(emAtt.RecordType.DeveloperName) != null) {
                            attStub.RecordTypeId = eaRTMap.get(emAtt.RecordType.DeveloperName).getRecordTypeId();
                        }
                        if (statusMap.get(emAtt.Status_vod__c) != null) {
                            attStub.Status_vod__c = statusMap.get(emAtt.Status_vod__c);
                        } else {
                            attStub.Status_vod__c = emAtt.Status_vod__c;
                        }
                        for(String mfield: mappedFields) {
                            attStub.put(mfield, emAtt.get(mfield));
                        }
                        attStubs.add(attStub);
                    }
                }

                if(attStubs.size() > 0) {
                    update attStubs;
                }
            }
        }
    }

    private void vodEmAttendeeCountRollupInsert() {
        Set<ID> eventIds = new Set<ID>();
        for(EM_Attendee_vod__c attendee: newAttendees) {
            if(attendee.Event_vod__c != null) {
                eventIds.add(attendee.Event_vod__c);
            }
        }

        List<EM_Event_vod__c> eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);

        if(eventsToUpdate.size() > 0) {
            update eventsToUpdate;
        }
    }

    private void vodEmAttendeeCountRollupUpdate() {
        Set<ID> eventIds = new Set<ID>();
        for(EM_Attendee_vod__c attendee: newAttendees) {
            EM_Attendee_vod__C oldAttendee = oldAttendeesMap.get(attendee.Id);
            if(attendee.Meal_Opt_In_vod__c != oldAttendee.Meal_Opt_In_vod__c || attendee.Status_vod__c != oldAttendee.Status_vod__c) {
                            if(attendee.Event_vod__c != null) {
                                    eventIds.add(attendee.Event_vod__c);
                            }
            }
        }

        if(eventIds.size() > 0) {
            List<EM_Event_vod__c> eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);
            for(EM_Event_vod__c event: eventsToUpdate){
                if(VOD_EVENT_UTILS.eventsWithOverrideLockTrue != null && VOD_EVENT_UTILS.eventsWithOverrideLockTrue.size() > 0 && VOD_EVENT_UTILS.eventsWithOverrideLockTrue.contains(event.Id)){
                    event.Override_Lock_vod__c = true;
                }
            }
            if(VOD_EVENT_UTILS.eventsWithOverrideLockTrue != null){
            VOD_EVENT_UTILS.eventsWithOverrideLockTrue.clear(); 
            }
            update eventsToUpdate;
        }
    }

    private void sendToEngage(Set<ID> attendeeIds, boolean isDelete, boolean isUpdate) {
        if (attendeeIds.size() > 0 && !(System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled())) {
            VeevaEngageAttendeeService engageAttendeeService = new VeevaEngageAttendeeService(attendeeIds, isDelete, isUpdate);
            System.enqueueJob(engageAttendeeService);
        }
    }
}