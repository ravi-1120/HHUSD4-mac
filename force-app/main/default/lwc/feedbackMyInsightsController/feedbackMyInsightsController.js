import MyInsightsController from 'c/myInsightsController';

export default class FeedbackMyInsightsController extends MyInsightsController {
  _feedbackLocalDataService;

  constructor(dataSvc, userInterface, messageSvc, sessionSvc, metaStore, appMetricsSvc, myInsightsService, feedbackLocalDataService) {
    super(dataSvc, userInterface, messageSvc, sessionSvc, metaStore, appMetricsSvc, myInsightsService);

    this._feedbackLocalDataService = feedbackLocalDataService;
  }

  set feedbackLocalDataService(service) {
    this._feedbackLocalDataService = service;
  }

  getFeedbackData() {
    return this._feedbackLocalDataService?.territoryModelDetails;
  }

  getFeedbackDataStoreId() {
    return this._feedbackLocalDataService?.territoryModelDetailsStoreId;
  }
}