public class SpeakerYTDCalculator {

    public static void calculate(Set<Id> speakerIds) {
        if(System.isFuture() || System.isBatch()) {
        	calculateSync(speakerIds);
        } else {
        	calculateFuture(speakerIds);
        }
    }

    @future
    public static void calculateFuture(Set<Id> speakerIds) {
        calculateSync(speakerIds);
    }

    public static Set<String> getSpeakerStatuses() {
        List<String> speakerSetting = new List<String>();
        Set<String> speakerStatuses = new Set<String>();
        Events_Management_Settings_vod__c emSetting = Events_Management_Settings_vod__c.getInstance();
        if(emSetting != null && emSetting.SPEAKER_ROLLUP_STATUS_FILTER_vod__c != null) {
        	speakerSetting = emSetting.SPEAKER_ROLLUP_STATUS_FILTER_vod__c.split(';;');
            String name = speakerSetting.get(0);
            String category = speakerSetting.get(1);
            if(speakerSetting.size() == 2) {
                List<Message_vod__c> speakerStatusesMessage = [SELECT Text_vod__c
                                                               FROM Message_vod__c
                                                               WHERE Active_vod__c = true
                                                               AND NAME = :name
                                                               AND Category_vod__c = :category
                                                               AND Language_vod__c = 'en_US'];
                if(speakerStatusesMessage.size() > 0 && speakerStatusesMessage.get(0).Text_vod__c != null) {
                    speakerStatuses = new Set<String>(speakerStatusesMessage.get(0).Text_vod__c.split(','));
                }
            }
        }

        if(speakerStatuses.isEmpty()) {
            speakerStatuses.add('Attended_vod');
            speakerStatuses.add('Signed_vod');
        }
        return speakerStatuses;
    }

    public static void calculateSync(Set<Id> speakerIds) {
        Boolean multiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();
        Boolean isNextYearAnnualCapSettingEnabled = VeevaEmSpeakerCapUtil.isNextYearAnnualCapSettingEnabled();
        Map<Id, Account> accounts = new Map<Id, Account>();
        for(Account account: [SELECT Id, (SELECT Id FROM EM_Speaker_vod__r) FROM Account WHERE Id IN (SELECT Account_vod__c FROM EM_Speaker_vod__c WHERE Id IN :speakerIds)]) {
       		accounts.put(account.Id, account);
        }
		Set<Id> accountSet = accounts.keySet();
        Map<Id,EM_Speaker_vod__c> speakersToUpdate = new Map<Id,EM_Speaker_vod__c>();

        Integer defaultDay = Integer.valueOf(EM_Speaker_vod__c.Year_To_Date_Reset_Day_vod__c.getDescribe().getDefaultValue());
        Integer defaultMonth = Integer.valueOf(EM_Speaker_vod__c.Year_To_Date_Reset_Month_vod__c.getDescribe().getDefaultValue());

		Set<String> speakerStatuses = getSpeakerStatuses();

        Map<Id, String> speakerIdToIsoCode = new Map<Id,String>();

        if(multiCurrency) {
        	List<EM_Speaker_vod__c> speakersWithIsoCode = Database.query('SELECT CurrencyIsoCode, Id FROM EM_Speaker_vod__c WHERE Id IN ' + MultiCurrencyUtil.toCommaSeperated(speakerIds));
            for(EM_Speaker_vod__c speaker: speakersWithIsoCode) {
                speakerIdtoIsoCode.put(speaker.Id, (String)speaker.get('CurrencyIsoCode'));
            }
        }


        for(Id speakerId: speakerIds) {
            EM_Speaker_vod__c speaker = new EM_Speaker_vod__c(Id=speakerId, Year_to_Date_Utilization_vod__c = 0, Year_to_Date_Spend_vod__c = 0, Next_Year_Committed_vod__c = 0, Upcoming_Committed_Costs_vod__c = 0);
            if(multiCurrency) {
            	speaker.put('CurrencyIsoCode', speakerIdtoIsoCode.get(speakerId));
            }
            speakersToUpdate.put(speakerId, speaker);
        }

        Set<Id> relevantEvents = new Set<Id>();
        Set<String> speakersAndEventsToRollup = new Set<String>();
        Map<Id, Set<Id>> speakerIdToEvent = new Map<Id, Set<Id>>();

        Date minimumDate = Date.newInstance(System.Today().year()-1, 1, 1);
        Date maximumDate = Date.newInstance(System.Today().year()+1, 12, 31);

        Map<String, EM_Speaker_Cap_vod__c> speakerCapsMap;
        if(isNextYearAnnualCapSettingEnabled) {
            speakerCapsMap = getImpactedSpeakerCaps(speakersToUpdate.keySet(), multiCurrency);
        }

        List<EM_Event_Speaker_vod__c> eventSpeakers;

        if(multiCurrency) {
            Datetime minDatetime = datetime.newInstance(minimumDate.year(), minimumDate.month(),minimumDate.day());
			Datetime maxDatetime = datetime.newInstance(maximumDate.year(), maximumDate.month(),maximumDate.day());

            String datetimeFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';

            String formattedMin = minDateTime.formatGmt(datetimeFormat);
            String formattedMax = maxDatetime.formatGmt(datetimeFormat);

        	eventSpeakers = Database.query('SELECT Id, CurrencyIsoCode, Event_vod__c, Event_vod__r.Status_vod__c, Event_vod__r.Start_Time_vod__c, Event_vod__r.Product_vod__c, Status_vod__c, ' +
                                                       ' Speaker_vod__c, Speaker_vod__r.Year_To_Date_Reset_Day_vod__c, Speaker_vod__r.Year_To_Date_Reset_Month_vod__c' +
                                                       ' FROM EM_Event_Speaker_vod__c ' +
                                                       ' WHERE Speaker_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(speakerIds) +
                                                       ' AND Event_vod__r.Status_vod__c != \'Canceled_vod\'' +
                                                       ' AND Event_vod__r.Start_Time_vod__c >= ' + formattedMin +
                                                       ' AND Event_vod__r.Start_Time_vod__c <= ' + formattedMax);
        } else {
        	eventSpeakers = [SELECT Id, Event_vod__c, Event_vod__r.Status_vod__c, Event_vod__r.Start_Time_vod__c, Event_vod__r.Product_vod__c, Status_vod__c,
                                                       Speaker_vod__c, Speaker_vod__r.Year_To_Date_Reset_Day_vod__c, Speaker_vod__r.Year_To_Date_Reset_Month_vod__c
                                                       FROM EM_Event_Speaker_vod__c
                                                       WHERE Speaker_vod__c IN :speakerIds
                                                       AND Event_vod__r.Status_vod__c != 'Canceled_vod'
                                                       AND Event_vod__r.Start_Time_vod__c >= :minimumDate
                                                       AND Event_vod__r.Start_Time_vod__c <= :maximumDate];
        }


        for(EM_Event_Speaker_vod__c eventSpeaker: eventSpeakers) {

            EM_Speaker_vod__c speaker = speakersToUpdate.get(eventSpeaker.Speaker_vod__c);
            Boolean validAddToUtilizationStatus = speakerStatuses.contains(eventSpeaker.Status_vod__c);

            Integer day = eventSpeaker.Speaker_vod__r.Year_To_Date_Reset_Day_vod__c != null ? Integer.valueOf(eventSpeaker.Speaker_vod__r.Year_To_Date_Reset_Day_vod__c): defaultDay;
            Integer month = eventSpeaker.Speaker_vod__r.Year_To_Date_Reset_Month_vod__c != null ? Integer.valueOf(eventSpeaker.Speaker_vod__r.Year_To_Date_Reset_Month_vod__c): defaultMonth;
            Date currentResetDate = Date.newInstance(System.today().year(), month, day);

            if(speaker.Next_Year_Reset_Date_vod__c == null) {
                if(currentResetDate <= System.Today()) {
                    speaker.Next_Year_Reset_Date_vod__c = Date.newInstance(System.today().year()+1, month, day);
                } else {
                    speaker.Next_Year_Reset_Date_vod__c = currentResetDate;
                }
            }

            Date startConstraint;
            Date endConstraint;
            Date speakerDate = speaker.Next_Year_Reset_Date_vod__c;


            if(System.today() < speakerDate) {
            	startconstraint = Date.newInstance(speakerDate.year()-1, speakerDate.month(), speakerDate.day());
                endConstraint = speakerDate;
            } else {
            	startconstraint = speakerDate;
                endConstraint = Date.newInstance(speakerDate.year()+1, speakerDate.month(), speakerDate.day());
            }

            Set<Id> speakerEvents = speakerIdToEvent.get(eventSpeaker.Speaker_vod__c);

            if(speakerEvents == null) {
                speakerEvents = new Set<Id>();
            }

            speakerEvents.add(eventSpeaker.Event_vod__c);
            speakerIdToEvent.put(eventSpeaker.Speaker_vod__c, speakerEvents);
            if(eventSpeaker.Event_vod__r.Start_Time_vod__c >= startconstraint) {
                speakersAndEventsToRollup.add(getEventToSpeakerId(eventSpeaker.Event_vod__c, eventSpeaker.Speaker_vod__c));
                if(validAddToUtilizationStatus && eventSpeaker.Event_vod__r.Start_Time_vod__c < endConstraint) {
                    speaker.Year_to_Date_Utilization_vod__c++;
                }
                relevantEvents.add(eventSpeaker.Event_vod__c);
            } else if(isNextYearAnnualCapSettingEnabled) {
                relevantEvents.add(eventSpeaker.Event_vod__c);
            }
            if(validAddToUtilizationStatus) {
                EM_Speaker_Cap_vod__c speakerCap = getAssociatedSpeakerCap(eventSpeaker.Event_vod__r, speaker, speakerCapsMap);
                if(speakerCap != null && speakerStatuses.contains(eventSpeaker.Status_vod__c)) {
                	speakerCap.Year_to_Date_Utilization_vod__c++;
            	}
            }

        }

        List<Expense_Line_vod__c> expenseLines;

        if(multiCurrency) {
            String query = 'SELECT CurrencyIsoCode, Actual_vod__c, Committed_vod__c, Expense_Header_vod__r.Incurred_Expense_Speaker_vod__r.Speaker_vod__c, Event_vod__r.Start_Time_vod__c, Event_vod__r.Status_vod__c,' +
                            ' Expense_Header_vod__r.Incurred_Expense_Account_vod__c, Expense_Header_vod__r.Incurred_Expense_Attendee_vod__r.Account_vod__c, Event_vod__c, Event_vod__r.Product_vod__c ' +
                            ' FROM Expense_Line_vod__c ' +
                            ' WHERE Event_vod__c IN :relevantEvents' +
                            ' AND (Expense_Header_vod__r.Incurred_Expense_Account_vod__c IN :accountSet' +
                            ' OR Expense_Header_vod__r.Incurred_Expense_Speaker_vod__r.Speaker_vod__c IN :speakerIds' +
                			' OR Expense_Header_vod__r.Incurred_Expense_Attendee_vod__r.Account_vod__c IN :accountSet) ' +
                			' AND Expense_Header_vod__r.Split_Lines_vod__c != \'Yes_vod\'' +
                			' AND Expense_Type_vod__r.Included_In_Speaker_Cap_vod__c = true';

            expenseLines = Database.query(query);
        } else {
            expenseLines = [SELECT Actual_vod__c, Committed_vod__c, Expense_Header_vod__r.Incurred_Expense_Speaker_vod__r.Speaker_vod__c, Event_vod__r.Start_Time_vod__c, Event_vod__r.Status_vod__c,
                            Expense_Header_vod__r.Incurred_Expense_Account_vod__c, Expense_Header_vod__r.Incurred_Expense_Attendee_vod__r.Account_vod__c, Event_vod__c, Event_vod__r.Product_vod__c
                            FROM Expense_Line_vod__c
                            WHERE Event_vod__c IN :relevantEvents
                            AND (Expense_Header_vod__r.Incurred_Expense_Account_vod__c IN :accounts.keySet() OR
                                 Expense_Header_vod__r.Incurred_Expense_Speaker_vod__r.Speaker_vod__c IN :speakerIds OR
                                 Expense_Header_vod__r.Incurred_Expense_Attendee_vod__r.Account_vod__c IN :accounts.keySet())
                            AND Expense_Header_vod__r.Split_Lines_vod__c != 'Yes_vod'
                            AND Expense_Type_vod__r.Included_In_Speaker_Cap_vod__c = true];
        }

        for(Expense_Line_vod__c expense : expenseLines) {
            EM_Speaker_vod__c speaker = null;


            if(expense.Expense_Header_vod__r.Incurred_Expense_Speaker_vod__r.Speaker_vod__c != null) {
            	speaker = speakersToUpdate.get(expense.Expense_Header_vod__r.Incurred_Expense_Speaker_vod__r.Speaker_vod__c);
            } else if (expense.Expense_Header_vod__r.Incurred_Expense_Account_vod__c != null) {
                Account account = accounts.get(expense.Expense_Header_vod__r.Incurred_Expense_Account_vod__c);
                if(account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {
                    EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speaker = speakersToUpdate.get(updateSpeaker.Id);
                }
            } else if (expense.Expense_Header_vod__r.Incurred_Expense_Attendee_vod__r.Account_vod__c != null) {
            	Account account = accounts.get(expense.Expense_Header_vod__r.Incurred_Expense_Attendee_vod__r.Account_vod__c);
                if(account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {
                    EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speaker = speakersToUpdate.get(updateSpeaker.Id);
                }
            }
            if(speaker != null && speakerIdToEvent.get(speaker.Id) != null && speakerIdToEvent.get(speaker.Id).contains(expense.Event_vod__c))  {
                EM_Event_vod__c event = expense.Event_vod__r;
                Boolean nextYear = speaker.Next_Year_Reset_Date_vod__c < event.Start_Time_vod__c;
                Boolean isClosed = event.Status_vod__c == 'Closed_vod';
                Boolean shouldRollupToSpeaker = speakersAndEventsToRollup.contains(getEventToSpeakerId(event.Id, speaker.Id));
                EM_Speaker_Cap_vod__c speakerCap = getAssociatedSpeakerCap(event, speaker, speakerCapsMap);
            	rollupExpense(speaker, expense, multiCurrency, nextYear, isClosed, speakerCap, shouldRollupToSpeaker);
            }
		}
		List<Expense_Attribution_vod__c> attributions;
        if(multicurrency) {
        	String query = 'SELECT CurrencyIsoCode, Expense_Line_vod__r.CurrencyIsoCode, Actual_vod__c, Expense_Line_vod__r.Event_vod__r.Start_Time_vod__c, Expense_Line_vod__r.Event_vod__r.Status_vod__c,' +
                            ' Incurred_Expense_Account_vod__c, Incurred_Expense_Speaker_vod__r.Speaker_vod__c, Incurred_Expense_Attendee_vod__r.Account_vod__c, Expense_Line_vod__r.Event_vod__c, Expense_Line_vod__r.Event_vod__r.Product_vod__c' +
                            ' FROM Expense_Attribution_vod__c ' +
                            ' WHERE Expense_Line_vod__r.Event_vod__c IN :relevantEvents'  +
                            ' AND (Incurred_Expense_Account_vod__c IN :accountSet' +
							' OR Incurred_Expense_Speaker_vod__r.Speaker_vod__c IN :speakerIds' +
                			' OR Incurred_Expense_Attendee_vod__r.Account_vod__c IN :accountSet)' +
							' AND Expense_Line_vod__r.Expense_Type_vod__r.Included_In_Speaker_Cap_vod__c = true' +
                            ' AND Expense_Line_vod__r.Expense_Header_vod__r.Split_Lines_vod__c = \'Yes_vod\'';

            attributions = Database.query(query);
        } else {
        	attributions = [SELECT Actual_vod__c, Expense_Line_vod__r.Event_vod__r.Start_Time_vod__c, Expense_Line_vod__r.Event_vod__r.Status_vod__c,
                            Incurred_Expense_Account_vod__c, Incurred_Expense_Speaker_vod__r.Speaker_vod__c, Incurred_Expense_Attendee_vod__r.Account_vod__c, Expense_Line_vod__r.Event_vod__c, Expense_Line_vod__r.Event_vod__r.Product_vod__c
                            FROM Expense_Attribution_vod__c
                            WHERE Expense_Line_vod__r.Event_vod__c IN :relevantEvents
                            AND Expense_Line_vod__r.Expense_Type_vod__r.Included_In_Speaker_Cap_vod__c = true
                            AND Expense_Line_vod__r.Expense_Header_vod__r.Split_Lines_vod__c = 'Yes_vod'
                            AND (Incurred_Expense_Account_vod__c IN :accounts.keySet() OR
                                 Incurred_Expense_Attendee_vod__r.Account_vod__c IN :accounts.keySet() OR
                                 Incurred_Expense_Speaker_vod__r.Speaker_vod__c IN :speakerIds)];
        }

        for(Expense_Attribution_vod__c attr: attributions) {
            EM_Speaker_vod__c speaker = null;
            if(attr.Incurred_Expense_Speaker_vod__r.Speaker_vod__c != null) {
            	speaker = speakersToUpdate.get(attr.Incurred_Expense_Speaker_vod__r.Speaker_vod__c);
            } else if (attr.Incurred_Expense_Account_vod__c != null) {
                Account account = accounts.get(attr.Incurred_Expense_Account_vod__c);
                if(account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {
                    EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speaker = speakersToUpdate.get(updateSpeaker.Id);
                }
            } else if (attr.Incurred_Expense_Attendee_vod__r.Account_vod__c != null) {
            	Account account = accounts.get(attr.Incurred_Expense_Attendee_vod__r.Account_vod__c);
                if(account.EM_Speaker_vod__r != null && !account.EM_Speaker_vod__r.isEmpty()) {
                    EM_Speaker_vod__c updateSpeaker = account.EM_Speaker_vod__r;
                    speaker = speakersToUpdate.get(updateSpeaker.Id);
                }
            }

            if(speaker != null && speakerIdToEvent.get(speaker.Id) != null && speakerIdToEvent.get(speaker.Id).contains(attr.Expense_Line_vod__r.Event_vod__c )) {
                Expense_Line_vod__c expense = attr.Expense_Line_vod__r;
                EM_Event_vod__c event = expense.Event_vod__r;
                Boolean shouldRollupToSpeaker = speakersAndEventsToRollup.contains(getEventToSpeakerId(event.Id, speaker.Id));
                Boolean nextYear = speaker.Next_Year_Reset_Date_vod__c < event.Start_Time_vod__c;
                Boolean isClosed = event.Status_vod__c == 'Closed_vod';
                EM_Speaker_Cap_vod__c speakerCap = getAssociatedSpeakerCap(event, speaker, speakerCapsMap);

                if (multiCurrency) {
                    attr.put('CurrencyIsoCode', (String) attr.Expense_Line_vod__r.get('CurrencyIsoCode'));
                }
                rollupExpense(speaker, attr, multiCurrency, nextYear, isClosed, speakerCap, shouldRollupToSpeaker);
            }
        }

        if(speakersToUpdate.values().size() > 0) {
            update speakersToUpdate.values();
            if(speakerCapsMap != null && !speakerCapsMap.isEmpty()) {
                update speakerCapsMap.values();
            }
        }
    }

    private static void rollupExpense(EM_Speaker_vod__c speaker, SObject expense, Boolean multiCurrency, Boolean nextYear, Boolean isClosed, EM_Speaker_Cap_vod__c speakerCap, Boolean shouldRollupToSpeaker) {
        Decimal actual = (Decimal)expense.get('Actual_vod__c');
        Decimal committed = null;
        Decimal speakerCapActual = actual;
        Decimal speakerCapCommitted = null;

        if(isClosed != null && expense.getSobjectType() != Schema.getGlobalDescribe().get('Expense_Attribution_vod__c')) {
            committed = (Decimal)expense.get('Committed_vod__c');
            speakerCapCommitted = committed;
        }

        if(multiCurrency) {
            String expenseCurrency = (String)expense.get('CurrencyIsoCode');
            String speakerCurrency = (String)speaker.get('CurrencyIsoCode');
            String speakerCapCurrency = (speakerCap != null) ? (String)speakerCap.get('CurrencyIsoCode') : null;
            if(actual != null) {
                actual = MultiCurrencyUtil.convertCurrency(expenseCurrency, speakerCurrency, actual);
                speakerCapActual = MultiCurrencyUtil.convertCurrency(expenseCurrency, speakerCapCurrency, speakerCapActual);
            }
            if(committed != null && !isClosed) {
                committed = MultiCurrencyUtil.convertCurrency(expenseCurrency, speakerCurrency, committed);
                speakerCapCommitted = MultiCurrencyUtil.convertCurrency(expenseCurrency, speakerCapCurrency, speakerCapCommitted);
            }
        }

        if(actual != null) {
            if(!nextYear && shouldRollupToSpeaker) {
                speaker.Year_to_Date_Spend_vod__c += actual;
            }
            if(speakerCap != null && speakerCapActual != null) {
                speakerCap.Year_to_Date_Spend_vod__c += speakerCapActual;
            }
        }
        else if(committed != null && !isClosed) {
            if(nextYear && shouldRollupToSpeaker) {
                speaker.Next_Year_Committed_vod__c += committed;
            } else if(shouldRollupToSpeaker) {
                speaker.Upcoming_Committed_Costs_vod__c += committed;
            }
            if(speakerCap != null && speakerCapCommitted != null) {
                speakerCap.Upcoming_Committed_Costs_vod__c += speakerCapCommitted;
            }
        }
    }

    private static EM_Speaker_Cap_vod__c getAssociatedSpeakerCap(EM_Event_vod__c event, EM_Speaker_vod__c speaker, Map<String, EM_Speaker_Cap_vod__c> speakerCapsMap){
        if(speakerCapsMap == null || speakerCapsMap.isEmpty()) {
            return null;
        }
        Id product = event.Product_vod__c;
        Date eventStartDate = event.Start_Time_vod__c.date();
        Integer eventYear = eventStartDate.year();

        List<String> uniqueProductCapKeys = new List<String>{
            VeevaEmSpeakerCapUtil.getUniqueProductCapKey(speaker.Id, product, String.valueOf(eventYear)),
            VeevaEmSpeakerCapUtil.getUniqueProductCapKey(speaker.Id, product, String.valueOf(eventYear-1))
        };

        for(String productCapKey : uniqueProductCapKeys) {
            if(speakerCapsMap.containsKey(productCapKey)) {
                EM_Speaker_Cap_vod__c speakerCap = speakerCapsMap.get(productCapKey);
                if(eventStartDate >= speakerCap.Start_Date_vod__c && eventStartDate <= speakerCap.End_Date_vod__c) {
                    return speakerCap;
                }
            }
        }
        return null;
    }

    private static Map<String, EM_Speaker_Cap_vod__c> getImpactedSpeakerCaps(Set<Id> speakerIds, Boolean isMultiCurrency) {
        Map<String, EM_Speaker_Cap_vod__c> impactedSpeakerCapsMap = new Map<String, EM_Speaker_Cap_vod__c>();
        Id productCapRecordTypeId = VeevaEmSpeakerCapUtil.getProductCapRecordTypeId();
        Integer calculationsStartYear = System.Today().year() - 1;
        List<EM_Speaker_Cap_vod__c> speakerCaps;
        if(isMultiCurrency) {
            String speakerCapsToCalculateQuery = 'SELECT Id, CurrencyIsoCode, Product_vod__c, Starting_Year_vod__c, Speaker_vod__c, Upcoming_Committed_Costs_vod__c, Year_to_Date_Spend_vod__c, Year_to_Date_Utilization_vod__c, Start_Date_vod__c, End_Date_vod__c' +
                                                    ' FROM EM_Speaker_Cap_vod__c' +
                                                    ' WHERE Speaker_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(speakerIds) +
                                                    ' AND RecordTypeId = \'' + productCapRecordTypeId + '\'' +
                                                    ' AND Starting_Year_vod__c >= \'' + calculationsStartYear + '\'';

            speakerCaps = Database.query(speakerCapsToCalculateQuery);
        } else {
            speakerCaps = [SELECT Id, Product_vod__c, Starting_Year_vod__c, Speaker_vod__c, Upcoming_Committed_Costs_vod__c, Year_to_Date_Spend_vod__c, Year_to_Date_Utilization_vod__c, Start_Date_vod__c, End_Date_vod__c
                            FROM EM_Speaker_Cap_vod__c
                            WHERE Speaker_vod__c in :speakerIds
                            AND RecordTypeId = :productCapRecordTypeId
                            AND Starting_Year_vod__c >= : String.valueOf(calculationsStartYear)];
        }
        if(speakerCaps != null && !speakerCaps.isEmpty()) {
            for(EM_Speaker_Cap_vod__c speakerCap : speakerCaps) {
                String speakerCapKey = VeevaEmSpeakerCapUtil.getUniqueProductCapKey(speakerCap);
                speakerCap.Upcoming_Committed_Costs_vod__c = 0;
                speakerCap.Year_to_Date_Spend_vod__c = 0;
                speakerCap.Year_to_Date_Utilization_vod__c = 0;
                impactedSpeakerCapsMap.put(speakerCapKey, speakerCap);
            }
        }
        return impactedSpeakerCapsMap;
    }

    private static String getEventToSpeakerId(Id eventId, Id speakerId) {
        return eventId+'-'+speakerId;
    }
}