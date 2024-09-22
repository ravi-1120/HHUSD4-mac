import { LightningElement, track, wire, api } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

import getPicklistValue from '@salesforce/apex/MSD_CORE_RegistrationController.getPicklistValue';
import getEligibilityDetail from '@salesforce/apex/MSD_CORE_RegistrationController.getEligibilityDetail';
import submitPersonalPage from '@salesforce/apex/MSD_CORE_SettingsController.submitPersonalPage';

import plus from '@salesforce/resourceUrl/plusicon';
import CloseIconImage from '@salesforce/resourceUrl/CloseIconImage';
import RegistrationPage from '@salesforce/resourceUrl/RegistrationPage';
import USER_ID from '@salesforce/user/Id';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

import registrationerror from '@salesforce/label/c.MSD_CORE_RegistrationError';
export default class MSD_CORE_EditPersonalPage extends LightningElement {

    plusimg = plus;
    closeimg = CloseIconImage;

    @track licenselist = [];
    @track counter = 0;
    @track accountData;

    @track salutation;
    @track firstname;
    @track lastname;
    @track suffix;
    @track designation;
    @track speciality;

    @track salutatioption = [];
    @track specialityoption = [];
    @track suffixoption = [];
    @track designationoption = [];
    @track licensestateoption = [];
    @track licensetypeoption = [];

    @track eligibilityWrapFinal = {};
    @track eligibilityWrap = {};

    @track eligibilityData;
    @track contactrole = '';

    @track nextbtnclass = 'nextbtncls';
    @track nextbtndisable = true;

    label = {
        registrationerror
    };

    // Method Name:         WiredgetSalutationPicklistValue
    // Method Use:          Used for getting Picklist value
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    @wire(getPicklistValue, { objectType: 'Account', selectedField: 'Preferred_Salutation_MRK__c' })
    WiredgetSalutationPicklistValue({ error, data }) {
        if (data) {
            console.log('Result of WiredgetSalutationPicklistValue-->', { data });
            let option = [];
            data.forEach(r => {
                option.push({
                    attributes: null,
                    label: r,
                    validFor: '',
                    value: r,
                });
            });
            this.salutatioption =  [{label:'--None--', value:''}, ...option]; //R5
        } if (error) {
            console.log('ERROR in WiredgetSalutationPicklistValue-->', { error });
        }
    }

    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        console.log({ value });
        const { data, error } = value;
        if (data) {
            console.log({ data });
            this.contactrole = data;
        }
        if (error) {
            console.log({ error });
        }
    }

    // Method Name:         WiredgetSpecialityPicklistValue
    // Method Use:          Used for getting Picklist value
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    @wire(getPicklistValue, { objectType: 'Account', selectedField: 'IMS_Sub_Specialty_MRK__c' })
    WiredgetSpecialityPicklistValue({ error, data }) {
        if (data) {
            console.log('Result of WiredgetSpecialityPicklistValue-->', { data });
            let option = [];
            data.forEach(r => {
                option.push({
                    attributes: null,
                    label: r,
                    validFor: '',
                    value: r,
                });
            });
            this.specialityoption = option;
        } if (error) {
            console.log('ERROR in WiredgetSpecialityPicklistValue-->', { error });
        }
    }

    // Method Name:         WiredgetSuffixPicklistValue
    // Method Use:          Used for getting Picklist value
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    @wire(getPicklistValue, { objectType: 'Account', selectedField: 'Preferred_Suffix_MRK__c' })
    WiredgetSuffixPicklistValue({ error, data }) {
        if (data) {
            console.log('Result of WiredgetSuffixPicklistValue-->', { data });
            let option = [];
            data.forEach(r => {
                option.push({
                    attributes: null,
                    label: r,
                    validFor: '',
                    value: r,
                });
            });
            this.suffixoption = [{label:'--None--', value:''}, ...option];         //R5
        } if (error) {
            console.log('ERROR in WiredgetSuffixPicklistValue-->', { error });
        }
    }

    // Method Name:         WiredgetDesignationPicklistValue
    // Method Use:          Used for getting Picklist value
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    @wire(getPicklistValue, { objectType: 'MSD_CORE_Eligibility__c', selectedField: 'MSD_CORE_Designation__c' })
    WiredgetDesignationPicklistValue({ error, data }) {
        if (data) {
            console.log('Result of WiredgetDesignationPicklistValue-->', { data });
            let option = [];
            data.forEach(r => {
                option.push({
                    attributes: null,
                    label: r,
                    validFor: '',
                    value: r,
                });
            });
            this.designationoption = option;
        } if (error) {
            console.log('ERROR in WiredgetDesignationPicklistValue-->', { error });
        }
    }

    // Method Name:         WiredgetStatePicklistValue
    // Method Use:          Used for getting Picklist value
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    @wire(getPicklistValue, { objectType: 'License__c', selectedField: 'MSD_CORE_License_State__c' })
    WiredgetStatePicklistValue({ error, data }) {
        if (data) {
            console.log('Result of WiredgetStatePicklistValue-->', { data });
            let option = [];
            data.forEach(r => {
                option.push({
                    attributes: null,
                    label: r,
                    validFor: '',
                    value: r,
                });
            });
            this.licensestateoption = option;
        } if (error) {
            console.log('ERROR in WiredgetStatePicklistValue-->', { error });
        }
    }

    // Method Name:         WiredgetTypePicklistValue
    // Method Use:          Used for getting Picklist value
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    @wire(getPicklistValue, { objectType: 'License__c', selectedField: 'MSD_CORE_Type_of_license__c' })
    WiredgetTypePicklistValue({ error, data }) {
        if (data) {
            console.log('Result of WiredgetTypePicklistValue-->', { data });
            let option = [];
            data.forEach(r => {
                option.push({
                    attributes: null,
                    label: r,
                    validFor: '',
                    value: r,
                });
            });
            this.licensetypeoption = option;
        } if (error) {
            console.log('ERROR in WiredgetTypePicklistValue-->', { error });
        }
    }

    // Method Name:         getEligibility
    // Method Use:          Used for getting Eligibility detail
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    getEligibility() {
        getEligibilityDetail({})
        .then((result)=>{
            console.log('Result in GetEligibility-->',{result});
            this.eligibilityData = result;
            this.loadEligibility();
            if (result.Licenses__r) {
                if (result.Licenses__r.length > 0) {
                    for (let key = 0; key < result.Licenses__r.length; key++) {
                        this.counter += 1;
                        this.licenselist.push({ 
                            id: 'inputbox' + this.counter, 
                            value: this.counter, 
                            name: result.Licenses__r[key].Name,
                            number: result.Licenses__r[key].MSD_CORE_License_Number__c,
                            state: result.Licenses__r[key].MSD_CORE_License_State__c,
                            type: result.Licenses__r[key].MSD_CORE_Type_of_license__c,
                            nameid: 'nameidval'+this.counter,
                            stateid: 'stateidval'+this.counter,
                            typeid: 'typeidval'+this.counter
                        });
                    }
                } 
            } else {
                this.counter += 1;
                this.licenselist.push({ 
                    id: 'inputbox' + this.counter, 
                    value: this.counter, 
                    name: '',
                    number: '',
                    state: '',
                    type: '',
                    nameid: 'nameidval'+this.counter,
                    stateid: 'stateidval'+this.counter,
                    typeid: 'typeidval'+this.counter
                });
            }
        })
        .catch((error)=>{
            console.log('Error in GetEligibility-->',{error});
        })
    }

    handlegaevent(event){
        console.log('enteredintoloop>>');
        let inptName = event.currentTarget.dataset.name;
        if(inptName == 'salutation'){
            this.fireDataLayerEvent('dropdown', '', 'salutation', '', 'settings__c', '/settings', '');
        }else if (inptName == 'firstname'){
            this.fireDataLayerEvent('label', '', 'first name', '', 'settings__c', '/settings', '');
        }
        else if (inptName == 'lastname'){
            this.fireDataLayerEvent('label', '', 'last name', '', 'settings__c', '/settings', '');
        }
        else if (inptName == 'suffix'){
            this.fireDataLayerEvent('dropdown', '', 'suffix', '', 'settings__c', '/settings', '');
        }
        else if (inptName == 'designation'){
            this.fireDataLayerEvent('dropdown', '', 'title', '', 'settings__c', '/settings', '');
        }
        else if (inptName == 'speciality'){
            this.fireDataLayerEvent('dropdown', '', 'specialty', '', 'settings__c', '/settings', '');
        }
        else if (inptName == 'name'){
            this.fireDataLayerEvent('label', '', 'name on license', '', 'settings__c', '/settings', '');
        }
        else if (inptName == 'number'){
            this.fireDataLayerEvent('label', '', 'license number', '', 'settings__c', '/settings', '');
        }
        else if (inptName == 'state'){
            this.fireDataLayerEvent('dropdown', '', 'licensing state', '', 'settings__c', '/settings', '');
        }
        else if (inptName == 'type'){
            this.fireDataLayerEvent('dropdown', '', 'license type', '', 'settings__c', '/settings', '');
        }
        
    }

    // Method Name:         renderedCallback
    // Method Use:          Used for loading external CSS file
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    renderedCallback() {
        Promise.all([
            loadStyle(this, RegistrationPage),
        ]).then(() => {
            console.log('Files loaded');
        })
            .catch(error => {
                console.log(error.body.message);
            });
    }

    // Method Name:         connectedCallback
    // Method Use:          Called on page load
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    connectedCallback() {
        this.getEligibility();
    }

    // Method Name:         addlicensesection
    // Method Use:          Used for the adding license section
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    addlicensesection() {
        let _tempList = [];
        if (this.licenselist.length < 3) {
            this.counter += 1;
            this.licenselist.push({ id: 'inputbox' + this.counter, value: this.counter, name: '', number: '', state: '', type: '', nameid: 'nameidval'+this.counter, stateid: 'stateidval'+this.counter, typeid: 'typeidval'+this.counter });
            let count = 0;
            this.licenselist.forEach(currentItem => {
                count += 1;
                currentItem.id = 'inputbox'+count;
                currentItem.nameid = 'nameidval'+count;
                currentItem.stateid = 'stateidval'+count;
                currentItem.typeid = 'typeidval'+count;
                currentItem.value = count;
                _tempList.push(currentItem);
            });
            console.log({_tempList});
            this.licenselist = [];
            this.licenselist = JSON.parse(JSON.stringify(_tempList));
            console.log('this.licenselist ADD LIC->',this.licenselist);
        } else {
            this.template.querySelector('c-custom-toast').showToast('error', 'You can add upto 3 License');
        }
        this.fireDataLayerEvent('button', '', 'add license', '', 'settings__c', '/settings', '');
    }

    // Method Name:         removelicensesection
    // Method Use:          Used for the remove license section
    // Developer Name:      Ravi Modi
    // Created Date:        04 Aug 2023
    removelicensesection(event) {
        let getid = event.currentTarget.dataset.id;
        let _tempList = [];
        let count = 0;
        this.licenselist.forEach(currentItem => {
            if (currentItem.id != getid) {
                count += 1;
                currentItem.id = 'inputbox' + count;
                currentItem.value = count;
                _tempList.push(currentItem);
            }
        });
        this.licenselist = [];
        this.licenselist = JSON.parse(JSON.stringify(_tempList));
    }

    // Method Name:         handlechange
    // Method Use:          Used for storing the value in var
    // Developer Name:      Ravi Modi
    // Created Date:        30th May 2023
    handlechange(event) {
        try {
            let name = event.currentTarget.dataset.name;
            if (name == 'salutation') {
                this.salutation = event.target.value;
            } else if (name == 'firstname') {
                this.firstname = event.target.value;
            } else if (name == 'lastname') {
                this.lastname = event.target.value;
            } else if (name == 'suffix') {
                this.suffix = event.target.value;
            } else if (name == 'designation') {
                this.designation = event.target.value;
            } else if (name == 'speciality') {
                this.speciality = event.target.value;
            }
            this.handleValidation();
        } catch (error) {
            console.log('Error in handlechange-->', { error });
        }
    }

    handleValidation() {
        let isValidField = true;
        let isValidCombo = true;

        let inputFields = this.template.querySelectorAll('.inputcsscls');
        inputFields.forEach(infield => {
            if (!infield.checkValidity()) {
                isValidField = false;
            }
        });

        let comboboxFields = this.template.querySelectorAll('.inputboxcls');
        comboboxFields.forEach(infield => {
            if (!infield.checkValidity()) {
                isValidCombo = false;
            }
        });

        console.log({isValidField});
        console.log({isValidCombo});
        if (isValidField && isValidCombo) {
            this.nextbtndisable = false;
            this.nextbtnclass = 'nextbtncls btnenablecls';
        } else {
            this.nextbtndisable = true;
            this.nextbtnclass = 'nextbtncls';
        }
    }

    handlebackclk(detailval) {
        const clickpreviouspage = new CustomEvent("hidepersonalpage", {
            detail: detailval
        });
        this.dispatchEvent(clickpreviouspage);
        this.fireDataLayerEvent('button', '', 'cancel', '', 'settings__c', '/settings', '');
    }

    handlenextclk() {
        try {
            this.eligibilityWrapFinal.salutation = this.salutation;
            this.eligibilityWrapFinal.firstname = this.firstname;
            this.eligibilityWrapFinal.lastname = this.lastname;
            this.eligibilityWrapFinal.suffix = this.suffix;
            this.eligibilityWrapFinal.designation = this.designation;
            this.eligibilityWrapFinal.speciality = this.speciality;

            let mainlicmap = {};
            for (let key in this.licenselist) {
                var licmap = new Map();
                licmap['nameval'] = this.licenselist[key].name;
                licmap['numberval'] = this.licenselist[key].number;
                licmap['stateval'] = this.licenselist[key].state;
                licmap['typeval'] = this.licenselist[key].type;
                mainlicmap[key] = licmap;
            }
            for(var key in mainlicmap){
                if(mainlicmap[key].nameval == ''){
                    delete mainlicmap[key];
                }
            }
            this.submitPersonalMethod(mainlicmap);
        } catch (error) {
            console.log('Error in Handle Finish-->', { error });
        }
        this.fireDataLayerEvent('button', '', 'save', '', 'settings__c', '/settings', '');
    }

    // Handle License Change
    handlelicchange(event) {
        let val = event.target.value;
        console.log({val});
        let dataid = event.currentTarget.dataset.id;
        console.log({dataid});
        let dataname = event.currentTarget.dataset.name;
        console.log({dataname});
        let count = 0;
        let _tempList = [];
        this.licenselist.forEach(currentItem => {
            console.log({currentItem});
            console.log({count});
            count += 1;
            if (currentItem.value == dataid) {
                console.log('IFF',{count});
                currentItem.id = 'inputbox' + count;
                currentItem.nameid = 'nameidval'+count;
                currentItem.stateid = 'stateidval'+count;
                currentItem.typeid = 'typeidval'+count;
                if(dataname == 'name') {
                    currentItem.name = val;
                }
                if(dataname == 'number') {
                    currentItem.number = val;
                }
                if(dataname == 'state') {
                    currentItem.state = val;
                }
                if(dataname == 'type') {
                    currentItem.type = val;
                }
                _tempList.push(currentItem);
            }
        });
    }

    submitPersonalMethod(licmap) {
        var licdata = JSON.stringify(licmap);
        console.log({licdata});
        console.log('eligibilityWrapFinal-->',this.eligibilityWrapFinal);

        submitPersonalPage({ wrapData: JSON.stringify(this.eligibilityWrapFinal), licensedata: licdata })
            .then((result) => {
                console.log('Result of submitEligibility--->', { result });
                // If Success
                if (result == 'Success') {
                    document.body.scrollTop = document.documentElement.scrollTop = 0;
                    this.handlebackclk('success');
                }
            })
            .catch((error) => {
                console.log('Error of submitEligibility--->', { error });
                this.template.querySelector('c-custom-toast').showToast('error', label.registrationerror);
            })
    }

    loadEligibility() {
        if (this.eligibilityData.MSD_CORE_Salutation__c) {
            this.salutation = this.eligibilityData.MSD_CORE_Salutation__c;
        }
        if (this.eligibilityData.MSD_CORE_First_Name__c) {
            this.firstname = this.eligibilityData.MSD_CORE_First_Name__c;
        }
        if (this.eligibilityData.MSD_CORE_Last_Name__c) {
            this.lastname = this.eligibilityData.MSD_CORE_Last_Name__c;
        }
        if (this.eligibilityData.MSD_CORE_Suffix__c) {
            this.suffix = this.eligibilityData.MSD_CORE_Suffix__c;
        }
        if (this.eligibilityData.MSD_CORE_Designation__c) {
            this.designation = this.eligibilityData.MSD_CORE_Designation__c;
        }
        if (this.eligibilityData.MSD_CORE_Specialty__c) {
            this.speciality = this.eligibilityData.MSD_CORE_Specialty__c;
        }
        if (this.salutation != '' && this.firstname != '' && this.lastname != '' && this.suffix != '' && this.designation != '' && this.speciality != '') {
            this.nextbtndisable = false;
            this.nextbtnclass = 'nextbtncls btnenablecls';
        } else {
            this.nextbtndisable = true;
            this.nextbtnclass = 'nextbtncls';
        }
        this.eligibilityWrapFinal = {};
        this.eligibilityWrapFinal.salutation = '';
        this.eligibilityWrapFinal.firstname = '';
        this.eligibilityWrapFinal.lastname = '';
        this.eligibilityWrapFinal.suffix = '';
        this.eligibilityWrapFinal.designation = '';
        this.eligibilityWrapFinal.speciality = '';
    }
    // Google Analytics.
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, productname) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'account management',
                page_purpose: 'account management',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: linkedtext,
                link_url: linkedurl,
                content_count: '',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: productname,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'settings',

            },
            bubbles: true,
            composed: true
        }));
    }
}