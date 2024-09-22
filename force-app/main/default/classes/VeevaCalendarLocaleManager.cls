public class VeevaCalendarLocaleManager {
    /*
    * The locale-to-weekend-day maps below is JSON Data from the Unicode CLDR Project.
    * This is taken from the module found at https://github.com/unicode-org/cldr-json.
    * This locale-related information is unlikely to change often, but does still require maintaining.
    * Refer to ICU CLDR locale data for any changes in work weeks/weekends by locale.
    */
    private static final Map<String, String> LOCALE_TO_WEEKEND_START = new Map<String, String>{
        '001' => 'sat',
        'AE' => 'fri',
        'AF' => 'thu',
        'BH' => 'fri',
        'DZ' => 'fri',
        'EG' => 'fri',
        'IL' => 'fri',
        'IN' => 'sun',
        'IQ' => 'fri',
        'IR' => 'fri',
        'JO' => 'fri',
        'KW' => 'fri',
        'LY' => 'fri',
        'OM' => 'fri',
        'QA' => 'fri',
        'SA' => 'fri',
        'SD' => 'fri',
        'SY' => 'fri',
        'UG' => 'sun',
        'YE' => 'fri'
    };

    private static final Map<String, String> LOCALE_TO_WEEKEND_END = new Map<String, String>{
        '001' => 'sun',
        'AE' => 'sat',
        'AF' => 'fri',
        'BH' => 'sat',
        'DZ' => 'sat',
        'EG' => 'sat',
        'IL' => 'sat',
        'IQ' => 'sat',
        'IR' => 'fri',
        'JO' => 'sat',
        'KW' => 'sat',
        'LY' => 'sat',
        'OM' => 'sat',
        'QA' => 'sat',
        'SA' => 'sat',
        'SD' => 'sat',
        'SY' => 'sat',
        'YE' => 'sat'
    };

    private static final String DEFAULT_LOCALE_KEY = '001';

    private static final Map<String, Integer> WEEKDAY_TO_INTEGER = new Map<String, Integer>{
        'mon' => 1,
        'tue' => 2,
        'wed' => 3,
        'thu' => 4,
        'fri' => 5,
        'sat' => 6,
        'sun' => 7
    };

    public static String getWeekendStart(String locale) {
        String weekendStart = LOCALE_TO_WEEKEND_START.get(locale);
        return (weekendStart != null ? weekendStart : LOCALE_TO_WEEKEND_START.get(DEFAULT_LOCALE_KEY));
    }

    public static String getWeekendEnd(String locale) {
        String weekendEnd = LOCALE_TO_WEEKEND_END.get(locale);
        return (weekendEnd != null ? weekendEnd : LOCALE_TO_WEEKEND_END.get(DEFAULT_LOCALE_KEY));
    }

    public static Integer getWeekendStartInt(String locale) {
        return WEEKDAY_TO_INTEGER.get(getWeekendStart(locale));
    }

    public static Integer getWeekendEndInt(String locale) {
        return WEEKDAY_TO_INTEGER.get(getWeekendEnd(locale));
    }

    public static Integer getWeekendLength(String locale) {
        Integer weekendStart = WEEKDAY_TO_INTEGER.get(getWeekendStart(locale));
        Integer weekendEnd = WEEKDAY_TO_INTEGER.get(getWeekendEnd(locale));

        return weekendEnd - weekendStart + 1;
    }

    public static Boolean isWeekendDay(String locale, Datetime refDatetime) {
        Integer weekendStart = WEEKDAY_TO_INTEGER.get(getWeekendStart(locale));
        Integer weekendEnd = WEEKDAY_TO_INTEGER.get(getWeekendEnd(locale));
        Integer weekdayInt = Integer.valueOf(refDatetime.format('u'));

        return (weekendStart <= weekdayInt) && (weekdayInt <= weekendEnd);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getWeekend(String locale){
        return new Map<String, String>{
            'weekendStart' => getWeekendStart(locale),
            'weekendEnd' => getWeekendEnd(locale)
        };
    }
}