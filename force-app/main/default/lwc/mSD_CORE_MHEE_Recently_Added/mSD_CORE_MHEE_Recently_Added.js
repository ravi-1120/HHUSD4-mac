import { LightningElement, track } from 'lwc';
import mheedomain from '@salesforce/label/c.MSD_CORE_MHEE_Domain_URL';

export default class MSD_CORE_MHEE_Recently_Added extends LightningElement {

mheedomain = mheedomain;
@track titlelist = ['Disease state decks title', 'Dossiers title', 'IPP title'];
@track myList = [
        {
            resourcename: "Disease state decks title",
            title: "Description text Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do ",
            content: "Antibacterial/Antifungal"
        },
        {
            resourcename: "Dossiers title",
            title: "Description text Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do ",
            content: "Antibacterial/Antifungal"
        },
        {
            resourcename: "IPP title",
            title: "Description text Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do ",
            content: "Antibacterial/Antifungal"
        }
    ];


    connectedCallback(){
        console.log('titlelist>>' + this.titlelist);
    }

    onallresources(){
        window.open(this.mheedomain + '/all-resources');
    }
}