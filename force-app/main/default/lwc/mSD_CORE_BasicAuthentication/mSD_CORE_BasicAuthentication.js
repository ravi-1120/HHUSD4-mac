import { LightningElement, track, api } from 'lwc';

export default class MSD_CORE_BasicAuthentication extends LightningElement {

    @track isModal = true;
    @track usernameval;
    @track passwordval;
    @api disablesection;

    handlechange(event) {
        let name = event.currentTarget.dataset.id;
        if (name == 'username') {
            this.usernameval = event.target.value;
        } else if (name == 'password') {
            this.passwordval = event.target.value;
        }
    }
    handlesumbit(){
        console.log('Handle Submit Call');
        if (this.usernameval == 'admin@merck.com' && this.passwordval == 'Merck@2023') {
            this.isModal = false;
            this.disablesection = true;
        } else {
            if(this.usernameval != 'admin@merck.com'){
                let us = this.template.querySelector('.uncls');
                us.setCustomValidity("Please enter valid username");
            }
            if(this.passwordval != 'Merck@2023') {
                let pw = this.template.querySelector('.pwcls');
                pw.setCustomValidity("Please enter valid Password");
            }
            this.isModal = true;
            this.disablesection = false;
        }

        const selectedEvent = new CustomEvent("passvaluetologin", {
            detail: this.disablesection
        });
        console.log('selectedEvent==>',{selectedEvent});
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
}