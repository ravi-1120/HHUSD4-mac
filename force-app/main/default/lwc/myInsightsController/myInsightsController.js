import VeevaPageController from 'c/veevaPageController';
import MyInsightsService from 'c/myInsightsService';
import SuggestionSurveyModal from 'c/suggestionSurveyModal';
import { createMessageContext, publish, subscribe, unsubscribe } from 'lightning/messageService';
import myInsightsModalChannel from '@salesforce/messageChannel/MyInsights_Modal__c';
import myInsightsNavigationChannel from '@salesforce/messageChannel/MyInsights_Navigation__c';

export default class MyInsightsController extends VeevaPageController {
  _htmlReportId;
  _htmlReportUUID;
  _modal = {};
  constructor(dataSvc, userInterface, messageSvc, sessionSvc, metaStore, appMetricsSvc, myInsightsService) {
    super(dataSvc, userInterface, messageSvc, metaStore, appMetricsSvc);
    this.myInsightsService = this.getProxiedService(myInsightsService || new MyInsightsService(dataSvc, sessionSvc));
    this.messageContext = createMessageContext();
  }

  get htmlReportId() {
    return this._htmlReportId;
  }

  set htmlReportId(value) {
    this._htmlReportId = value;
  }

  get htmlReportUUID() {
    return this._htmlReportUUID;
  }

  set htmlReportUUID(value) {
    this._htmlReportUUID = value;
  }

  showLoadingModal() {
    this.publishLoadingModalMessage(true);
  }

  closeLoadingModal() {
    this.publishLoadingModalMessage(false);
  }

  publishLoadingModalMessage(loading) {
    publish(this.messageContext, myInsightsModalChannel, {
      htmlReportId: this.htmlReportId,
      htmlReportUUID: this.htmlReportUUID,
      type: 'loading',
      data: {
        loading,
      },
    });
  }

  showConfirmationModal(modalConfig, closeCallback) {
    const title = this._getModalTitle(modalConfig);
    const messages = this._getModalMessages(modalConfig);
    if ((modalConfig && title) || messages) {
      const data = {
        title,
        messages,
      };
      this._showModal('confirm', data, message => {
        if (closeCallback) {
          closeCallback(message.data.result !== 'closed');
        }
      });
    }
  }

  showAlertModal(modalConfig, closeCallback) {
    const title = this._getModalTitle(modalConfig);
    const messages = this._getModalMessages(modalConfig);
    if ((modalConfig && title) || messages) {
      const data = {
        title,
        messages,
      };
      this._showModal('alert', data, () => {
        // The user cannot necessarily accept or decline an alert
        if (closeCallback) {
          closeCallback();
        }
      });
    }
  }

  matchesHTMLReportIdAndUUID(message) {
    return message && this.htmlReportId === message.htmlReportId && this.htmlReportUUID === message.htmlReportUUID;
  }

  async showDismissSuggestionSurveyModal(title, survey, labels, closeCallback) {
    if (title && survey && labels) {
      const result = await SuggestionSurveyModal.open({
        size: "small",
        title,
        cancelLabel: labels.cancel,
        submitLabel: labels.submit,
        survey
      });
      if (result && closeCallback) {
        closeCallback(result);
      } else if (!result && closeCallback) {
        closeCallback({ submit: false });
      }
    }
  }

  navigateToUrl(url) {
    publish(this.messageContext, myInsightsNavigationChannel, {
      htmlReportId: this.htmlReportId,
      htmlReportUUID: this.htmlReportUUID,
      urlInfo: {
        url,
      },
    });
  }

  navigateToViewRecord(object, recordId, targetId) {
    publish(this.messageContext, myInsightsNavigationChannel, {
      htmlReportId: this.htmlReportId,
      htmlReportUUID: this.htmlReportUUID,
      viewRecord: {
        object,
        recordId,
        targetId
      },
    });
  }

  navigateToViewSection(recordId, myInsightsUuid) {
    publish(this.messageContext, myInsightsNavigationChannel, {
      htmlReportId: this.htmlReportId,
      htmlReportUUID: this.htmlReportUUID,
      viewSection: {
        recordId,
      },
      myInsightsUuid
    });
  }

  navigateToNewRecord(object, fields) {
    publish(this.messageContext, myInsightsNavigationChannel, {
      htmlReportId: this.htmlReportId,
      htmlReportUUID: this.htmlReportUUID,
      newRecord: {
        object,
        fields,
      },
    });
  }

  getFeedbackData() {
    // This function is implemented in the FeedbackMyInsightsController subclass
    throw new Error('getFeedbackData not yet implemented');
  }

  _showModal(type, data, modalCloseCallback) {
    publish(this.messageContext, myInsightsModalChannel, {
      htmlReportId: this.htmlReportId,
      htmlReportUUID: this.htmlReportUUID,
      type,
      data,
    });
    const confirmationModalResponseSubscription = subscribe(this.messageContext, myInsightsModalChannel, message => {
      if (this.matchesHTMLReportIdAndUUID(message) && message.type === 'modalClosed' && message.data) {
        if (modalCloseCallback) {
          modalCloseCallback(message);
        }
        unsubscribe(confirmationModalResponseSubscription);
      }
    });
  }

  _getModalTitle(modalConfig) {
    if (!modalConfig) {
      return undefined;
    }
    return modalConfig.title;
  }

  _getModalMessages(modalConfig) {
    if (!modalConfig) {
      return undefined;
    }
    return modalConfig.messages;
  }

  async getBaseCdnDomainUrl() {
    return this.myInsightsService.retrieveCdnDomain();
  }

  async getOrgId() {
    return this.myInsightsService.retrieveOrgId();
  }

  async getCdnAuthToken(cdnContentUrl) {
    return this.myInsightsService.retrieveCdnAuthToken(cdnContentUrl);
  }
}