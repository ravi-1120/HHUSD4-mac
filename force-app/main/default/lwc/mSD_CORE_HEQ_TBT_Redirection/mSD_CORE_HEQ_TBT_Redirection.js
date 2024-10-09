import { LightningElement, track, wire } from 'lwc';
import getRedirectURL from '@salesforce/apex/MSD_CORE_HEQ_TBT_RedirectionHandler.getRedirectURL';

export default class SessionIframeComponent extends LightningElement {  
    @track error;
    iframeUrl = 'https://tbt-dev.healtheq.com/personalized-resource/';
    @track template_id = '';
    @track job_code = '';

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    connectedCallback() {
        this.template_id = this.getUrlParamValue(window.location.href, 'template_id');
        this.job_code = this.getUrlParamValue(window.location.href, 'job_code');
        this.iframeUrl = this.iframeUrl + this.template_id + '/'+ this.job_code;
    }

    // Fetch url using Apex method
    //@wire(getRedirectURL)
    // wiredRedirectURL({ error, data }) {
    //     if (data) {
    //         console.log('data==>>'+data);            
    //         //Here we append the session ID as a query parameter to the iframe URL
    //         this.iframeUrl = data;
    //         console.log('IFrame URL: ' + this.iframeUrl );
    //     } else if (error) {
    //         console.log('error==>>'+error.message);
    //         this.error = error;
    //     }
    // }
}