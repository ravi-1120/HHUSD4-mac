import getAllAddresses from '@salesforce/apex/VeevaAddress.getAllAddresses';
import getAccountUserTerritories from '@salesforce/apex/VeevaTerritoryController.getAccountUserTerritories';
import { getService, SERVICES } from 'c/veevaServiceFactory';

const FIELDS_TO_QUERY = [
  'Id',
  'Name',
  'Account_vod__c',
  'Address_Line_2_vod__c',
  'Primary_vod__c',
  'City_vod__c',
  'State_vod__c',
  'Zip_vod__c',
  'Country_vod__c',
];

export default class VeevaAddressService {
  addresses = {};

  async getAddressOptions(accountId) {
    let territories = [];

    if (this.addresses[accountId]?.length > 0) {
      return this.addresses[accountId];
    }

    try {
      territories = await getAccountUserTerritories({
        accountId,
      });

      const options = await getAllAddresses({
        accountIds: [accountId],
        territoryName: territories[0]?.Name,
        fieldNames: FIELDS_TO_QUERY,
        orderBy: 'Id ASC',
        duplicateRawAddressFields: false
      });

      this.addresses[accountId] = options[accountId]
        ? options[accountId].map(address => this.toPicklistOptionFormat(address, territories[0]?.Name))
        : [];
    } catch (e) {
      this.addresses[accountId] = [];
    }
    return this.addresses[accountId];
  }

  async getInvalidAddress(id) {
    const invalidRecord = await getService(SERVICES.UI_API).getRecord(
      id,
      FIELDS_TO_QUERY.map(field => `Address_vod__c.${field}`),
      true
    );

    return this.toPicklistOptionFormat(this.getUiApiFields(invalidRecord), undefined);
  }

  getUiApiFields(uiApiRecord = {}) {
    const fields = {};
    Object.entries(uiApiRecord.fields).forEach(([fieldName, fieldValue]) => {
      fields[fieldName] = fieldValue.value;
    });
    return fields;
  }

  toPicklistOptionFormat(address, territoryName) {
    const name = this.toAddressFormat(address);
    const preferredTSF = territoryName && address.TSF_vod__r?.[0].Territory_vod__c === territoryName;
    return {
      label: name,
      value: address.Id,
      attributes: null,
      validFor: [],
      primary: address.Primary_vod__c,
      preferredTSF,
      id: address.Id,
    };
  }

  toAddressFormat(address) {
    let addressText = '';
    if (address) {
      addressText = address.Name;
      if (address.Address_line_2_vod__c) {
        addressText += `, ${address.Address_line_2_vod__c}`;
      }
      if (address.City_vod__c) {
        addressText += `, ${address.City_vod__c}`;
      }
      if (address.State_vod__c) {
        addressText += `, ${address.State_vod__c}`;
      }
      if (address.Zip_vod__c) {
        addressText += ` ${address.Zip_vod__c}`;
      }
    }
    return addressText;
  }

  getDefaultAddress(accountId) {
    const accountAddresses = this.addresses[accountId];
    let defaultAddr = { value: '' };
    if (!accountId) {
      return defaultAddr.value;
    }
    const preferredTSF = accountAddresses?.find(option => option.preferredTSF);
    const primary = accountAddresses?.find(option => option.primary);
    if (accountAddresses.length > 0) {
      defaultAddr = preferredTSF || primary || accountAddresses[0];
    }
    return defaultAddr.value;
  }
}