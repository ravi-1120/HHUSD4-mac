import { LightningElement, track} from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import FORM_FACTOR from '@salesforce/client/formFactor';

//Static Resource
import BANNER_STYLES from '@salesforce/resourceUrl/MSD_CORE_HEQ_Carousel';
import HEQ_Banner_1 from '@salesforce/resourceUrl/MSD_CORE_HEQ_Banner_1'
import HEQ_Banner_2 from '@salesforce/resourceUrl/MSD_CORE_HEQ_Banner_2'
import HEQ_Banner_3 from '@salesforce/resourceUrl/MSD_CORE_HEQ_Banner_3'
import HEQ_Banner2_Mb from '@salesforce/resourceUrl/MSD_CORE_HEQ_Banner2_Mb'
import HEQ_Banner1_Mb from '@salesforce/resourceUrl/MSD_CORE_HEQ_Banner1_Mb'
import HEQ_Banner3_Mb from '@salesforce/resourceUrl/MSD_CORE_HEQ_Banner3_Mb'

//Custom Labels
import carouselAlt1 from '@salesforce/label/c.MSD_CORE_HEQ_CarouselAlt1';
import carouselAlt2 from '@salesforce/label/c.MSD_CORE_HEQ_CarouselAlt2';
import carouselAlt3 from '@salesforce/label/c.MSD_CORE_HEQ_CarouselAlt3';

export default class MSD_CORE_HEQ_Carousel extends LightningElement {

    @track HEQ_Banner_1 = HEQ_Banner_1;
    @track HEQ_Banner_2 = HEQ_Banner_2;
    @track HEQ_Banner_3 = HEQ_Banner_3;

    labels = {
        carouselAlt1,
        carouselAlt2,
        carouselAlt3
    }

    connectedCallback() {
        this.loadStyles();
        if (FORM_FACTOR === "Large") {
            this.HEQ_Banner_1 = HEQ_Banner_1;
            this.HEQ_Banner_2 = HEQ_Banner_2;
            this.HEQ_Banner_3 = HEQ_Banner_3;
        } else if (FORM_FACTOR === "Medium") {
            this.HEQ_Banner_1 = HEQ_Banner2_Mb;
            this.HEQ_Banner_2 = HEQ_Banner1_Mb;
            this.HEQ_Banner_3 = HEQ_Banner3_Mb;
        }
    }

    loadStyles() {
        loadStyle(this, BANNER_STYLES)
            .then(() => {
                console.log('Styles loaded successfully for Carousel Component.');
            })
            .catch(error => {
                console.error('Error loading styles for Carousel Component:', error);
            });
    }
}