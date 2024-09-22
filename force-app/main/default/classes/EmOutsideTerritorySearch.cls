public without sharing class EmOutsideTerritorySearch {
    
    private static final Integer USER_RECORD_ACCESS_LIMIT = 200;

    @AuraEnabled
    public static List<OutsideSearchResult> getAttendees(String termString, List<String> fields, String viewId, String orderBy, String orderDirection, Integer qLimit, Integer offset, EmAttendeeSelection.EmOutsideTerritoryRule oot, boolean includeAddress, boolean useCustomFieldFormatting) {
        List<OutsideSearchResult> results = new List<OutsideSearchResult>();
        EmAttendeeSelection.Filters filters = createFiltersFromRule(oot);
        List<EmAttendeeSelection.AttendeeResult> accounts = EmAttendeeSelection.getAttendees(termString, fields, viewId,  new List<String>(), filters, orderBy,  orderDirection, qLimit, offset, includeAddress, useCustomFieldFormatting);
        Map<Id, EmAttendeeSelection.AttendeeResult> accountMap = new Map<Id, EmAttendeeSelection.AttendeeResult>();
        List<Id> orderedAccountIds = new List<Id>();
        for (EmAttendeeSelection.AttendeeResult account : accounts) {
            Id accountId = (Id) account.record.get('Id');
            orderedAccountIds.add(accountId);
            accountMap.put(accountId, account);
        }
        return stampOutsideAccounts(orderedAccountIds, accountMap);
    }

    private static EmAttendeeSelection.Filters createFiltersFromRule(EmAttendeeSelection.EmOutsideTerritoryRule oot) {
        return new EmAttendeeSelection.Filters()
            .setOutOfTerritoryRecordTypes(oot.recordTypeDeveloperNames)
            .setOutOfTerritoryCountries(oot.countryCodes)
            .setRecordTypePredicateTemplate(EmAttendeeSelection.RECORD_TYPE_PREDICATE_TEMPLATE)
            .setCountryPredicateTemplate(EmAttendeeSelection.COUNTRY_PREDICATE_TEMPLATE);
    }

    @AuraEnabled
    public static Integer getQueryCount(String termString, List<String> fields, String viewId, String orderBy, String orderDirection, Integer qLimit, Integer offset, EmAttendeeSelection.EmOutsideTerritoryRule oot) {
        List<OutsideSearchResult> results = new List<OutsideSearchResult>();
        EmAttendeeSelection.Filters filters = new EmAttendeeSelection.Filters()
            .setOutOfTerritoryRecordTypes(oot.recordTypeDeveloperNames)
            .setOutOfTerritoryCountries(oot.countryCodes)
            .setRecordTypePredicateTemplate(EmAttendeeSelection.RECORD_TYPE_PREDICATE_TEMPLATE)
            .setCountryPredicateTemplate(EmAttendeeSelection.COUNTRY_PREDICATE_TEMPLATE);
        return EmAttendeeSelection.getQueryCount(viewId, new List<String>(), filters);
    }

    @AuraEnabled
    public static List<ChildAccountOutsideSearchResult> getChildAccounts(String termString, List<String> fields, String viewId, String orderBy, String orderDirection, Integer qLimit, Integer offset, EmAttendeeSelection.EmOutsideTerritoryRule oot, boolean useCustomFieldFormatting) {
        EmAttendeeSelection.Filters filters = new EmAttendeeSelection.Filters()
            .setOutOfTerritoryRecordTypes(oot.recordTypeDeveloperNames)
            .setOutOfTerritoryCountries(oot.countryCodes)
            .setRecordTypePredicateTemplate(VeevaChildAccountAttendeeSelection.RECORD_TYPE_PREDICATE_TEMPLATE)
            .setCountryPredicateTemplate(VeevaChildAccountAttendeeSelection.COUNTRY_PREDICATE_TEMPLATE);
        List<VeevaChildAccountAttendeeSelection.ChildAccountResult> accounts = VeevaChildAccountAttendeeSelection.getChildAccounts(termString, fields, viewId, new List<String>(), orderBy,  orderDirection, qLimit, offset, true, filters, useCustomFieldFormatting);
        List<Id> orderedAccountIds = new List<Id>();
        for (VeevaChildAccountAttendeeSelection.ChildAccountResult account : accounts) {
            orderedAccountIds.add(account.parentId);
            orderedAccountIds.add(account.childId);
        }
        return stampOutsideAccounts(orderedAccountIds, accounts);
    }

    private static List<ChildAccountOutsideSearchResult> stampOutsideAccounts(List<Id> orderedRecordIds, List<VeevaChildAccountAttendeeSelection.ChildAccountResult> attendees) {
        Map<Id, Boolean> recordAccess = getRecordAccess(orderedRecordIds);
        List<ChildAccountOutsideSearchResult> results = new List<ChildAccountOutsideSearchResult>();

        for (VeevaChildAccountAttendeeSelection.ChildAccountResult emAttendee : attendees) {
            Id childId = (Id) emAttendee.childId;
            Id parentId = (Id) emAttendee.parentId;
            boolean hasRecordAccess = recordAccess.get(childId) && recordAccess.get(parentId);
            results.add(new ChildAccountOutsideSearchResult(!hasRecordAccess, emAttendee));
        }

        return results;
    }

    private static List<OutsideSearchResult> stampOutsideAccounts(List<Id> orderedRecordIds, Map<Id, SObject> recordsMap) {
        Map<Id, Boolean> recordAccess = getRecordAccess(orderedRecordIds);
        List<OutsideSearchResult> results = new List<OutsideSearchResult>();
        for (Id recordId : orderedRecordIds) { //Preserve original order of records
            results.add(new OutsideSearchResult(!recordAccess.get(recordId), recordsMap.get(recordId).getPopulatedFieldsAsMap()));
        }
        return results;
    }

    private static List<OutsideSearchResult> stampOutsideAccounts(List<Id> orderedRecordIds, Map<Id, EmAttendeeSelection.AttendeeResult> recordsMap) {
        Map<Id, Boolean> recordAccess = getRecordAccess(orderedRecordIds);
        List<OutsideSearchResult> results = new List<OutsideSearchResult>();
        for (Id recordId : orderedRecordIds) { //Preserve original order of records
            results.add(new OutsideSearchResult(!recordAccess.get(recordId), recordsMap.get(recordId)));
        }
        return results;
    }

    private static List<OutsideSearchResult> stampOutsideAccounts(List<Id> orderedRecordIds, List<SObject> attendees) {
        List<OutsideSearchResult> results = new List<OutsideSearchResult>();
        Map<Id, Boolean> recordAccess = getRecordAccess(orderedRecordIds);
        for (Sobject emAttendee : attendees) {
            if (emAttendee.get('Child_Account_vod__c') != null) {
                Id childId = (Id) emAttendee.getSObject('Child_Account_vod__r').get('Child_Account_vod__c');
                Id parentId = (Id) emAttendee.getSObject('Child_Account_vod__r').get('Parent_Account_vod__c');
                boolean hasRecordAccess = recordAccess.get(childId) && recordAccess.get(parentId);
                results.add(new OutsideSearchResult(!hasRecordAccess, emAttendee.getPopulatedFieldsAsMap()));
            } else if (emAttendee.get('Contact_vod__c') != null) {
                Id recordId = (Id) emAttendee.get('Contact_vod__c');
                results.add(new OutsideSearchResult(!recordAccess.get(recordId), emAttendee.getPopulatedFieldsAsMap()));
            } else if (emAttendee.get('User_vod__c') != null) {
                Id recordId = (Id) emAttendee.get('User_vod__c');
                results.add(new OutsideSearchResult(!recordAccess.get(recordId), emAttendee.getPopulatedFieldsAsMap()));
            }

        }
        return results;
    }

    private static Map<Id, Boolean> getRecordAccess(List<Id> orderedRecordIds) {
        Map<Id, Boolean> recordAccess = new Map<Id, Boolean>();
        Id userId = UserInfo.getUserId();
        List<List<Id>> idChunks = new List<List<Id>>();
        if (orderedRecordIds.size() > USER_RECORD_ACCESS_LIMIT) {
            List<Id> chunk = new List<Id>();
            for (Id recordId : orderedRecordIds) {
                if (chunk.size() == USER_RECORD_ACCESS_LIMIT) {
                    idChunks.add(chunk);
                    chunk = new List<Id>();
                }
                chunk.add(recordId);
            }
            if (chunk.size() > 0) {
                idChunks.add(chunk);
            }
        } else {
            idChunks.add(orderedRecordIds);
        }
        for (List<Id> chunk : idChunks) { // UserRecordAccess can only query 200 records at a time
            for (UserRecordAccess ura : [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE RecordId IN :chunk AND UserId = :userId]) {
                recordAccess.put(ura.RecordId, ura.HasReadAccess);
            }
        }
        return recordAccess;
    }
    
    public virtual class OutsideSearchResult {
        @AuraEnabled
        public boolean outside {get;set;}
        @AuraEnabled
        public Map<String, Object> fields {get;set;}

        OutsideSearchResult() {
            this.outside = false;
            fields = new Map<String, Object>();
        }
        
        OutsideSearchResult(Boolean outsideTerr, Map<String, Object> fields) {
            this.outside = outsideTerr;
            this.fields = fields;
        }

        OutsideSearchResult(Boolean outsideTerr, EmAttendeeSelection.AttendeeResult record) {
            this.outside = outsideTerr;
            this.fields = record.record.getPopulatedFieldsAsMap().clone();
            this.fields.put('Address_vod__r', record.address);
        }
    }

    public class ChildAccountOutsideSearchResult extends OutsideSearchResult {
        @AuraEnabled
        public Id childAccountId;
        @AuraEnabled
        public Id childId;
        @AuraEnabled
        public Id parentId;
        
        ChildAccountOutsideSearchResult(Boolean outsideTerr, VeevaChildAccountAttendeeSelection.ChildAccountResult attendee) {
            this.childAccountId = attendee.childAccountId;
            this.childId = attendee.childId;
            this.parentId = attendee.parentId;
            this.outside = outsideTerr;
            this.fields = attendee.fields;
        }
    }

    @AuraEnabled
    public static List<OutsideSearchResult> getOutsideExistingAttendeesWithChildAccounts(String eventId) {
        List<String> attendeeLookupFields = new List<String>{'Contact_vod__c', 'User_vod__c'};
        List<String> childAccountFields = new List<String>{'Child_Account_vod__c', 'Parent_Account_vod__c'};
        List<SObject> existingAttendees = EmAttendeeSelection.getExistingAttendees(eventId);
        List<Id> orderedIds = new List<Id>();
        for (SObject emAttendee : existingAttendees) {
            if (emAttendee.get('Child_Account_vod__c') != null) {
                for (String field : childAccountFields) {
                    Id attendeeTypeId = (Id) emAttendee.getSObject('Child_Account_vod__r').get(field);
                    orderedIds.add(attendeeTypeId);
                }
            } else {
                for (String lookup : attendeeLookupFields) {
                    if (emAttendee.get(lookup) != null) {
                        Id attendeeTypeId = (Id) emAttendee.get(lookup);
                        orderedIds.add(attendeeTypeId);
                        break;
                    }
                }
            }
        }
        return stampOutsideAccounts(orderedIds, existingAttendees);
    }
    
    @AuraEnabled
    public static List<OutsideSearchResult> getOutsideExistingAttendees(String eventId) {
        List<String> attendeeLookupFields = new List<String>{'Account_vod__c', 'Contact_vod__c', 'User_vod__c'};
        List<SObject> existingAttendees = EmAttendeeSelection.getExistingAttendees(eventId);
        Map<Id, SObject> attendeeMap = new Map<Id, SObject>();
        List<Id> orderedIds = new List<Id>();
        for (SObject emAttendee : existingAttendees) {
            for (String lookup : attendeeLookupFields) {
                if (emAttendee.get(lookup) != null) {
                    Id attendeeTypeId = (Id) emAttendee.get(lookup);
                    orderedIds.add(attendeeTypeId);
                    attendeeMap.put(attendeeTypeId, emAttendee);
                    break;
                }
            }
        }
        return stampOutsideAccounts(orderedIds, attendeeMap);
    }

}