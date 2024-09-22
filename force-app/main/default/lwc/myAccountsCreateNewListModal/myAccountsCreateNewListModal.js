import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { createRecord } from 'lightning/uiRecordApi';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';

import ACCOUNT_LIST_OBJECT from '@salesforce/schema/Account_List_vod__c';
import ACCOUNT_LIST_NAME_FLD from '@salesforce/schema/Account_List_vod__c.Name';
import ACCOUNT_LIST_ICON_NAME_FLD from '@salesforce/schema/Account_List_vod__c.Icon_Name_vod__c';

import createAccountListItems from '@salesforce/apex/VeevaMyAccountsController.createAccountListItems';

export default class MyAccountsAddToListModal extends LightningModal {
  @api labels;
  @api accountIds = [];

  objectApiNames = [ACCOUNT_LIST_OBJECT.objectApiName];

  listNameLabel;
  listIconLabel;

  _options;
  selectedIcon = {};
  listNameValue;
  loading = false;
  iconError;
  fieldErrors = [];
  recordErrors = [];

  get areFieldsNotPopulated() {
    return !this.selectedIcon.value || !this.listNameValue;
  }

  get options() {
    const { colorIconNames } = this.labels;
    return (
      colorIconNames?.split(' ')?.map((colorIconName, index) => ({
        label: colorIconName,
        value: `${index}`,
        iconStyle: `--sds-c-icon-color-foreground-default: var(--veeva-vod-theme-${index});`,
        icon: 'utility:stop',
      })) ?? []
    );
  }

  @wire(getObjectInfos, { objectApiNames: '$objectApiNames' })
  wiredObjectInfos({ data }) {
    if (data) {
      const accountListObjectInfo = data.results[0].result;
      this.listNameLabel = accountListObjectInfo.fields[ACCOUNT_LIST_NAME_FLD.fieldApiName].label;
      this.listIconLabel = accountListObjectInfo.fields[ACCOUNT_LIST_ICON_NAME_FLD.fieldApiName].label;
    }
  }

  connectedCallback() {
    if (this.options.length > 0) {
      [this.selectedIcon] = this.options;
    }
  }

  updateListName(event) {
    this.listNameValue = event.detail.value;
  }

  updateIconName(event) {
    const { value } = event.detail;
    this.selectedIcon = this.options.find(icon => icon.value === value);
  }

  handleCancel() {
    this.close();
  }

  async handleOkay() {
    this.loading = true;
    this.recordErrors = [];
    this.fieldErrors = [];
    try {
      const accountList = await createRecord({
        apiName: ACCOUNT_LIST_OBJECT.objectApiName,
        fields: {
          [ACCOUNT_LIST_NAME_FLD.fieldApiName]: this.listNameValue,
          [ACCOUNT_LIST_ICON_NAME_FLD.fieldApiName]: this.selectedIcon.value,
        },
      });
      const accountListItems = await createAccountListItems({ accountListId: accountList.id, accountIds: this.accountIds });
      this.close({ accountList, accountListItems });
    } catch (e) {
        this.dispatchError(e);
    }
    this.loading = false;
  }

  updateFields(errorMap) {
    const fieldLabels = [];
    const elements = this.template.querySelectorAll("[data-validity]")
    elements.forEach(element => {
        element.setCustomValidity(errorMap.get(element.label));
        fieldLabels.push({fieldLabel: element.label});
        element.reportValidity();
    });
    if (errorMap.has(this.listIconLabel)) {
      this.iconError = errorMap.get(this.listIconLabel);
      fieldLabels.push({fieldLabel: this.listIconLabel});
    }
    return fieldLabels;
  }

  dispatchError(e) {
    const errorMessages = [];
    const fieldMessageMap = new Map();
    
    if (e.body?.output?.errors != null || e.body?.output?.fieldErrors != null) {
      
      // Assign record type errors
      e.body.output.errors.forEach(customError => {
        errorMessages.push(customError.message);
      });

      // Assign field errors
      Object.values(e.body.output.fieldErrors).forEach(fieldErrorArray => {
        fieldErrorArray.forEach(fieldError => {
          if (!fieldMessageMap.has(fieldError.fieldLabel)) {
            fieldMessageMap.set(fieldError.fieldLabel, fieldError.message);
          } else {
            fieldMessageMap.set(fieldError.fieldLabel, `${fieldMessageMap.get(fieldError.fieldLabel)}\n${fieldError.message}`);
          }
        });
      });

      this.recordErrors = errorMessages;
      this.fieldErrors = this.updateFields(fieldMessageMap);
    } else {
      // According to https://salesforce.stackexchange.com/questions/387924/lightning-modal-custom-event-not-working-in-winter-23-release
      // Without enabling Lightning Web Security we cannot dispatch events from elements extending LightningModal
      // We will have our child element dispatch events on the modals behalf
      this.template.querySelector('c-my-accounts-modal-dispatch').dispatchErrorToast(e);
    }
    
  }
}