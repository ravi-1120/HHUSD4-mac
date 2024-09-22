import EmController from 'c/emController';
import EmEventConstant from 'c/emEventConstant';
import VeevaUtils from 'c/veevaUtils';
import EM_EVENT from '@salesforce/schema/EM_Event_vod__c';

export default class EmEventSessionController extends EmController {
  async initRecordCreateBase(pageRef) {
    await super.initRecordCreateBase(pageRef);
    await this.populateStartAndEndTimes();
  }

  async populateStartAndEndTimes() {
    if (
      !this.record.rawValue(EmEventConstant.EVENT) ||
      (this.record.rawValue(EmEventConstant.START_TIME) && this.record.rawValue(EmEventConstant.END_TIME))
    ) {
      return;
    }
    const eventRecord = await this.uiApi.getRecord(this.record.rawValue(EmEventConstant.EVENT), [
      `${EM_EVENT.objectApiName}.${EmEventConstant.START_TIME}`,
      `${EM_EVENT.objectApiName}.${EmEventConstant.END_TIME}`,
    ]);
    const startTime = VeevaUtils.lookupTraversal(eventRecord)([EmEventConstant.START_TIME]);
    if (startTime) {
      this.setFieldValue(EmEventConstant.START_TIME, startTime);
    }
    const endTime = VeevaUtils.lookupTraversal(eventRecord)([EmEventConstant.END_TIME]);
    if (endTime) {
      this.setFieldValue(EmEventConstant.END_TIME, endTime);
    }
  }
}