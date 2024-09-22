import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import bannerLogo from '@salesforce/resourceUrl/banner';
import Createpasswordlogo from '@salesforce/resourceUrl/Createpasswordlogo';
import createpasswordcss from '@salesforce/resourceUrl/createpasswordcss';
import MSD_CORE_CloseIcon from '@salesforce/resourceUrl/MSD_CORE_CloseIcon';
import MSD_CORE_SelectIcon from '@salesforce/resourceUrl/MSD_CORE_SelectIcon'; 
import redcrossicon from '@salesforce/resourceUrl/redcrossicon';
import Emptycircle from '@salesforce/resourceUrl/Emptycircle';
import greenchecklogo from '@salesforce/resourceUrl/greenchecklogo';
import { loadStyle } from 'lightning/platformResourceLoader';
import Welcomelogo from '@salesforce/resourceUrl/Welcomelogo';
import doLogin from '@salesforce/apex/MSD_CORE_ResetPasswordController.doLogin';
import createPassword from '@salesforce/apex/MSD_CORE_ResetPasswordController.createPassword';
import isguest from '@salesforce/user/isGuest';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

export default class MSD_CORE_Createpassword extends LightningElement {

    bannerLogo = bannerLogo;
    Createpasswordlogo =Createpasswordlogo;
    Welcomelogo = Welcomelogo;
    closeicon = MSD_CORE_CloseIcon;
    selecticon = MSD_CORE_SelectIcon;
    Emptycircle = Emptycircle;
    redcrossicon = redcrossicon;
    greenchecklogo = greenchecklogo;

    @track password = '';
    @track password1 = '';
    @track inputType = 'password';
    @track inputType1 = 'password';
    @track errorval = false;
    @track inputclass = 'input-container';
    @track intialchar = true;
    @track checkcharerror = false;
    @track intialletter = true;
    @track checklettererror = false;
    @track intialnum = true;
    @track checknumerror = false;
    @track intialspecail = true;
    @track checkspecialerror = false;
    @track intialpassword = true;
    @track checkpasserror = false;
    @track accountId;//Account Id
    showPasswordLabel = false;
    showConfirmPasswordLabel = false;
    @track brandId;
    domainurl = domainurl;
    
    eyeIcon = 'utility:hide';
    eyeIcon1 = 'utility:hide';

    connectedCallback() {
        if(!this.isGuestUser) {
            window.location.href = this.domainurl+'/dashboard';
        }
        
        Promise.all([
            loadStyle(this, createpasswordcss)
        ])
    }

    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.accountId = currentPageReference.state.recordId;
            this.brandId = currentPageReference.state.brandId;
        }
    }

    get isGuestUser() {
        return isguest;  
    }

    handleChange(event) {
        this.password = event.target.value;

        if(this.password.trim() == '') {
            this.showPasswordLabel = false;
        }
        else {
            this.showPasswordLabel = true;
        }
        
        this.checkchar  = contains8Char(this.password);
        if(this.checkchar == true){
            this.intialchar = false;
            this.checkcharerror = false;
        }else {
            this.intialchar = false;
            this.checkcharerror = true;
        }
            
        this.checkletter = containsUppercase(this.password);
        if(this.checkletter == true){
            this.intialletter = false;
            this.checklettererror = false;
        }else {
            this.intialletter = false;
            this.checklettererror = true;
        }

        this.checknum = containsNumber(this.password);
        if(this.checknum == true){
            this.intialnum = false;
            this.checknumerror = false;
        }else {
            this.intialnum  = false;
            this.checknumerror = true;
        }
        
        this.checkspecial = containsSpecialChar(this.password);
        if(this.checkspecial == true){
            this.intialspecail = false;
            this.checkspecialerror = false;
        }else {
            this.intialspecail = false;
            this.checkspecialerror = true;
        }

        if (!this.password) {
            this.intialchar = true;
            this.intialletter = true;
            this.intialnum = true;
            this.intialspecail = true;
            this.intialpassword = true;
            this.checkcharerror = false;
            this.checklettererror = false;
            this.checknumerror = false;
            this.checkspecialerror = false;
            this.checkpasserror = false;
            console.log("Password is empty");
        }

        this.passwordmatch=false;
        this.intialpassword=true;
        this.checkpasserror = false;
    }

    handleChange1(event) {
        this.password1 = event.target.value;

        if(this.password1.trim() == '') {
            this.showConfirmPasswordLabel = false;
        }
        else {
            this.showConfirmPasswordLabel = true;
        }

        this.password1 = event.target.value;
        
        if(this.password === this.password1){
            this.passwordmatch = true;
            this.intialpassword = false;
            this.checkpasserror = false;
        }else{
            this.checkpasserror = true;
            this.intialpassword = false;
            this.passwordmatch = false;
        }
    }

    togglePasswordVisibility() {
        this.inputType = this.inputType === 'password' ? 'text' : 'password';
        this.eyeIcon = this.inputType === 'password' ? 'utility:hide' : 'utility:preview';
    }

    togglePasswordVisibility1() {
        this.inputType1 = this.inputType1 === 'password' ? 'text' : 'password';
        this.eyeIcon1 = this.inputType1 === 'password' ? 'utility:hide' : 'utility:preview';
    }

    passwordclick(event){
        if(this.password === this.password1){
            this.errorval = false;
            this.inputclass = 'input-container';
            this.createAndLogin();
        }else {
            this.errorval = true;
            this.inputclass = 'input-container1';
        }
    }

    createAndLogin() {
        createPassword({ accountID: this.accountId, newPassword: this.password })
            .then(result => {
                if (result === 'Success!') {
                    // Password successfully created, now login
                    doLogin({ accountID: this.accountId, password: this.password, brandId: this.brandId })
                        .then(loginUrl => {
                            if (loginUrl) {
                                window.location.href = loginUrl;
                            } else {
                                this.showToast('Error', 'Login URL not available', 'error');
                            }
                        })
                        .catch(error => {
                            this.showToast('Error', error.body.message, 'error');
                        });
                } else {
                    this.showToast('Error', result, 'error');
                }
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
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