import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import ACCORDION_STYLES from '@salesforce/resourceUrl/AccordionStyles';
import { loadStyle } from 'lightning/platformResourceLoader';
import productdetailcss from '@salesforce/resourceUrl/productdetail';   //Static Resource For CSS
import USER_ID from "@salesforce/user/Id";

import getBrandInformations from '@salesforce/apex/MSD_CORE_ProductList.getBrandInformations';

export default class Sample extends LightningElement {

    recordId;
    infoval;
    safetyinfo;
    activesection = [];
    aactsec;

    @track prodname;
    @api productName;
    @api applyFilter = false;
    
    acrname;
    acr2name;
    saftyshort;
    infovalshort;
    accordian1 = false;
    showShortInfo = true;
    infovalshortInfo = true;
    safetyinfoDisplay = true;
    infovalDisplay = true;
    indicationDisplay = true;

    @track contactrole = '';
    @track indiHeader;
    @track ssiHeader;
    @track indiExpHeader;
    @track ssiExpHeader;
    @track readMoreIndication;
    @track readMoreSSI;
    setbindInd = false;
    setbindSaf = false;
    indTagName = '';
    safTagName = '';
    acr1 = false;
    acr2 = false;
    acr3 = false;

    accordioncls = 'accordioncls';
    mfr_indicationtxt = 'mfr_indicationtxt';
    mfr_indicationtxtindisafe = 'mfr_indicationtxt indisafe';
    
    connectedCallback() {
        this.getBrandInformations();
        var ses = sessionStorage.getItem('SelectedValue');
        this.activesection = ses;
        this.contactrole = sessionStorage.getItem('SFMC_Audience');

        loadStyle(this, ACCORDION_STYLES)
            .then(() => {
                console.log('Styles loaded successfully');
            })
            .catch(error => {
                console.error('Error loading styles', error);
            });

        setTimeout(() => {
            this.template.querySelector('.scroll_b_3').classList.add('block_cls');
            this.template.querySelector('.acc2').classList.add('block_cls');
            if (ses == 'true') {
                this.template.querySelector('.scroll_b_1').classList.remove('db');
            } else {
                this.template.querySelector('.scroll_b_1').classList.add('db');
            }
        }, 1);

        if(this.productName == 'GARDASIL®' && this.applyFilter) {
            this.accordioncls = 'accordioncls hide';
            this.mfr_indicationtxt = 'mfr_indicationtxt fontsize12';
            this.mfr_indicationtxtindisafe = 'mfr_indicationtxt indisafe fontsize12';
        }
    }

    // Get Selected Product Record id from Parameter
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            var urlStateParameters = currentPageReference.state;
            this.recordId = urlStateParameters.recordId;
          
            setTimeout(() => {
                this.template.querySelector('.scroll_b_3').classList.add('block_cls');
                this.template.querySelector('.acc2').classList.add('block_cls');
            }, 10);
        }
    }

     //    <!-- Added by Sabari - MFRUS-113 -->
    addbinding(){
        let finddescelements = this.template.querySelectorAll('.indisafe');
        const delay = 300;
        finddescelements.forEach((element)=>{
        const datavalue = element.getAttribute("data-value");
        const name = element.getAttribute("name");
        element.innerHTML = datavalue;
        setTimeout(() => {
        if(name=="Indication")
        {
            const readmore1tag = this.template.querySelector('#readmore1');
            if(readmore1tag && !this.setbindInd){
              readmore1tag.addEventListener('click',this.readmore1.bind(this));
              this.setbindInd = true;
            }
        }else if(name=="SSI"){
            const readmore2tag = this.template.querySelector('#readmore2');
            if(readmore2tag && !this.setbindSaf){
              readmore2tag.addEventListener('click',this.readmore2.bind(this));
              this.setbindSaf = true;
            }
        }
        },delay);
        });
    }

    // Called Twice when Page is loaded
    renderedCallback() {
        /* Added by Sabari to add the readmore in indication and safety */
        this.addbinding();

        let sc = this.template.querySelector('.scrolling_cls');
        if(sc){
            let h = screen.height;
            if(h){
                    sc.style.height = h;
            }
            
        }

        // For Loading CSS file from the Static Resource
        // this.template.querySelector('.scroll_b_3').classList.add('block_cls');
        // this.template.querySelector('.acc2').classList.add('block_cls');
        Promise.all([
            loadStyle(this, productdetailcss)
        ]).then(() => {
            console.log('Files loaded');
        })
        .catch(error => {
            console.log(error.body.message);
        });      
    }

    getBrandInformations() {
        getBrandInformations({ prodId: this.recordId, objectName: 'Product'})
            .then(result => {
                var width = screen.width;
                if (result.hasOwnProperty('Indication')){
                    this.infoval = result['Indication'].Section_Details__c;
                    this.indiHeader = result['Indication'].Section_Label__c;
                    this.indiExpHeader = result['Indication'].Label_Accordion_Expanded__c;
                    if (width < 768) {
                        var indication = result['Indication'].Accordion_Preview_Mobile__c;
                        this.infovalshort = indication;
                        this.readMoreIndication = result['Indication'].Show_Read_More_Mobile__c;
                    }else {
                        this.infovalshort =  result['Indication'].Accordion_Preview_Desktop__c;
                        this.readMoreIndication = result['Indication'].Show_Read_More__c;
                    }
                    
                    this.prodname = result['Indication'].Product_Payor__r.MSD_CORE_Product_Family__c;
                    //    <!-- Added by Sabari - MFRUS-113 -->
                    if(this.readMoreIndication){
                        let appendText = '<span id="readmore1" class="readmore1" style="color: #00857C !important;font-family: \'Invention\' !important;font-style: normal !important;font-weight: 600 !important;cursor: pointer;text-decoration: underline;text-decoration-color: #00857C !important;">Read more</span>';
                        const closingTags = this.infovalshort.match(/<\/s*(\w+)[^>]*>/gi);
                        if(closingTags && closingTags.length>0){
                            const lastClosingTag = closingTags[closingTags.length-1];
                            const tagName = lastClosingTag.substring(2,lastClosingTag.indexOf('>'));
                            this.indTagName = tagName;
                        }
                        
                        let newInfovalshort = this.infovalshort.replace(/<ul/g,'<ul class="slds-list_dotted slds-m-bottom_medium"').replace(/<ol/g, '<ol class="slds-list_ordered slds-m-bottom_medium"');
                        newInfovalshort = newInfovalshort.replace(/<h2/g,'<h2 class="slds-m-bottom_medium"');
                        this.infovalshort = newInfovalshort;
                        if(this.indTagName=='ul' || this.indTagName == 'ol'){
                            let lastLiIndex = this.infovalshort.lastIndexOf('</li>');
                            
                            if(lastLiIndex !==-1){
                                let modifiedText = this.infovalshort.slice(0,lastLiIndex)+' '+appendText+this.infovalshort.slice(lastLiIndex);
                                this.infovalshort = modifiedText;
                                }else{
                                    this.infovalshort = this.infovalshort + appendText;
                                }
                            }
                            else if(this.indTagName == 'p') {
                            let lastPIndex = this.infovalshort.lastIndexOf('</p>');
                            if(lastPIndex !==-1){
                                let modifiedText = this.infovalshort.slice(0,lastPIndex)+' '+appendText+this.infovalshort.slice(lastPIndex);
                                this.infovalshort = modifiedText;
                            }
                        }
                        else if(this.indTagName == 'div') {
                            let removedivtext = this.infovalshort.replace(/<\/div>/g,'');
                            let lastbeforetag;
                            const closingTags = removedivtext.match(/<\/s*(\w+)[^>]*>/gi);
                            if(closingTags && closingTags.length>0){
                                const lastClosingTag = closingTags[closingTags.length-1];
                                const tagName = lastClosingTag.substring(2,lastClosingTag.indexOf('>'));
                                lastbeforetag = tagName;
                            }

                            if(lastbeforetag == 'p'){
                                let lastPIndex = this.infovalshort.lastIndexOf('</p>');
                                if(lastPIndex !==-1){
                                    let modifiedText = this.infovalshort.slice(0,lastPIndex)+' '+appendText+this.infovalshort.slice(lastPIndex);
                                    this.infovalshort = modifiedText;
                                }
                            }else if(lastbeforetag == 'ul' || lastbeforetag == 'ol'){
                                let lastLiIndex = this.infovalshort.lastIndexOf('</li>');
                                if(lastLiIndex !==-1){
                                    let modifiedText = this.infovalshort.slice(0,lastLiIndex)+' '+appendText+this.infovalshort.slice(lastLiIndex);
                                    this.infovalshort = modifiedText;
                                }
                            }
                        }
                        else{
                            this.infovalshort = this.infovalshort + appendText;
                        }
                    }
                }

                if (result.hasOwnProperty('Selected Safety Information')){
                    this.safetyinfo = result['Selected Safety Information'].Section_Details__c;
                    this.ssiHeader = result['Selected Safety Information'].Section_Label__c;
                    this.ssiExpHeader = result['Selected Safety Information'].Label_Accordion_Expanded__c;
                    if (width < 768) {
                        var saft = result['Selected Safety Information'].Accordion_Preview_Mobile__c;
                        this.saftyshort = saft;
                        
                        var ses = sessionStorage.getItem('SelectedValue');
                        if (ses == 'true'){
                            //this.showShortInfo = false;
                        }
                        this.readMoreSSI = result['Selected Safety Information'].Show_Read_More_Mobile__c;
                    }else {
                        this.saftyshort = result['Selected Safety Information'].Accordion_Preview_Desktop__c;
                        this.readMoreSSI = result['Selected Safety Information'].Show_Read_More__c;
                    }
                    this.prodname = result['Selected Safety Information'].Product_Payor__r.MSD_CORE_Product_Family__c;
                    
                    //    <!-- Added by Sabari - MFRUS-113 -->
                    if(this.readMoreSSI){
                        let appendText = '<span id="readmore2"  class="readmore2" style="color: #00857C !important;font-family: \'Invention\' !important;font-style: normal !important;font-weight: 600 !important;cursor: pointer;text-decoration: underline;text-decoration-color: #00857C !important;">Read more</span>';
                        const closingTags = this.saftyshort.match(/<\/s*(\w+)[^>]*>/gi);
                        if(closingTags && closingTags.length>0){
                            const lastClosingTag = closingTags[closingTags.length-1];
                            const tagName = lastClosingTag.substring(2,lastClosingTag.indexOf('>'));
                            this.safTagName = tagName;
                        }
                     
                        let newsaftyshort = this.saftyshort.replace(/<ul/g,'<ul class="slds-list_dotted slds-m-bottom_medium"').replace(/<ol/g, '<ol class="slds-list_ordered slds-m-bottom_medium"');
                        newsaftyshort = newsaftyshort.replace(/<h2/g,'<h2 class="slds-m-bottom_medium"');
                        this.saftyshort = newsaftyshort;
                        if(this.safTagName=='ul' || this.safTagName == 'ol'){
                            let lastLiIndex = this.saftyshort.lastIndexOf('</li>');
                            if(lastLiIndex !==-1){
                                let modifiedText = this.saftyshort.slice(0,lastLiIndex)+' '+appendText+this.saftyshort.slice(lastLiIndex);
                                this.saftyshort = modifiedText;
                                }else{
                                    this.saftyshort = this.saftyshort + appendText;
                                }
                        }else if(this.safTagName == 'p'){
                            let lastPIndex = this.saftyshort.lastIndexOf('</p>');
                            if(lastPIndex !==-1){
                                let modifiedText = this.saftyshort.slice(0,lastPIndex)+' '+appendText+this.saftyshort.slice(lastPIndex);
                                this.saftyshort = modifiedText;
                            }
                        }
                        else if(this.safTagName == 'div') {
                            let removedivtext = this.saftyshort.replace(/<\/div>/g,'');
                            let lastbeforetag;
                            const closingTags = removedivtext.match(/<\/s*(\w+)[^>]*>/gi);
                            if(closingTags && closingTags.length>0){
                                const lastClosingTag = closingTags[closingTags.length-1];
                                const tagName = lastClosingTag.substring(2,lastClosingTag.indexOf('>'));
                                lastbeforetag = tagName;
                            }
                            if(lastbeforetag == 'p'){
                                let lastPIndex = this.saftyshort.lastIndexOf('</p>');
                                if(lastPIndex !==-1){
                                    let modifiedText = this.saftyshort.slice(0,lastPIndex)+' '+appendText+this.saftyshort.slice(lastPIndex);
                                    this.saftyshort = modifiedText;
                                }
                            }else if(lastbeforetag == 'ul' || lastbeforetag == 'ol'){
                                let lastLiIndex = this.saftyshort.lastIndexOf('</li>');
                                if(lastLiIndex !==-1){
                                    let modifiedText = this.saftyshort.slice(0,lastLiIndex)+' '+appendText+this.saftyshort.slice(lastLiIndex);
                                    this.saftyshort = modifiedText;
                                }
                            }
                        }else{
                            this.saftyshort = this.saftyshort + appendText;
                        }
                    }
                }
                
                this.acr2name = this.ssiHeader;
                this.acrname = this.indiHeader;

                var a1 = this.infovalshort;
                var a2 = this.saftyshort;

                if (a1 != undefined) {
                    if (a1.length < 5) {
                        this.template.querySelector('.scroll_b_1').classList.remove('db');
                    }else {
                        this.template.querySelector('.scroll_b_1').classList.add('db');
                    }
                }else {
                    this.template.querySelector('.scroll_b_1').classList.remove('db');
                }

                if (a2 != undefined) {
                    if (a2.length < 5) {
                        this.template.querySelector('.scroll_b_2').classList.add('block_cls');
                    }else {
                        this.template.querySelector('.scroll_b_2').classList.remove('block_cls');
                    }
                }else {
                    this.template.querySelector('.scroll_b_2').classList.add('block_cls');
                }
            })
            .catch(error => {
                console.log({ error });
            });
    }
    

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
    }

    clc(event) {
        try{
            this.aactsec = event.target.name;
            var width = screen.width;
            var activesectionname = event.target.name;
            var test_lst = [];

            if (activesectionname == 'Indication') {
                this.accordian1 = true;
                sessionStorage.setItem("SelectedValue", true);

                if (this.acr1 == false) {   // close to open                    
                    this.fireDataClickEvent("accordion",'','expand',"indication",this.prodname);
                    var classnamevar = this.template.querySelector('.sample-bg');

                    if(classnamevar){
                        this.template.querySelector('.sample-bg')?.classList.add('sample-active');
                    }
                    var classnamevar1 = this.template.querySelector('.accordian_cls');
                    if(classnamevar1){
                        this.template.querySelector('.accordian_cls')?.classList.add('zindex');
                    }
                    
                    if (width < 768) { // for mobile
                        this.showShortInfo = true;		   //Modified by Sabari to show the Selected Safety Short text
                        this.infovalshortInfo = true;
                        this.acr1 = true;
                        this.acr2 = false;
                        this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                        this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                    }
                    else {    // for desktop
                        this.acr1 = true;
                        this.acr2 = false;
                        this.acrname = this.indiExpHeader;
                        let sb1 = this.template.querySelector('.scroll_b_1');
                        if(sb1){
                            sb1.classList.remove('db');
                        }
                        let sb2 = this.template.querySelector('.scroll_b_2');
                        if(sb2){
                            sb2.classList.remove('block_cls');
                        }
                    }
                    test_lst.push('Indication');
                } else {  // open to close
                    this.fireDataClickEvent("accordion",'',"collapse","indication",this.prodname);
                    document.body.style.overflowY = 'scroll';
                    this.template.querySelector('.sample-bg')?.classList.remove('sample-active');
                    this.template.querySelector('.accordian_cls')?.classList.remove('zindex');

                    if (width < 768) {
                        this.infovalshortInfo = false;
                        this.acr1 = false;
                        this.acrname = this.indiHeader;
                        this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                        this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                    } else {
                        this.acr1 = false;
                        this.acrname = this.indiHeader;
                        let sb1 = this.template.querySelector('.scroll_b_1');
                        if(sb1){
                            sb1.classList.remove('db');
                        }
                        let sb2 = this.template.querySelector('.scroll_b_2');
                        if(sb2){
                            sb2.classList.remove('block_cls');
                        }
                    }
                    test_lst.push('  ');
                }
                if (this.acr1) {
                    this.template.querySelector('.am2')?.classList.remove('acc_margintopsample');
                }
                else {
                    this.template.querySelector('.am2').classList.add('acc_margintopsample');
                }
            }
            else if (activesectionname == 'Selected Safety Information') {
                if (this.acr2 == false) { // Close to Open
                    this.fireDataClickEvent("accordion",'',"expand","isi",this.prodname);
                    //document.body.style.overflowY = 'hidden';/*AMS - E2ESE-1531*/
                    this.template.querySelector('.sample-bg')?.classList.add('sample-active');
                    this.template.querySelector('.accordian_cls')?.classList.add('zindex');

                    if (width < 768) {
                        this.showShortInfo = true;	  //Modified by Sabari to show the Selected Safety Short text
                        this.infovalshortInfo = false;
                        this.acr2 = true;
                        this.acr1 = false;
                        this.acr2name = this.ssiExpHeader;
                        this.template.querySelector('.scroll_b_2')?.classList.add('block_cls');
                        this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                        this.template.querySelector('.acc')?.classList.add('block_cls');
                        this.template.querySelector('.acc2')?.classList.add('db');
                        this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                    }else {
                        this.acr2 = true;
                        this.acr1 = false;
                        this.acr2name = this.ssiExpHeader;
                        let sb2 = this.template.querySelector('.scroll_b_2');
                        if(sb2){
                            sb2.classList.add('block_cls');
                        }
                        let ac1 = this.template.querySelector('.acc');
                        if(ac1){
                            ac1.classList.add('block_cls');
                        }
                        let ac2 = this.template.querySelector('.acc2');
                        if(ac2){
                            ac2.classList.add('db');
                        }
                        if (this.accordian1 && this.acr1) {
                            let sb1 = this.template.querySelector('.scroll_b_1');
                            if(sb1){
                                sb1.classList.add('db');
                            }
                        } else {
                            let sb1 = this.template.querySelector('.scroll_b_1');
                            if(sb1){
                                sb1.classList.remove('db');
                            }
                        }
                    }
                    test_lst.push('Selected Safety Information');
                } else { // Open to Close
                    this.fireDataClickEvent("accordion",'',"collapse","isi",this.prodname);
                    
                    document.body.style.overflowY = 'scroll';

                    this.template.querySelector('.sample-bg').classList.remove('sample-active');
                    this.template.querySelector('.accordian_cls').classList.remove('zindex');

                    if (width < 768) {
                        this.acr2 = false;
                        this.acr2name = this.ssiHeader;
                        this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                        this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                        this.template.querySelector('.acc')?.classList.remove('block_cls');
                        this.template.querySelector('.acc2')?.classList.remove('db');
                        this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                        this.showShortInfo = true;		//Modified by Sabari to show the Selected Safety Short text
                    }else {
                        this.acr2 = false;
                        this.acr2name = this.ssiHeader;
                        this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                        this.template.querySelector('.scroll_b_1')?.classList.add('db');
                        this.template.querySelector('.acc')?.classList.remove('block_cls');
                        this.template.querySelector('.acc2')?.classList.remove('db');
                        this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                    }
                    let kk = sessionStorage.getItem("SelectedValue");
                    this.infovalshortInfo = false;
                } 
            } else if (activesectionname == 'Indication2') {
                //document.body.style.overflowY = 'hidden';/*AMS - E2ESE-1531*/
                this.accordian1 = true;
                sessionStorage.setItem("SelectedValue", true);
                this.template.querySelector('.sample-bg').classList.add('sample-active');
                this.template.querySelector('.accordian_cls').classList.add('zindex');

                if (width < 768) {
                    this.acr1 = true;
                    this.acr2 = false;
                    this.acrname = this.indiExpHeader;
                    this.template.querySelector('.scroll_b_3').classList.remove('db');
                    this.template.querySelector('.acc2').classList.remove('db');
                    this.template.querySelector('.scroll_b_1').classList.remove('db');
                    this.template.querySelector('.scroll_b_2').classList.remove('block_cls');
                    this.template.querySelector('.acc').classList.remove('block_cls');
                }
                else {
                    this.acr1 = true;
                    this.acr2 = false;
                    this.acrname = this.indiExpHeader;
                    this.template.querySelector('.scroll_b_3').classList.remove('db');
                    this.template.querySelector('.acc2').classList.remove('db');
                    this.template.querySelector('.scroll_b_1').classList.remove('db');
                    this.template.querySelector('.scroll_b_2').classList.remove('block_cls');
                    this.template.querySelector('.acc').classList.remove('block_cls');
                }
                test_lst.push('Indication');
            }
            if (activesectionname != undefined) {

                this.activesection = test_lst;
                this.accodianname();
            }
        }catch(error){
            console.log('error in clc',error);
        }
        //    <!-- Added by Sabari - MFRUS-113 -->
        this.setbindSaf = false;
        this.addbinding();
    }

    readmore1(event) {
        var tt = ['Indication'];
        this.acrname = this.indiExpHeader;
        this.acr2name = this.ssiHeader;
        var test_lst = [];
        this.accordian1 = true;
        sessionStorage.setItem("SelectedValue", true);
        var width = screen.width;

        if (this.acr1 == false) {
            //document.body.style.overflowY = 'hidden';/*AMS - E2ESE-1531*/
            this.template.querySelector('.sample-bg').classList.add('sample-active');
            this.template.querySelector('.accordian_cls').classList.add('zindex');

            if (width < 768) { // for mobile
                this.acr1 = true;
                this.acr2 = false;
                this.template.querySelector('.scroll_b_1').classList.remove('db');
                this.template.querySelector('.scroll_b_3').classList.remove('db');
                this.template.querySelector('.scroll_b_2').classList.remove('block_cls');
                this.template.querySelector('.acc2').classList.remove('db');
            }else {    // for desktop
                this.acr1 = true;
                this.acr2 = false;
                this.acrname = this.indiExpHeader;
                this.template.querySelector('.scroll_b_1').classList.remove('db');
                this.template.querySelector('.scroll_b_3').classList.remove('db');
                this.template.querySelector('.scroll_b_2').classList.remove('block_cls');
                this.template.querySelector('.acc2').classList.remove('db');
            }
            test_lst.push('Indication');
        }else {
            document.body.style.overflowY = 'scroll';

            this.template.querySelector('.sample-bg').classList.remove('sample-active');
            this.template.querySelector('.accordian_cls').classList.remove('zindex');

            if (width < 768) {
                this.acr1 = false;
                this.acrname = this.indiHeader;
                this.template.querySelector('.scroll_b_1').classList.remove('db');
                this.template.querySelector('.scroll_b_3').classList.remove('db');
                this.template.querySelector('.scroll_b_2').classList.add('block_cls');
                this.template.querySelector('.acc2').classList.remove('db');
            }else {
                this.acr1 = false;
                this.acrname = this.indiHeader;
                this.template.querySelector('.scroll_b_1').classList.remove('db');
                this.template.querySelector('.scroll_b_3').classList.remove('db');
                this.template.querySelector('.scroll_b_2').classList.remove('block_cls');
                this.template.querySelector('.acc2').classList.remove('db');
            }
            test_lst.push('  ');
        }
        this.activesection = test_lst;
        //    <!-- Added by Sabari - MFRUS-113 -->
        this.setbindSaf=false;
        this.addbinding();
    }

    readmore2(event) {
        var tt = ['Selected Safety Information'];
        var width = screen.width;
        var test_lst = [];
        this.acr2name = this.ssiExpHeader;
        this.acrname = this.indiHeader;

        if (this.acr2 == false) {
            //document.body.style.overflowY = 'hidden';/*AMS - E2ESE-1531*/
            this.template.querySelector('.sample-bg')?.classList.add('sample-active');
            this.template.querySelector('.accordian_cls')?.classList.add('zindex');

            if (width < 768) {
                this.acr2 = true;
                this.acr1 = false;
                this.acr2name = this.ssiExpHeader;
                this.template.querySelector('.scroll_b_2')?.classList.add('block_cls');
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.acc')?.classList.add('block_cls');
                this.template.querySelector('.acc2')?.classList.add('db');
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
            }else {
                this.acr2 = true;
                this.acr1 = false;
                this.acr2name = this.ssiExpHeader;
                this.template.querySelector('.scroll_b_2')?.classList.add('block_cls');
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.acc')?.classList.add('block_cls');
                this.template.querySelector('.acc2')?.classList.add('db');
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
            }
            test_lst.push('Selected Safety Information');
        }
        else {
            //change dd
            this.fireDataClickEvent("accordion", "", "collapse", "indication", this.prodname);
            //change dd
            this.template.querySelector(".am2").classList.add("acc_margintopsample")
            document.body.style.overflowY = 'scroll';
            this.template.querySelector('.sample-bg').classList.remove('sample-active');
            this.template.querySelector('.accordian_cls').classList.remove('zindex');

            if (width < 768) {
                this.acr2 = false;
                //change dd
                 this.acr1 = false;
                this.acr2name = this.ssiHeader;
                this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.acc')?.classList.remove('block_cls');
                this.template.querySelector('.acc2')?.classList.remove('db');
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
            }else {
                this.acr2 = false;
                //change dd
                this.acr1 = false;
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                this.acr2name = this.ssiHeader;
                this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.acc')?.classList.remove('block_cls');
                this.template.querySelector('.acc2')?.classList.remove('db');
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
            }
            //change dd
            test_lst.push('  ');
        }
        this.activesection = test_lst;
        //    <!-- Added by Sabari - MFRUS-113 -->
        this.setbindSaf = false;
        this.addbinding();
    }

    readmore3() {
        var test_lst = [];
        this.acr1 = true;
        this.acr2 = false;
        var width = screen.width;
        this.acrname = this.indiExpHeader;
        this.acr2name = this.ssiHeader;

        //document.body.style.overflowY = 'hidden';/*AMS - E2ESE-1531*/

        this.template.querySelector('.sample-bg').classList.add('sample-active');
        this.template.querySelector('.accordian_cls').classList.add('zindex');

        if (width < 768) {
            this.acr1 = true;
            this.acr2 = false;
            this.acrname = this.indiExpHeader;
            this.template.querySelector('.scroll_b_3').classList.remove('db');
            this.template.querySelector('.acc2').classList.remove('db');
            this.template.querySelector('.scroll_b_1').classList.add('block_cls');
            this.template.querySelector('.scroll_b_2').classList.remove('block_cls');
            this.template.querySelector('.acc').classList.remove('block_cls');
        }else {
            this.acr1 = true;
            this.acr2 = false;
            this.acrname = this.indiExpHeader;
            this.template.querySelector('.scroll_b_3').classList.remove('db');
            this.template.querySelector('.acc2').classList.remove('db');
            this.template.querySelector('.scroll_b_1').classList.add('block_cls');
            this.template.querySelector('.scroll_b_2').classList.remove('block_cls');
            this.template.querySelector('.acc').classList.remove('block_cls');
        }
        test_lst.push('Indication');

        this.activesection = test_lst;
    }

    accodianname() {
        if (this.acr1 == true) {
            this.acrname = this.indiExpHeader;
        }else {
            this.acrname = this.indiHeader;
        }

        if (this.acr2 == true) {
            this.acr2name = this.ssiExpHeader;
        }else {
            this.acr2name = this.ssiHeader;
        }
    }

    fireDataClickEvent(category, action, label,module, prodname) {
        const { host, hostname, href, origin, pathname, port, protocol, search } = window.location;
        let pagetype;
        let linktext;
        if (pathname == '/merckportal/library/detail') {
            pagetype = 'resources';
            linktext = 'detail__c';
        } else if(pathname == '/merckportal/product/productdetail') {
            pagetype = 'product';
            linktext = 'productdetail__c';
        }

       this.dispatchEvent(new CustomEvent('fireDataClickEvent', {
          
           detail: {               
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: pagetype,
                page_purpose:'product detail',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text:linktext,
                link_url:pathname,
                content_count:'',
                content_saved:'',
                content_appointments:'',
                content_requests:'',
                content_name:'',
                page_localproductname:prodname,      
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: '',

           },
           bubbles: true,
           composed: true
       }));
   }
}