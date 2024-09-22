import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import myInsightsNavigationChannel from '@salesforce/messageChannel/MyInsights_Navigation__c';

export default class MyInsightsLightningNavigator extends NavigationMixin(LightningElement) {

  @api htmlReportId;
  @api htmlReportUuid;

  @wire(CurrentPageReference)
  pageReference;

  @wire(MessageContext)
  messageContext;

  subscription;

  connectedCallback() {
    this.subscribeToNavigationChannel();
  }

  disconnectedCallback() {
    this.unsubscribeFromNavigationChannel();
  }

  subscribeToNavigationChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(this.messageContext, myInsightsNavigationChannel, message => this.handleNavigationMessage(message));
    }
  }

  unsubscribeFromNavigationChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  handleNavigationMessage(message) {
    if (this.isValid(message)) {
      if (message.viewRecord) {
        this.navigateToViewRecordPage(message.viewRecord);
      } else if (message.urlInfo) {
        this.navigateToUrl(message.urlInfo);
      } else if (message.newRecord) {
        this.navigateToNewRecordCreation(message.newRecord);
      }
    }
  }

  navigateToViewRecordPage(viewRecordPageInfo) {
    const { object, recordId, targetId } = viewRecordPageInfo;
    if (object && recordId) {
      const nav = {
          type: 'standard__recordPage',
          attributes: {
              objectApiName: object,
              actionName: 'view',
              recordId,
          },
      }
      // Add query parameter for report tab target
      if (targetId) {
          nav.state = {
              c__myinsightsTabId: targetId
          }
      }
      this[NavigationMixin.Navigate](nav);
    }
  }

  navigateToUrl(urlInfo) {
    const { url } = urlInfo;
    if (url) {
      this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
          url,
        },
      });
    }
  }

  async navigateToNewRecordCreation(newRecord) {
    const { object, fields } = newRecord;
    if (object) {
      const pageRefState = {
        c__flowVariables: JSON.stringify(this.createFlowVariables(object, fields)),
        c__inContextOfRef: JSON.stringify(this.pageReference),
      };

      this[NavigationMixin.Navigate]({
        type: 'standard__objectPage',
        attributes: {
          objectApiName: object,
          actionName: 'new',
        },
        state: pageRefState,
      });
    }
  }

  createFlowVariables(object, fields) {
    const flowVariables = [
      {
        name: 'objectApiName',
        value: object,
        type: 'String',
      },
    ];
    if (fields) {
      flowVariables.push({
        name: 'defaultFieldValues',
        value: this.formatFields(fields),
        type: 'String',
      });
    }
    return flowVariables;
  }

  isValid(message) {
    return message.htmlReportId === this.htmlReportId && message.htmlReportUUID === this.htmlReportUuid;
  }

  formatFields(fields) {
    const formattedFields = {};
    Object.entries(fields).forEach(([key, value]) => {
      formattedFields[key] = {
        displayValue: null,
        value,
      };
    });
    return formattedFields;
  }
}