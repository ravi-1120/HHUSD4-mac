import { wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getVeevaSettings from '@salesforce/apex/VeevaCustomSettingsService.getVeevaSettings';
import getCustomSettings from '@salesforce/apex/VeevaCustomSettingsService.getCustomSettings';

const DCR_MODE_ENABLED = 1;
const DCR_MODE_SHADOW_ACCTS = 2;
const NON_DISABLED_DCR_MODES = [DCR_MODE_ENABLED, DCR_MODE_SHADOW_ACCTS];

const NavigateToNewAccount = Symbol('NavigateToNewAccount');
const NavigateToViewAccount = Symbol('NavigateToViewAccount');

const VeevaAccountNavigationMixin = SuperClass =>
  class extends NavigationMixin(SuperClass) {
    @wire(CurrentPageReference)
    pageRef;

    navigationSettings = {};

    async initializeSettings() {
      const veevaSettings = await getVeevaSettings({ settingFieldNames: ['DATA_CHANGE_REQUEST_MODE_vod__c', 'NEW_ACCOUNT_WIZARD_vod__c'] });
      const gasSettings = await getCustomSettings({
        customSettingObjectName: 'Global_Account_Search_Settings_vod__c',
        settingFieldNames: ['My_Accounts_Redirect_vod__c'],
      });
      const networkSettings = await getCustomSettings({
        customSettingObjectName: 'Network_Settings_vod__c',
        settingFieldNames: ['NETWORK_CUSTOMER_MASTER_MODE_vod__c', 'ACTIVATE_NETWORK_ACCOUNT_SEARCH_vod__c'],
      });

      this.navigationSettings.hasDcrEnabled = NON_DISABLED_DCR_MODES.includes(veevaSettings.DATA_CHANGE_REQUEST_MODE_vod__c);
      this.navigationSettings.isNAWEnabled = veevaSettings.NEW_ACCOUNT_WIZARD_vod__c;
      this.navigationSettings.isGASMyAccountsRedirect =
        networkSettings?.NETWORK_CUSTOMER_MASTER_MODE_vod__c === 0 &&
        !networkSettings?.ACTIVATE_NETWORK_ACCOUNT_SEARCH_vod__c &&
        gasSettings?.My_Accounts_Redirect_vod__c;
      this.navigationSettings.isNAS = networkSettings?.NETWORK_CUSTOMER_MASTER_MODE_vod__c === 1 && networkSettings?.ACTIVATE_NETWORK_ACCOUNT_SEARCH_vod__c;
    }

    [NavigateToViewAccount](accountId) {
      this._navigateToRecordPage('standard__recordPage', 'view', 'Account', accountId, null);
    }

    async [NavigateToNewAccount]() {
      if (Object.keys(this.navigationSettings).length <= 0) {
        await this.initializeSettings();
      }

      if (this.navigationSettings.isGASMyAccountsRedirect && this.pageRef?.attributes?.apiName !== 'Global_Account_Search_vod') {
        this._navigateToGAS();
      } else if (this.navigationSettings.isNAS ) {
        this._navigateToNAS();
      } else if (this.navigationSettings.isNAWEnabled === true) {
        this._navigateToNewAccountWizard();
      } else {
        this._navigateToNewAccountPage();
      }
    }

    async _navigateToNewAccountWizard() {
      const newAccountWizardUrl = '/apex/NewAccountWithRecordTypeLgtnVod';
      const currentUrl = await this[NavigationMixin.GenerateUrl](this.pageRef);
      const queryParams = new URLSearchParams({
        retURL: currentUrl,
      });
      if (this.navigationSettings.hasDcrEnabled) {
        queryParams.append('dcr', 'true');
      }
      this._navigateToUrl(`${newAccountWizardUrl}?${queryParams.toString()}`);
    }

    _navigateToNewAccountPage() {
      const state = { useRecordTypeCheck: 1 };
      this._navigateToRecordPage('standard__objectPage', 'new', 'Account', null, state);
    }

    async _navigateToNAS() {
      const currentUrl = await this[NavigationMixin.GenerateUrl](this.pageRef);
      this._navigateToUrl(`/apex/NetworkAccountSearchVod?retURL=${currentUrl}`);
    }

    _navigateToGAS() {
      this._navigateToUrl('/lightning/n/Global_Account_Search_vod');
    }

    _navigateToUrl(url) {
      this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
          url,
        },
      });
    }

    _navigateToRecordPage(type, actionName, objectApiName, recordId, state) {
      this[NavigationMixin.Navigate]({
        type,
        attributes: {
          actionName,
          recordId,
          objectApiName,
        },
        state,
      });
    }
  };

VeevaAccountNavigationMixin.NavigateToNewAccount = NavigateToNewAccount;
VeevaAccountNavigationMixin.NavigateToViewAccount = NavigateToViewAccount;
export default VeevaAccountNavigationMixin;