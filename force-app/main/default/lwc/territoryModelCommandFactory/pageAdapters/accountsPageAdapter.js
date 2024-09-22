import { COLUMN_IDS, OPERATOR } from 'c/feedbackAccountsDatatable';
import { CHALLENGE_STATUSES } from 'c/territoryFeedbackConstants';
import FeedbackPageAdapter from './feedbackPageAdapter';

export default class AccountsPageAdapter extends FeedbackPageAdapter {
  showModal(modalConfig, confirmationCallback) {
    this.territoryFeedbackPage.showTerritoryModelCommandModal(modalConfig, confirmationCallback);
  }

  clearModal() {
    this.territoryFeedbackPage.clearTerritoryModelCommandModal();
  }

  showLoadingSpinner() {
    this.territoryFeedbackPage.renderLoadingSpinner(true);
  }

  hideLoadingSpinner() {
    this.territoryFeedbackPage.renderLoadingSpinner(false);
  }

  updatePendingChallenges() {
    // Does not need implemented, as the AccountsPage will refresh the page after command execution
  }

  updateNumAccounts() {
    // Does not need implemented, as the AccountsPage will refresh the page after command execution
  }

  updateActivityCounts() {
    // Does not need implemented, as the AccountsPage will refresh the page after command execution
  }

  refreshTable() {
    // Accounts Page will simply refresh data from Align
    this.territoryFeedbackPage.loadTable();
  }

  updateTerritoryModels() {
    // Does not need implemented, as the AccountsPage will refresh the page after command execution
  }

  navigateToAccountsScreen() {
    // Closes any open modals since we're already on the Accounts screen.
    this.clearModal();

    // Then clear any existing columns filters and filter on pending challenges for review.
    this.territoryFeedbackPage.replaceFilter(COLUMN_IDS.CHALLENGE_STATUS, CHALLENGE_STATUSES.CHALLENGED, OPERATOR.CONTAINS);
  }
}