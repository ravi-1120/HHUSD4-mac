import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';

export default class TerritoryFeedbackModal extends LightningElement {
  @api confirmationCallback;
  modalType;
  modalTitle;
  modalMessages;

  get displayModal() {
    return this.showConfirmationModal || this.showPendingChallengesModal;
  }

  get showConfirmationModal() {
    return this.modalType === 'confirmation';
  }

  get showPendingChallengesModal() {
    return this.modalType === 'pendingChallenges' || this.modalType === 'pendingChallengesWithReview';
  }

  get showReviewButton() {
    return this.modalType === 'pendingChallengesWithReview';
  }

  async connectedCallback() {
    await this.loadVeevaMessages();
  }

  @api
  showModal(modalConfig) {
    ({ type: this.modalType, title: this.modalTitle, body: this.modalMessages } = modalConfig);
  }

  @api
  clearModal() {
    this.modalType = null;
    this.modalTitle = null;
    this.modalMessages = null;
  }

  handleConfirmCommand(event) {
    this.dispatchEvent(
      new CustomEvent('confirm', {
        detail: {
          selectedButton: event.target.name,
        },
      })
    );
  }

  handleCancelCommand() {
    this.dispatchEvent(new CustomEvent('cancel'));
  }

  async loadVeevaMessages() {
    const messageService = getService('messageSvc');
    [this.yesMessage, this.noMessage, this.cancelMessage, this.approveAllMessage, this.rejectAllMessage, this.reviewMessage] = await Promise.all([
      messageService.getMessageWithDefault('YES', 'Common', 'Yes'),
      messageService.getMessageWithDefault('NO', 'Common', 'No'),
      messageService.getMessageWithDefault('CANCEL', 'Common', 'Cancel'),
      messageService.getMessageWithDefault('APPROVE_ALL', 'Feedback', 'Approve All'),
      messageService.getMessageWithDefault('REJECT_ALL', 'Feedback', 'Reject All'),
      messageService.getMessageWithDefault('REVIEW', 'Feedback', 'Review'),
    ]);
  }
}