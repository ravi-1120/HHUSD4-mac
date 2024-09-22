import { wire } from 'lwc';
import { getPageController } from 'c/veevaPageControllerFactory';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import GasImplicitFilterAccess from 'c/gasImplicitFilterAccess';
import IMPLICIT_FILTER_OBJECT from '@salesforce/schema/Implicit_Filter_vod__c';
import IMPLICIT_FILTER_CONDITION_OBJECT from '@salesforce/schema/Implicit_Filter_Condition_vod__c';
import VeevaMainPage from 'c/veevaMainPage';
import VeevaToastEvent from 'c/veevaToastEvent';

const PAGE_NAME = 'Global Account Search Configuration';

export default class GlobalAccountSearchAdminTab extends VeevaMainPage {
  pageName = PAGE_NAME;
  objectNames = [IMPLICIT_FILTER_OBJECT, IMPLICIT_FILTER_CONDITION_OBJECT];
  implicitFiltersVisible = false;
  accessDenied = false;

  objectInfoLoaded = false;

  title = PAGE_NAME;
  accessDeniedLabel = 'Access Denied';
  pageCtrl = getPageController('pageCtrl');

  get isPageReady() {
    return this.objectInfoLoaded;
  }

  @wire(getObjectInfos, { objectApiNames: '$objectNames' })
  wiredObjectInfos({ error, data }) {
    if (data) {
      const objectInfos = data.results;
      const implicitFilterObjectInfo = objectInfos[0].result;
      const implicitFilterConditionObjectInfo = objectInfos[1].result;
      this.implicitFiltersVisible = this.isAbleToViewImplicitFilters(implicitFilterObjectInfo, implicitFilterConditionObjectInfo);
      this.accessDenied = !this.implicitFiltersVisible;
      this.objectInfoLoaded = true;
    } else if (error) {
      this.setError(error);
    }
  }

  async connectedCallback() {
    super.connectedCallback();
    const veevaMessageService = getPageController('messageSvc');
    await this.loadVeevaMessages(veevaMessageService);
  }

  async loadVeevaMessages(veevaMessageService) {
    await veevaMessageService.loadVeevaMessageCategories(['Common', 'Global Account Search']);

    [this.title, this.accessDeniedLabel] = await Promise.all([
      veevaMessageService.getMessageWithDefault('GAS_CONFIGURATION', 'Global Account Search', this.title),
      veevaMessageService.getMessageWithDefault('ACCESS_DENIED', 'Common', this.accessDeniedLabel),
    ]);
  }

  // eslint-disable-next-line class-methods-use-this
  isAbleToViewImplicitFilters(implicitFilterObjectInfo, implicitFilterConditionObjectInfo) {
    return GasImplicitFilterAccess.hasImplicitFilterAccess(implicitFilterObjectInfo, implicitFilterConditionObjectInfo);
  }

  setError(e) {
    const errMsg = e.body && e.body.message ? e.body.message : this.errorMessage;
    const error = { message: errMsg };
    this.dispatchEvent(VeevaToastEvent.error(error, 'sticky'));
  }
}