import { AlignError, AsyncProcessRunningError } from 'c/territoryFeedbackErrors';
import TerritoryModelRecord from 'c/territoryModelRecord';
import LOCALE from '@salesforce/i18n/locale';
import TerritoryModelCommand from './territoryModelCommand';

export default class ManagerReturnAllToRosterMembersCommand extends TerritoryModelCommand {
  constructor(territoryFeedbackBasePage, targetTerritoryModel, label) {
    super(territoryFeedbackBasePage, targetTerritoryModel, label);
    this.numChildrenThatCanTransition = targetTerritoryModel.getChildrenThatCanTransition(TerritoryModelRecord.FEEDBACK_STATE).length;
    this.numChildrenThatCannotTransition = targetTerritoryModel.repLevelChildTerritories.length - this.numChildrenThatCanTransition;
  }

  async modalBody() {
    const messages = [];
    if (this.numChildrenThatCannotTransition) {
      const [cannotTransitionMessage, proceedMessage] = await Promise.all([
        this.messageService.getMessageWithDefault(
          'SUB_TERRS_CANNOT_BE_RETURNED',
          'Feedback',
          '{0} of the subordinate territories are not in a state that can be returned to their roster members.'
        ),
        this.messageService.getMessageWithDefault('PROCEED_WITH_REMAINING_TERRS', 'Feedback', 'Proceed with the remaining territories?'),
      ]);

      const formattedNumChildren = new Intl.NumberFormat(LOCALE).format(this.numChildrenThatCannotTransition);

      messages.push(cannotTransitionMessage.replace('{0}', formattedNumChildren));
      messages.push(proceedMessage);
    } else {
      messages.push(await this.messageService.getMessageWithDefault('ARE_YOU_SURE', 'Common', 'Are you sure?'));
    }
    return messages;
  }

  modalType() {
    return 'confirmation';
  }

  async execute() {
    await this.showModal(async () => {
      this.territoryFeedbackPage.clearModal();
      this.territoryFeedbackPage.showLoadingSpinner();
      await this.returnAllToRosterMembers();
      this.territoryFeedbackPage.hideLoadingSpinner();
    });
  }

  async returnAllToRosterMembers() {
    const runAsynchronously = this.numChildrenThatCanTransition >= 100;

    const response = await this.territoryFeedbackPage.territoryFeedbackService.moveToLifecycleState(
      this.targetTerritoryModel.id,
      TerritoryModelRecord.FEEDBACK_STATE,
      runAsynchronously
    );

    // For MVP we want to stop user from proceeding until async process has finished
    if (runAsynchronously) {
      throw new AsyncProcessRunningError("An asynchronous process is running against this user's data.");
    } else if (response.status !== 'SUCCESS') {
      throw new AlignError(response.message);
    }

    this.territoryFeedbackPage.updateTerritoryModels(
      response.territoryModelIds,
      null,
      response.availableLifecycleActions,
      false,
      true,
      response.canReview
    );
    this.territoryFeedbackPage.refreshTable();
  }
}