import { LightningElement, api, track } from 'lwc';

export default class EmBusRulesCommentsForm extends LightningElement {
  @api get page() {
    return this._page;
  }
  set page(value) {
    this._page = value;
    if (value) {
      this.rows = JSON.parse(JSON.stringify(value.rows));
      this.formRerendered = true;
      this.dispatchOverridesChangeEvent();
    }
  }

  @track rows = [];

  formRerendered = false;

  get singleColumn() {
    return !this.rows.some(row => row.commentBox || row.name);
  }

  renderedCallback() {
    if (this.formRerendered) {
      const inputs = this.template.querySelectorAll('lightning-textarea');
      inputs.forEach(input => {
        input.reportValidity();
      });
      this.formRerendered = false;
    }
  }

  handleCommentChange(event) {
    if (event.target.name != null) {
      this.rows[event.target.name].override.Comment_vod__c = event.target.value;
      event.target.reportValidity();
      this.dispatchOverridesChangeEvent();
    }
  }

  dispatchOverridesChangeEvent() {
    this.dispatchEvent(
      new CustomEvent('overrideschange', {
        detail: {
          overrides: this.rows.map(row => row.override),
        },
      })
    );
  }
}