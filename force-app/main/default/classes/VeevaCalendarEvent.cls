@JsonAccess(deserializable='always')
public with sharing class VeevaCalendarEvent {
    private static final Integer DAY_IN_MINUTES = 1440;

    @AuraEnabled public String id { get; private set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String eventType { get; set; }
    @AuraEnabled public String startDate { get; private set; }
    @AuraEnabled public String endDate { get; private set; }
    @AuraEnabled public Boolean allDay { get; private set; }
    @AuraEnabled public String accountUrl { get; private set; }
    @AuraEnabled public String accountId { get; private set; }
    @AuraEnabled public String address { get; private set; }
    @AuraEnabled public String description { get; private set; }
    @AuraEnabled public String status { get; private set; }
    @AuraEnabled public String statusLabel { get; private set; }
    @AuraEnabled public String acctIdentifier { get; private set; }
    @AuraEnabled public String callChannel {get; private set; }
    @AuraEnabled public String callChannelLabel {get; private set; }
    @AuraEnabled public String popoverCallChannelText {get; private set; }
    @AuraEnabled public String recordType {get; private set; }
    @AuraEnabled public String objectType {get; private set; }
    @AuraEnabled public String programType {get; private set; }
    @AuraEnabled public String medicalEventType {get; private set; }
    @AuraEnabled public String location {get; private set; }
    @AuraEnabled public String parentAccount {get; private set; }
    @AuraEnabled public String owner {get; private set; }
    @AuraEnabled public String ownerUrl {get; private set; }
    @AuraEnabled public String ownerId {get; private set; }
    @AuraEnabled public Integer duration { get; private set; }
    @AuraEnabled public String durationUnit { get; private set; }
    @AuraEnabled public Integer childCallNumber { get; private set; }
    @AuraEnabled public Boolean isSigned {get; private set; }
    @AuraEnabled public Boolean hasSampleCard {get; private set; }
    @AuraEnabled public Boolean hasUnscheduledRemoteMeeting {get; private set; }
    @AuraEnabled public Integer uninvitedRemoteAttendeeNumber {get; private set; }
    @AuraEnabled public Integer remoteAttendeeNumber {get; private set; }
    @AuraEnabled public List<String> childrenEvents { get; private set; }
    @AuraEnabled public String eventDateTime { get; private set; }
    @AuraEnabled public List<List<String>> viewedSlides { get; private set; }
    @AuraEnabled public String meetingTypeLabel { get; private set; }
    @AuraEnabled public String meetingType { get; private set; }
    @AuraEnabled public String phone { get; private set; }
    @AuraEnabled public Boolean hasKeyMessageDescriptionFls { get; private set; }
    @AuraEnabled public Boolean unavailable { get; private set; }
    @AuraEnabled public Boolean draggable { get; private set; }
    @AuraEnabled public Boolean resizable { get; private set; }
    @AuraEnabled public String emEventId { get; private set; }
    @AuraEnabled public String externalCalendarId { get; private set; }
    @AuraEnabled public Boolean hasCall { get; private set; }
    @AuraEnabled public String childAccountId { get; private set; }
    @AuraEnabled public String sensitivity {get; private set; }
    @AuraEnabled public Boolean accountDoNotCall {get; private set; }
    @AuraEnabled public String accountRecordType {get; private set; }

    public VeevaCalendarEvent(VeevaCalendarEventBuilder builder) {
        this.name = builder.name;
        this.eventType = builder.eventType;
        this.startDate = builder.startDate; 
        this.endDate = builder.endDate; 
        this.allDay = builder.allDay; 
        this.accountUrl = builder.accountUrl;
        this.accountId = builder.accountId; 
        this.address = builder.address; 
        this.description = builder.description; 
        this.status = builder.status;
        this.statusLabel = builder.statusLabel;
        this.acctIdentifier = builder.acctIdentifier; 
        this.id = builder.id; 
        this.callChannel = builder.callChannel;
        this.callChannelLabel = builder.callChannelLabel;
        this.recordType = builder.recordType;
        this.objectType = builder.objectType;
        this.programType = builder.programType;
        this.medicalEventType = builder.medicalEventType;
        this.location = builder.location;
        this.parentAccount = builder.parentAccount;
        this.owner = builder.owner;
        this.ownerUrl = builder.ownerUrl;
        this.ownerId = builder.ownerId;
        this.durationUnit = 'm';
        this.duration = builder.duration; 
        this.childCallNumber = builder.childCallNumber; 
        this.isSigned = builder.isSigned;
        this.hasSampleCard = builder.hasSampleCard;
        this.hasUnscheduledRemoteMeeting = builder.hasUnscheduledRemoteMeeting;
        this.uninvitedRemoteAttendeeNumber = builder.uninvitedRemoteAttendeeNumber;
        this.remoteAttendeeNumber = builder.remoteAttendeeNumber;
        this.childrenEvents = builder.children; 
        this.eventDateTime = builder.eventDateTime;
        this.viewedSlides = builder.viewedSlides;
        this.meetingTypeLabel = builder.meetingTypeLabel;
        this.meetingType = builder.meetingType;
        this.phone = builder.phone;
        this.hasKeyMessageDescriptionFls = builder.hasKeyMessageDescriptionFls;
        this.unavailable = builder.unavailable;
        this.childAccountId = builder.childAccountId;
        this.emEventId = builder.emEventId;
        this.externalCalendarId = builder.externalCalendarId;
        this.hasCall = builder.hasCall;
        this.resizable = builder.resizable;
        this.draggable = builder.draggable;
        this.sensitivity = builder.sensitivity;
        this.accountDoNotCall = builder.accountDoNotCall;
        this.accountRecordType = builder.accountRecordType;
    }

    public Boolean equals(Object o) {
        if (this === o) {
            return true;
        } else if (o == null || !(o instanceof VeevaCalendarEvent)) {
            return false;
        } 
        VeevaCalendarEvent other = (VeevaCalendarEvent) o;
        return (this.id == null && other.id == null) || this.id.equals(other.id);
    }

    public Integer hashCode() {
        return this.startDate.hashCode() * this.id.hashCode();
    }

    @AuraEnabled
    public static String formatAllDay(Date startDate, Integer duration) {
        Integer days = duration / DAY_IN_MINUTES;
        String formattedDate = startDate.format();
        if(duration > DAY_IN_MINUTES) {
            formattedDate += ' - ' + startDate.addDays(days).format();
        }
        return formattedDate;
    }

    @AuraEnabled
    public static String formatAllDayECE(Date startDate, Integer duration) {
        Integer days = duration / DAY_IN_MINUTES;
        String formattedDate = startDate.format();
        if(duration > DAY_IN_MINUTES) {
            formattedDate += ' - ' + startDate.addDays(days - 1).format(); // e.g. if all day event starts 3/24T00:00 and days = 2, then end date should be 3/25, not 3/26.
        }
        return formattedDate;
    }

    private static Boolean localeFormatEndsWithDate(Datetime givenDateTime) {
        String formattedDateTime = givenDateTime.format();
        String formattedDate = givenDateTime.date().format();
        return formattedDateTime.endsWithIgnoreCase(formattedDate);
    }

    @AuraEnabled
    public static String formatHourly(DateTime startDateTime, Integer duration) {
        String startFormatted = startDateTime.format();
        if (duration == null || duration <= 0) {
            return startFormatted;
        }
        DateTime endDateTime = startDateTime.addMinutes(duration);
        String endFormatted = endDateTime.format();
        if (endDateTime.isSameDay(startDateTime) && localeFormatEndsWithDate(startDateTime)) {
            startFormatted = startFormatted.remove(startDateTime.date().format()).trim().removeEnd('.').removeEnd(',').trim();
        } else if (endDateTime.isSameDay(startDateTime)) {
            endFormatted = endFormatted.remove(endDateTime.date().format()).removeStart('.').removeStart(',').trim();
        }
        return startFormatted + ' - ' + endFormatted;
    }
}