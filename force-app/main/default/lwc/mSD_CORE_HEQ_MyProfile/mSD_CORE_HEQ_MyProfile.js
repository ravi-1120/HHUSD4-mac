import { LightningElement, track, api } from 'lwc';

//Apex References
// import getLanguageOptions from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getLanguageOptions';
// import getTimezoneOptions from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getTimezoneOptions';
import getuser from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getuser';
// import updateUserLanguage from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.updateUserLanguage';
// import updateUserTimezone from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.updateUserTimezone';

//User ID
import USER_ID from '@salesforce/user/Id';

//Custom Labels
import customerProfileName from '@salesforce/label/c.MSD_CORE_HEQ_CustomerProfile';
import aeProfileName from '@salesforce/label/c.MSD_CORE_HEQ_AEProfile';
import home from '@salesforce/label/c.MSD_CORE_HEQ_Home';
import DefaultCountry from '@salesforce/label/c.MSD_CORE_Default_Country';
import EmailId from '@salesforce/label/c.MSD_CORE_Email';
import FirstName from '@salesforce/label/c.MSD_CORE_First_Name';
import ID from '@salesforce/label/c.MSD_CORE_ID';
import Language from '@salesforce/label/c.MSD_CORE_Language';
import LastName from '@salesforce/label/c.MSD_CORE_Last_Name';
import MyProfile from '@salesforce/label/c.MSD_CORE_My_Profile';
import Phone from '@salesforce/label/c.MSD_CORE_Phone';
import Roles from '@salesforce/label/c.MSD_CORE_HEQ_User_role';
import Timezone from '@salesforce/label/c.MSD_CORE_Time_Zone';

export default class MSD_CORE_HEQ_MyProfile extends LightningElement {
    userId = USER_ID;
    user;
    @track timezoneOptions = [];
    @track selectedTimezone;
    @track languageOptions = [];
    @track selectedLanguage;
    @track userVar;
    @track userChar;
    @track isHEQProfile = false;

    @api profileData;

    labels = {
        home,
        MyProfile,
        ID,
        Roles,
        FirstName,
        LastName,
        Phone,
        EmailId,
        DefaultCountry,
        Language,
        Timezone

    }

    connectedCallback() {
        this.loadUserData();
        // this.loadTimezoneOptions();
        // this.loadLanguageOptions();
        this.dispatchEvent(new CustomEvent("componentInit", {
            bubbles: true,
            composed: true,
            detail: "profile"
        }))
        if (this.profileData) {
            console.log('Profile data received: ', this.profileData);
        }
    }

    // @api
    // setdata(userData){
    //     this.showSpinner = true;
    //     let usersData = JSON.stringify(userData);
    //     this.uuid = userData.uuid;
    //     console.log('SetData' + JSON.stringify(userData));
    //     console.log('uuid ' + this.uuid);
    //     // if(this.uuid){
    //     //     this.userLogin(userData.email, userData.givenName, userData.familyName, userData.uuid);
    //     // }else{
    //     //     this.showSpinner = false;
    //     // }
    // }
    @api
    setdata(profileData) {
        this.profileData = profileData;
        console.log('Profile data set via setdata: ', JSON.stringify(this.profileData));
    }

    loadUserData() {
        getuser({ userId: this.userId })
            .then(result => {
                this.userVar = result;
                this.userChar = (this.userVar.FirstName?.charAt(0) ?? '') + (this.userVar.LastName?.charAt(0) ?? '');
                console.log('Original User Data:', result);
                this.user = this.replaceEmptyFields(result);
                 this.isHEQProfile = this.userVar.Profile?.Name === aeProfileName;
                 console.log('this.isHEQProfile', this.isHEQProfile);
                // this.selectedTimezone = this.user.TimeZoneSidKey;
                // this.selectedLanguage = this.user.LanguageLocaleKey;
                console.log('Processed User Data:', this.user);
            })
            .catch(error => {
                console.error('Error fetching user:', error);
            });
    }

    redirectToHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/landing-page'
            }
        });
    }

    replaceEmptyFields(data) {
        if (data && typeof data === 'object') {
            const updatedData = {};
            for (const field in data) {
                if (data.hasOwnProperty(field)) {
                    updatedData[field] = this.replaceEmptyFields(data[field]);
                }
            }
            console.log('updatedData', JSON.stringify(updatedData));
            return updatedData;
        } else {
            return data !== null && data !== undefined && data !== '' ? data : '';
        }
    }

    get userRoleName() {
        return this.user && this.user.UserRole && this.user.UserRole.Name ? this.user.UserRole.Name : '';
    }

    get userPhone(){
        return this.user ? this.user.Phone  : 'NA';
    }

    get phone() {
        return this.profileData.address.phone || 'N/A';
    }

    get licenseType() {
        return this.profileData.license.licenseType || 'N/A';
    }

    get licenseNumber() {
        return this.profileData.license.licenseNumber || 'N/A';
    }

    get designation() {
        return this.profileData.designation || 'N/A';
    }

    // loadUserData() {
    //     getuser({ userId: this.userId })
    //         .then(result => {
    //             this.user = result;
    //             console.log('User data:', this.user);
    //         })
    //         .catch(error => {
    //             console.error('Error fetching user:', error);
    //         });
    // }

    // @track user;

    // @wire(getuser, { userId: '$userId' })
    // wiredUser({ error, data }) {
    //     if (data) {
    //         console.log('RESULT IS', JSON.stringify(data));
    //         this.user = data;
    //     } else if (error) {
    //         console.error('Error retrieving user data', error);
    //     }
    // }

    // get languageOptions() {
    //     return [
    //         { label: 'English', value: 'en' },
    //         { label: 'Spanish', value: 'es' }
    //     ];
    // }

    // loadLanguageOptions() {
    //     getLanguageOptions()
    //         .then(result => {
    //             this.languageOptions = result.map(option => ({
    //                 label: option.label,
    //                 value: option.value
    //             }));
    //             console.log('Language options:', this.languageOptions);
    //         })
    //         .catch(error => {
    //             console.error('Error fetching language options:', error);
    //         });
    // }

    // loadTimezoneOptions() {
    //     getTimezoneOptions()
    //         .then(result => {
    //             // Convert the list of maps to the format required by lightning-combobox
    //             this.timezoneOptions = result.map(option => ({
    //                 label: option.label,
    //                 value: option.value
    //             }));
    //             console.log('Timezone options:', this.timezoneOptions);
    //         })
    //         .catch(error => {
    //             console.error('Error fetching timezone options:', error);
    //         });
    // }

    // handleTimezoneChange(event) {
    //     this.selectedTimezone = event.detail.value;
    //     console.log('Timezone selected: ', this.selectedTimezone);
    // }

    // handleLanguageChange(event) {
    //     this.selectedLanguage = event.detail.value;
    //     console.log('Language selected: ', this.selectedLanguage);
    // }

    // handleUpdateClick() {
    //     Promise.all([
    //         updateUserTimezone({
    //             userId: this.userId,
    //             timezone: this.selectedTimezone
    //         }),
    //         updateUserLanguage({
    //             userId: this.userId,
    //             language: this.selectedLanguage
    //         })
    //     ])
    //         .then(() => {
    //             this.user.TimeZoneSidKey = this.selectedTimezone;
    //             this.user.LanguageLocaleKey = this.selectedLanguage;
    //             console.log('User details updated successfully.');
    //             return this.loadUserData();
    //         })
    //         .then(() => {
    //             window.location.reload();
    //         })
    //         .catch(error => {
    //             console.error('Error updating user details:', error);
    //         });
    // }
}