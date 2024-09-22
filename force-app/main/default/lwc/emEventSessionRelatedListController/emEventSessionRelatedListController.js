import EmEventConstant from 'c/emEventConstant';
import EmRelatedListController from 'c/emRelatedListController';
import EM_EVENT from '@salesforce/schema/EM_Event_vod__c';

export default class EmEventSessionRelatedListController extends EmRelatedListController {
  getEmDefaultFieldValues() {
    const defVals = super.getEmDefaultFieldValues();
    if (this.pageCtrl?.objectApiName === EM_EVENT.objectApiName) {
      if (this.pageCtrl.record?.rawValue(EmEventConstant.START_TIME)) {
        defVals.Start_Time_vod__c = this.pageCtrl.record.value(EmEventConstant.START_TIME);
      }
      if (this.pageCtrl.record?.rawValue(EmEventConstant.END_TIME)) {
        defVals.End_Time_vod__c = this.pageCtrl.record.value(EmEventConstant.END_TIME);
      }
    }
    return defVals;
  }
}