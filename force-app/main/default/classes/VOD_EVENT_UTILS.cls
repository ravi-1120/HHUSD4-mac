public class VOD_EVENT_UTILS {
    //Global variable to store the event that Override_Lock_vod__c will be set to true
    public static List<ID> eventsWithOverrideLockTrue = new List<ID>();
    
    public static List<EM_Event_vod__c> rollupCountsToEvent(Set<Id> eventIds) {
        Map<Id, EM_Event_vod__c> eventsToUpdate = new Map<Id, EM_Event_vod__c>();
        for(Id eventId: eventIds) {
            EM_Event_vod__C event = new EM_Event_vod__c(Id = eventId,
                                                        Invited_Attendees_vod__c = 0,
                                                        Walk_In_Count_vod__c = 0,
                                                        Online_Registrant_Count_vod__c = 0,
                                                        Actual_Attendance_vod__c = 0,
                                                        Attendees_Requesting_Meals_vod__c = 0,
                                                        Attendees_With_Meals_vod__c = 0,
                                                        HCPs_With_Meals_vod__c = 0);
            eventsToUpdate.put(eventId, event);
        }
        addSubTotals(eventsToUpdate, VOD_Utils.getAttendeeStatuses(), true);
        addSubTotals(eventsToUpdate, SpeakerYTDCalculator.getSpeakerStatuses(), false);
        
        Map<Id, Decimal> eventToAggregateCost = getAggregateCosts(eventIds);
        for (EM_Event_vod__c event: eventsToUpdate.values()) {
            if (event.Attendees_With_Meals_vod__c > 0) {
                Decimal cost = eventToAggregateCost.get(event.Id) == null ? 0 : eventToAggregateCost.get(event.Id);
                VOD_EXPENSE_LINE_TRIG.rollUpMeals(event, cost, true);
            }
        }
        
        // Ad-Hoc Sync Process
        EMEventTriggerHandler.syncEvents(eventsToUpdate.values());
        
        return eventsToUpdate.values();
    }
    
    @TestVisible private static void addSubTotals(Map<Id, EM_Event_vod__c> eventsToUpdate, Set<String> validStatuses, Boolean isAttendee) {
        Set<Id> eventIds = eventsToUpdate.keySet();
        String query = 'SELECT COUNT(Id) total, COUNT(Account_vod__c) hcps, GROUPING(Status_vod__c) groupingStatus, GROUPING(Meal_Opt_In_vod__c) groupingMeal, Event_vod__c, Status_vod__c, Meal_Opt_In_vod__c';
        if (isAttendee) {
            query += ', COUNT(Walk_In_Status_vod__c) walkInCount, COUNT(Online_Registration_Status_vod__c) onlineRegistrants FROM EM_Attendee_vod__c ';
        } else {
            query += ' FROM EM_Event_Speaker_vod__c ';
        }
        query += 'WHERE Event_vod__c IN :eventIds GROUP BY ROLLUP(Event_vod__c, Status_vod__c, Meal_Opt_In_vod__c) HAVING GROUPING(Event_vod__c) = 0'; // Discard grand total since we don't need the sum across all events
        
        for (AggregateResult result : Database.query(query)) {
            Id eventId = (Id) result.get('Event_vod__c');
            EM_Event_vod__c event = eventsToUpdate.get(eventId);
            
            Boolean groupingStatus = (Integer) result.get('groupingStatus') == 1; // if true, subtotal includes all records with any value for the field
            Boolean groupingMeal = (Integer) result.get('groupingMeal') == 1; // if false, subtotal includes records with only the specific value for the field on result
            Boolean validStatus = validStatuses.contains((String)result.get('Status_vod__c'));
            Integer total = (Integer) result.get('total');
            
            if (groupingStatus && groupingMeal) { // Subtotal is calculated using all Attendees/Speakers on the event regardless of Status of Meal Opt In
                event.Invited_Attendees_vod__c += total; 
                if (isAttendee) {
                    event.Walk_In_Count_vod__c += (Integer) result.get('walkInCount');
                    event.Online_Registrant_Count_vod__c += (Integer) result.get('onlineRegistrants');
                }
            }
            
            if (validStatus && groupingMeal) { // Subtotal is calculated using all Attendees/Speakers on the event with a particular status, Meal Opt In does not matter
                event.Actual_Attendance_vod__c += total;
            }
            
            if (!groupingMeal && (Boolean)result.get('Meal_Opt_In_vod__c')) { // Subtotal is calculated with all records on the event with a specific status and meal opt in value
                event.Attendees_Requesting_Meals_vod__c += total;
                if (validStatus) {
                    event.Attendees_With_Meals_vod__c += total;
                    event.HCPs_With_Meals_vod__c += (Integer) result.get('hcps');
                }
            }
            eventsToUpdate.put(eventId, event);
        }
    }

    public static void updateAttendeeStub(Map<String, String> idToStubMap) {
        if(System.isFuture() || System.isBatch()) {
            updateAttendeeStubSync(idToStubMap);
        } else {
            updateAttendeeStubFuture(idToStubMap);
        }
    }

    @future
    public static void updateAttendeeStubFuture(Map<String, String> idToStubMap) {
        updateAttendeeStubSync(idToStubMap);
    }

    public static void updateAttendeeStubSync(Map<String, String> idToStubMap) {
        List<EM_Attendee_vod__c> updateAttendees = new List<EM_Attendee_vod__c>();
        for(String keyId: idToStubMap.keySet()) {
            String stubId = idtoStubMap.get(keyId);
            updateAttendees.add(new EM_Attendee_vod__c(Id = keyId, Stub_SFDC_Id_vod__c = stubId));
        }
        if(updateAttendees.size() > 0) {
            update updateAttendees;
        }
    }

    public static void updateSpeakerStub(Map<String, String> idToStubMap) {
        if(System.isFuture() || System.isBatch()) {
            updateSpeakerStubSync(idToStubMap);
        } else {
            updateSpeakerStubFuture(idToStubMap);
        }
    }

    @future
    public static void updateSpeakerStubFuture(Map<String, String> idToStubMap) {
        updateSpeakerStubSync(idToStubMap);
    }

    public static void updateSpeakerStubSync(Map<String, String> idToStubMap) {
        List<EM_Event_Speaker_vod__c> updateSpeakers = new List<EM_Event_Speaker_vod__c>();
        for(String keyId: idToStubMap.keySet()) {
            String stubId = idtoStubMap.get(keyId);
            updateSpeakers.add(new EM_Event_Speaker_vod__c(Id = keyId, Stub_SFDC_Id_vod__c = stubId));
        }
        if(updateSpeakers.size() > 0) {
            update updateSpeakers;
        }
    }

    public static void updateTeamMemberStub(Map<String, String> idToStubMap) {
        if(System.isFuture() || System.isBatch()) {
            updateTeamMemberStubSync(idToStubMap);
        } else {
            updateTeamMemberStubFuture(idToStubMap);
        }
    }

    @future
    public static void updateTeamMemberStubFuture(Map<String, String> idToStubMap) {
        updateTeamMemberStubSync(idToStubMap);
    }

    public static void updateTeamMemberStubSync(Map<String, String> idToStubMap) {
        List<EM_Event_Team_Member_vod__c> updateTeamMembers = new List<EM_Event_Team_Member_vod__c>();
        for(String keyId: idToStubMap.keySet()) {
            String stubId = idtoStubMap.get(keyId);
            updateTeamMembers.add(new EM_Event_Team_Member_vod__c(Id = keyId, Stub_SFDC_Id_vod__c = stubId));
        }
        if(updateTeamMembers.size() > 0) {
            update updateTeamMembers;
        }
    }

    public static Map<Id, Decimal> getAggregateCosts(Set<Id> eventIds) {
        boolean multiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

        List<Expense_Line_vod__c> expenseLines = new List<Expense_Line_vod__c>();

        if(multiCurrency) {
            expenseLines = Database.query('SELECT Event_vod__c, Actual_vod__c, CurrencyIsoCode, Event_vod__r.CurrencyIsoCode FROM Expense_Line_vod__c WHERE Expense_Type_vod__r.Meal_Expense_vod__c = true AND Event_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(eventIds));
        } else {
            expenseLines = [SELECT Event_vod__c, Actual_vod__c FROM Expense_Line_vod__c
                            WHERE Expense_Type_vod__r.Meal_Expense_vod__c = true AND Event_vod__c IN : eventIds];
        }

        Map<Id, Decimal> eventToAggregateCost = new Map<Id, Decimal>();

        for (Expense_Line_vod__c line : expenseLines) {
            if(eventToAggregateCost.get(line.Event_vod__c) == null) {
                eventToAggregateCost.put(line.Event_vod__c, 0);
            }
            Decimal lineCost = line.Actual_vod__c != null ? line.Actual_vod__c : 0;
            Decimal eventAggregate = eventToAggregateCost.get(line.Event_vod__c);

            if(multiCurrency) {
                lineCost = MultiCurrencyUtil.convertCurrency((String)line.get('CurrencyIsoCode'), (String)line.getSobject('Event_vod__r').get('CurrencyIsoCode'), lineCost);
            }
            eventAggregate += lineCost;
            eventToAggregateCost.put(line.Event_vod__c, eventAggregate);
        }

        return eventToAggregateCost;
    }
    
    public static void addErrorToLockedEventChildObject(List<SObject> sObjects, Set<String> lockedEvents){
        for(SObject eventChildObject : sObjects){
            if(eventChildObject.get('Event_vod__c') != null && lockedEvents.contains(eventChildObject.get('Event_vod__c').toString())) {
                eventChildObject.addError('Event is locked');
            }
        }
    }

    public static void addEventToEventsWithOverrideLockTrueFromDependentObject(SObject dependentObject) {
        if(dependentObject != null) {
        	ID event = (ID) dependentObject.get('Event_vod__c');
           	if(event != null && dependentObject.get('Override_Lock_vod__c') == true && !eventsWithOverrideLockTrue.contains(event)) {
            	eventsWithOverrideLockTrue.add(event);
                dependentObject.put('Override_Lock_vod__c', false);
            }
        }
    }

    public static void removeEventFromEventsWithOverrideLock(ID event) {
        for(Integer i = 0; i < eventsWithOverrideLockTrue.size(); i++) {
            ID iterEvent = eventsWithOverrideLockTrue.get(i);
            if(iterEvent == event) {
                eventsWithOverrideLockTrue.remove(i);
                break;
            }
        }
    }
}