import { LightningElement, api, wire } from 'lwc';
import EmEventConstant from 'c/emEventConstant';
import { fireEvent } from 'c/pubsub';
import { MessageContext, publish } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';

export default class EmEventButton extends LightningElement {
  @api meta;
  @api pageCtrl;

  @wire(MessageContext)
  messageContext;

  get recordId() {
    return this.pageCtrl.recordId;
  }

  get isMenu() {
    return this.meta.menu;
  }

  buttonHandler = {
    Generate_Invitations_vod: this.openPrintTemplateDialog,
    Generate_Sign_In_vod: this.openPrintTemplateDialog,
    Attendee_Reconciliation_vod: this.attendeeReconcilation,
  };

  handleClick() {
    if (this.buttonHandler[this.meta.name]) {
      this.buttonHandler[this.meta.name].bind(this)();
    } else {
      this.eventAction();
    }
  }

  openPrintTemplateDialog() {
    const dialogMeta = {
      button: this.meta,
      dataSvc: this.pageCtrl.dataSvc,
      messageSvc: this.pageCtrl.messageSvc,
      recordTypeName: this.meta.name === 'Generate_Sign_In_vod' ? 'Print_Sign_In_Template_vod' : 'Print_Invitation_Template_vod',
    };
    fireEvent(this, EmEventConstant.DISPLAY_PRINT_TEMPLATE_DIALOG, dialogMeta);
  }

  attendeeReconcilation() {
    const payload = {
      key: EmEventConstant.ATTENDEE_RECONCILIATION,
      eventId: this.recordId
    };
    publish(this.messageContext, eventsManagementChannel, payload);
  }

  async eventAction() {
    const response = await this.pageCtrl.eventActionSvc.getEventAction(this.recordId, this.meta.name);
    const eventAction = response.data[0];

    const dialogMeta = { eventAction, button: this.meta, ctrl: this.pageCtrl };
    if (EmEventButton.displayEventActionDialog(this.meta.name, eventAction)) {
      fireEvent(this, EmEventConstant.DISPLAY_EVENT_ACTION_DIALOG, dialogMeta);
    } else {
      this.pageCtrl.handleEventActionResult(eventAction.Id, {});
    }
  }

  static displayEventActionDialog(buttonName, eventAction) {
    // check event action and determine if we should show a dialog
    const actionType = eventAction.SFDC_Action_Type_vod__c;
    return (
      buttonName === 'Reschedule_vod' ||
      (!actionType && buttonName === 'Submit_for_Approval_vod') ||
      actionType === 'Submit_Manual_vod' ||
      eventAction.Allow_Comments_vod__c ||
      eventAction.Confirmation_Message_vod__c
    );
  }
}