import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';

import ACCOUNT_LIST_OBJECT from '@salesforce/schema/Account_List_vod__c';
import ACCOUNT_LIST_NAME_FLD from '@salesforce/schema/Account_List_vod__c.Name';


export default class MyAccountsEditListModal extends LightningModal {
  @api accountListId;
  @api labels;
  @api existingName;

  objectApiNames = [ACCOUNT_LIST_OBJECT.objectApiName];

  listNameLabel;
  listIconLabel;

  listNameValue;
  loading = false;

  get areFieldsNotPopulated() {
    return !this.listNameValue;
  }

  @wire(getObjectInfos, { objectApiNames: '$objectApiNames' })
  wiredObjectInfos({ data }) {
    if (data) {
      const accountListObjectInfo = data.results[0].result;
      this.listNameLabel = accountListObjectInfo.fields[ACCOUNT_LIST_NAME_FLD.fieldApiName].label;
    }
  }

  connectedCallback() {
    this.listNameValue = this.existingName;
  }

  updateListName(event) {
    this.listNameValue = event.detail.value;
  }

  handleCancel() {
    this.close();
  }

  async handleOkay() {
    this.loading = true;
    try {
      const accountList = await updateRecord({
        fields: {
          Id: this.accountListId,
          [ACCOUNT_LIST_NAME_FLD.fieldApiName]: this.listNameValue,
        },
      });
      this.close({ accountList });
    } catch (e) {
      this.dispatchError(e);
    }
    this.loading = false;
  }

  dispatchError(e) {
    // According to https://salesforce.stackexchange.com/questions/387924/lightning-modal-custom-event-not-working-in-winter-23-release
    // Without enabling Lightning Web Security we cannot dispatch events from elements extending LightningModal
    // We will have our child element dispatch events on the modals behalf
    this.template.querySelector('c-my-accounts-modal-dispatch').dispatchErrorToast(e);
  }

  
}