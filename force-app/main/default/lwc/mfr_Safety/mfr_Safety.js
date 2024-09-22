import { LightningElement, api, track } from 'lwc';
import getBrandInformations from '@salesforce/apex/MSD_CORE_ProductList.getBrandInformations';

export default class Mfr_Safety extends LightningElement {

    infoval;
    safetyinfo;
    @track indiHeader;
    @track ssiHeader;
    @api product;

    connectedCallback(){
        this.getBrandInformations();
    }
    
    getBrandInformations() {
        console.log('Saftey product-->', this.product);
        getBrandInformations({ prodId: this.product })
            .then(result => {
                if (result.hasOwnProperty('Indication')){
                    this.infoval = result['Indication'].Section_Details__c;
                    this.indiHeader = result['Indication'].Section_Label__c;
                }
                if (result.hasOwnProperty('Selected Safety Information')){
                    this.safetyinfo = result['Selected Safety Information'].Section_Details__c;
                    this.ssiHeader = result['Selected Safety Information'].Section_Label__c;
                }
            })
            .catch(error => {
                console.log({ error });
            })
    }
}