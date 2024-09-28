import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import communityPath from '@salesforce/community/basePath';
import { loadStyle } from 'lightning/platformResourceLoader';

//Static Resources
import HEQ_Header_CSS_1 from '@salesforce/resourceUrl/MSD_CORE_HEQ_Header_CSS_1';
import HEQ_Header_CSS_2 from '@salesforce/resourceUrl/MSD_CORE_HEQ_Header_CSS_2';
import HEQ_Logo from '@salesforce/resourceUrl/MSD_CORE_HEQ_Logo';

//Custom Labels
import customerProfileName from '@salesforce/label/c.MSD_CORE_HEQ_CustomerProfile';
import aeProfileName from '@salesforce/label/c.MSD_CORE_HEQ_AEProfile';
import logoutURL from '@salesforce/label/c.MSD_CORE_HEQ_LogoutURL';
import logoAlt from '@salesforce/label/c.MSD_CORE_HEQ_LogoAlt';
import searchPlaceholder from '@salesforce/label/c.MSD_CORE_HEQ_SearchPlaceholder';
import close from '@salesforce/label/c.MSD_CORE_Close_Btn';
import menu from '@salesforce/label/c.MSD_CORE_Menu';
import search from '@salesforce/label/c.MSD_CORE_Search';

//Apex Classes
import getUser from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getuser';
import retrieveHeqHeaderMetadata from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.retrieveHeqHeaderMetadata';
import getUserPreference from '@salesforce/apex/MSD_CORE_HEQ_UserPreferenceController.getUserPreference';

export default class mSD_CORE_HEQ_Header extends NavigationMixin(LightningElement) {

    mainLogo = HEQ_Logo;

    @api recordId;

    @track isDropdownOpen = false;
    @track mobileVersionMenu = true;
    @track isShow = true;
    @track showDropdown = false;
    @track showSignout = false;
    @track isMenu = false;
    @track isSearch = false;
    @track dropdownValue = 'View All';
    @track userChar;
    @track userVar;
    @track keyword = '';
    @track resourcedata;
    @track myaccountList = [];
    @track profileMenuList = [];
    @track showTandC = false;
    @track showHelpDropdown = false;
    @track helpSubMenuItems = [];
    @track helpMenuItem = null;
    @track mobileHelpDropdownOpen = false;
    @track showMobileHelpMenu = false;
    @track showSpinner = false;


    labels = {
        logoAlt,
        searchPlaceholder,
        menu,
        close,
        search
    };

    connectedCallback() {
        this.checkUserPreference();
        document.addEventListener('click', this.closeDropdown.bind(this));

        Promise.all([
            loadStyle(this, HEQ_Header_CSS_1),
            loadStyle(this, HEQ_Header_CSS_2)
        ])
            .then(() => {
                console.log("All scripts and CSS are loaded. perform any initialization function.")
            })
            .catch(error => {
                console.log("failed to load the scripts");
            });

        const paramValue = this.getUrlParamValue(window.location.href, 'Id');

        getUser({ userId: paramValue })
            .then(result => {
                this.userVar = result;
                this.userChar = (this.userVar.FirstName?.charAt(0) ?? '') + (this.userVar.LastName?.charAt(0) ?? '');

                if (result.Profile.Name == customerProfileName) {
                    this.isShow = false;
                } else if (result.Profile.Name == aeProfileName) {
                    this.isShow = true;
                }
            })
            .catch(error => {
                console.log("getUser header" + JSON.stringify(error));
            })

        retrieveHeqHeaderMetadata({}).then(result => {
            console.log('Header Config List->' + JSON.stringify(result));
            result.forEach(item => {
                if (item.Icon__c !== null && item.Icon__c !== undefined) {
                    item.Icon__c = item.Icon__c ? communityPath + '/' + item.Icon__c : item.Icon__c;
                }
                if (item.Menu_Type__c == 'My Account') {
                    this.myaccountList.push(item);
                } else if (item.Menu_Type__c == 'Profile') {
                    this.profileMenuList.push(item);
                }
                
            });

            this.helpMenuItem = this.profileMenuList.find(item => item.Label === 'Help');

            console.log('My Account List ->' + JSON.stringify(this.myaccountList));
            console.log('Profile List ->' + JSON.stringify(this.profileMenuList));
            console.log('Help Menu Item ->' + JSON.stringify(this.helpMenuItem));

        }).catch(error => {
            console.log('error->' + JSON.stringify(error));
        });
    }

    // @api
    // handleKeywordEvent(event){
    //     this.keyword = '';
    // }

    get mobileHelpDropdownIcon() {
        return this.mobileHelpDropdownOpen ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get mobileHelpDropdownClass() {
        return this.mobileHelpDropdownOpen ? 'mobile-help-submenu show' : 'mobile-help-submenu';
    }

    openMobileHelpMenu() {
        this.showMobileHelpMenu = true;
        this.helpMenuItems = [
                 { label: 'Help home', url: '/help/home' },
                 { label: 'Quick guide', url: '/help/quick-guide' },
                 { label: 'Contact us', url: '/help/contact-us' }
             ];
    }

    closeMobileHelpMenu() {
        this.showMobileHelpMenu = false;
    }

    // toggleMobileHelpDropdown() {
    //     this.mobileHelpDropdownOpen = !this.mobileHelpDropdownOpen;
    //     //  this.showHelpDropdown = !this.showHelpDropdown;
    //     if (this.mobileHelpDropdownOpen) {
    //         this.helpMenuItems = [
    //             { label: 'Help home', url: '/help/home' },
    //             { label: 'Quick guide', url: '/help/quick-guide' },
    //             { label: 'Contact us', url: '/help/contact-us' }
    //         ];
    //     }
    // }

    closeDropdown(event) {
        if (!this.template.querySelector('.profile-icon').contains(event.target)) {
            this.isDropdownOpen = false;
        }
        this.handleRemoveSearch();
    }

    redirectHomePage(event) {
        this.keyword = '';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/landing-page'
            }
        });

        if (!this.mobileVersionMenu) this.handleMobileMenu();
    }

    handleMobileMenu() {
        if (this.mobileVersionMenu) {
            document.body.classList.add('no-scroll');
        } else {
            document.body.classList.remove('no-scroll');
        }
        this.mobileVersionMenu = !this.mobileVersionMenu;
    }

    toggleDropdown(event) {
        event.stopPropagation();
        this.isDropdownOpen = !this.isDropdownOpen;
        if (this.isShow == false) {
            console.log('CSS ' + this.isShow);
            setTimeout(() => {
                const element = this.template.querySelector('.dropdown-menu');
                if (element) {
                    element.classList.add('dropdown-mb');
                }
            }, 0);
        }
    }

    searchKeyword(event) {
        this.isSearch = false;
        if (this.dropdownValue) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/resources?keyword=${encodeURIComponent(this.keyword)}&type=${encodeURIComponent(this.dropdownValue)}`
                }
            });
        }
    }

    handleLogout() {
        this.showSpinner = true;
        if (!this.isShow) {
            this.dispatchEvent(new CustomEvent("endSession", {
                bubbles: true,
                composed: true,
                detail: "endSession"
            }))
        } else {
            let LogoutURL = communityPath + logoutURL;
            window.location.replace(LogoutURL);
        }
    }

    handleChange(event) {
        console.log('->' + event.target.value);
        console.log('event.key->' + event.key);

        this.keyword = event.target.value;

        if (event.key == 'Enter') {
            this.isSearch = false;
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/resources?keyword=${encodeURIComponent(event.target.value)}&type=${encodeURIComponent(this.dropdownValue)}`
                }
            });
        }
    }

    handleRedirection(event) {
        const { name, label } = event.currentTarget.dataset;

        event.preventDefault();
        if (label === 'Sign Out') {
            this.handleLogout();
        } else if (label === 'Help') {
            this.toggleHelpDropdown();
        } else {
            this.showHelpDropdown = false;
            if (name) {
                this.keyword = '';
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: name
                    }
                });
                console.log('Entered Menu >>' ,this.keyword);
            }
        }

        if (!this.mobileVersionMenu) this.handleMobileMenu();
        this.showDropdown = false;
    }


    toggleHelpDropdown() {
        this.showHelpDropdown = !this.showHelpDropdown;
        if (this.showHelpDropdown) {
            this.helpSubMenuItems = [
                { label: 'Help home', url: '/help/home' },
                { label: 'Quick guide', url: '/help/quick-guide' },
                { label: 'Contact us', url: '/help/contact-us' }
            ];
        }
        console.log('Help clicked, showHelpDropdown:', this.showHelpDropdown);
        console.log('helpSubMenuItems:', JSON.stringify(this.helpSubMenuItems));
    }


    handleKeyEvent(event) {
        var eleId = event.currentTarget.dataset.id;

        if (event.keyCode === 13) {
            this.template.querySelector(`[data-id="${eleId}"]`).click();
        }
    }

    async checkUserPreference() {
        try {
            console.log('Fetching user preference...');
            const userPreference = await getUserPreference();
            console.log('User preference fetched:', userPreference);

            if (!userPreference) {
                console.log('No user preference found.');
            } else if (userPreference.MSD_CORE_Accepted_T_C__c === false || userPreference.MSD_CORE_Accepted_T_C__c === "false") {
                console.log('MSD_CORE_Accepted_T_C__c is false, showing popup.');
                this.showTandC = true;
            } else if (userPreference.MSD_CORE_Accepted_T_C__c === true || userPreference.MSD_CORE_Accepted_T_C__c === "true") {
                console.log('MSD_CORE_Accepted_T_C__c is true, no need to show popup.');
            } else {
                console.log('Unexpected value for MSD_CORE_Accepted_T_C__c:', userPreference.MSD_CORE_Accepted_T_C__c);
            }
        } catch (error) {
            console.error('Error fetching user preference:', error);
        }
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.closeDropdown.bind(this));
    }

}