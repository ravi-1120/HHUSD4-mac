import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import PDSExternalCSS from '@salesforce/resourceUrl/PDSExternalCSS';
import { loadStyle } from 'lightning/platformResourceLoader';

import setUserPassword from '@salesforce/apex/PDS_PortalAuthController.setUserPassword';

import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Email';

import myprofile from '@salesforce/label/c.PDS_My_Profile';
import emailaddress from '@salesforce/label/c.PDS_Label_Email_Address';
import changepassword from '@salesforce/label/c.PDS_Change_Password';
import pwdRequirements from '@salesforce/label/c.PDS_PWD_Requirements';
import newPassword from '@salesforce/label/c.PDS_New_Password';
import confirmPassword from '@salesforce/label/c.PDS_ConfirmPassword';
import update from '@salesforce/label/c.PDS_Update';
import cancel from '@salesforce/label/c.PDS_Cancel';
import passReqMinChars from '@salesforce/label/c.PDS_Password_Req_Min_Chars';
import passReqUpperLower from '@salesforce/label/c.PDS_Password_Req_Upper_Lower_Case';
import passReqNumber from '@salesforce/label/c.PDS_Password_Req_Number';
import passReqSpecialChars from '@salesforce/label/c.PDS_Password_Req_Special_Char';
import passReqMatch from '@salesforce/label/c.PDS_Password_Req_Match';
import passwordUpdateSuccess from '@salesforce/label/c.PDS_Password_Update_Success';
import resetErrorMsg from '@salesforce/label/c.PDS_RepeatedPassword_Error';


export default class PdsMyProfile extends NavigationMixin(LightningElement) {
    userEmail;
    newpassword;
    confirmpassword;
    resetDisabled = true;
    resetError = false;

    labels = {
        myprofile,
        emailaddress,
        changepassword,
        pwdRequirements,
        confirmPassword,
        newPassword,
        update,
        cancel,
        passReqMinChars,
        passReqUpperLower,
        passReqNumber,
        passReqSpecialChars,
        passReqMatch,
        passwordUpdateSuccess,
        resetErrorMsg
    };

    @track valRules = [
        { label: 'length', regex: /.{8,}/, message: this.labels.passReqMinChars },
        { label: 'alpha', regex: /^(?=.*[a-z])(?=.*[A-Z]).*$/, message: this.labels.passReqUpperLower },
        { label: 'number', regex: /\d/, message: this.labels.passReqNumber },
        { label: 'specialChar', regex: /[!@#$%^&*()_+{}\[\]:;'"<>,.?/~`\\|\-=]/, message: this.labels.passReqSpecialChars },
        { label: 'match', message: this.labels.passReqMatch },
    ];

    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] }) wireuser({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.userEmail = data.fields.Email.value;
        }
    }

    connectedCallback() {
        this.newpassword = '';
        this.confirmpassword = '';
        Promise.all([
            loadStyle(this, PDSExternalCSS)
        ])
    }

    handleUserInput(event) {
        const { name, value } = event.target;
        if (name == 'Password') this.newpassword = value;
        if (name == 'Confirm Password') this.confirmpassword = value;

        this.validatePassword();
        this.disableReset();
    }

    validatePassword() {
        this.passwordCriteria = this.valRules.reduce((result, valRule) => {
            if (valRule.regex) {
                result[valRule.label] = valRule.regex.test(this.newpassword);
            }
            return result;
        }, { match: this.newpassword !== '' && this.confirmpassword !== '' && this.newpassword === this.confirmpassword });
        this.getClassNames();
    }

    getClassNames() {
        this.valRules = this.valRules.map(rule => {
            const className = this.passwordCriteria[rule.label] ? 'active-vc' : '';
            return { ...rule, className };
        });
    }

    disableReset() {
        this.resetDisabled = !Object.values(this.passwordCriteria).every(value => value);
    }

    updatePassword() {
        if (!this.resetDisabled) {
            setUserPassword({ userId: USER_ID, newPassword: this.newpassword })
                .then(result => {
                    console.log('result : ', result);
                    if (result == 'Reset Success') {
                        this.template.querySelector('c-pds-Toast-Message').showToast(this.labels.passwordUpdateSuccess);

                        this.newpassword = '';
                        this.confirmpassword = '';
                        this.validatePassword();
                        this.resetDisabled = true;
                    } else if (result.includes('invalid repeated')) {
                        this.resetError = true;
                    }
                })
                .catch(error => {
                    console.error('Error', error);
                });
        }
    }

    navigateBackToDashboard() {
        console.log('navigateBackToDashboard');
        var name = 'Home';
        var url = '/'
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: name,
                url: url
            }
        });
    }
}