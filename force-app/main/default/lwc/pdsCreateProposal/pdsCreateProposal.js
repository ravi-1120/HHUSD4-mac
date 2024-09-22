import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class PdsCreateProposal extends LightningElement {
    
    @api availableActions = [];

    connectedCallback() {
     this.handleSuccess();
     this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Donation request proposal document has been generated successfully.",
                        variant: "success",
                    }),
                );
    }
  
    handleSuccess() {
        this.handleRefresh();
    }

    handleRefresh() {
        if (this.availableActions.find((action) => action === 'FINISH')) {
            const navigateNextEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }
}