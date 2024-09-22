import { LightningElement, api } from 'lwc';
import FeedbackMyInsightsController from 'c/feedbackMyInsightsController';
import { getService, SERVICES } from 'c/veevaServiceFactory';

export default class FeedbackMyInsights extends LightningElement {
  @api htmlReportId;
  @api maxHeight;
  @api pageCtrl;

  _feedbackLocalDataService;

  @api
  get feedbackLocalDataService() {
    return this._feedbackLocalDataService;
  }

  set feedbackLocalDataService(service) {
    this._feedbackLocalDataService = service;
    if (this.pageCtrl) {
      this.pageCtrl.feedbackLocalDataService = this._feedbackLocalDataService;
      this.refreshMyInsights();
    }
  }

  get myInsightsElement() {
    return this.template.querySelector('c-my-insights');
  }

  connectedCallback() {
    if (!this.pageCtrl) {
      this.pageCtrl = new FeedbackMyInsightsController(
        getService(SERVICES.DATA),
        getService(SERVICES.UI_API),
        getService(SERVICES.MESSAGE),
        getService(SERVICES.SESSION),
        getService(SERVICES.META),
        getService(SERVICES.APP_METRIC_SERVICE),
        null, // let MyInsightsController handle instantiation of MyInsightsService
        this.feedbackLocalDataService
      );
    }
  }

  refreshMyInsights() {
    this.myInsightsElement?.refresh();
  }
}