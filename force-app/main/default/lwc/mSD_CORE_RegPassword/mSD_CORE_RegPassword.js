import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import MSD_CORE_CloseIcon from '@salesforce/resourceUrl/MSD_CORE_CloseIcon';
import MSD_CORE_SelectIcon from '@salesforce/resourceUrl/MSD_CORE_SelectIcon';
import RegistrationPage from '@salesforce/resourceUrl/RegistrationPage';

import savePassword from '@salesforce/apex/MSD_CORE_RegistrationController.savePassword';

export default class MSD_CORE_Reg_Password extends LightningElement {

    closeicon = MSD_CORE_CloseIcon;
    selecticon = MSD_CORE_SelectIcon;

    @api accountid;
    @track checkchar = false;
    @track checkletter = false;
    @track checknum = false;
    @track checkspecial = false;
    @track nextbtndisable = true;
    @track password = '';
    @track confirmpassword = '';
    @track nextbtnclass = 'nextbtncls';
    @track errormsg = false;
    pageName = 'Password';
    @track passwordmatch = false;//1267

    // Method Name:         renderedCallback
    // Method Use:          Used for loading external CSS file
    // Developer Name:      Ravi Modi
    // Created Date:        22th May 2023
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

    // Method Name:         handlechange
    // Method Use:          Used for getting the value on change
    // Developer Name:      Ravi Modi
    // Created Date:        23th May 2023
    handlechange(event) {

        let nameval = event.currentTarget.dataset.name;
        if (nameval == 'password') {
            this.password = event.target.value;
            this.checkchar  = contains8Char(this.password);
            this.checkletter = containsUppercase(this.password);
            this.checknum = containsNumber(this.password);
            this.checkspecial = containsSpecialChar(this.password);
            this.passwordmatch=false;
        } else {
            this.confirmpassword = event.target.value;
        }
    }

    // Method Name:         handlechangeConfirm
    // Method Use:          Used to validate confirm password is matching with new password
    // Developer Name:      Subhash
    // Created Date:        7th July 2023
    handlechangeConfirm(event) {
        this.confirmpassword = event.target.value;
        this.passwordmatch=false;
        if(this.password === this.confirmpassword){
            this.passwordmatch= true;
            console.log('this.confirmpassword--->' + this.confirmpassword);
        }
        if (this.checkchar && this.checkletter && this.checknum && this.checkspecial && this.passwordmatch) {
            this.nextbtndisable = false;
            this.nextbtnclass = 'nextbtncls btnenablecls';
        } else {
            this.nextbtndisable = true;
            this.nextbtnclass = 'nextbtncls';
        }
    }

    // Method Name:         handleClick
    // Method Use:          Used for Navigation and validation check
    // Developer Name:      Ravi Modi
    // Created Date:        24th May 2023
    handleClick(event) {
        if (this.password != '' || this.confirmpassword != '') {
            if (this.password === this.confirmpassword) {
                this.errormsg = false;
                this.savePassword();
                const clicknextpage = new CustomEvent("showpasspage", {
                    detail: false
                });
                this.dispatchEvent(clicknextpage);
            } else {
                this.errormsg = true;
            }   
        }
    }

    // Method Name:         savePassword
    // Method Use:          Used for Saving data into backedn
    // Developer Name:      Ravi Modi
    // Created Date:        24th May 2023
    savePassword() {
        savePassword({ recordId: this.accountid, passwordval: this.password})
            .then((result) => {
                console.log('<-----Result of savePassword----->',{result});
            })
            .catch((error) => {
                console.log('<-----Error in savePassword----->',{error});
            })
    }
    
}

function contains8Char(str) {
    return /.{8,}$/.test(str);
}
function containsUppercase(str) {
    let checkup = /[A-Z]/.test(str);
    let checklo= /[a-z]/.test(str);
    let checkval;
    if(checkup && checklo) {
        checkval = true;
    } else {
        checkval = false;
    }
    return checkval;
}
function containsNumber(str) {
    return /[0-9]/.test(str);
}
function containsSpecialChar(str) {
    return /[-’/`~!#*$@_%+=.,^&(){}[\]|;:”<>?\\]/g.test(str);
}