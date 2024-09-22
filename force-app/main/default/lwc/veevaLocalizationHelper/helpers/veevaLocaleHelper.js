import LOCALE from '@salesforce/i18n/locale';
import LANGUAGE from '@salesforce/i18n/lang';

const LOCALE_SEPARATOR = '-';

export default class VeevaLocaleHelper {
  static getUserLanguageLocale() {
    const langSubstring = LANGUAGE.split(LOCALE_SEPARATOR)[0];

    const splitLocale = LOCALE.split(LOCALE_SEPARATOR);
    const localeSubstring = splitLocale[1] ?? splitLocale[0];

    return `${langSubstring}${LOCALE_SEPARATOR}${localeSubstring}`;
  }
}