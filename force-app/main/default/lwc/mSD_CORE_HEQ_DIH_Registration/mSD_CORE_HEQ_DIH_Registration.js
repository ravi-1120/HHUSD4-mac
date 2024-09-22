import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import isguest from '@salesforce/user/isGuest';
//Static Resources
import dihLogin from '@salesforce/resourceUrl/MSD_CORE_HEQ_FEP';
//Apex Class
import dihUserRegistration from '@salesforce/apex/MSD_CORE_HEQ_AuthController.createCustomerPortalUser';

export default class MSD_CORE_HEQ_DIH_Registration extends NavigationMixin(LightningElement) {

    showSpinner = false;
    uuid;
    @track dihURL;

    @wire(CurrentPageReference)
    wiredStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.stateRef = currentPageReference.state.state;
        }
    }

    connectedCallback() {
        this.showSpinner = true;
        // this.dispatchEvent(new CustomEvent("componentInit", {
        //     bubbles: true,
        //     composed: true,
        //     detail: "reg"
        // }))
        this.dihURL = dihLogin + '/index.html?screenToRender=traditionalRegistration';
        this.showSpinner = false;
    }

    // @api
    // setdata(userData){
    //     this.showSpinner = true;
    //     console.log('SetData' + JSON.stringify(userData.uuid));
    //     let usersData = JSON.stringify(userData);
    //     this.uuid = userData.uuid;
    //     console.log('uuid ' + this.uuid);
    //     if(this.uuid && this.stateRef){
    //         this.dihURL = '';
    //         this.userRegistration(userData.email, userData.givenName, userData.familyName, userData.uuid);
    //     }else{
    //         this.dihURL = dihLogin + '/index.html?screenToRender=traditionalRegistration';
    //         this.showSpinner = false;
    //     }
    // }

    // userRegistration(email, firstName, lastName, uuid) {
    //     console.log('userRegistration' + email);
    //     dihUserRegistration({ email: email, firstName: firstName, lastName: lastName, uuid: uuid })
    //         .then((result) => {
    //             if(result !=null && result !=undefined){
    //                 this[NavigationMixin.Navigate]({
    //                     type: 'standard__webPage',
    //                     attributes: {
    //                         url: '/'
    //                     }
    //                 });
    //             }else{
    //                 this.showSpinner = true;
    //             }
    //             console.log('dihUserRegistration' + result);
    //         }).catch((err) => {
    //             console.log('dihUserRegistration ' + JSON.stringify(err));
    //         });
    // }
}