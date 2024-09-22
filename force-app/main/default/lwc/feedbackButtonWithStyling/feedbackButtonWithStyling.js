import { LightningElement, api } from 'lwc';

export default class FeedbackButtonWithStyling extends LightningElement {
  @api text;
  @api disabled;
  @api buttonValue;
  @api clickHandler;
  @api isNumeric;
  @api goalId;

  handleClick(event) {
    event.goalId = this.goalId;
    this.clickHandler(event);
  }
}