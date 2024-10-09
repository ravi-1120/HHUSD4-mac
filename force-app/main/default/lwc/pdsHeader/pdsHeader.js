import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import communityPath from '@salesforce/community/basePath';
import isguest from '@salesforce/user/isGuest';
//Import Static Resources
import medsLogo from '@salesforce/resourceUrl/PDSMEDSWhiteLogo';
import avatar from '@salesforce/resourceUrl/PDSAvatar';
//Import Custom Label
import menuProfile from '@salesforce/label/c.PDS_Menu_Profile';
import menuLogout from '@salesforce/label/c.PDS_Menu_Logout';

export default class PdsHeader extends NavigationMixin(LightningElement) {
    labels = {
        menuProfile,
        menuLogout
    };
    isGuestUser = isguest;

    medsLogo = medsLogo;
    avatar = avatar;
    @track dropdownOpen = false;
    @track url;

    connectedCallback() {
        // Promise.all([
        //     loadStyle(this, PDSExternalCSS)
        // ])
    }

    navigateToDashboard() {
        if(this.isGuestUser == false){
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    name: 'Home',
                    url: '/'
                }
            });
        }
    }

    navigateToProfile() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/profile'
            }
        });
    }

    navigateToLogin() {
        this.url = communityPath+ '/secur/logout.jsp?retUrl=%2FMEDs%2Flogin';
        window.location.replace(this.url);
    }

    toggleDropdown() {
        console.log('toggle Dropdown');
        this.dropdownOpen = !this.dropdownOpen;
    }
}