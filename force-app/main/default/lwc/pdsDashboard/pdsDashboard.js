import { LightningElement, track, wire, api } from 'lwc';
import makerequest from '@salesforce/resourceUrl/PDSMakeRequest';
import viewrequest from '@salesforce/resourceUrl/PDSVRequest';
import mdpmakerequest from '@salesforce/resourceUrl/PDS_MDP_MakeRequest';
import mdpviewrequest from '@salesforce/resourceUrl/PDS_MDP_ViewRequest';
import { loadStyle } from 'lightning/platformResourceLoader';
import PDSDashboardcss from '@salesforce/resourceUrl/PDSDashboardcss';
import { NavigationMixin } from 'lightning/navigation';
import getRequestPage from '@salesforce/apex/PDS_DashboardController.getRequestPage';
import USER_ID from '@salesforce/user/Id';
import makerequestheader from '@salesforce/label/c.PDS_Dashboard_MRequest_Header';
import makerequestfooter from '@salesforce/label/c.PDS_MRequest_Card_Footer';
import makerequestbutton from '@salesforce/label/c.PDS_MRequest_Button';
import vrequestheader from '@salesforce/label/c.PDS_VRequest_Header';
import vrequestfooter from '@salesforce/label/c.PDS_VRequest_Footer';
import vrequestbutton from '@salesforce/label/c.PDS_VRequest_Button';
import requestTypeHeader from '@salesforce/label/c.PDS_RequestType_Header';
import cancelBtn from '@salesforce/label/c.PDS_Cancel_Btn';
import continueBtn from '@salesforce/label/c.PDS_Continue_Btn';
import mmop from '@salesforce/label/c.PDS_MMOP';
import getRelatedDonationTypes from '@salesforce/apex/PDS_DashboardController.getRelatedDonationTypes';

export default class PdsDashboard extends NavigationMixin(LightningElement) {

    USER_ID = USER_ID;
    makerequest = makerequest;
    viewrequest = viewrequest;
    mdpmakerequest = mdpmakerequest;
    mdpviewrequest = mdpviewrequest;
    contactData;
    createdContact;
    showSpinner = false;
    @track intaketype = false;
    @track donationTypes = [];
    @track isDisabled = false;
    @track selectedOptions = {};
    @track requestResult;
    @track isMDP = false;
    @track isMMOP = false;
    @track proposalId;
    @track donationName;

    connectedCallback() {
        this.showSpinner = true;
        this.getPageAccess();
        Promise.all([
            loadStyle(this, PDSDashboardcss)
        ])
    }

    labels = {
        makerequestheader,
        makerequestfooter,
        makerequestbutton,
        vrequestheader,
        vrequestfooter,
        vrequestbutton,
        requestTypeHeader,
        cancelBtn,
        continueBtn,
        mmop
    };

    closeResponse() {
        this.intaketype = false;
        this.selectedValue='';
        // this.template.querySelector('.cancel-btn').classList.remove('no-scroll'); 
        // this.template.querySelector('.crossicon').classList.remove('no-scroll'); 
    }
    value = '';

    @wire(getRelatedDonationTypes, { userId: '$USER_ID' })
    wiredDonationTypes({ error, data }) {
        if (data) {
            console.log('Data Types ' + JSON.stringify(data));
            this.donationTypes = data.map(donationType => ({ label: donationType.proposalId, value: donationType.donationType,uniqueName: donationType.donationType + '-' + donationType.proposalId, options: [{ label: mmop+' '+'-'+' '+ donationType.donationName, value: donationType.donationType }] }));
            this.isDisabled = (this.donationTypes.length == 0 && this.requestResult == 'MMOP') ? true : false;
        } else if (error) {
            console.log('error' + error);
        }
    }

    handleChange(event) {
        this.selectedValue = event.detail.value;
        const radioGroups = this.template.querySelectorAll('lightning-radio-group');
        radioGroups.forEach(group => {
            if (group.name !== event.target.name) {
                group.value = null;
            }
        });
    }
    get scrollableClass() {
        return this.donationTypes.length > 5 ? 'scrollable-container' : '';
    }
    // handleCardClick(event) {
    //     this.selectedValue = event.currentTarget.dataset.name;
    //     this.proposalId = event.currentTarget.dataset.id;

    //     const radioGroups = this.template.querySelectorAll('lightning-radio-group');
    //     console.log('radioGroups'+radioGroups);
    //     radioGroups.forEach(group => {
    //         group.value = (group.name === this.selectedValue) ? this.selectedValue : null;
    //     });
    // }
    handleCardClick(event) {
        const selectedName = event.currentTarget.dataset.name;
        const selectedId = event.currentTarget.dataset.id;

        this.selectedValue = selectedName;
        this.proposalId = selectedId;

        const radioGroups = this.template.querySelectorAll('lightning-radio-group');
        radioGroups.forEach(group => {
            const groupName = group.dataset.name;
            group.value = (groupName === selectedName + '-' + selectedId) ? selectedName : null;
        });
    }

    requestDetail() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'My_Requests__c',
                url: '/my-requests'
            }
        });
    }

    getRequest() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'Donation_Request__c',
                url: '/donation-request'
            }
        });
    }

    handleContinue() {
        if (!this.selectedValue) {
            console.error('No option selected');
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'Donation_Request__c',
                url: '/donation-request' + '?name=' + this.selectedValue + '&pid=' + this.proposalId
            }
        });
    }

    handleClick() {
        this.showSpinner = true;
        if (this.requestResult === 'MDP') {
            this.getRequest();
        } else {
            this.intaketype = true;
            this.showSpinner = false;
            // this.template.querySelector('.get-button').classList.add('no-scroll'); 
        }
    }

    get getButtonClass() {
        // return 'get-button' + ((this.donationTypes.length === 0 || this.requestResult === 'MMOP') ? ' disabled-button' : '');
    }

    getPageAccess() {
        getRequestPage({ userid: this.USER_ID })
            .then((result) => {
                this.requestResult = result;
                if(this.requestResult == 'MDP'){
                    this.isMDP = true;
                } else if(this.requestResult == 'MMOP'){
                    this.isMMOP = true;
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                console.error('error-->', { error });
            })
    }
}