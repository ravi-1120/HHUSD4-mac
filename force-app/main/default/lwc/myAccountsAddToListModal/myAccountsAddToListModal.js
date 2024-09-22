import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';

import ACCOUNT_LIST_OBJECT from '@salesforce/schema/Account_List_vod__c';
import ACCOUNT_LIST_NAME_FLD from '@salesforce/schema/Account_List_vod__c.Name';

import createAccountListItems from '@salesforce/apex/VeevaMyAccountsController.createAccountListItems';

export default class MyAccountsAddToListModal extends LightningModal {
  @api labels;
  @api accountIds;

  objectApiNames = [ACCOUNT_LIST_OBJECT.objectApiName];

  listNameLabel;

  _options;
  selectedList = {};
  loading = false;

  @api
  get options() {
    return (
      this._options?.map(list => ({
        ...list,
        checked: this.selectedList.value === list.value,
        style: `--sds-c-icon-color-foreground-default: var(--veeva-vod-theme-${list.color});`,
      })) ?? []
    );
  }

  set options(value) {
    this._options = value;
  }

  get areFieldsNotPopulated() {
    return !this.selectedList.value;
  }

  @wire(getObjectInfos, { objectApiNames: '$objectApiNames' })
  wiredObjectInfos({ data }) {
    if (data) {
      const accountListObjectInfo = data.results[0].result;
      this.listNameLabel = accountListObjectInfo.fields[ACCOUNT_LIST_NAME_FLD.fieldApiName].label;
    }
  }

  connectedCallback() {
    if (this.options.length > 0) {
      [this.selectedList] = this.options;
    }
  }

  updateListName(event) {
    const { value } = event.detail;
    this.selectedList = this.options.find(option => option.value === value);
  }

  handleCancel() {
    this.close();
  }

  async handleOkay() {
    const accountListId = this.selectedList.value;
    if (accountListId) {
      this.loading = true;
      try {
        const accountListItems = await createAccountListItems({ accountListId, accountIds: this.accountIds });
        this.close(accountListItems);
      } catch (e) {
        this.dispatchError(e);
      }
      this.loading = false;
    }
  }

  dispatchError(e) {
    // According to https://salesforce.stackexchange.com/questions/387924/lightning-modal-custom-event-not-working-in-winter-23-release
    // Without enabling Lightning Web Security we cannot dispatch events from elements extending LightningModal
    // We will have our child element dispatch events on the modals behalf
    this.template.querySelector('c-my-accounts-modal-dispatch').dispatchErrorToast(e);
  }
}