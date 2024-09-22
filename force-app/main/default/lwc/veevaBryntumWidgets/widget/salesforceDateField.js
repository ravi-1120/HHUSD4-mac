import LOCALE from '@salesforce/i18n/locale';

export default function loadSalesforceDateFieldWidget(bryntumNamespace) {
  // Do not define and initialize SalesforceDateField more than once
  if (bryntumNamespace.SalesforceDateField) {
    return;
  }

  bryntumNamespace.SalesforceDateField = class SalesforceDateField extends bryntumNamespace.DateField {
    static get $name() {
      return 'SalesforceDateField';
    }

    static get type() {
      return 'salesforcedate';
    }

    // Statically define format to use based on User's Locale
    get format() {
      const dateParts = new Intl.DateTimeFormat(LOCALE, {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
      }).formatToParts();
      const partsMapping = {
        month: 'MM',
        day: 'DD',
        year: 'YYYY',
      };
      return dateParts.map(({ type, value }) => partsMapping[type] ?? value).join('');
    }

    // Do not allow format to be updated
    // eslint-disable-next-line no-empty-function
    set format(value) {}
  };
  bryntumNamespace.SalesforceDateField.initClass();
}