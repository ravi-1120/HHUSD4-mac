import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import cancelSuccess from '@salesforce/label/c.PDS_CancelRequestConfirmation';
import cancelError from '@salesforce/label/c.PDS_CancelRequestError';
import cancelBtn from '@salesforce/label/c.PDS_Cancel_Btn';
import submitBtn from '@salesforce/label/c.PDS_Submit_Btn';
import cancelDonationRequest from '@salesforce/label/c.PDS_CancelDonationRequest';

export default class PdsCancelDonationRequest extends LightningElement {
    @api recordId;
    labels ={
        cancelBtn,
        submitBtn,
        cancelDonationRequest
    }
    handleSubmit() {

        const fields = {
            Id: this.recordId, // The Id of the record to update
            PDS_Donation_Request_Status__c: 'Cancelled', 
            PDS_Request_Resolution__c: 'Canceled' 
        };

        // Create a record input object
        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            // Show success message using toast event
            this.closeAction();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'success',
                    message: cancelSuccess,
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            // Show error message using toast event
            this.closeAction();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: cancelError,
                    variant: 'error'
                })
            );
        });
    }
    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}