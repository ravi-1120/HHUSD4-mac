import { publish, createMessageContext } from 'lightning/messageService';
import componentRefreshMessage from '@salesforce/messageChannel/Component_Refresh_Message__c';
import FieldController from 'c/fieldController';

export default class EmDatetimeFieldController extends FieldController {
  constructor(meta, pageCtrl, field, record, emDatetimeFieldService) {
    super(meta, pageCtrl, field, record);
    this.pageCtrl = pageCtrl;
    this.emDatetimeFieldService = emDatetimeFieldService;
    this.messageContext = createMessageContext();
    this.fieldRefreshKey = field.apiName;
  }

  setFieldValue(value, reference, source) {
    const fieldName = this.field.apiName || this.field;
    this.datetimeValue = value;
    if (this.pageCtrl.isNew) {
      this.datetimeValue = this.emDatetimeFieldService.getOverriddenTime(fieldName, value, source);
      if (this.datetimeValue !== value) {
        const payload = {
          recordId: this.pageCtrl.id,
          pageMode: this.pageCtrl.action,
          keyToRefresh: fieldName,
        };
        publish(this.messageContext, componentRefreshMessage, payload);
      }
    }
    this.pageCtrl.setFieldValue(this.field, this.datetimeValue, reference, this.record, source);
  }
}