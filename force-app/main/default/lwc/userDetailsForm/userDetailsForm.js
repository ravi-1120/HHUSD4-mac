import { LightningElement, track, api } from 'lwc';
import messageHeader from '@salesforce/label/c.HCP_Scheduler_Footer_Message_Header'
import messageFooter from '@salesforce/label/c.HCP_Scheduler_Footer_Message_Footer'
import userFormHeader from '@salesforce/label/c.AMO_User_Form_Header';
import indicationLabel from '@salesforce/label/c.AMO_User_Form_Indication_Label';
import userInfoLabel from '@salesforce/label/c.AMO_User_Information_Label';
import userPhoneInfoLabel from '@salesforce/label/c.AMO_User_Phone_Info_Label';
import userPhoneLabel from '@salesforce/label/c.AMO_User_Phone_Label';
import userEmailLabel from '@salesforce/label/c.AMO_User_Email_Label';
import userEmailLabelCallMeNow from '@salesforce/label/c.AMO_User_Email_Label_Call_Me_Now';


//const USER_FORM_FOOTER = 'Your phone number is only required to reach you. Rest assured, this information will not be stored or used for any other reason.';
const EMAIL_REGEX = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;

export default class UserDetailsForm extends LightningElement {
    label = {
        messageHeader,
        messageFooter,
        userFormHeader,
        indicationLabel,
        userInfoLabel,
        userPhoneInfoLabel,
        userPhoneLabel,
        userEmailLabel,
        userEmailLabelCallMeNow
    };
    //userFormFooter = USER_FORM_FOOTER;
    @track userFormRecord = {};
    @track disableSubmit = false;
    @api isCallMeNow;
    timeoutId;

    handleUserFormChange(event) {
        let currentLabel = event.target.dataset.value;
        this.userFormRecord[currentLabel] = event['currentTarget'].value;
        // clearTimeout(this.timeoutId);
        //  this.timeoutId = setTimeout(this.handleDataLayerEvent.bind(this, event.target), 1000);
    }

    handleSubmit() {
        let phoneField = this.template.querySelector('.Phone');
        if (phoneField.value != null) {
            if (!this.validatePhoneNumber(phoneField.value)) {
                phoneField.setCustomValidity("Please give a valid phone number.");
            } else {
                phoneField.setCustomValidity(""); // clear previous value
            }
            phoneField.reportValidity();
        }
        var emailField = this.template.querySelector('.email');
        console.log('email field length-->' + emailField.value.length);
        if (emailField.value.length > 0) {
            if (!EMAIL_REGEX.test(emailField.value)) {
                emailField.setCustomValidity("You have entered an invalid format.");
            } else {
                emailField.setCustomValidity(""); // clear previous value
            }
            emailField.reportValidity();
        }
        else {
            emailField.setCustomValidity("");
        }
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);
        if (allValid) {
            this.disableSubmit = true;
            const userFormDetailsEvent = new CustomEvent("userformdetails", {
                detail: this.userFormRecord
            });
            this.dispatchEvent(userFormDetailsEvent);
        }
    }


    validatePhoneNumber(phoneNumberString) {
        var cleanedtemp = ('' + phoneNumberString).replace(/\D/g, '');
        console.log('cleanedtemp-->' + cleanedtemp);
        var lenghtToCheck = 10;//(phoneNumberString.includes('+1')) ? 11 : 10;
        console.log('---' + lenghtToCheck);
        if (cleanedtemp.length == lenghtToCheck) {
            /*var match = phoneNumberString.match(/^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/im);
            if (match) {
                return true;
            }
            else {
                return false;
            }*/
            return true;
        } else {
            return false;
        }
    }

    handleDataLayerEvent(event) {
        var evt = { 'label': event.target.dataset.value, 'value': 'click' };
        const selectedTimeslotEvent = new CustomEvent("userdetailschange", {
            detail: evt
        });
        this.dispatchEvent(selectedTimeslotEvent);
    }
}