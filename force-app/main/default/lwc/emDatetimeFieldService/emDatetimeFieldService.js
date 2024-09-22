import EmEventConstant from 'c/emEventConstant';
import TIME_ZONE from '@salesforce/i18n/timeZone';

const BASE_START_TIME = '12:00:00.000Z';
const BASE_END_TIME = '13:00:00.000Z';
export default class EmDatetimeFieldService {
  _isTimeFieldSet = {};

  getOverriddenTime(fieldName, value, source) {
    let newDateTime = value;
    if (value !== null && !this._isTimeFieldSet[fieldName]) {
      let offset;
      // legacy fields are normalized to User's timezone, local datetime fields are in UTC
      if (this.isLegacyField(fieldName)) {
        offset = this.getTzOffset(value);
        newDateTime = this.addTzOffset(value, offset);
      }
      newDateTime = newDateTime.split('T');
      if (fieldName === EmEventConstant.ZVOD_END_TIME || fieldName === EmEventConstant.END_TIME) {
        newDateTime[1] = BASE_END_TIME;
      } else {
        newDateTime[1] = BASE_START_TIME;
      }
      newDateTime = newDateTime.join('T');
      if (this.isLegacyField(fieldName)) {
        newDateTime = this.addTzOffset(newDateTime, -1 * offset);
      }
      this._isTimeFieldSet[fieldName] = true;
    } else if (source === 'UndoClick') {
      this._isTimeFieldSet[fieldName] = false;
    } else if (!this._isTimeFieldSet[fieldName]) {
      this._isTimeFieldSet[fieldName] = true;
    }
    return newDateTime;
  }

  isLegacyField(fieldName) {
    return fieldName === EmEventConstant.START_TIME || fieldName === EmEventConstant.END_TIME;
  }

  addTzOffset(dateTimeStr, offset) {
    const dateTimeObj = new Date(dateTimeStr);
    const offsetDatetime = new Date(dateTimeObj.getTime() + offset);
    return offsetDatetime.toISOString();
  }

  getTzOffset(dateTimeStr) {
    const dateTimeObj = new Date(dateTimeStr);
    const utcDate = new Date(dateTimeObj.toLocaleString('en-US', { timeZone: 'UTC' }));
    const tzDate = new Date(dateTimeObj.toLocaleString('en-US', { timeZone: TIME_ZONE }));
    return tzDate.getTime() - utcDate.getTime();
  }
}