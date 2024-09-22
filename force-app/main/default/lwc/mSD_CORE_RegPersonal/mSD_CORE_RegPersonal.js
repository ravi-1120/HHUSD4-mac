import { LightningElement, track, wire, api } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

import getAccountDetail from '@salesforce/apex/MSD_CORE_RegistrationController.getAccountDetail';
import getPicklistValue from '@salesforce/apex/MSD_CORE_RegistrationController.getPicklistValue';
import submitEligibility from '@salesforce/apex/MSD_CORE_RegistrationController.submitEligibility';

import plus from '@salesforce/resourceUrl/plusicon';
import CloseIconImage from '@salesforce/resourceUrl/CloseIconImage';
import RegistrationPage from '@salesforce/resourceUrl/RegistrationPage';

import registrationerror from '@salesforce/label/c.MSD_CORE_RegistrationError';
export default class MSD_CORE_RegPersonal extends LightningElement {

    plusimg = plus;
    closeimg = CloseIconImage;
    pageName = 'Personal';

    @api accountid;
    @api mobilescreen;
    @track licenselist = [];
    @track counter = 1;
    @track accountData;
    @track licbool;

    @track salutation;
    @track firstname;
    @track lastname;
    @track suffix;
    @track designation;
    @track specialty;

    @track salutatioption = [];
    @track specialityoption = [];
    @track suffixoption = [];
    @track designationoption = [];
    @track licensestateoption = [];
    @track licensetypeoption = [];

    @track eligibilityWrapFinal = {};
    @track eligibilityWrap = {};

    label = {
        registrationerror
    };

    @api
    get registrationwrap() {
        return this.eligibilityWrap;
    }
    set registrationwrap(value) {
        this.eligibilityWrap = value;
    }

    // Method Name:         WiredgetSalutationPicklistValue
    // Method Use:          Used for getting Picklist value
    // Developer Name:      Ravi Modi
    // Created Date:        31th May 2023
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
            this.salutatioption =  [{label:'--None--', value:''}, ...option]; //INC2747387 -- Added by Sabari
        } if (error) {
            console.log('ERROR in WiredgetSalutationPicklistValue-->', { error });
        }
    }

    // Method Name:         WiredgetSpecialityPicklistValue
    // Method Use:          Used for getting Picklist value
    // Developer Name:      Ravi Modi
    // Created Date:        31th May 2023
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
    // Created Date:        31th May 2023
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
            this.suffixoption = [{label:'--None--', value:''}, ...option]; //R5- INC2747387 -- Added by Sabari
        } if (error) {
            console.log('ERROR in WiredgetSuffixPicklistValue-->', { error });
        }
    }

    // Method Name:         WiredgetDesignationPicklistValue
    // Method Use:          Used for getting Picklist value
    // Developer Name:      Ravi Modi
    // Created Date:        31th May 2023
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
    // Created Date:        31th May 2023
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
    // Created Date:        31th May 2023
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

    // Method Name:         WiredgetAccountDetail
    // Method Use:          Used for getting Account detail
    // Developer Name:      Ravi Modi
    // Created Date:        29th May 2023
    @wire(getAccountDetail, { recordId: '$accountid' })
    // @wire(getAccountDetail, { recordId: '0016C00000nmSOtQAM' })
    WiredgetAccountDetail({ error, data }) {
        if (data) {
            console.log('Result of WiredgetAccountDetail-->', { data });
            this.accountData = data;
            this.loadWrapperData();
        } if (error) {
            console.log('ERROR in WiredgetAccountDetail-->', { error });
        }
    }


    // Method Name:         renderedCallback
    // Method Use:          Used for loading external CSS file
    // Developer Name:      Ravi Modi
    // Created Date:        29th May 2023
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
    // Created Date:        29th May 2023
    connectedCallback() {
        document.body.scrollTop = document.documentElement.scrollTop = 0;
        this.licenselist.push({ id: 'inputbox' + this.counter, value: this.counter, name: '', number: '', state: '', type: '',  nameid: 'nameidval'+this.counter, stateid: 'stateidval'+this.counter, typeid: 'typeidval'+this.counter });
        console.log('eligibilityWrap-->', this.eligibilityWrap);
    }

    // Method Name:         addlicensesection
    // Method Use:          Used for the adding license section
    // Developer Name:      Ravi Modi
    // Created Date:        29th May 2023
    addlicensesection() {
        let _tempList = [];
        if (this.licenselist.length < 3) {
            this.counter += 1;
            this.licenselist.push({ id: 'inputbox' + this.counter, value: this.counter, name: '', number: '', state: '', type: '',  nameid: 'nameidval'+this.counter, stateid: 'stateidval'+this.counter, typeid: 'typeidval'+this.counter });
            let count = 0;
            this.licenselist.forEach(currentItem => {
                count += 1;
                currentItem.id = 'inputbox' + count;
                currentItem.value = count;
                currentItem.nameid = 'nameidval'+count;
                currentItem.stateid = 'stateidval'+count;
                currentItem.typeid = 'typeidval'+count;
                _tempList.push(currentItem);
            });
            this.licenselist = [];
            this.licenselist = JSON.parse(JSON.stringify(_tempList));
        } else {
            this.template.querySelector('c-custom-toast').showToast('error', 'You can add upto 3 License');
        }
        console.log('ADD LIC --->',this.licenselist);
        this.fireDataLayerEvent("button", 'step_3', "add license" , 'registration_flow', 'Register', '/SelfRegister');
    }

    // Method Name:         removelicensesection
    // Method Use:          Used for the remove license section
    // Developer Name:      Ravi Modi
    // Created Date:        29th May 2023
    removelicensesection(event) {
        let getid = event.currentTarget.dataset.id;
        let _tempList = [];
        if (this.licenselist.length >= 1) { //R5 INC2747388 - Added By Sabari
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
            console.log('Remove -->>',this.licenselist);
        }
    }

    handleInfo(){
        this.fireDataLayerEvent("link", 'step_3', "view information" , 'registration_flow', 'Register', '/SelfRegister');
    }

    // Method Name:         handlechange
    // Method Use:          Used for storing the value in var
    // Developer Name:      Ravi Modi
    // Created Date:        30th May 2023
    handlechange(event) {
        try {
            let name = event.currentTarget.dataset.name;
            let lbname = event.currentTarget.dataset.lbname;
            if (name == 'salutation') {
                this.salutation = event.target.value;
                this.fireDataLayerEvent("dropdown", 'step_3', "salutation" , 'registration_flow', 'Register', '/SelfRegister');
            } else if (name == 'firstname') {
                this.firstname = event.target.value;
            } else if (name == 'lastname') {
                this.lastname = event.target.value;
            } else if (name == 'suffix') {
                this.suffix = event.target.value;
                this.fireDataLayerEvent("dropdown", 'step_3', "suffix" , 'registration_flow', 'Register', '/SelfRegister');
            } else if (name == 'designation') {
                this.designation = event.target.value;
                this.fireDataLayerEvent("dropdown", 'step_3', "title" , 'registration_flow', 'Register', '/SelfRegister');
            } else if (name == 'speciality') {
                this.speciality = event.target.value;
                this.fireDataLayerEvent("dropdown", 'step_3', "specialty" , 'registration_flow', 'Register', '/SelfRegister');
            } else if (lbname == 'Licensing state(s)') {
                this.fireDataLayerEvent("dropdown", 'step_3', "licensing state" , 'registration_flow', 'Register', '/SelfRegister');
            } else if (lbname == 'Type of license') {
                this.fireDataLayerEvent("dropdown", 'step_3', "license type" , 'registration_flow', 'Register', '/SelfRegister');
            }
        } catch (error) {
            console.log('Error in handlechange-->', { error });
        }
    }
   

    // Handle License Change
    handlelicchange(event) {
        this.licbool = true;
        let val = event.target.value;
        console.log({val});
        let dataid = event.currentTarget.dataset.id;
        console.log({dataid});
        let dataname = event.currentTarget.dataset.name;
        console.log({dataname});

        if(dataname == 'state'){
            this.fireDataLayerEvent("dropdown", 'step_3', "licensing state" , 'registration_flow', 'Register', '/SelfRegister'); 
        }
        if(dataname == 'type'){
            this.fireDataLayerEvent("dropdown", 'step_3', "license type" , 'registration_flow', 'Register', '/SelfRegister');
        }

        let count = 0;
        let _tempList = [];
        this.licenselist.forEach(currentItem => {
            console.log({currentItem});
            console.log({count});
            count += 1;
            if (currentItem.value == dataid) {
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
        console.log('this.licenselist===>>>>>',this.licenselist);
    }

    handlegaevent(event){
        console.log('entered into gaevent');
           let labelname = event.currentTarget.dataset.name;
           let cardname = event.currentTarget.dataset.lbname;
           if(labelname == 'firstname'){
              this.fireDataLayerEvent("label", 'step_3', "first name" , 'registration_flow', 'Register', '/SelfRegister');   
           }
           else if(labelname == 'lastname'){
              this.fireDataLayerEvent("label", 'step_3', "last name" , 'registration_flow', 'Register', '/SelfRegister');   
           }
           else if(cardname == 'licensename'){
              this.fireDataLayerEvent("label", 'step_3', "name on license" , 'registration_flow', 'Register', '/SelfRegister');   
           }
           else if(cardname == 'licenseno'){
              this.fireDataLayerEvent("label", 'step_3', "license number" , 'registration_flow', 'Register', '/SelfRegister');   
           }
           else if(cardname == 'Licensing state(s)'){
            console.log('entered licensingstate',cardname );
            this.fireDataLayerEvent("label", 'step_3', "licensing state" , 'registration_flow', 'Register', '/SelfRegister');  
           }
           else if(cardname == 'Type of license'){
            this.fireDataLayerEvent("label", 'step_3', "license type" , 'registration_flow', 'Register', '/SelfRegister');   
           }
    }

    handlebackclk() {
        const clickpreviouspage = new CustomEvent("showeligibilitypage", {
            detail: {
                showPersonal: false,
                salutation: this.salutation,
                firstname: this.firstname,
                lastname: this.lastname,
                suffix: this.suffix,
                designation: this.designation,
                speciality: this.speciality
            }
        });
        this.dispatchEvent(clickpreviouspage);
        this.fireDataLayerEvent("button", 'step_3', "back" , 'registration_flow', 'Register', '/SelfRegister');
    }

    handlenextclk() {
        this.fireDataLayerEvent("button", "step_4", "finish registration", 'registration_flow', 'Register', '/SelfRegister');
        
        try {

            let isValidField = true;
            let isValidCombo = true;

            let inputFields = this.template.querySelectorAll('.inputcsscls');
            inputFields.forEach(infield => {
                if (!infield.checkValidity()) {
                    console.log('IFFF');
                    infield.reportValidity();
                    isValidField = false;
                }
            });

            let comboboxFields = this.template.querySelectorAll('.inputboxcls');
            comboboxFields.forEach(infield => {
                if (!infield.checkValidity()) {
                    infield.reportValidity();
                    isValidCombo = false;
                }
            });

            if (!this.salutation) {
                this.salutation = this.template.querySelector('[data-name="salutation"').value;
            }
            if (!this.firstname) {
                this.firstname = this.template.querySelector('[data-name="firstname"').value;
            }
            if (!this.lastname) {
                this.lastname = this.template.querySelector('[data-name="lastname"').value;
            }
            if (!this.suffix) {
                this.suffix = this.template.querySelector('[data-name="suffix"').value;
            }
            if (!this.designation) {
                this.designation = this.template.querySelector('[data-name="designation"').value;
            }
            if (!this.speciality) {
                this.speciality = this.template.querySelector('[data-name="speciality"').value;
            }

            this.eligibilityWrapFinal.salutation = this.salutation;
            this.eligibilityWrapFinal.firstname = this.firstname;
            this.eligibilityWrapFinal.lastname = this.lastname;
            this.eligibilityWrapFinal.suffix = this.suffix;
            this.eligibilityWrapFinal.designation = this.designation;
            this.eligibilityWrapFinal.specialty = this.speciality;

            let mainlicmap = {};
            for (let key in this.licenselist) {
                var licmap = new Map();
                licmap['nameval'] = this.licenselist[key].name;
                licmap['numberval'] = this.licenselist[key].number;
                licmap['stateval'] = this.licenselist[key].state;
                licmap['typeval'] = this.licenselist[key].type;
                mainlicmap[key] = licmap;
            }
            if (isValidField && isValidCombo) {
                for(var key in mainlicmap){
                    if(mainlicmap[key].nameval == ''){
                        delete mainlicmap[key];
                    }
                }
                this.submitEligibilityMethod(mainlicmap);
            } 
        } catch (error) {
            console.log('Error in Handle Finish-->', { error });
        }
        
    }

    submitEligibilityMethod(licmap) {
        var licdata = JSON.stringify(licmap);

        submitEligibility({ accountid: this.accountid, wrapData: JSON.stringify(this.eligibilityWrapFinal), licensedata: licdata })
            .then((result) => {
                console.log('Result of submitEligibility--->', { result });
                if (result == 'Success') {
                    const clicknextpage = new CustomEvent("hidesuccesspage", {
                        detail: false
                    });
                    this.dispatchEvent(clicknextpage);
                }
            })
            .catch((error) => {
                console.log('Error of submitEligibility--->', { error });
                this.template.querySelector('c-custom-toast').showToast('error', label.registrationerror);
            })
    }

    loadWrapperData() {
        try {
            if (this.eligibilityWrap.salutation) {
                this.salutation = this.eligibilityWrap.salutation;
            } else {
                this.salutation = this.accountData.Preferred_Salutation_MRK__c;
            }
            if (this.eligibilityWrap.firstname) {
                this.firstname = this.eligibilityWrap.firstname;
            } else {
                this.firstname = this.accountData.Preferred_First_Name_MRK__c;
            }
            if (this.eligibilityWrap.firstname) {
                this.lastname = this.eligibilityWrap.lastname;
            } else {
                this.lastname = this.accountData.Preferred_Last_Name_MRK__c;;
            }
            if (this.eligibilityWrap.suffix) {
                this.suffix = this.eligibilityWrap.suffix;
            } else {
                this.suffix = this.accountData.Preferred_Suffix_MRK__c;
            }
            if (this.eligibilityWrap.designation) {
                this.designation = this.eligibilityWrap.designation;
            } else {
                this.designation = this.accountData.MSD_CORE_IDS_Customer_Designation__c;
            }
            if (this.eligibilityWrap.specialty) {
                this.specialty = this.eligibilityWrap.specialty;
            } else {
                this.specialty = this.accountData.IMS_Sub_Specialty_MRK__c;
            }
            this.eligibilityWrapFinal = {};
            this.eligibilityWrapFinal.salutation = '';
            this.eligibilityWrapFinal.firstname = '';
            this.eligibilityWrapFinal.lastname = '';
            this.eligibilityWrapFinal.suffix = '';
            this.eligibilityWrapFinal.designation = '';
            this.eligibilityWrapFinal.specialty = '';
        } catch (error) {
            console.log('Error of loadWrapperData--->', { error });
        }
    }

    //google analytics
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'account management',
                page_purpose: 'registration',
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
                page_localproductname: '',
                sfmc_id: '',
                sfmc_audience: '',
                page_url: location.href,
                page_title: 'Self Registration',

            },
            bubbles: true,
            composed: true
        }));
    }
}