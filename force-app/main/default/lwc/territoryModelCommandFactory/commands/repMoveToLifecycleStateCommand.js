import { AlignError } from 'c/territoryFeedbackErrors';
import TerritoryFeedbackConstants from 'c/territoryFeedbackConstants';
import LOCALE from '@salesforce/i18n/locale';
import TerritoryModelCommand from './territoryModelCommand';

export default class RepMoveToLifecycleStateCommand extends TerritoryModelCommand {
  constructor(territoryFeedbackBasePage, targetTerritoryModel, label, lifecycleStateName) {
    super(territoryFeedbackBasePage, targetTerritoryModel, label);
    this.lifecycleStateName = lifecycleStateName;
  }

  get shouldRenderPendingChallengesModal() {
    return this.targetTerritoryModel.numPendingChallenges && this.lifecycleStateName !== 'change_state_to_draft__c' && this.lifecycleStateName !== 'change_state_to_manager_review__c';
  }

  async modalBody() {
    return this.shouldRenderPendingChallengesModal ? this.pendingChallengesModalBody() : this.confirmationModalBody();
  }

  async pendingChallengesModalBody() {
    const [pendingMsg, approveOrRejectMsg] = await Promise.all([
      this.messageService.getMessageWithDefault('CHALLENGES_STILL_PENDING', 'Feedback', '{0} challenges are still pending.'),
      this.messageService.getMessageWithDefault(
        'CHALLENGES_MUST_BE_APPROVED',
        'Feedback',
        'Challenges must be approved or rejected before submitting.'
      ),
    ]);

    const formattedNumPendingChallenges = new Intl.NumberFormat(LOCALE).format(this.targetTerritoryModel.numPendingChallenges);

    return [pendingMsg.replace('{0}', formattedNumPendingChallenges), approveOrRejectMsg];
  }

  async confirmationModalBody() {
    const confirmationMessage = await this.messageService.getMessageWithDefault('ARE_YOU_SURE', 'Common', 'Are you sure?')
    return [confirmationMessage];
  } 

  modalType() {
    return this.shouldRenderPendingChallengesModal ? 'pendingChallengesWithReview' : 'confirmation';
  }

  async execute() {
    if (this.shouldRenderPendingChallengesModal) {
      await this.showModal(async userAction => {
        this.territoryFeedbackPage.showLoadingSpinner();
        if (userAction === 'review') {
          this.navigateToAccountsScreen();
        } else {
          await this.approveOrRejectPendingChallenges(userAction);
          await this.moveToLifecycleState();
        }
        this.territoryFeedbackPage.hideLoadingSpinner();
      });
    } else {
      await this.showModal(async () => {
        this.territoryFeedbackPage.clearModal();
        this.territoryFeedbackPage.showLoadingSpinner();
        await this.moveToLifecycleState();
        this.territoryFeedbackPage.hideLoadingSpinner();
      });
    }
  }

  navigateToAccountsScreen() {
    this.territoryFeedbackPage.navigateToAccountsScreen(this.targetTerritoryModel.id, TerritoryFeedbackConstants.PENDING_CHALLENGES);
  }

  async approveOrRejectPendingChallenges(shouldApprove) {
    const response = await this.territoryFeedbackPage.territoryFeedbackService.bulkApproveOrRejectPendingChallenges(
      this.targetTerritoryModel.id,
      shouldApprove === 'approve'
    );

    if (response.status !== 'SUCCESS') {
      throw new AlignError(response.message);
    }

    this.territoryFeedbackPage.updatePendingChallenges(this.targetTerritoryModel.id);
    this.territoryFeedbackPage.updateNumAccounts(this.targetTerritoryModel.id, response.fieldPlanBasicTerritoryModel);
    this.territoryFeedbackPage.updateActivityCounts(this.targetTerritoryModel.id, response.fieldPlanBasicTerritoryModel);
  }

  async moveToLifecycleState() {
    const response = await this.territoryFeedbackPage.territoryFeedbackService.moveToLifecycleState(
      this.targetTerritoryModel.id,
      this.lifecycleStateName,
      false
    );

    if (response.status !== 'SUCCESS') {
      throw new AlignError(response.message);
    }

    const isFeedbackComplete = this.lifecycleStateName === 'change_state_to_feedback_complete__c';
    this.territoryFeedbackPage.updateTerritoryModels(
      response.territoryModelIds,
      response.lifecycleState,
      response.availableLifecycleActions,
      isFeedbackComplete,
      false,
      response.canReview
    );
    this.territoryFeedbackPage.refreshTable();
    this.territoryFeedbackPage.clearModal();
  }
}