import { AlignError } from 'c/territoryFeedbackErrors';
import LOCALE from '@salesforce/i18n/locale';
import TerritoryModelCommand from './territoryModelCommand';

export default class ApproveOrRejectPendingChallengesCommand extends TerritoryModelCommand {
  constructor(territoryFeedbackBasePage, targetTerritoryModel, label, shouldApprove) {
    super(territoryFeedbackBasePage, targetTerritoryModel, label);
    this.shouldApprove = shouldApprove;
  }

  async modalBody() {
    const approveOrRejectMessage = this.shouldApprove
      ? await this.messageService.getMessageWithDefault('APPROVE_ALL_PENDING_CHALLENGES', 'Feedback', 'Approve all {0} pending challenges?')
      : await this.messageService.getMessageWithDefault('REJECT_ALL_PENDING_CHALLENGES', 'Feedback', 'Reject all {0} pending challenges?');

    const formattedNumPendingChallenges = new Intl.NumberFormat(LOCALE).format(this.targetTerritoryModel.numPendingChallenges);

    return [approveOrRejectMessage.replace('{0}', formattedNumPendingChallenges)];
  }

  modalType() {
    return 'confirmation';
  }

  async execute() {
    await this.showModal(async () => {
      this.territoryFeedbackPage.clearModal();
      this.territoryFeedbackPage.showLoadingSpinner();
      await this.approveOrRejectPendingChallenges();
      this.territoryFeedbackPage.hideLoadingSpinner();
    });
  }

  async approveOrRejectPendingChallenges() {
    const response = await this.territoryFeedbackPage.territoryFeedbackService.bulkApproveOrRejectPendingChallenges(
      this.targetTerritoryModel.id,
      this.shouldApprove
    );

    if (response.status !== 'SUCCESS') {
      throw new AlignError(response.message);
    }

    this.territoryFeedbackPage.updatePendingChallenges(this.targetTerritoryModel.id);
    this.territoryFeedbackPage.updateNumAccounts(this.targetTerritoryModel.id, response.fieldPlanBasicTerritoryModel);
    this.territoryFeedbackPage.updateActivityCounts(this.targetTerritoryModel.id, response.fieldPlanBasicTerritoryModel);
    this.territoryFeedbackPage.refreshTable();
  }
}