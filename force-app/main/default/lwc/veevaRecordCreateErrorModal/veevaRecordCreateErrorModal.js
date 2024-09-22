import { LightningElement, api, track } from 'lwc';

export default class VeevaRecordCreateError extends LightningElement {
  
  @api error;
  @api closeHandler;

  @api
  get messages() {
    return this.error.messages;
  }

  @api
  get title() {
    return this.error.title;
  }

  @api
  get hasLoadedMessage() {
    return this.error;
  }
  
  handleClose() {
    if(this.closeHandler) {
      this.closeHandler();
    }
  }
}