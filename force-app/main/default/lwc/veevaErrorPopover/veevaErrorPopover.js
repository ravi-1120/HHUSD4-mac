import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';

export default class VeevaErrorPopover extends LightningElement {
  // {Array} of field objects
  @api fieldErrors;
  // {Array} of Strings
  @api recordErrors;

  defaultSnagLabel = 'We hit a snag.';
  defaultPageErrorsLabel = 'Review the errors on this page.';
  defaultFieldErrorsLabel = 'Review the following fields.';

  get showRecordErrors() {
    return this.recordErrors?.length > 0;
  }

  get showFieldErrors() {
    return this.fieldErrors?.length > 0;
  }

  get addGapBetweenSections() {
    return this.showRecordErrors && this.showFieldErrors;
  }

  async connectedCallback() {
    await this.loadDefaultVeevaMessages();
  }

  handleKeyDown(event) {
    if (event.code === 'Escape') {
      this.dispatchClose();
    }
  }

  renderedCallback() {
    this.template.querySelector('a')?.focus();
  }

  async loadDefaultVeevaMessages() {
    const veevaMessageService = getService('messageSvc');
    [this.defaultSnagLabel, this.defaultPageErrorsLabel, this.defaultFieldErrorsLabel] = await Promise.all([
      veevaMessageService.getMessageWithDefault('WE_HIT_A_SNAG', 'Lightning', this.defaultSnagLabel),
      veevaMessageService.getMessageWithDefault('REVIEW_THE_ERRORS_ON_THIS_PAGE', 'Lightning', this.defaultPageErrorsLabel),
      veevaMessageService.getMessageWithDefault('REVIEW_THE_FOLLOWING_FIELDS', 'Lightning', this.defaultFieldErrorsLabel),
    ]);
  }

  handleClick(event) {
    this.dispatchEvent(
      new CustomEvent('errorclicked', {
        detail: {
          fieldError: this.fieldErrors.find(fieldError => fieldError.index === Number.parseInt(event.target.dataset.index, 10)),
        },
        bubbles: true,
        composed: true,
      })
    );
  }

  dispatchClose() {
    this.dispatchEvent(new CustomEvent('close'));
  }
}