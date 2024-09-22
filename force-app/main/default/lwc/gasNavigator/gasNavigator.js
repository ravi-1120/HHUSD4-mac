import { api, LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

export default class GasNavigator extends NavigationMixin(LightningElement) {
  @wire(CurrentPageReference)
  pageRef;

  @api
  async navigateToNewAccountWizard(hasDcrEnabled) {
    const newAccountWizardUrl = '/apex/NewAccountWithRecordTypeLgtnVod';
    const currentUrl = await this[NavigationMixin.GenerateUrl](this.pageRef);
    const queryParams = new URLSearchParams({
      retURL: currentUrl,
    });
    if (hasDcrEnabled) {
      queryParams.append('dcr', 'true');
    }
    this.navigateToUrl(`${newAccountWizardUrl}?${queryParams.toString()}`);
  }

  @api
  navigateToViewAccount(accountId) {
    this.navigateToRecordPage('standard__recordPage', 'view', 'Account', accountId, null);
  }

  @api
  navigateToNewAccountPage() {
    const state = { useRecordTypeCheck: 1 };
    this.navigateToRecordPage('standard__objectPage', 'new', 'Account', null, state);
  }

  navigateToUrl(url) {
    this[NavigationMixin.Navigate]({
      type: 'standard__webPage',
      attributes: {
        url,
      },
    });
  }

  navigateToRecordPage(type, actionName, objectApiName, recordId, state) {
    // References https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.reference_page_reference_type
    this[NavigationMixin.Navigate]({
      type,
      attributes: {
        actionName,
        recordId,
        objectApiName,
      },
      state
    });
  }
}