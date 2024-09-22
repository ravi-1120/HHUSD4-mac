public inherited sharing class VeevaDateValidationHelper {
    // Returns true iff startDate and endDate are both non-null or are both null. In other words, returns false if only one value is populated.
    public static boolean areStartDateAndEndDatePopulatedOrNull(Date startDate, Date endDate) {
        return (startDate == null && endDate == null) || (startDate != null && endDate != null);
    }

    // Returns true iff all arguments are non-null or if all are null.
    public static boolean areStartDateTimeAndEndDateTimePopulatedOrNull(Date startDate, Time startTime, Date endDate, Time endTime) {
        return (startDate == null && startTime == null && endDate == null && endTime == null)
            || (startDate != null && startTime != null && endDate != null && endTime != null);
    }

    // Returns true if startDate is earlier than endDate, or if both fields are null.
    public static boolean areStartDateAndEndDateValid(Date startDate, Date endDate) {
        return (startDate == null && endDate == null) || startDate < endDate;
    }

    // Returns true if startDate + startTime is earlier than endDate + endTime, or if all fields are null.
    public static boolean areStartDateTimeAndEndDateTimeValid(Date startDate, Time startTime, Date endDate, Time endTime) {
        return (startDate == null && startTime == null && endDate == null && endTime == null)
            || (DateTime.newInstance(startDate, startTime) < DateTime.newInstance(endDate, endTime));
    }
}