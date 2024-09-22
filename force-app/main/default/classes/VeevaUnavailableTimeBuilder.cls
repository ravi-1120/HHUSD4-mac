public class VeevaUnavailableTimeBuilder {
    private Unavailable_Time_vod__c ut;

    public VeevaUnavailableTimeBuilder() {
        this.ut = new Unavailable_Time_vod__c();
    }

    public VeevaUnavailableTimeBuilder setId(ID recordId) {
        this.ut.Id = recordId;
        return this;
    }

    public VeevaUnavailableTimeBuilder setOwnerId(ID ownerId) {
        this.ut.ownerId = ownerId;
        return this;
    }

    public VeevaUnavailableTimeBuilder setCall(ID callId) {
        this.ut.Call2_vod__c = callId;
        return this;
    }

    public VeevaUnavailableTimeBuilder setTimeOffTerritory(ID timeOffTerritoryId) {
        this.ut.Time_Off_Territory_vod__c = timeOffTerritoryId;
        return this;
    }

    public VeevaUnavailableTimeBuilder setStartAndEndDates(String locale, Boolean disableTotWeekends, Date startDate, String timescale, String startTime, Integer hoursOff) {
        List<Datetime> adjustedDates = VeevaUnavailableTimeBuilder.calculateStartAndEndDates(locale, disableTotWeekends, startDate, timescale, startTime, hoursOff);
        this.ut.Start_Datetime_vod__c = adjustedDates.get(0);
        this.ut.End_Datetime_vod__c = adjustedDates.get(1);
        return this;
    }

    public VeevaUnavailableTimeBuilder setStartAndEndDates(Datetime startDatetime, Integer duration) {
        if (startDatetime == null) {
            Date today = System.today();
            startDatetime = Datetime.newInstance(today.year(), today.month(), today.day());
        }
        duration = duration == null ? 30 : duration;
        this.ut.Start_Datetime_vod__c = startDatetime;
        this.ut.End_Datetime_vod__c = startDatetime.addMinutes(duration);
        return this;
    }

    public static List<Datetime> calculateStartAndEndDates(String locale, Boolean disableTotWeekends, Date startDate, String timescale, String startTime, Integer hoursOff) {
        Datetime adjustedStart;
        Datetime adjustedEnd;

        if (timescale == 'AM Off') {
            adjustedStart = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 8, 0, 0);
            adjustedEnd = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 12, 0, 0);
        } else if (timescale == 'PM Off') {
            adjustedStart = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 13, 0, 0);
            adjustedEnd = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 17, 0, 0);
        } else if (timescale == 'Hourly') {
            // Start time example: '8:30 AM'
            List<String> startTimeParts = startTime.split(':| ');
            Integer startTimeHour = Integer.valueOf(startTimeParts.get(0));
            Integer startTimeMinutes = Integer.valueOf(startTimeParts.get(1));
            String amOrPm = startTimeParts.get(2);
            
            if (amOrPm == 'PM' && startTimeHour != 12) {
                startTimeHour += 12;
            }

            adjustedStart = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), startTimeHour, startTimeMinutes, 0);
            adjustedEnd = adjustedStart.addHours(hoursOff == null ? 1 : hoursOff); // ipad defaults to 1hr if no Hours_vod specified
        } else {
            adjustedStart = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
            if (timescale == 'All Day') {
                adjustedEnd = adjustedStart.addDays(1);
            } else if (timescale == '2 Days') {
                adjustedEnd = adjustedStart.addDays(2);            
            } else if (timescale == '3 Days') {
                adjustedEnd = adjustedStart.addDays(3);
            } else if (timescale == '4 Days') {
                adjustedEnd = adjustedStart.addDays(4);
            } else if (timescale == '5 Days') {
                adjustedEnd = adjustedStart.addDays(5);
            }

            List<String> localeParts = locale.split('_'); // example: en_US
            String localeSuffix = localeParts.size() > 1 ? localeParts.get(1) : '001'; // 001 is default locale
            if (!disableTotWeekends && VeevaUnavailableTimeBuilder.datetimesSpanWeekend(localeSuffix, adjustedStart, adjustedEnd)) {
                Integer weekendLength = VeevaCalendarLocaleManager.getWeekendLength(localeSuffix);
                Integer daysToAdd = weekendLength;
                Integer startDatetimeInt = Integer.valueOf(adjustedStart.format('u'));
                Integer weekendEndInt = VeevaCalendarLocaleManager.getWeekendEndInt(localeSuffix);

                if (timescale == 'All Day') {
                    daysToAdd = 0;
                } else if (weekendLength > 1 && (startDatetimeInt == weekendEndInt)) {
                    daysToAdd -= 1;
                }
                adjustedEnd = adjustedEnd.addDays(daysToAdd);
            }
        }
        return new List<Datetime>{adjustedStart, adjustedEnd};
    }

    private static Boolean datetimesSpanWeekend(String locale, Datetime startDatetime, Datetime endDatetime) {
        Integer weekendStartInt = VeevaCalendarLocaleManager.getWeekendStartInt(locale);
        Integer weekendEndInt = VeevaCalendarLocaleManager.getWeekendEndInt(locale);
        Integer startDatetimeInt = Integer.valueOf(startDatetime.format('u'));
        Integer endDatetimeInt = Integer.valueOf(endDatetime.format('u'));
        // A Time Off Territory cannot span more than 5 days
        return VeevaCalendarLocaleManager.isWeekendDay(locale, startDatetime)
            || (VeevaCalendarLocaleManager.isWeekendDay(locale, endDatetime) && endDatetimeInt != weekendStartInt)
            || (startDatetimeInt <= weekendStartInt && weekendEndInt <= endDatetimeInt) 
            || (endDatetimeInt < startDatetimeInt && startDatetimeInt <= weekendStartInt);
    }

    public Unavailable_Time_vod__c build() {
        return this.ut;
    }
}