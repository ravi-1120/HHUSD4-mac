public inherited sharing class VeevaCalendarEventBuilder {
    private static final Integer DAY_IN_MINUTES = 1440;

    public String name { get; private set; }
    public String startDate { get; private set; }
    public String endDate { get; private set; }
    public Boolean allDay { get; private set; }
    public String eventType { get; private set; }
    public String accountUrl { get; private set; }
    public String accountId { get; private set; }
    public String address { get; private set; }
    public String description { get; private set; }
    public String status { get; private set; }
    public String statusLabel { get; private set; }
    public String acctIdentifier { get; private set; }
    public String id { get; private set; }
    public String callChannel { get; private set; }
    public String callChannelLabel { get; private set; }
    public String recordType { get; private set; }
    public String objectType { get; private set; }
    public String programType {get; private set; }
    public String medicalEventType {get; private set; }
    public String location { get; private set; }
    public String parentAccount { get; private set; }
    public String owner { get; private set; }
    public String ownerUrl { get; private set; }
    public String ownerId { get; private set; }
    public Integer duration { get; private set; }
    public Integer childCallNumber { get; private set; }
    public Boolean isSigned { get; private set; }
    public Boolean hasSampleCard { get; private set; }
    public Boolean hasUnscheduledRemoteMeeting { get; private set; }
    public Integer uninvitedRemoteAttendeeNumber { get; private set; }
    public Integer remoteAttendeeNumber {get; private set; }
    public List<String> children { get; private set; }
    public String eventDateTime { get; private set; }
    public List<List<String>> viewedSlides { get; private set; }
    public String meetingTypeLabel { get; private set; }
    public String meetingType { get; private set; }
    public String phone { get; private set; }
    public Boolean hasKeyMessageDescriptionFls { get; private set; }
    public Boolean unavailable { get; private set; }
    public Boolean draggable { get; private set; }
    public Boolean resizable { get; private set; }
    public String emEventId { get; private set; }
    public String externalCalendarId { get; private set; }
    public Boolean hasCall { get; private set; }
    public String childAccountId { get; private set; }
    public String sensitivity {get; private set; }
    public Boolean accountDoNotCall {get; private set; }
    public String accountRecordType {get; private set; }

    public VeevaCalendarEventBuilder(String name, String Id, String recordType, String objectType) {
        this.name = name;
        this.id = Id;
        this.recordType = recordType;
        this.objectType = objectType;
    }

    public VeevaCalendarEvent build() {
        return new VeevaCalendarEvent(this);
    }

    public VeevaCalendarEventBuilder hasKeyMessageDescriptionFls(Boolean hasKeyMessageDescriptionFls) {
        this.hasKeyMessageDescriptionFls = hasKeyMessageDescriptionFls;
        return this;
    }

    public VeevaCalendarEventBuilder hasCall(Boolean hasCall) {
        this.hasCall = hasCall;
        return this;
    }

    public VeevaCalendarEventBuilder accountUrl(Id acctId) {
        if (acctId != null) { 
            this.accountUrl = getUrl(acctId);
        }
        return this;
    }

    public VeevaCalendarEventBuilder ownerUrl(Id ownerId) {
        this.ownerUrl = getUrl(ownerId);
        return this;
    }

    public VeevaCalendarEventBuilder ownerId(Id ownerId) {
        this.ownerId = ownerId;
        return this;
    }

    public VeevaCalendarEventBuilder address(String address) {
        if (!String.isBlank(address)) {
            this.address = address;
            this.description = address;
        }
        return this;
    }

    public VeevaCalendarEventBuilder children(List<String> children) {
        if (children != null) {
            this.children = children;
            this.childCallNumber = children.size();
        } else {
            this.childCallNumber = 0;
        }
        return this;
    }

    public VeevaCalendarEventBuilder viewedSlides(List<Multichannel_Activity_Line_vod__c> mcalList, Boolean hasViewOrderFls) {
        this.viewedSlides = new List<List<String>>(); // each entry of the main list is a list with 2 components, 0: the description, 1: the view order
        if (mcalList == null) {
            return this;
        }
        for (Multichannel_Activity_Line_vod__c mcal : mcalList) {
            List<String> descriptionToTime = new List<String>();
            descriptionToTime.add(mcal.Key_Message_vod__r.Description_vod__c != null ? mcal.Key_Message_vod__r.Description_vod__c : '');
            descriptionToTime.add(hasViewOrderFls && mcal.View_Order_vod__c != null ? String.valueOf(mcal.View_Order_vod__c) : '0');
            this.viewedSlides.add(descriptionToTime);
        }
        return this;
    }

    public VeevaCalendarEventBuilder location(String location, Boolean isChildAccountCall) {
        this.location = isChildAccountCall ? null : location;
        return this;
    }

    public VeevaCalendarEventBuilder location(String location) {
        this.location = location;
        return this;
    }

    public VeevaCalendarEventBuilder eventType(String eventType) {
        this.eventType = eventType;
        return this;
    }

    public VeevaCalendarEventBuilder programType(String programType) {
        this.programType = programType;
        return this;
    }

    public VeevaCalendarEventBuilder medicalEventType(String medicalEventType) {
        this.medicalEventType = medicalEventType;
        return this;
    }

    public VeevaCalendarEventBuilder duration(Integer duration) {
        this.duration = duration;
        return this;
    }

    public VeevaCalendarEventBuilder accountId(String accountId) {
        this.accountId = accountId;
        return this;
    }

    public VeevaCalendarEventBuilder callChannel(String callChannel) {
        this.callChannel = callChannel;
        return this;
    }

    public VeevaCalendarEventBuilder callChannelLabel(String callChannelLabel) {
        this.callChannelLabel = callChannelLabel;
        return this;
    }

    public VeevaCalendarEventBuilder status(String status) {
        this.status = status;
        return this;
    }

    public VeevaCalendarEventBuilder statusLabel(String statusLabel) {
        this.statusLabel = statusLabel;
        return this;
    }

    public VeevaCalendarEventBuilder parentAccount(String parentAccount) {
        this.parentAccount = parentAccount;
        return this;
    }

    public VeevaCalendarEventBuilder accountIdentifier(String acctIdentifier) {
        this.acctIdentifier = acctIdentifier;
        return this;
    }

    public VeevaCalendarEventBuilder owner(String owner) {
        this.owner = owner;
        return this;
    }

    public VeevaCalendarEventBuilder allDay(Boolean allDay) {
        this.allDay = allDay;
        return this;
    }

    public VeevaCalendarEventBuilder isSigned(Datetime signature) {
        this.isSigned = signature != null;
        return this;
    }

    public VeevaCalendarEventBuilder hasSampleCard(String sampleCard, String sampleSendCard) {
        this.hasSampleCard = sampleCard != null || sampleSendCard != null;
        return this;
    }

    public VeevaCalendarEventBuilder hasUnscheduledRemoteMeeting(String remoteMeetingId, Boolean remoteMeetingScheduled) {
        this.hasUnscheduledRemoteMeeting = Boolean.valueOf(!String.isBlank(remoteMeetingId) && !remoteMeetingScheduled);
        return this;
    }

    public VeevaCalendarEventBuilder unavailable(Boolean unavailable) {
        this.unavailable = unavailable;
        return this;
    }

    public VeevaCalendarEventBuilder sensitivity(String sensitivity) {
        this.sensitivity = sensitivity;
        return this;
    }

    public VeevaCalendarEventBuilder accountDoNotCall(Boolean accountDoNotCall) {
        this.accountDoNotCall = accountDoNotCall;
        return this;
    }

    public VeevaCalendarEventBuilder accountRecordType(String accountRecordType) {
        this.accountRecordType = accountRecordType;
        return this;
    }

    public VeevaCalendarEventBuilder resizable() {
        return this.resizable(null, null, null);
    }

    public VeevaCalendarEventBuilder resizable(Boolean enableSamplesOnSave, Boolean hasCallDatetime, Boolean hasCallDatetimeFLS) {
        if (this.objectType == 'Call2_vod__c') {
            Boolean draggable = this.status != 'Submitted_vod' && this.owner == null && !this.isSigned && !(this.hasSampleCard && enableSamplesOnSave && this.status == 'Saved_vod') && (hasCallDatetimeFLS || (!hasCallDatetimeFLS && !hasCallDatetime));
            this.draggable = draggable;
            this.resizable = draggable && !this.allDay && Datetime.valueOf(this.startDate).isSameDay(Datetime.valueOf(this.endDate));
        } else if (this.objectType == 'Event') {
            this.draggable = true;
            this.resizable = !this.allDay && Datetime.valueOf(this.startDate).isSameDay(Datetime.valueOf(this.endDate));
        } else {
            this.draggable = false;
            this.resizable = false;
        }
        return this;
    }

    public VeevaCalendarEventBuilder childAccountId(String childAccountId) {
        this.childAccountId = childAccountId;
        return this;
    }

    public VeevaCalendarEventBuilder remoteAttendees(VeevaRemoteMeetingData remoteMeetingInfo) {
        if (remoteMeetingInfo != null) {
            this.uninvitedRemoteAttendeeNumber = remoteMeetingInfo.getTotalAttendees() - remoteMeetingInfo.getInvitedAttendees();
            this.remoteAttendeeNumber = remoteMeetingInfo.getTotalAttendees();
        }
        return this;
    }
    
    public VeevaCalendarEventBuilder meetingType(String meetingType) {
        this.meetingType = meetingType;
        return this;
    }

    public VeevaCalendarEventBuilder meetingTypeLabel(String meetingTypeLabel) {
        this.meetingTypeLabel = meetingTypeLabel;
        return this;
    }

    public VeevaCalendarEventBuilder phone(String phone) {
        this.phone = phone;
        return this;
    }

    public VeevaCalendarEventBuilder emEventId(String emEventId) {
        this.emEventId = emEventId;
        return this;
    }

    public VeevaCalendarEventBuilder externalCalendarId(String externalCalendarId) {
        this.externalCalendarId = externalCalendarId;
        return this;
    }

    public VeevaCalendarEventBuilder eventTimes(SObject event, Map<String, SObjectField> fieldMap) {
        return eventTimes(event, fieldMap, null, null);
    }

    // set this.allDay, this.duration, this.startDate, this.endDate, this.eventDateTime
    public VeevaCalendarEventBuilder eventTimes(SObject event, Map<String, SObjectField> fieldMap, Integer weekendStart, Integer weekendEnd) {
        if (event instanceof Call2_vod__c) {
            Call2_vod__c call = (Call2_vod__c) event;
            Boolean allDay = isAllDayCall(call, fieldMap);

            setCallTimesAndDuration(call, allDay);
            allDay(allDay);
        } else if (event instanceof Time_Off_Territory_vod__c) {
            Time_Off_Territory_vod__c tot = (Time_Off_Territory_vod__c) event;
            String totType = getTimeOffTerritoryType(tot, fieldMap);

            setTimeOffTerritoryTimesAndDuration(tot, totType, fieldMap, weekendStart, weekendEnd);
            allDay(isAllDayTot(totType));
        } else if (event instanceof Medical_Event_vod__c) {
            Medical_Event_vod__c me = (Medical_Event_vod__c) event;
            Boolean userHasStartTimeEndTimeFLS = isFieldAccessible('Start_Time_vod__c', fieldMap) && isFieldAccessible('End_Time_vod__c', fieldMap);
            Boolean allDay = isAllDayMedicalEvent(me, userHasStartTimeEndTimeFLS);

            setMedicalEventTimesAndDuration(me, allDay, userHasStartTimeEndTimeFLS);
            allDay(allDay);
        } else if (event instanceof Event) {
            Event e = (Event) event;

            setCalendarEntryTimesAndDuration(e);
            allDay(e.IsAllDayEvent);
        } else if (event instanceof Multichannel_Activity_vod__c) {
            Multichannel_Activity_vod__c up = (Multichannel_Activity_vod__c) event;

            setUnassignedPresentationTimesAndDuration(up);
            allDay(false);
        } else if (event instanceof Unavailable_Time_vod__c) {
            Unavailable_Time_vod__c ut = (Unavailable_Time_vod__c) event;
            Boolean allDay = isAllDayUnavailableTime(ut);
            
            setUnavailableTimeTimesAndDuration(ut, allDay);
            allDay(allDay);
        } else if (event instanceof Meeting_Request_vod__c) {
            Meeting_Request_vod__c mr = (Meeting_Request_vod__c) event;
            setMeetingRequestTimesAndDuration(mr);
            allDay(false);
        } else if (event instanceof External_Calendar_Event_vod__c) {
            External_Calendar_Event_vod__c ee = (External_Calendar_Event_vod__c) event;

            setExternalEventTimesAndDuration(ee, ee.Is_All_Day_vod__c);
            allDay(ee.Is_All_Day_vod__c);
        }

        return this;
    }

    public static String getUrl(Id id) {
        return System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + id;
    }

    @TestVisible
    private static Integer getCallDurationWithMinimum(Call2_vod__c call, Integer minimum) {
            Integer duration = Integer.valueOf(call.Duration_vod__c);
            if (duration == null || duration < minimum) {
                duration = minimum;
            }
        return duration;
    }

    private static Boolean isAllDayCall(Call2_vod__c call, Map<String, SObjectField> callFields) {
        return !isFieldAccessible('Call_Datetime_vod__c', callFields) || call.Call_Datetime_vod__c == null;
    }

    private static Boolean isAllDayTot(String totType) {
        return new Set<String>{'invalid', 'All Day', '2 Days', '3 Days', '4 Days', '5 Days'}.contains(totType);
    }

    private static Boolean isAllDayMedicalEvent(Medical_Event_vod__c me, Boolean userHasStartTimeEndTimeFLS) {
        if (!userHasStartTimeEndTimeFLS || me.Start_Time_vod__c == null || me.End_Time_vod__c == null) {
            return true;
        }
        
        if (me.Start_Time_vod__c != null && me.End_Time_vod__c != null) {
            if (me.Start_Time_vod__c.hour() == 0 && me.Start_Time_vod__c.minute() == 0 && me.End_Time_vod__c.hour() == 0 && me.End_Time_vod__c.minute() == 0) {
                return true;
            }
        }

        return false;
    }

    private static Boolean isAllDayUnavailableTime(Unavailable_Time_vod__c ut) {
        Datetime startDatetime = ut.Start_Datetime_vod__c;
        Datetime endDatetime = ut.End_Datetime_vod__c;

        // all day format for Unavailable_Time_vod__c ex: Start_Datetime_vod = 2022-10-11T00:00:00.000Z and End_Datetime_vod =2022-10-12T00:00:00.000Z
        return (startDatetime.hour() == 0 && startDatetime.minute() == 0 && endDatetime.hour() == 0 && endDatetime.minute() == 0);
    }

    private static String getTimeOffTerritoryType(Time_Off_Territory_vod__c tot, Map<String, SObjectField> totFields) {
        return !isFieldAccessible('Time_vod__c', totFields) ? 'invalid' : tot.Time_vod__c;
    }

    private static Boolean isFieldAccessible(String fieldName, Map<String, SobjectField> objectFields) {
        return objectFields.get(fieldName) != null && objectFields.get(fieldName).getDescribe().isAccessible();
    }

    private void setCallTimesAndDuration(Call2_vod__c call, Boolean allDay) {
        this.duration = getCallDurationWithMinimum(call, 0);
        Integer nonMinDuration = Integer.valueOf(call.Duration_vod__c);
        Datetime startTime;
        if (allDay) {
            Date eventDate = call.Call_Date_vod__c;
            startTime = Datetime.newInstance(eventDate.year(), eventDate.month(), eventDate.day());
            this.eventDateTime = VeevaCalendarEvent.formatAllDayECE(eventDate, getCallDurationWithMinimum(call, 0));
        } else {
            startTime = call.Call_Datetime_vod__c;
            this.eventDateTime = VeevaCalendarEvent.formatHourly(startTime, nonMinDuration);
        }
        this.endDate = string.valueOf(startTime.addMinutes(this.duration));
        this.startDate = String.valueOf(startTime);
    }

    private void setTimeOffTerritoryTimesAndDuration(Time_Off_Territory_vod__c tot, String totType, Map<String, SObjectField> fieldMap, Integer weekendStart, Integer weekendEnd) {
        Datetime startTime = Datetime.newInstance(tot.Date_vod__c, Time.newInstance(0, 0, 0, 0));
        String timeStr = isFieldAccessible('Start_Time_vod__c', fieldMap) ? tot.Start_Time_vod__c : null;
        if (!String.isBlank(timeStr)) {
            Integer hour = Integer.valueOf(timeStr.substringBefore(':'));
            Integer minutes = Integer.valueOf(timeStr.substringAfter(':').substringBefore(' '));
            startTime = startTime.addHours(hour);
            startTime = startTime.addMinutes(minutes);
            if (timeStr.substringAfterLast(' ').equals('PM') && startTime.hour() != 12) {
                startTime = startTime.addHours(12);
            }
        } else {
            startTime = startTime.addHours(8); // if not specified, default start time is 8:00am
        }
        switch on totType {
            when null, 'invalid', 'All Day' {
                this.duration = (60 * (24 - startTime.hour())) - 1;
                this.endDate = String.valueOf(startTime.addMinutes(this.duration));
                this.eventDateTime = VeevaCalendarEvent.formatAllDay(startTime.date(), this.duration);
            }
            when 'Hourly' {
                Integer hourNum = Integer.valueOf(isFieldAccessible('Hours_vod__c', fieldMap) ? tot.Hours_vod__c : 1);
                this.duration = Integer.valueOf(60 * hourNum);
                this.endDate = String.valueOf(startTime.addMinutes(this.duration));
                this.eventDateTime = VeevaCalendarEvent.formatHourly(startTime, this.duration);
            } 
            when 'AM Off', 'PM Off' {
                this.duration = 60 * 4;
                startTime = tot.Time_vod__c.equals('PM Off') ? startTime.addHours(5) : startTime;
                this.endDate = String.valueOf(startTime.addMinutes(this.duration));
                this.eventDateTime = VeevaCalendarEvent.formatHourly(startTime, this.duration);
            }
            when '2 Days', '3 Days', '4 Days', '5 Days' {
                Object weekendSetting = VeevaCustomSettingsService.getVeevaSettings(new List<String>{'DISABLE_TOT_WEEKENDS_vod__c'}).get('DISABLE_TOT_WEEKENDS_vod__c');
                Boolean adjustTotEndDate = weekendSetting != null ? !Boolean.valueOf(weekendSetting) : false;
                Integer numOfDays = Integer.valueOf(tot.Time_vod__c.substringBefore(' Days'));
                Integer additionalDays = 0;
                if (adjustTotEndDate) {
                    Integer index = 0;
                    while (index < (numOfDays + additionalDays) && additionalDays < 2) {
                        Integer weekdayNumber = math.mod((Integer.valueOf(startTime.format('u')) + index), 7);
                        additionalDays += (weekdayNumber == weekendStart || weekdayNumber == weekendEnd) ? 1 : 0;
                        index++;
                    }                                      
                }
                this.duration = (60 * 24 * (numOfDays + additionalDays)) - ((60 * startTime.hour()) + startTime.minute() + 1);
                this.endDate = String.valueOf(startTime.addMinutes(this.duration));
                this.eventDateTime = VeevaCalendarEvent.formatAllDay(startTime.date(), this.duration);
            }
            when else {
                System.debug('Invalid/Nonexistent value for field Time_vod__c');
            }
        }
        this.startDate = String.valueOf(startTime);
    }

    private void setUnavailableTimeTimesAndDuration(Unavailable_Time_vod__c ut, Boolean allDay){
        Datetime startDateTime = ut.Start_Datetime_vod__c;
        Datetime endDateTime = ut.End_Datetime_vod__c;
        if (allDay) {
            endDateTime = endDateTime.addSeconds(-1);
        }
    
        this.duration = Integer.valueOf((endDateTime.getTime() - startDateTime.getTime()) / (1000 * 60));
        this.startDate = String.valueOf(startDateTime);
        this.endDate = string.valueOf(this.duration >= 30 ? endDateTime : startDateTime.addMinutes(30));

        if (allDay) {
            this.eventDateTime = VeevaCalendarEvent.formatAllDay(startDateTime.date(), this.duration);
        } else {
            this.eventDateTime = VeevaCalendarEvent.formatHourly(startDateTime, this.duration);
        }
    }
    
    private void setMedicalEventTimesAndDuration(Medical_Event_vod__c me, Boolean allDay, Boolean userHasStartTimeEndTimeFLS) {
        Datetime startDateTime;
        Datetime endDateTime;
        if (userHasStartTimeEndTimeFLS) {
            startDateTime = me.Start_Time_vod__c;
            endDateTime = me.End_Time_vod__c;
        }

        if (startDateTime != null && endDateTime != null && startDateTime.isSameDay(endDateTime)) {
            this.duration = (60 * (endDateTime.hour() - startDateTime.hour())) + (endDateTime.minute() - startDateTime.minute());
        } else {
            if (startDateTime == null) {
                Date eventDate = me.Start_Date_vod__c;
                startDateTime = Datetime.newInstance(eventDate.year(), eventDate.month(), eventDate.day());
            }
            if (endDateTime == null && me.End_Date_vod__c == null) {
                Date eventDate = me.Start_Date_vod__c;
                endDateTime = eventDate != null ? Datetime.newInstance(eventDate.year(), eventDate.month(), eventDate.day(), 23, 59, 59) : Datetime.newInstance(startDateTime.year(), startDateTime.month(), startDateTime.day(), 23, 59, 59);
            } else if (endDateTime == null) {
                Date eventDateEnd = me.End_Date_vod__c;
                endDateTime = Datetime.newInstance(eventDateEnd.year(), eventDateEnd.month(), eventDateEnd.day()+1);
                endDateTime = endDateTime.addMinutes(-1);
            }
            this.duration = Integer.valueOf((endDateTime.getTime() - startDateTime.getTime()) / (1000 * 60));
        }

        this.startDate = String.valueOf(startDateTime);
        this.endDate = string.valueOf(this.duration >= 30 ? endDateTime : startDateTime.addMinutes(30));
        if (allDay) {
            if (startDateTime.hour() == 0 && startDateTime.minute() == 0 && endDateTime.hour() == 0 && endDateTime.minute() == 0) {
                Integer days = duration / DAY_IN_MINUTES;
                this.duration = 24 * 60 * days - 1;
            }
            this.eventDateTime = VeevaCalendarEvent.formatAllDay(startDateTime.date(), this.duration);
        } else {
            this.eventDateTime = VeevaCalendarEvent.formatHourly(startDateTime, this.duration);
        }
    }

    private void setCalendarEntryTimesAndDuration(Event e) {
        Datetime startDateTime = e.StartDateTime;
        Datetime endDateTime = e.EndDateTime;
        this.duration = e.DurationInMinutes;
        if (e.isAllDayEvent) {
            startDateTime = Datetime.newInstanceGmt(startDateTime.yearGmt(), startDateTime.monthGmt(), startDateTime.dayGmt(), 0, 0, 0);
            endDateTime = Datetime.newInstanceGmt(endDateTime.yearGmt(), endDateTime.monthGmt(), endDateTime.dayGmt()+1, 0, 0, 0);
            this.eventDateTime = VeevaCalendarEvent.formatAllDay(startDateTime.dateGmt(), this.duration - 1);
            this.startDate = String.valueOfGmt(startDateTime);
            this.endDate = String.valueOfGmt(endDateTime);
        } else {
            this.eventDateTime = VeevaCalendarEvent.formatHourly(startDateTime, this.duration);
            this.startDate = String.valueOf(startDateTime);
            this.endDate = String.valueOf(endDateTime);
        }
    }

    private void setUnassignedPresentationTimesAndDuration(Multichannel_Activity_vod__c up) {
        this.duration = 30; // Total_duration_vod__c is ignored, all UP events display as 30 min in week view
        Datetime startDateTime = up.Start_DateTime_vod__c;
        Datetime endDateTime = startDateTime.addMinutes(this.duration);

        this.eventDateTime = VeevaCalendarEvent.formatHourly(startDateTime, this.duration);
        this.startDate = String.valueOf(startDateTime);
        this.endDate = String.valueOf(endDateTime);
    }

    private void setMeetingRequestTimesAndDuration(Meeting_Request_vod__c mr) {
        Datetime startDateTime = mr.Start_DateTime_vod__c;
        Integer intDuration = mr.Duration_vod__c != null ? mr.Duration_vod__c.intValue() : 30;
        this.duration = intDuration;
        this.startDate = String.valueOf(startDateTime);
        this.endDate = String.valueOf(startDateTime.addMinutes(intDuration));
        this.eventDateTime = VeevaCalendarEvent.formatHourly(startDateTime, intDuration);
    }

    private void setExternalEventTimesAndDuration(External_Calendar_Event_vod__c ee, Boolean allDay) {
        Datetime startDateTime = ee.Start_Datetime_vod__c;
        Datetime endDateTime = ee.End_Datetime_vod__c;
        this.startDate = allDay ? String.valueOfGmt(startDateTime) : String.valueOf(startDateTime);
        this.endDate = allDay ? String.valueOfGmt(endDateTime) : String.valueOf(endDateTime);
        Integer duration = Integer.valueOf((endDateTime.getTime() - startDateTime.getTime()) / (1000 * 60));
        if (allDay) {
            this.eventDateTime = VeevaCalendarEvent.formatAllDayECE(startDateTime.dateGMT(), duration);
        } else {
            this.eventDateTime = VeevaCalendarEvent.formatHourly(startDateTime, duration);
        }
        this.duration = duration < 30 ? 30 : duration;
    }
}