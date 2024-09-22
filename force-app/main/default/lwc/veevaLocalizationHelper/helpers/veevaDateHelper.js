import LOCALE from '@salesforce/i18n/locale';
import LANGUAGE from '@salesforce/i18n/lang';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import getWeekend from '@salesforce/apex/VeevaCalendarLocaleManager.getWeekend';
import FIRSTDAYOFWEEK from '@salesforce/i18n/firstDayOfWeek';
import VeevaLocaleHelper from './veevaLocaleHelper';

const AM_DATETIME = new Date(2000, 0, 1, 1);
const PM_DATETIME = new Date(2000, 0, 1, 13);
const WEEKDAYS_MAPPING = {
  mon: 1,
  tue: 2,
  wed: 3,
  thu: 4,
  fri: 5,
  sat: 6,
  sun: 0,
};

export default class VeevaDateHelper {
  static format(date, sfFieldType) {
    switch (sfFieldType?.toLowerCase()) {
      case 'datetime':
        return VeevaDateHelper.formatDateTime(date);
      case 'time':
        return VeevaDateHelper.formatTime(date);
      default:
        return VeevaDateHelper.formatDate(date);
    }
  }

  static formatDate(date, timeZone) {
    const formatOptions = { month: 'numeric', day: 'numeric', year: 'numeric', timeZone };
    return new Intl.DateTimeFormat(LOCALE, formatOptions).format(date);
  }

  static formatDateTime(date, timeZone = TIME_ZONE) {
    const formatOptions = { month: 'numeric', day: 'numeric', year: 'numeric', hour: 'numeric', minute: 'numeric', timeZone };
    return VeevaDateHelper._formatTime(date, formatOptions);
  }

  static formatTime(date) {
    const formatOptions = { timeStyle: 'short' };
    return VeevaDateHelper._formatTime(date, formatOptions);
  }

  static formatMonthDay(date) {
    const formatOptions = { month: 'numeric', day: 'numeric' };
    return VeevaDateHelper._formatTime(date, formatOptions);
  }

  static formatDateRange(date1, date2) {
    const userLangLocale = VeevaLocaleHelper.getUserLanguageLocale();

    const dateParts = Intl.DateTimeFormat(LANGUAGE, { year: 'numeric', month: 'long', day: 'numeric' }).formatToParts(date1);
    const dateRangeStr = Intl.DateTimeFormat(userLangLocale, { year: 'numeric', month: 'long', day: 'numeric' }).formatRange(date1, date2);

    if (dateParts.filter(part => !dateRangeStr.includes(part.value)).length > 0) {
      const startDate = Intl.DateTimeFormat(LANGUAGE, { year: 'numeric', month: 'long', day: 'numeric' }).format(date1);
      const endDate = Intl.DateTimeFormat(LANGUAGE, { year: 'numeric', month: 'long', day: 'numeric' }).format(date2);
      return `${startDate} - ${endDate}`;
    }
    return Intl.DateTimeFormat(userLangLocale, { year: 'numeric', month: 'long', day: 'numeric' }).formatRange(date1, date2);
  }

  static getMeridiem(beforeNoon = true) {
    const dateTime = beforeNoon ? AM_DATETIME : PM_DATETIME;
    const languageParts = Intl.DateTimeFormat(LANGUAGE, { timeStyle: 'short' }).formatToParts(dateTime);
    const langDayPeriod = languageParts.filter(part => part.type === 'dayPeriod');
    if (langDayPeriod.length > 0 && langDayPeriod[0].value) {
      return langDayPeriod[0].value;
    }
    return null;
  }

  static getMeridiemPlaceHolderForDateFormatString() {
    const meridiem = VeevaDateHelper.getMeridiem(true);
    let meridiemStr = 'a'; // if language does not capitalize am/pm
    if (meridiem) {
      if (!meridiem.toLowerCase().includes('a') && !meridiem.toLowerCase().includes('m')) {
        meridiemStr = meridiem; // if language does not use latin characters, but does display a meridiem
      } else if (meridiem === meridiem.toUpperCase()) {
        meridiemStr = 'A'; // if language capitalizes AM/PM
      }
    }
    return meridiemStr;
  }

  static async getWeekendDays() {
    let locale = LOCALE;
    if (LOCALE.split('-').length > 1) {
        locale = LOCALE.split('-')[1].slice(-2).toUpperCase();
    } else if(LOCALE.split('-').length === 1) {
        locale = LOCALE.slice(-2).toUpperCase();
    }
    const weekend = await getWeekend({ locale });
    return [WEEKDAYS_MAPPING[weekend.weekendStart], WEEKDAYS_MAPPING[weekend.weekendEnd]];
  }

  static _formatTime(dateTime, formatOptions) {
    const localeParts = new Intl.DateTimeFormat(LOCALE, formatOptions).formatToParts(dateTime);
    const langParts = new Intl.DateTimeFormat(LANGUAGE, formatOptions).formatToParts(dateTime);
    const langDayPeriod = langParts.filter(part => part.type === 'dayPeriod');
    let formattedTime = '';
    for (const part of localeParts) {
      if (langDayPeriod?.length > 0 && part.type === 'dayPeriod') {
        formattedTime += langDayPeriod[0].value;
      } else {
        formattedTime += part.value;
      }
    }
    return formattedTime;
  }

  /**
   * Get the first visible calendar date for a date's week
   * @param {Date} date date 
   * @param {String} firstDayOfWeek first day of week
   * @returns {Date} the first date for the date params week
   */
  static getFirstVisibleDateOfWeek(date, firstDayOfWeek) {
    const resultDate = new Date(date);
    const firstDayDiff = Math.abs(resultDate.getDay() - firstDayOfWeek);
    const firstDayOffset = resultDate.getDay() >= firstDayOfWeek ? 0 - firstDayDiff : firstDayDiff - 7;
    resultDate.setDate(resultDate.getDate() + firstDayOffset);
    return resultDate;
  }

  /**
   * Get a date for a day of the week
   * @param {Date} date the selected calendar date 
   * @param {number} dayOfWeek day of the week
   * @param {number} previewOnDay if by day selected in call cycles tab, the day that is being shown. empty if not selected.
   * @returns {Date} the start date for the call cycle entry
   */
  static getDateForWeekDay(date, dayOfWeek, previewOnDay) {
    const targetDayOfWeek = previewOnDay === 0 ? 0 : previewOnDay || dayOfWeek;
    const dayOffset = ((FIRSTDAYOFWEEK - 1) > targetDayOfWeek) ? targetDayOfWeek + (7 - (FIRSTDAYOFWEEK -1)) % 7 :
        (targetDayOfWeek - (FIRSTDAYOFWEEK - 1)) % 7;
    const firstWeekDay = this.getFirstVisibleDateOfWeek(date, FIRSTDAYOFWEEK - 1);
    const callStartDate = new Date(firstWeekDay);
    callStartDate.setDate(callStartDate.getDate() + dayOffset);
    return callStartDate;
  }
}