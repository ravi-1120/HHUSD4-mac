import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import productdetailcss from '@salesforce/resourceUrl/productdetail';   //Static Resource For CSS
import USER_ID from "@salesforce/user/Id";
import getBrandInformations from '@salesforce/apex/MSD_CORE_ProductList.getBrandInformations';

export default class Samplenew extends LightningElement {

    recordId;
    infoval;
    safetyinfo;
    activesection = [];
    aactsec;
    prodname;
    genericname;
    acrname;
    acr2name;
    saftyshort;
    infovalshort;
    accordian1 = false;
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

    connectedCallback() {
        this.getBrandInformations();
        var ses = sessionStorage.getItem('SelectedValue');
        console.log({ ses });
        
        this.activesection = ses;

        this.contactrole = sessionStorage.getItem('SFMC_Audience');
        setTimeout(() => {
            this.template.querySelector('.scroll_b_3')?.classList.add('block_cls');
            this.template.querySelector('.acc2')?.classList.add('block_cls');
            if (ses == 'true') {
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
            } else {
                this.template.querySelector('.scroll_b_1')?.classList.add('db');
            }
        }, 1);
    }

    // Get Selected Product Record id from Parameter
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            var urlStateParameters = currentPageReference.state;
            this.recordId = urlStateParameters.recordId;
            setTimeout(() => {
                this.template.querySelector('.scroll_b_3')?.classList.add('block_cls');
                this.template.querySelector('.acc2')?.classList.add('block_cls');
            }, 10);
            this.getBrandInformations();
        }
    }
    
    // <!-- Added by Sabari - MFRUS-113 -->
    addbinding(){
        let finddescelements = this.template.querySelectorAll('.indisafe');
        const delay = 300;
        finddescelements.forEach((element)=>{
        const datavalue = element.getAttribute("data-value");
        const name = element.getAttribute("name");
        console.log('inside rendered '+datavalue);
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

        // For Loading CSS file from the Static Resource
        //   this.template.querySelector('.scroll_b_3')?.classList.add('block_cls');
        // this.template.querySelector('.acc2')?.classList.add('block_cls');
        Promise.all([
            loadStyle(this, productdetailcss)
        ]).then(() => {
        })
        .catch(error => {
        });
    }

    // Get Product Indication
    getBrandInformations() {
        getBrandInformations({ prodId: this.recordId, objectName: 'Catalog'})
            .then(result => {
                console.log('getBrandInformations : ',{result});
                var width = screen.width;
                if (result.hasOwnProperty('Indication')){
                    console.log('Indication : ',result['Indication']);
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
                    // <!-- Added by Sabari - MFRUS-113 -->
                    if(this.readMoreIndication){
                      let appendText = '<span id="readmore1"  style="color: #00857C !important;font-family: \'Invention\' !important;font-style: normal !important;font-weight: 600 !important;font-size: 14px !important;cursor: pointer;text-decoration: underline;text-decoration-color: #00857C !important;">Read more</span>';
                      const closingTags = this.infovalshort.match(/<\/s*(\w+)[^>]*>/gi);
                      if(closingTags && closingTags.length>0){
                          const lastClosingTag = closingTags[closingTags.length-1];
                          const tagName = lastClosingTag.substring(2,lastClosingTag.indexOf('>'));
                          this.indTagName = tagName;
                      }
                      console.log('Last tag:'+this.indTagName);
                      let newInfovalshort = this.infovalshort.replace(/<ul/g,'<ul class="slds-list_dotted slds-m-bottom_medium"').replace(/<ol/g, '<ol class="slds-list_ordered slds-m-bottom_medium"');
                      newInfovalshort = newInfovalshort.replace(/<h2/g,'<h2 class="slds-m-bottom_medium"');
                      this.infovalshort = newInfovalshort;
                      if(this.indTagName=='ul' || this.indTagName == 'ol'){
                          let lastLiIndex = this.infovalshort.lastIndexOf('</li>');
                          console.log('lastLiIndex:'+lastLiIndex);
                          if(lastLiIndex !==-1){
                            let modifiedText = this.infovalshort.slice(0,lastLiIndex)+' '+appendText+this.infovalshort.slice(lastLiIndex);
                            console.log('modifiedText:'+modifiedText);
                            this.infovalshort = modifiedText;
                            }else{
                                this.infovalshort = this.infovalshort + appendText;
                            }
                      }else if(this.indTagName == 'p')
                      {
                        let lastPIndex = this.infovalshort.lastIndexOf('</p>');
                        console.log('lastPIndex:'+lastPIndex);
                        if(lastPIndex !==-1){
                            let modifiedText = this.infovalshort.slice(0,lastPIndex)+' '+appendText+this.infovalshort.slice(lastPIndex);
                            console.log('modifiedText:'+modifiedText);
                            this.infovalshort = modifiedText;
                        }
                      }else if(this.indTagName == 'div')
                      {
                        let removedivtext = this.infovalshort.replace(/<\/div>/g,'');
                        let lastbeforetag;
                        const closingTags = removedivtext.match(/<\/s*(\w+)[^>]*>/gi);
                        if(closingTags && closingTags.length>0){
                            const lastClosingTag = closingTags[closingTags.length-1];
                            const tagName = lastClosingTag.substring(2,lastClosingTag.indexOf('>'));
                            lastbeforetag = tagName;
                        }
                        console.log('lastbeforetag - '+lastbeforetag);

                        if(lastbeforetag == 'p'){
                            let lastPIndex = this.infovalshort.lastIndexOf('</p>');
                            console.log('lastPIndex:'+lastPIndex);
                            if(lastPIndex !==-1){
                                let modifiedText = this.infovalshort.slice(0,lastPIndex)+' '+appendText+this.infovalshort.slice(lastPIndex);
                                console.log('modifiedText:'+modifiedText);
                                this.infovalshort = modifiedText;
                            }
                        }else if(lastbeforetag == 'ul' || lastbeforetag == 'ol'){
                            let lastLiIndex = this.infovalshort.lastIndexOf('</li>');
                            console.log('lastLiIndex:'+lastLiIndex);
                            if(lastLiIndex !==-1){
                                let modifiedText = this.infovalshort.slice(0,lastLiIndex)+' '+appendText+this.infovalshort.slice(lastLiIndex);
                                console.log('modifiedText:'+modifiedText);
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
                    console.log('Selected Safety Information : ',result['Selected Safety Information']);
                    this.safetyinfo = result['Selected Safety Information'].Section_Details__c;
                    this.ssiHeader = result['Selected Safety Information'].Section_Label__c;
                    this.ssiExpHeader = result['Selected Safety Information'].Label_Accordion_Expanded__c;
                    if (width < 768) {
                        var saft = result['Selected Safety Information'].Accordion_Preview_Mobile__c;
                        this.saftyshort = saft;
                        var ses = sessionStorage.getItem('SelectedValue');
                        if (ses == 'true'){
                            this.showShortInfo = false;
                        }
                        this.readMoreSSI = result['Selected Safety Information'].Show_Read_More_Mobile__c;
                    }else {
                        this.saftyshort = result['Selected Safety Information'].Accordion_Preview_Desktop__c;
                        this.readMoreSSI = result['Selected Safety Information'].Show_Read_More__c;
                    }
                    this.prodname = result['Selected Safety Information'].Product_Payor__r.MSD_CORE_Product_Family__c;
                    // <!-- Added by Sabari - MFRUS-113 -->
                     if(this.readMoreSSI){
                      let appendText = '<span id="readmore2"  style="color: #00857C !important;font-family: \'Invention\' !important;font-style: normal !important;font-weight: 600 !important;font-size: 14px !important;cursor: pointer;text-decoration: underline;text-decoration-color: #00857C !important;">Read more</span>';
                      const closingTags = this.saftyshort.match(/<\/s*(\w+)[^>]*>/gi);
                      if(closingTags && closingTags.length>0){
                          const lastClosingTag = closingTags[closingTags.length-1];
                          const tagName = lastClosingTag.substring(2,lastClosingTag.indexOf('>'));
                          this.safTagName = tagName;
                      }
                      console.log('Last saf tag:'+this.safTagName);
                      let newsaftyshort = this.saftyshort.replace(/<ul/g,'<ul class="slds-list_dotted slds-m-bottom_medium"').replace(/<ol/g, '<ol class="slds-list_ordered slds-m-bottom_medium"');
                      newsaftyshort = newsaftyshort.replace(/<h2/g,'<h2 class="slds-m-bottom_medium"');
                      this.saftyshort = newsaftyshort;
                      if(this.safTagName=='ul' || this.safTagName == 'ol'){
                          let lastLiIndex = this.saftyshort.lastIndexOf('</li>');
                          console.log('lastLiIndex:'+lastLiIndex);
                          if(lastLiIndex !==-1){
                            let modifiedText = this.saftyshort.slice(0,lastLiIndex)+' '+appendText+this.saftyshort.slice(lastLiIndex);
                            console.log('modifiedText:'+modifiedText);
                            this.saftyshort = modifiedText;
                            }else{
                                this.saftyshort = this.saftyshort + appendText;
                            }
                      }else if(this.safTagName == 'p'){
                        let lastPIndex = this.saftyshort.lastIndexOf('</p>');
                        console.log('lastPIndex:'+lastPIndex);
                        if(lastPIndex !==-1){
                            let modifiedText = this.saftyshort.slice(0,lastPIndex)+' '+appendText+this.saftyshort.slice(lastPIndex);
                            console.log('modifiedText:'+modifiedText);
                            this.saftyshort = modifiedText;
                        }
                      }else if(this.safTagName == 'div')
                      {
                        let removedivtext = this.saftyshort.replace(/<\/div>/g,'');
                        let lastbeforetag;
                        const closingTags = removedivtext.match(/<\/s*(\w+)[^>]*>/gi);
                        if(closingTags && closingTags.length>0){
                            const lastClosingTag = closingTags[closingTags.length-1];
                            const tagName = lastClosingTag.substring(2,lastClosingTag.indexOf('>'));
                            lastbeforetag = tagName;
                        }
                        console.log('lastbeforetag - '+lastbeforetag);
                        if(lastbeforetag == 'p'){
                            let lastPIndex = this.saftyshort.lastIndexOf('</p>');
                            console.log('lastPIndex:'+lastPIndex);
                            if(lastPIndex !==-1){
                                let modifiedText = this.saftyshort.slice(0,lastPIndex)+' '+appendText+this.saftyshort.slice(lastPIndex);
                                console.log('modifiedText:'+modifiedText);
                                this.saftyshort = modifiedText;
                            }
                        }else if(lastbeforetag == 'ul' || lastbeforetag == 'ol'){
                            let lastLiIndex = this.saftyshort.lastIndexOf('</li>');
                            console.log('lastLiIndex:'+lastLiIndex);
                            if(lastLiIndex !==-1){
                                let modifiedText = this.saftyshort.slice(0,lastLiIndex)+' '+appendText+this.saftyshort.slice(lastLiIndex);
                                console.log('modifiedText:'+modifiedText);
                                this.saftyshort = modifiedText;
                            }
                        }
                      }else{
                         this.saftyshort = this.saftyshort + appendText;
                      }
                    }
                }

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

                this.acr2name = this.ssiHeader;
                this.acrname = this.indiHeader;
            })
            .catch(error => {
                console.log('Error' + JSON.stringify(error));
            })
    }

    handleSectionToggle(event) {

    }

    clc(event) {
        console.log('clc');
        console.log(event.target.name);
        this.aactsec = event.target.name;

        var width = screen.width;

        var activesectionname = event.target.name;
        var test_lst = [];

        if (activesectionname == 'Indication') {
            this.accordian1 = true;
            sessionStorage.setItem("SelectedValue", true);

            if (this.acr1 == false) {   // close to open
                this.fireDataClickEvent("accordion",'','expand',"indication",this.prodname);
                //document.body.style.overflowY = 'hidden';/*AMS - E2ESE-1531*/

                this.template.querySelector('.sample-bg')?.classList.add('sample-active');
                this.template.querySelector('.accordian_cls')?.classList.add('zindex');

                if (width < 768) { // for mobile
                    this.acr1 = true;
                    this.acr2 = false;
                    this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                    this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                }
                else {    // for desktop
                    this.acr1 = true;
                    this.acr2 = false;
                    this.acrname = this.indiExpHeader;
                    this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                    this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                }
                test_lst.push('Indication');
            }
            else {  // open to close
                this.fireDataClickEvent("accordion",'',"collapse","indication",this.prodname);
                document.body.style.overflowY = 'scroll';

                this.template.querySelector('.sample-bg')?.classList.remove('sample-active');
                this.template.querySelector('.accordian_cls')?.classList.remove('zindex');

                if (width < 768) {
                    this.acr1 = false;
                    this.acrname = this.indiHeader;
                    this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                    this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                } else {
                    this.acr1 = false;
                    this.acrname = this.indiHeader;
                    this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                    this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                }
                test_lst.push('  ');
            }
            if (this.acr1) {
                this.template.querySelector('.am2')?.classList.remove('acc_margintopsample');
            }
            else {
                this.template.querySelector('.am2')?.classList.add('acc_margintopsample');
            }
            console.log('111', this.acr1);
        }
        else if (activesectionname == 'Selected Safety Information') {

            if (this.acr2 == false) {
                this.fireDataClickEvent("accordion",'',"expand","isi",this.prodname);
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
                }
                else {
                    this.acr2 = true;
                    this.acr1 = false;
                    this.acr2name = this.ssiExpHeader;
                    this.template.querySelector('.scroll_b_2')?.classList.add('block_cls');
                    this.template.querySelector('.acc')?.classList.add('block_cls');
                    this.template.querySelector('.acc2')?.classList.add('db');
                    if (this.accordian1 && this.acr1) {
                        this.template.querySelector('.scroll_b_1')?.classList.add('db');
                    } else {
                        this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                    }
                }
                test_lst.push('Selected Safety Information');
            }
            else {
                this.fireDataClickEvent("accordion",'',"collapse","isi",this.prodname);
                document.body.style.overflowY = 'scroll';

                this.template.querySelector('.sample-bg')?.classList.remove('sample-active');
                this.template.querySelector('.accordian_cls')?.classList.remove('zindex');

                if (width < 768) {
                    this.acr2 = false;
                    this.acr2name = this.ssiHeader;
                    this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                    this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                    this.template.querySelector('.acc')?.classList.remove('block_cls');
                    this.template.querySelector('.acc2')?.classList.remove('db');
                    this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                }
                else {
                    this.acr2 = false;
                    this.acr2name = this.ssiHeader;
                    this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                    this.template.querySelector('.scroll_b_1')?.classList.add('db');
                    this.template.querySelector('.acc')?.classList.remove('block_cls');
                    this.template.querySelector('.acc2')?.classList.remove('db');
                    this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                }
                if (this.accordian1 && !this.acr1) {
                    this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                }
                else {
                    this.template.querySelector('.scroll_b_1')?.classList.add('db');
                }
            }
            console.log('222', this.acr2);
        }
        else if (activesectionname == 'Indication2') {

            //document.body.style.overflowY = 'hidden';/*AMS - E2ESE-1531*/
            this.accordian1 = true;
            sessionStorage.setItem("SelectedValue", true);
            this.template.querySelector('.sample-bg')?.classList.add('sample-active');
            this.template.querySelector('.accordian_cls')?.classList.add('zindex');

            if (width < 768) {
                this.acr1 = true;
                this.acr2 = false;
                this.acrname = this.indiExpHeader;
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                this.template.querySelector('.acc2')?.classList.remove('db');
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                this.template.querySelector('.acc')?.classList.remove('block_cls');
            }
            else {
                this.acr1 = true;
                this.acr2 = false;
                this.acrname = this.indiExpHeader;
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                this.template.querySelector('.acc2')?.classList.remove('db');
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                this.template.querySelector('.acc')?.classList.remove('block_cls');
            }
            test_lst.push('Indication');
        }
        if (activesectionname != undefined) {

            this.activesection = test_lst;
            console.log(this.activesection);
            this.accodianname();
        }
        // <!-- Added by Sabari - MFRUS-113 -->
        this.setbindSaf=false;
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

            this.template.querySelector('.sample-bg')?.classList.add('sample-active');
            this.template.querySelector('.accordian_cls')?.classList.add('zindex');

            if (width < 768) { // for mobile
                this.acr1 = true;
                this.acr2 = false;
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                this.template.querySelector('.acc2')?.classList.remove('db');
            }
            else {    // for desktop
                this.acr1 = true;
                this.acr2 = false;
                this.acrname = this.indiExpHeader;
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                this.template.querySelector('.acc2')?.classList.remove('db');

                console.log(this.infoval.length);
                console.log(this.safetyinfo.length);
            }
            test_lst.push('Indication');
        }
        else {
            document.body.style.overflowY = 'scroll';
            this.template.querySelector('.sample-bg')?.classList.remove('sample-active');
            this.template.querySelector('.accordian_cls')?.classList.remove('zindex');

            if (width < 768) {
                this.acr1 = false;
                this.acrname = this.indiHeader;
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                this.template.querySelector('.scroll_b_2')?.classList.add('block_cls');
                this.template.querySelector('.acc2')?.classList.remove('db');
            }
            else {
                this.acr1 = false;
                this.acrname = this.indiHeader;
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
                this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                this.template.querySelector('.acc2')?.classList.remove('db');
            }
            test_lst.push('  ');
        }

        this.activesection = test_lst;
        // <!-- Added by Sabari - MFRUS-113 -->
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
            }
            else {
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

            document.body.style.overflowY = 'scroll';

            this.template.querySelector('.sample-bg')?.classList.remove('sample-active');
            this.template.querySelector('.accordian_cls')?.classList.remove('zindex');

            if (width < 768) {
                this.acr2 = false;
                this.acr2name = this.ssiHeader;
                this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.acc')?.classList.remove('block_cls');
                this.template.querySelector('.acc2')?.classList.remove('db');
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
            }
            else {
                this.acr2 = false;
                this.acr2name = this.ssiHeader;
                this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
                this.template.querySelector('.scroll_b_1')?.classList.remove('db');
                this.template.querySelector('.acc')?.classList.remove('block_cls');
                this.template.querySelector('.acc2')?.classList.remove('db');
                this.template.querySelector('.scroll_b_3')?.classList.remove('db');
            }
        }
        this.activesection = test_lst;
        // <!-- Added by Sabari - MFRUS-113 -->
        this.setbindSaf=false;
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

        this.template.querySelector('.sample-bg')?.classList.add('sample-active');
        this.template.querySelector('.accordian_cls')?.classList.add('zindex');

        if (width < 768) {
            this.acr1 = true;
            this.acr2 = false;
            this.acrname = this.indiExpHeader;
            this.template.querySelector('.scroll_b_3')?.classList.remove('db');
            this.template.querySelector('.acc2')?.classList.remove('db');
            this.template.querySelector('.scroll_b_1')?.classList.add('block_cls');
            this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
            this.template.querySelector('.acc')?.classList.remove('block_cls');
        }
        else {
            this.acr1 = true;
            this.acr2 = false;
            this.acrname = this.indiExpHeader;
            this.template.querySelector('.scroll_b_3')?.classList.remove('db');
            this.template.querySelector('.acc2')?.classList.remove('db');
            this.template.querySelector('.scroll_b_1')?.classList.add('block_cls');
            this.template.querySelector('.scroll_b_2')?.classList.remove('block_cls');
            this.template.querySelector('.acc')?.classList.remove('block_cls');
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
        console.log('event triggered');
        const { host, hostname, href, origin, pathname, port, protocol, search } = window.location;
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {
          
           detail: {               
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'registration',
                page_purpose:'registration',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text:'schedule__c',
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
                page_title: 'settings',

           },
           bubbles: true,
           composed: true
       }));
   }
}