import { LightningElement,wire,track,api } from 'lwc';
import getUser from '@salesforce/apex/HEQ_HeaderController.getuser';
import { NavigationMixin } from 'lightning/navigation';

export default class HEQ_Vertical_Nav extends NavigationMixin(LightningElement) {

@track isExpand = true;

@track isShow = true;

handleBrowse(event){
    console.log('handleBrowse');
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: `/resources?type=${encodeURIComponent('Browse All')}`
        }
    });
}

handleCollectionsclick(){
    console.log('handleBrowse');
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: `/resources/collections`
        }
    });
}

connectedCallback() {
    const paramValue = this.getUrlParamValue(window.location.href, 'Id');
    console.log('paramValue->'+paramValue);
    getUser({ userId: paramValue })
        .then(result => {
            console.log('result->' + JSON.stringify(result));
            console.log(result.Profile.Name);
            if(result.Profile.Name == 'HEQ Customer'){
                this.isShow = false;
            }else if(result.Profile.Name == 'HEQ - Account Ex'){
                this.isShow = true;
            }
            console.log('->'+this.isExpand+'--'+this.isShow);
            // this.error = undefined;
        })
        .catch(error => {
            // this.error = error;
            // this.accounts = undefined;
        })
}

handleExpand(event){
    console.log('handleExpand');
    this.isExpand = this.isExpand ? false : true;
}



getUrlParamValue(url, key) {
    return new URL(url).searchParams.get(key);
}

}