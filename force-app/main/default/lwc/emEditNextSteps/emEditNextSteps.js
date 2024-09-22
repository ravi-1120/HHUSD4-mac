/* eslint-disable @lwc/lwc/no-inner-html */
import { LightningElement, api } from 'lwc';

export default class EmEditNextSteps extends LightningElement {
  @api nextStepsText;
  @api nextStepsTitle;

  renderedCallback() {
    this.setHTML();
  }

  setHTML() {
    const attachmentPoint = this.template.querySelector('.htmlContainer');
    if (attachmentPoint) {
      attachmentPoint.innerHTML = this.nextStepsText;
      this._innerHTMLSet = true;
    }
  }

  closeSideBar() {
    this.dispatchEvent(
      new CustomEvent('closesidebar', {
        bubbles: true,
        composed: true,
      })
    );
  }
}