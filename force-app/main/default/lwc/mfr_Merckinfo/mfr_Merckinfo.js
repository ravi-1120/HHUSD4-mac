import { LightningElement } from 'lwc';
import newlogo from '@salesforce/resourceUrl/banner';
import moreres from '@salesforce/label/c.MSD_CORE_MoreResource';            //Label for Medical Guide
import merckinfo from '@salesforce/label/c.MerckInfo';            //Label for Medical Guide
import merckinfo1 from '@salesforce/label/c.MSD_CORE_merckinfo1';  
export default class Mfr_Merckinfo extends LightningElement {

    logo1 = newlogo;
    label = {
        moreres,
        merckinfo,
        merckinfo1
    }
}