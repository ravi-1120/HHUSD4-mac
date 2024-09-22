// This class defines the interface of methods and properties used by the TerritoryModelCommands.
// If a property or method is named differently and/or doesn't exist in the actual `territoryFeedbackPage` subclass implementation,
// then the corresponding property or function should be overridden in the adapter class.
export default class FeedbackPageAdapter {
  constructor(territoryFeedbackPage) {
    this.territoryFeedbackPage = territoryFeedbackPage;
  }

  get territoryFeedbackService() {
    return this.territoryFeedbackPage.territoryFeedbackService;
  }

  get messageService() {
    return this.territoryFeedbackPage.messageService;
  }

  clearModal() {
    this.territoryFeedbackPage.clearModal();
  }

  showLoadingSpinner() {
    this.territoryFeedbackPage.showLoadingSpinner();
  }

  hideLoadingSpinner() {
    this.territoryFeedbackPage.hideLoadingSpinner();
  }

  updatePendingChallenges(territoryId) {
    this.territoryFeedbackPage.updatePendingChallenges(territoryId);
  }

  updateNumAccounts(territoryId, updatedTerritoryWithCounts) {
    this.territoryFeedbackPage.updateNumAccounts(territoryId, updatedTerritoryWithCounts);
  }

  updateActivityCounts(territoryId, updatedTerritoryWithPlanChannels) {
    this.territoryFeedbackPage.updateActivityCounts(territoryId, updatedTerritoryWithPlanChannels);
  }

  refreshTable() {
    this.territoryFeedbackPage.refreshTable();
  }

  updateTerritoryModels(updatedTerritoryIds, updatedStatus, updatedLifecycleActions, isFeedbackComplete, isFeedback, canReview) {
    this.territoryFeedbackPage.updateTerritoryModels(
      updatedTerritoryIds,
      updatedStatus,
      updatedLifecycleActions,
      isFeedbackComplete,
      isFeedback,
      canReview
    );
  }

  navigateToAccountsScreen(selectedTerritoryModelId, selectedAccountsFilter) {
    this.territoryFeedbackPage.navigateToAccountsScreen(selectedTerritoryModelId, selectedAccountsFilter);
  }
}