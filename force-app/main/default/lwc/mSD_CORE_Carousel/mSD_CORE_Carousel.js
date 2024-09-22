/**
 * Auther:              Ravi Modi (Focal CXM)
 * Component Name:      mSD_CORE_Carousel
 * Description:         Used for Display Study Detail Carousel Section
 * Used in:             MHEE Portal Site Study Detail Page(mSD_CORE_Studydetail LWC)
 * Created Date:        27th March 2023
 * Lastmodified Date:   27th March 2023
 */

import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import USER_ID from '@salesforce/user/Id';          //User Id

// Static Resource
import CarouselCss from '@salesforce/resourceUrl/MSD_CORE_Carousel';

// Apex Class
import getCarouselImage from '@salesforce/apex/MSD_CORE_StudyDetailController.getCarouselImage';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

export default class MSD_CORE_Carousel extends LightningElement {
    
    @track contactrole; 
    @track sdrecordId;              //Storing Study Detail Id from the Parameter
    @track caroselimg;              //Storing Carosel Image
    @api clinicalcontname;

    // Method Name:         renderedCallback
    // Method Use:          Used for loading external CSS file
    // Developer Name:      Ravi Modi
    // Created Date:        27th March 2023
    renderedCallback() {
        Promise.all([
            loadStyle(this, CarouselCss),
        ]).then(() => {
            console.log('Files loaded');
        })
        .catch(error => {
            console.log(error.body.message);
        });

        // For Adding boarder on First Carousel image
        let datalid = '[data-transform="-000%"]';
        let togglecls = this.template.querySelector(datalid);
        if (togglecls) {
            togglecls.classList.add('bordercls');
        }

        // For Disable right Click
        let imgElements = this.template.querySelectorAll('.imgcls');
        if (imgElements) {
            Array.from(imgElements).forEach(imgElement => {
                imgElement.addEventListener('contextmenu', event => {
                    event.preventDefault();
                });
            });
        }
    }
    
    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        console.log('wiredgetContactRole-->',{ value });
        const { data, error } = value;
        if (data) {
            this.contactrole = data;
        }
        if (error) {
            console.log({ error });
        }
    }

    // Method Name:         WiredgetStateParameters
    // Method Use:          Used for getting Record Id from the parameter
    // Developer Name:      Ravi Modi
    // Created Date:        27th March 2023
    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.sdrecordId = currentPageReference.state.recordId;
        }
    }

    // Method Name:         WiredgetCarouselImage
    // Method Use:          Used for getting Images for specific Study Detail
    // Developer Name:      Ravi Modi
    // Created Date:        27th March 2023
    @wire(getCarouselImage, { recordId : '$sdrecordId' })
    WiredgetCarouselImage(value) {
        console.log('WiredgetCarouselImage -->',{value});
        const { data, error } = value;
        if(data) {
            this.caroselimg = this.getFormattedData(data).sort();
            console.log('this.caroselimg-->',this.caroselimg);
        } else if(error) {
            console.log('WiredgetCarouselImage--->',{error});
        }
    }

    // Method Name:         getFormattedData
    // Method Use:          Used for Formatting the Data
    // Developer Name:      Ravi Modi
    // Created Date:        27th March 2023
    getFormattedData(datavalue) {
        let returndata = datavalue.map(ele => ({
            CarouselImg: 'data:image/png;base64,'+ele.VersionData,
            Transform: '-'+ele.Order+'00%',
            Order: ele.Order,
        }));
        /* Formation */
        returndata.sort((a, b) => {
            return parseInt(a.Order) - parseInt(b.Order);
        });
        return returndata;
    }

    // Method Name:         handleImageClick
    // Method Use:          Used for changing the carousel image
    // Developer Name:      Ravi Modi
    // Created Date:        27th March 2023
    handleImageClick(event) {

        try {
            let transformval = event.target.dataset.transform;
            document.documentElement.style.setProperty('--transval', transformval);
            let prebordercls = this.template.querySelector('.bordercls');
            if (prebordercls) {
                prebordercls.classList.remove('bordercls');
            }
            let datalid = '[data-transform="' +transformval+ '"]';
            let togglecls = this.template.querySelector(datalid);
            togglecls.classList.add('bordercls');   
        } catch (error) {
            console.log('Error in handleImageClick==>',{error});
        }
        this.fireDataLayerEvent("pagination", '', "thumbnail" , '', 'StudyDetail__c', '/studydetail');
    }

    //googleanalytics
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'account management',
                page_purpose: 'registration',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: linkedtext,
                link_url: linkedurl,
                content_count: '',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: this.clinicalcontname,
                page_localproductname: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'Self Registration',

            },
            bubbles: true,
            composed: true
        }));
    }

}