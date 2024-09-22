import { LightningElement, wire, api, track } from 'lwc';
import HEQ_Header_CSS_1 from '@salesforce/resourceUrl/HEQ_Header_CSS_1';
import HEQ_Header_CSS_2 from '@salesforce/resourceUrl/HEQ_Header_CSS_2';
import HEQ_Logo from '@salesforce/resourceUrl/HEQ_Logo';
import { loadStyle } from 'lightning/platformResourceLoader';
import getUser from '@salesforce/apex/HEQ_HeaderController.getuser';
import fetchResources from '@salesforce/apex/HEQ_HeaderController.fetchResources';
import retrieveHeqHeaderMetadata from '@salesforce/apex/HEQ_HeaderController.retrieveHeqHeaderMetadata';
import { NavigationMixin } from 'lightning/navigation';

export default class HEQ_Header extends NavigationMixin(LightningElement) {

    mainLogo = HEQ_Logo;

    @api recordId;
    @track userVar;
    @track isShow = true;
    @track showDropdown = false;
    @track showSignout = false;
    @track isMenu = false;
    @track isSearch = false;
    @track keyword = '';
    @track dropdownValue = 'By Resource';
    @track resourcedata;

    @track myaccountList = [];
    @track profileMenuList = [];

    handleDropdown(event) {
        console.log('data-name->' + event.currentTarget.dataset.name);
        this.dropdownValue = event.currentTarget.dataset.name;
    }


    // handleRedirection(){

    // }

    redirectHomePage(event){
        console.log('redirectHomePage');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/'
            }
        });
    }

    handleMenu(event) {
        this.isMenu = this.isMenu ? false : true;
    }

    

    searchKeyword(event){
        this.isSearch = false;
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/resources?keyword=${encodeURIComponent(this.keyword)}&type=${encodeURIComponent(this.dropdownValue)}`
                }
            });
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

        // fetchResources({keyword: event.target.value}).then(data=>{
        //     console.log('data->'+JSON.stringify(data));
        //     if(data.length > 0){
        //         this.resourcedata = data;
        //     }else{
        //         this.resourcedata = false;
        //     }
        //     console.log('data->'+JSON.stringify(this.resourcedata));
        // }).catch(error=>{
        //     console.log('error->'+JSON.stringify(error));
        // });
    }

    handleSavedItems(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/saved-items`
            }
        });
    }

    handleRedirection(event){
        var pageName = event.currentTarget.dataset.name;

        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: pageName
            }
        });

        this.showDropdown = false;
        // if(pageName == 'My Collections'){
        //     this.handleCollections(event);
        // }
    }


    handleCollections(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/collections`
            }
        });
    }

    handleSearch(event) {
        this.isSearch = this.isSearch ? false : true;
    }

    handleAccountDropdown() {

        
        this.showDropdown = this.showDropdown ? false : true;
    }

    handleSignout() {
        this.showSignout = this.showSignout ? false : true;
    }

    connectedCallback() {
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
        console.log('recordId->' + this.recordId);

        const paramValue = this.getUrlParamValue(window.location.href, 'Id');
        console.log('paramValue->' + paramValue);

        getUser({ userId: paramValue })
            .then(result => {
                console.log('result->' + JSON.stringify(result));
                console.log(result.Profile.Name);
                this.userVar = result;
                if (result.Profile.Name == 'HEQ Customer') {
                    this.isShow = false;
                } else if (result.Profile.Name == 'HEQ - Account Ex') {
                    this.isShow = true;
                }
                // this.error = undefined;
            })
            .catch(error => {
                // this.error = error;
                // this.accounts = undefined;
            })

            retrieveHeqHeaderMetadata({}).then(result =>{
                console.log('Header Config List->'+ JSON.stringify(result));
                result.forEach(item=>{
                    if(item.Menu_Type__c == 'My Account'){
                        this.myaccountList.push(item);
                    }else if(item.Menu_Type__c == 'Profile'){
                        this.profileMenuList.push(item);
                    }
                });

                console.log('My Account List ->' + JSON.stringify(this.myaccountList));
                console.log('Profile List ->' + JSON.stringify(this.profileMenuList));

            }).catch(error =>{
                console.log('error->'+JSON.stringify(error));
            });


    }



    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

}