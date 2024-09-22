import { AlignError } from 'c/territoryFeedbackErrors';
import TerritoryModelRecord from 'c/territoryModelRecord';
import TerritoryModelCommand from './territoryModelCommand';

export default class RepReturnToRosterMemberCommand extends TerritoryModelCommand {
  async modalBody() {
    const areYouSureMessage = await this.messageService.getMessageWithDefault('ARE_YOU_SURE', 'Common', 'Are you sure?');
    return [areYouSureMessage];
  }

  modalType() {
    return 'confirmation';
  }

  execute() {
    this.showModal(async () => {
      this.territoryFeedbackPage.clearModal();
      this.territoryFeedbackPage.showLoadingSpinner();
      await this.returnToRosterMember();
      this.territoryFeedbackPage.hideLoadingSpinner();
    });
  }

  async returnToRosterMember() {
    const response = await this.territoryFeedbackPage.territoryFeedbackService.moveToLifecycleState(
      this.targetTerritoryModel.id,
      TerritoryModelRecord.FEEDBACK_STATE,
      false
    );

    if (response.status !== 'SUCCESS') {
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