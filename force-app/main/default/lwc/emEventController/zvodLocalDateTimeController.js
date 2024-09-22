import EmEventConstant from 'c/emEventConstant';
import EmDatetimeFieldController from './emDatetimeFieldController';

export default class ZvodLocalDateTimeController extends EmDatetimeFieldController {
  constructor(meta, pageCtrl, field, record, isStartDateTime, emDatetimeFieldService) {
    super(meta, pageCtrl, field, record, emDatetimeFieldService);
    this.isStartDateTime = isStartDateTime;
    this.dataType = 'DateTime';
    this.timezone = 'UTC';
    this.inputType = 'datetime';
  }

  get dataType() {
    return this._dataType;
  }

  set dataType(value) {
    this._dataType = value;
  }

  set timezone(value) {
    this._timezone = value;
  }

  get timezone() {
    return this._timezone;
  }

  get label() {
    if (this.isStartDateTime && this.pageCtrl?.startTimeLabel) {
      return this.pageCtrl.startTimeLabel;
    }
    if (!this.isStartDateTime && this.pageCtrl?.endTimeLabel) {
      return this.pageCtrl.endTimeLabel;
    }
    return super.label;
  }

  setFieldValue(value, reference, source) {
    super.setFieldValue(value, reference, source);
    if ((this.field.apiName || this.field) === EmEventConstant.ZVOD_START_TIME) {
      this.setLocalStartTimeFields(this.datetimeValue);
    }
    if ((this.field.apiName || this.field) === EmEventConstant.ZVOD_END_TIME) {
      this.setLocalEndTimeFields(this.datetimeValue);
    }
  }

  setLocalStartTimeFields(value) {
    const [date, time] = this.splitDateTime(value);
    this.record.setFieldValue(EmEventConstant.START_DATE, date, null);
    this.record.setFieldValue(EmEventConstant.START_TIME_LOCAL, time, null);
  }

  setLocalEndTimeFields(value) {
    const [date, time] = this.splitDateTime(value);
    this.record.setFieldValue(EmEventConstant.END_DATE, date, null);
    this.record.setFieldValue(EmEventConstant.END_TIME_LOCAL, time, null);
  }

  splitDateTime(dateTime) {
    if (dateTime) {
      return dateTime.split('T');
    }
    return [null, null];
  }
}