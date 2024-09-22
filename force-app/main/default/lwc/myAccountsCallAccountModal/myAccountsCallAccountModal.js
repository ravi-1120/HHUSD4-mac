import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class MyAccountsCallAccountModal extends LightningModal {
  @api labels;
  @api phoneNumber;
  @api record;

  get headerLabel() {
    const accountName = this.record?.['Account-Formatted_Name_vod__c'] ?? this.record?.['Account-Name'];
    return [this.labels.callLabel, accountName].filter(value => value).join(' ');
  }

  get recordId() {
    return this.record?.['Account-Id'];
  }
}