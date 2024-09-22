import ACCOUNT from '@salesforce/schema/Account';
import DATA_CHANGE_REQUEST from '@salesforce/schema/Data_Change_Request_vod__c';
import DATA_CHANGE_REQUEST_LINE from '@salesforce/schema/Data_Change_Request_Line_vod__c';
import DCR_FIELD_TYPE from '@salesforce/schema/DCR_Field_Type_vod__c';
import MyAccountsButtonController from '../myAccountsButtonController';

const DCR_MODE_ENABLED = 1;
const DCR_MODE_SHADOW_ACCTS = 2;
const NON_DISABLED_DCR_MODES = [DCR_MODE_ENABLED, DCR_MODE_SHADOW_ACCTS];

export default class NewAccountActionController extends MyAccountsButtonController {
  static REQUIRED_OBJECTS = [
    ACCOUNT.objectApiName,
    DATA_CHANGE_REQUEST.objectApiName,
    DATA_CHANGE_REQUEST_LINE.objectApiName,
    DCR_FIELD_TYPE.objectApiName,
  ];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest('NEW', 'Common', 'New', 'newBtn');
  static CUSTOM_SETTINGS = [
    {
      customSettingObjectName: 'Veeva_Settings_vod__c',
      settingFieldNames: ['DATA_CHANGE_REQUEST_MODE_vod__c', 'NEW_ACCOUNT_WIZARD_vod__c'],
    },
    {
      customSettingObjectName: 'Global_Account_Search_Settings_vod__c',
      settingFieldNames: ['My_Accounts_Redirect_vod__c'],
    },
    {
      customSettingObjectName: 'Network_Settings_vod__c',
      settingFieldNames: [
        'NETWORK_CUSTOMER_MASTER_MODE_vod__c',
        'ACTIVATE_NETWORK_ACCOUNT_SEARCH_vod__c',
        'CRM_MANAGED_ACCOUNT_TYPES_vod__c',
        'THIRD_PARTY_MANAGED_ACCOUNT_TYPES_vod__c',
      ],
    },
  ];

  getLabel(messageMap) {
    return messageMap.newBtn;
  }

  isVisible(objectInfoMap, settings) {
    const veevaSettings = settings.get('Veeva_Settings_vod__c');
    const networkSettings = settings.get('Network_Settings_vod__c');

    const dcrMode = veevaSettings.DATA_CHANGE_REQUEST_MODE_vod__c;
    const networkMasterMode = networkSettings.NETWORK_CUSTOMER_MASTER_MODE_vod__c;

    const hasDcrEnabled = NON_DISABLED_DCR_MODES.includes(dcrMode);
    const blankManagedAccountTypes = this._isManagedAccountTypesBlank(settings);
    const noNetworkAndNoDcr = networkMasterMode === 0 && dcrMode === 0;
    const fullNetwork = networkMasterMode === 1;

    const networkAccountSearchActive = networkSettings.ACTIVATE_NETWORK_ACCOUNT_SEARCH_vod__c;

    const fullNetworkAndNAS = fullNetwork && networkAccountSearchActive;
    const accountCreatePermission = objectInfoMap[ACCOUNT.objectApiName]?.createable && (blankManagedAccountTypes || noNetworkAndNoDcr);
    const supportedNetworkMode = [0, 1];
    const dcrCreatePermission =
      hasDcrEnabled &&
      objectInfoMap[DATA_CHANGE_REQUEST.objectApiName]?.createable &&
      objectInfoMap[DATA_CHANGE_REQUEST_LINE.objectApiName]?.createable &&
      objectInfoMap[DCR_FIELD_TYPE.objectApiName]?.queryable &&
      supportedNetworkMode.includes(networkMasterMode);

    const globalAccountSearchSettings = settings.get('Global_Account_Search_Settings_vod__c');

    const isGASMyAccountsRedirect = networkMasterMode === 0 && !networkAccountSearchActive && globalAccountSearchSettings.My_Accounts_Redirect_vod__c;

    return fullNetworkAndNAS || isGASMyAccountsRedirect || accountCreatePermission || dcrCreatePermission;
  }

  _isManagedAccountTypesBlank(settings) {
    const crmManagedAccountTypes = settings.get('Network_Settings_vod__c').CRM_MANAGED_ACCOUNT_TYPES_vod__c;
    const thirdPartyManagedAccountTypes = settings.get('Network_Settings_vod__c').THIRD_PARTY_MANAGED_ACCOUNT_TYPES_vod__c;
    return (
      (!crmManagedAccountTypes && !thirdPartyManagedAccountTypes) ||
      (crmManagedAccountTypes.length === 0 && thirdPartyManagedAccountTypes.length === 0) ||
      (crmManagedAccountTypes.includes('CRM_MANAGED_ACCOUNT_TYPES') && thirdPartyManagedAccountTypes.includes('THIRD_PARTY_MANAGED_ACCOUNT_TYPES'))
    );
  }

  get disabled() {
    return false;
  }

  async createActionEvents() {
    return [new CustomEvent('newaccount')];
  }
}