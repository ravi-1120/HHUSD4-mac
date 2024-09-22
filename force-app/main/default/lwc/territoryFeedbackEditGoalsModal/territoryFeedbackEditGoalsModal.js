import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';

export default class TerritoryFeedbackEditGoalsModal extends LightningElement {
  @api accountRecord;
  @api goalMetadata;
  @api header;
  @api territoryFeedbackService;
  @api territoryModelId;
  @api isAddTargetChallenge;
  @api useDefaultGoals;

  saveMessage;
  cancelMessage;

  async connectedCallback() {
    await this.loadLabels();
  }

  async loadLabels() {
    const messageService = getService('messageSvc');

    [this.saveMessage, this.cancelMessage] = await Promise.all([
      messageService.getMessageWithDefault('SAVE', 'Common', 'Save'),
      messageService.getMessageWithDefault('CANCEL', 'Common', 'Cancel'),
    ]);
  }

  get modalSize() {
    if (this.goalMetadata.length <= 2) {
      return 'small';
    }
    if (this.goalMetadata.length > 2 && this.goalMetadata.length < 5) {
      return 'medium';
    }
    return 'large';
  }

  get goalEditor() {
    return this.template.querySelector('c-territory-feedback-goal-editor');
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent('close'));
  }

  handleSubmit() {
    this.dispatchEvent(
      new CustomEvent('submitgoals', {
        detail: {
          feedbackGoalEditorRecord: this.goalEditor.feedbackGoalEditorRecord,
        },
      })
    );
  }
}