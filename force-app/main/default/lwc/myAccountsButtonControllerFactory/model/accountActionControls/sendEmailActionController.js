import LightningAlert from 'lightning/alert';
import SENT_EMAIL from '@salesforce/schema/Sent_Email_vod__c';
import isFieldOnEditLayout from '@salesforce/apex/VeevaLayoutService.isFieldOnEditLayout';
import { SERVICES, getService} from 'c/veevaServiceFactory';
import MyAccountsButtonController from '../myAccountsButtonController';

export default class SendEmailActionController extends MyAccountsButtonController {
  static REQUIRED_OBJECTS = [SENT_EMAIL.objectApiName];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest()
    .addRequest('SEND_EMAIL_BUTTON', 'ApprovedEmail', 'Send Email', 'sendEmailBtn')
    .addRequest('APPROVED_EMAIL_LIMIT', 'ApprovedEmail', '', 'approvedEmailLimit');

  static CUSTOM_SETTINGS = [
    {
      customSettingObjectName: 'Approved_Email_Settings_vod__c',
      settingFieldNames: ['DISABLED_APPROVED_EMAIL_ENTRYPOINTS_vod__c', 'ADD_RECIPIENTS_vod__c', 'ENABLE_GROUP_EMAIL_vod__c'],
    },
  ];

  constructor(objectInfoMap, messageMap, settings) {
    super(objectInfoMap, messageMap, settings);
    this.objectInfoMap = objectInfoMap;
    this.messageMap = messageMap;
    this.settings = settings;
  }

  getLabel(messageMap) {
    return messageMap.sendEmailBtn;
  }

  isVisible(objectInfoMap, settings) {
    const disabledEmailEntrypoints = settings.get('Approved_Email_Settings_vod__c')?.DISABLED_APPROVED_EMAIL_ENTRYPOINTS_vod__c;
    return objectInfoMap[SENT_EMAIL.objectApiName] && !disabledEmailEntrypoints?.includes('MyAccounts_vod');
  }

  get disabled() {
    return !this.selectedAccounts || this.selectedAccounts.length === 0;
  }

  async createActionEvents() {
    const accountIdSet = new Set(this.selectedAccounts.map(selectedAccount => selectedAccount['Account-Id']));
    if (accountIdSet.size > 90) {
      await LightningAlert.open({
        message: this.messageMap.approvedEmailLimit,
        theme: 'warning',
      });
      return [];
    }
    const url = await this._generateSendEmailUrl(accountIdSet);
    return [new CustomEvent('sendemail', { detail: { url } })];
  }

  async _generateSendEmailUrl(accountIdSet) {
    let url = `/apex/Send_Approved_Email_vod?location=Account_vod`;
    const isGroupEmailConfigured = await this._isGroupEmailConfigured();
    if (isGroupEmailConfigured) {
      const uiAPI = getService(SERVICES.UI_API);
      const accounts = await uiAPI.getBatchRecords([...accountIdSet], ['Account.IsPersonAccount'], true);
      const nonPersonAccounts = accounts.filter(account => !account.fields.IsPersonAccount.value);
      if (nonPersonAccounts.length === 1) {
        url += `&groupId=${nonPersonAccounts[0].id}`;
        accountIdSet.delete(nonPersonAccounts[0].id);
      }
    }
    url += `&accts=${[...accountIdSet].join(',')}`;
    url += `&retURL=${document.location.pathname}`;
    return url;
  }

  async _isGroupEmailConfigured() {
    const isParentEmailEditable = await this._isParentEmailEditable();
    return (
      this.settings.get('Approved_Email_Settings_vod__c')?.ADD_RECIPIENTS_vod__c === '1' &&
      this.settings.get('Approved_Email_Settings_vod__c')?.ENABLE_GROUP_EMAIL_vod__c > 0 &&
      isParentEmailEditable
    );
  }

  async _isParentEmailEditable() {
    const parentEmailCreateable = this.objectInfoMap[SENT_EMAIL.objectApiName]?.fields?.Parent_Email_vod__c?.createable;
    let isParentEmailEditable = false;
    if (parentEmailCreateable) {
      const { recordTypeId } = Object.values(this.objectInfoMap[SENT_EMAIL.objectApiName].recordTypeInfos).find(
        recordTypeInfo => recordTypeInfo.defaultRecordTypeMapping
      );
      const parentEmailOnLayout = await isFieldOnEditLayout({ objectApiName: 'Sent_Email_vod__c', fieldName: 'Parent_Email_vod__c', recordTypeId });
      if (parentEmailOnLayout) {
        isParentEmailEditable = true;
      }
    }
    return isParentEmailEditable;
  }
}