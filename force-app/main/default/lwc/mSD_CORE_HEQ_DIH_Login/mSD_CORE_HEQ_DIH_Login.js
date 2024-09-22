import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import isguest from '@salesforce/user/isGuest';
//Static Resources
import dihLogin from '@salesforce/resourceUrl/MSD_CORE_HEQ_FEP';
//Apex Class
import dihUserLogin from '@salesforce/apex/MSD_CORE_HEQ_AuthController.dihUserLogin';

export default class MSD_CORE_HEQ_DIH_Login extends NavigationMixin(LightningElement) {

    showSpinner = false;
    @track dihURL;

    @wire(CurrentPageReference)
    wiredStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.stateRef = currentPageReference.state.state;
        }
    }

    connectedCallback() {
        this.showSpinner = true;
        this.dispatchEvent(new CustomEvent("componentInit", {
            bubbles: true,
            composed: true,
            detail: "login"
        }))
        this.dihURL = dihLogin + '/index.html';
        this.showSpinner = false;
    }

    @api
    setdata(userData){
        this.showSpinner = true;
        console.log('SetData' + JSON.stringify(userData.uuid));
        let usersData = JSON.stringify(userData);
        this.uuid = userData.uuid;
        console.log('uuid ' + this.uuid);
        if(this.uuid){
            this.dihURL = '';
            this.userLogin(userData.email, userData.givenName, userData.familyName, userData.uuid);
        }else{
            this.dihURL = dihLogin + '/index.html';
            this.showSpinner = false;
        }
    }

    userLogin(email, firstName, lastName, uuid) {
        this.showSpinner = true;
        console.log('userRegistration' + email);
        dihUserLogin({ email: email, firstName: firstName, lastName: lastName, uuid: uuid })
            .then((result) => {
                if (result != 'Error' && isguest) {
                    window.location.href = result;
                } else {
                    this.dihURL = dihLogin + '/index.html';
                    this.showSpinner = true;
                }
                console.log('dihUserLogin' + result);
            }).catch((err) => {
                console.log('dihUserLogin ' + JSON.stringify(err));
            });
    }
}