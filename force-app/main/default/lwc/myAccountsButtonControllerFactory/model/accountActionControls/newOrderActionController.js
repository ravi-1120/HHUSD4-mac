import LightningAlert from 'lightning/alert';
import ORDER_OBJECT from '@salesforce/schema/Order_vod__c';
import ORDER_LINE_OBJECT from '@salesforce/schema/Order_Line_vod__c';
import PRICING_RULE_OBJECT from '@salesforce/schema/Pricing_Rule_vod__c';

import { SERVICES, getService } from 'c/veevaServiceFactory';
import MyAccountsDataService from 'c/myAccountsDataService';
import MyAccountsButtonController from '../myAccountsButtonController';

export default class NewOrderActionController extends MyAccountsButtonController {
  _accountDataService = new MyAccountsDataService(getService(SERVICES.DATA));

  static REQUIRED_OBJECTS = [ORDER_OBJECT.objectApiName, ORDER_LINE_OBJECT.objectApiName];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest()
    .addRequest('New_Order', 'ORDER_MANAGEMENT', 'New Order', 'newOrderBtn')
    .addRequest(
      'ORDER_TYPE_MULTI_RECIPIENT_ERROR',
      'ORDER_MANAGEMENT',
      'The Order Type is not enabled for multiple recipient accounts',
      'multiRecipientError'
    )
    .addRequest('RECIPIENTS_MAX', 'ORDER_MANAGEMENT', 'There cannot be more than {0} recipients', 'maxRecipientsError')
    .addRequest('ORDER_TYPE_NOT_ALLOWED', 'ORDER_MANAGEMENT', 'Order type {0} is not allowed for {1}', 'orderTypeNotAllowed');

  static CUSTOM_SETTINGS = [
    {
      customSettingObjectName: 'Veeva_Settings_vod__c',
      settingFieldNames: ['Number_Delivery_Dates_vod__c'],
    }, 
  ];

  constructor(objectInfoMap, messageMap, settings) {
    super(objectInfoMap, messageMap);
    this._messageMap = messageMap;
    this.settings = settings;
  }

  get disabled() {
    return !this.selectedAccounts || this.selectedAccounts.length === 0;
  }

  getLabel(messageMap) {
    return messageMap.newOrderBtn;
  }

  isVisible(objectInfoMap) {
    return NewOrderActionController.REQUIRED_OBJECTS
        .map(objectApiName => objectInfoMap[objectApiName])
        .every(objectInfo => objectInfo?.createable && objectInfo?.deletable && objectInfo.updateable) 
        && !objectInfoMap[PRICING_RULE_OBJECT.objectApiName]?.createable
        && !objectInfoMap[PRICING_RULE_OBJECT.objectApiName]?.deletable
        && !objectInfoMap[PRICING_RULE_OBJECT.objectApiName]?.updateable;
  }

  async createActionEvents() {
    const accountIdSet = new Set(this.selectedAccounts.map(selectedAccount => selectedAccount['Account-Id']));
    const url = await this._generateUrl();
    if (url) {
      return [new CustomEvent('neworder', { detail: { accountIds: [...accountIdSet], url } })];
    }
    return [];
  }

  async _generateUrl() {
    const url = '/apex/New_Order_vod';
    let params;
    if (this.selectedAccounts.length > 1) {
      params = await this._handleMultiRecipients();
    } else if (this.selectedAccounts.length === 1) {
      params = this._handleSingleRecipient(this.selectedAccounts[0]['Account-Id']);
    }

    if(params) {
      params += `&isFromCall=true&retURL=${window.location.href}`;
    }

    return params ? url + params : null;
  }

  _handleSingleRecipient(accountId) {
    return `?acctid=${accountId}`;
  }

  async _handleMultiRecipients() {
    let params;
    const accountIds = this.selectedAccounts.map(account => account['Account-Id']);
    const numberDeliveryDates = this.settings?.get('Veeva_Settings_vod__c')?.Number_Delivery_Dates_vod__c;
    const maxOrderRecipients = Math.min(numberDeliveryDates && numberDeliveryDates > 0 ? numberDeliveryDates : 5 , 12);
    if(accountIds.length > maxOrderRecipients) {
      await LightningAlert.open({
        message: this._messageMap.maxRecipientsError.replace('{0}', maxOrderRecipients),
        theme: 'warning',
      });
      return params;
    }
    const orderTypeInfo = await this._accountDataService.getOrderTypeInfoByAccounts(accountIds);
    const firstOrderTypeInfo = orderTypeInfo[accountIds[0]];

    if (firstOrderTypeInfo.availableOrderTypes[firstOrderTypeInfo.defaultOrderTypeName] && !firstOrderTypeInfo.multiRecipientEnabled) {
      await LightningAlert.open({
        message: this._messageMap.multiRecipientError,
        theme: 'warning',
      });
      params = this._handleSingleRecipient(this.selectedAccounts[0]['Account-Id']);
    } else {
      const validAccountIds = accountIds.filter(
        key => !orderTypeInfo[key].noOrdersChecked && orderTypeInfo[key].availableOrderTypes[firstOrderTypeInfo.defaultOrderTypeName]
      );
      if (validAccountIds && validAccountIds.length <= 0) {
        await LightningAlert.open({
          message: this._messageMap.multiRecipientError,
          theme: 'warning',
        });
      } else {
        await this._showWarningOnInvalidAccounts(orderTypeInfo, firstOrderTypeInfo);
        params = `?multiRecipients=true&recipientIds=${validAccountIds}`;
      }
    }
    return params;
  }

  async _showWarningOnInvalidAccounts(orderTypeInfo, firstOrderTypeInfo) {
    const invalidAccounts = Object.keys(orderTypeInfo).filter(
      key => !orderTypeInfo[key].noOrdersChecked && !orderTypeInfo[key].availableOrderTypes[firstOrderTypeInfo.defaultOrderTypeName]
    );
    if (invalidAccounts.length > 0) {
      const invalidAccountNames = invalidAccounts.map(id => orderTypeInfo[id].accountName);
      const orderTypeLabelOrName = firstOrderTypeInfo.defaultOrderTypeLabel
        ? firstOrderTypeInfo.defaultOrderTypeLabel
        : firstOrderTypeInfo.defaultOrderTypeName;
      await LightningAlert.open({
        message: this._messageMap.orderTypeNotAllowed.replace('{0}', orderTypeLabelOrName).replace('{1}', invalidAccountNames.join('; ')),
        theme: 'warning',
      });
    }
  }
}