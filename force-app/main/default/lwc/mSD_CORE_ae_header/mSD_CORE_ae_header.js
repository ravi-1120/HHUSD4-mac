import { LightningElement, track, api, wire } from 'lwc';
import AMO_FONTS from '@salesforce/resourceUrl/AMO_Fonts'
import Merck_logo from '@salesforce/label/c.Merck_Logo';
import Headermsg1 from '@salesforce/label/c.MSD_CORE_ae_Header_Message1';
import Headermsg from '@salesforce/label/c.MSD_CORE_ae_Header_Message';
export default class MSD_CORE_ae_header extends LightningElement {
    imageUrl = Merck_logo;
    fontsBaseUrl = AMO_FONTS;

    label = {
        Headermsg1,
        Headermsg
    }
      
}