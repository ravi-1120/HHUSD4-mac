import CommandHandler from './commandHandler';

export default class TerritoryFeedbackDataCommand extends CommandHandler {
  constructor(veevaUserInterfaceAPI, dataStore, feedbackMyInsightsController) {
    super(veevaUserInterfaceAPI);
    this.dataStore = dataStore;
    this.feedbackMyInsightsController = feedbackMyInsightsController;
  }

  async response() {
    const feedbackDataStoreId = this.feedbackMyInsightsController.getFeedbackDataStoreId();
    const territoryModelDetails = this.dataStore.retrieve(feedbackDataStoreId) || this.feedbackMyInsightsController.getFeedbackData();
    return this.formatResponse(territoryModelDetails);
  }

  formatResponse(territoryModelDetails) {
    return {
      success: true,
      terrData: territoryModelDetails,
    };
  }
}