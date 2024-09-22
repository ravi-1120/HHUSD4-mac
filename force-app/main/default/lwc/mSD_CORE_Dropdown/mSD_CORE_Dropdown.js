import { LightningElement, track, wire, api } from 'lwc';
import MSD_CORE_Close from '@salesforce/resourceUrl/MSD_CORE_Close';
import getFilterdata from '@salesforce/apex/MSD_CORE_ProductList.getmfeeFilter';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from "@salesforce/user/Id";
export default class MSD_CORE_Dropdown extends LightningElement {


    @track label;
    inputValue = '';
    dropDownInFocus = false;
    @track selectedvalue = [];
    @track handleselectvalue;
    closeicon = MSD_CORE_Close;
    @track allrecord = [];
    @api type;
    @api disease;
    @track oncology = false;
    @track nononcology = false;
    firstRun = true;
    @track contactrole = '';
    @api compoundvalue;

    // get inputOptions() {
    //     return [
    //         { label: 'Cardiovascular MK-2060', value: 'Cardiovascular MK-2060' },
    //         { label: 'NASH MK-6024', value: 'NASH MK-6024' },
    //         { label: 'NASH MK-3655', value: 'NASH MK-3655' },
    //         { label: 'HIV-1 Infection Adult Islatravir Lenacapavir MK-8591D1', value: 'HIV-1 Infection Adult Islatravir Lenacapavir MK-8591D1' },
    //         { label: 'HIV-1 Infection Islatravir MK-9591B2', value: 'HIV-1 Infection Islatravir MK-9591B2' },
    //         { label: 'Schizophrenia MK-8189', value: 'Schizophrenia MK-8189' },
    //         { label: 'Treatment resistant deression ML-1942', value: 'Treatment resistant deression ML-1942' },
    //         { label: 'Pulmonary arterial hypertension MK-5475', value: 'Pulmonary arterial hypertension MK-5475' },
    //     ];
    // }

    @track inputOptions =  [
           /* { label: 'Cutaneous Tumors', value: 'Cutaneous Tumors', checked:  false, partialchecked:false, subdata: 
                [
                    { label: 'Melanoma', value: 'Melanoma', checked: false },
                    { label: 'Merkel Cell Carcinoma', value: 'Merkel Cell Carcinoma' , checked: false }
                ]
            },
            { label: 'Lung Cancers', value: 'Lung Cancers' , checked:  false, partialchecked:false, subdata:
                [
                    { label: 'NSCLC', value: 'NSCLC',  checked: false},
                    { label: 'SCLC', value: 'SCLC',  checked: false }
                ]
            },
            { label: 'Gastrointestinal Cancers', value: 'Gastrointestinal Cancers' , checked:  false, partialchecked:false, subdata:
                [
                    { label: 'Gastric', value: 'Gastric',  checked: false},
                    { label: 'Hepatocellular', value: 'Hepatocellular',  checked: false },
                    { label: 'Billiary', value: 'Billiary',  checked: false },
                    { label: 'Esophageal', value: 'Esophageal',   checked: false}
                ]
            },
            { label: 'Genitourinary Cancers', value: 'Genitourinary Cancers' , checked:  false, partialchecked:false, subdata:
                [
                    { label: 'Urothelial', value: 'Urothelial',  checked: false},
                    { label: 'Renal', value: 'Renal',  checked: false},
                    { label: 'Prostate', value: 'Prostate',  checked: false},
                ]
            },
            { label: 'Women\'s Cancers', value: 'Women\'s Cancers' , checked:  false, partialchecked:false, subdata:
                [
                    { label: 'Breast', value: 'Breast', checked: false },
                    { label: 'Cervical', value: 'Cervical',  checked: false },
                    { label: 'Ovarian', value: 'Ovarian',  checked: false },
                    { label: 'Endometrial', value: 'Endometrial',  checked: false },
                ]
            },
            { label: 'Hematological Malignancies', value: 'Hematological Malignancies' , checked:  false, partialchecked:false},
            { label: 'Head and Neck Cancers', value: 'Head and Neck Cancers' , checked:  false, partialchecked:false} */
        ];
    

    @track inputOptions2 =  [
          /*  { label: 'Phase 1', value: 'Phase 1' , checked:  false, partialchecked:false, subdata: 
                [
                    { label: 'Cardiovascular disease MK-2060', value: 'Cardiovascular disease MK-2060' , checked: false},
                    { label: 'NASH MK-6024', value: 'NASH MK-6024' , checked: false },
                    { label: 'NASH MK-3655', value: 'NASH MK-3655' , checked: false },
                    { label: 'HIV-1 Infection Adult Islatravir Lenacapavir Mk-8591D1', value: 'HIV-1 Infection Adult Islatravir Lenacapavir Mk-8591D1', checked: false },
                    { label: 'HIV-1 Infection Adult Islatravir Mk-8591D1', value: 'HIV-1 Infection Adult Islatravir Mk-8591D1' , checked: false }
                ]
            },
            { label: 'Phase 2', value: 'Phase 2' , checked:  false, partialchecked:false, subdata:
                [
                    { label: 'HIV-1 Infection Doravirine/Islatravir MK-8591A2', value: 'HIV-1 Infection Doravirine/Islatravir MK-8591A2' , checked: false},
                    { label: 'Anti-Viral COVID 19 molnupiravir MK-44821', value: 'Anti-Viral COVID 19 molnupiravir MK-44821', checked: false }
                ]
            },
            { label: 'Under review', value: 'Under review' , checked:  false, partialchecked:false, subdata:
                [
                    { label: 'Cough gefapixant MK-7264', value: 'Cough gefapixant MK-7264' , checked: false },
                    { label: 'Pneumococcal Infection for pediatric use V114', value: 'Pneumococcal Infection for pediatric use V114', checked: false },
                ]
            } */
        ];
    
@wire(getFilterdata,{type:'$type'})
wirefilter(result)
{
    if(result.error)
    {
           console.log('INside Wire Error');
        this.error=result.error;
    }
    else if(result.data)
    {
        console.log('INside Wire Filter');
        console.log({result});
        console.log('disease-->',this.disease);
        // this.disease = 'Melanoma';
        console.log(JSON.stringify(result.data));
        let phases = [];
        if(this.type == 'nononcology' ){
            phases = [];
            for(let i=0; i< result.data.length; i++ ){
                if(!(phases.includes(result.data[i].MSD_CORE_Phase__c)) ){
                    phases.push(result.data[i].MSD_CORE_Phase__c)
                }
            }
            for(let i=0; i< phases.length; i++ ){
                let studydetails = result.data.filter(e => e.MSD_CORE_Phase__c == phases[i]);
                let studydetailoption ={};
                 studydetailoption.label = phases[i];
                 studydetailoption.value = phases[i];

                 studydetailoption.checked = false;
                 studydetailoption.partialchecked = false;
                 let subrecords = [];
                for(let j=0; j < studydetails.length; j++){
                        let subrecord = {};
                        subrecord.label = studydetails[j].Name;
                        subrecord.value = studydetails[j].Name;
                        if(  studydetails[j].Name ==  this.disease ){
                            subrecord.checked = true;
                           
                            studydetailoption.checked = true;
                            studydetailoption.partialchecked = true;
                            if(!(this.selectedvalue.includes(this.disease))){
                                this.selectedvalue.push(this.disease);
                                console.log('this.selectedvalue-->',this.selectedvalue);
                            }
                        }else{
                           
                            subrecord.checked = false;
                        }
                        
                        subrecords.push(subrecord);

                }
                studydetailoption.subdata = subrecords;
                this.inputOptions2.push(studydetailoption);
            }
        }
        if(this.type == 'oncology' ){
            phases = [];
            console.log(':::Oncology:::');
            console.log({result});
             for(let i=0; i< result.data.length; i++ ){
                 if( result.data[i].MSD_CORE_Parent_Tumor__r){
                      if(!(phases.includes(result.data[i].MSD_CORE_Parent_Tumor__r.Name)) ){
                            phases.push(result.data[i].MSD_CORE_Parent_Tumor__r.Name)
                        }
                 }else{
                      if(!(phases.includes(result.data[i].Name)) ){
                            phases.push(result.data[i].Name)
                        }
                 }
               
            }
            for(let i=0; i< phases.length; i++ ){
                let tumordetails = result.data.filter(e => { return e.MSD_CORE_Parent_Tumor__r && e.MSD_CORE_Parent_Tumor__r.Name == phases[i] } );
                  console.log({tumordetails});
                  console.log('this.disease--->',this.disease);
                //   this.disease = this.disease.split(' ')[0];
                //   console.log('==>this.disease--->',this.disease);
                let tumordetailoption ={};
                 tumordetailoption.label = phases[i];
                 tumordetailoption.value = phases[i];
                 tumordetailoption.checked = false;
                 tumordetailoption.partialchecked = false;
                 let subrecords = [];
                for(let j=0; j < tumordetails.length; j++){
                        let subrecord = {};
                        subrecord.label = tumordetails[j].Name;
                        subrecord.value = tumordetails[j].Name;
                        if(  tumordetails[j].Name ==  this.disease ){
                            subrecord.checked = true;
                            tumordetailoption.checked = true;
                            tumordetailoption.partialchecked = true;
                            console.log('this.selectedvalue-----=>',this.selectedvalue);
                             if(!(this.selectedvalue.includes(this.disease))){
                                this.selectedvalue.push(this.disease);
                            }
                        }else{
                            
                            subrecord.checked = false;
                        }
                    subrecords.push(subrecord);
                }
                tumordetailoption.subdata = subrecords;
                this.inputOptions.push(tumordetailoption);
                console.log('this.selectedvalue--->',this.selectedvalue);
                console.log('this.inputOptions--->',this.inputOptions);
            }
            console.log('Input Options'+JSON.stringify(this.inputOptions));
        }
    }
}


    connectedCallback() {

        if (this.type == 'oncology') {
            this.oncology = true;
            this.label = 'Select cancer types you would like to discuss';
        }else{
            this.nononcology = true;   
            this.label = 'Select topics you would like to discuss';
        }
        this.contactrole = sessionStorage.getItem("SFMC_Audience");

        console.log('disease'+ this.disease);
console.log('type'+ this.type);
        
    }

    renderedCallback(){
        this.handleEvent();
    }


   /* renderedCallback(){
        if(this.firstRun && this.selectedvalue.length == 0){
       // let checkboxselect = this.template.querySelector('[data-id="' + this.disease + '"]');
       // if(checkboxselect ){
           //  console.log({ checkboxselect });
           // checkboxselect.firstChild.classList.toggle("slds-is-selected");

          //  if (checkboxselect.firstChild.classList.contains('slds-is-selected')) {
               
                if(this.type == 'oncology'){
                    for(let i=0; i <  this.inputOptions.length ; i++ ){
                            for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                    if( this.inputOptions[i].subdata[j].value == this.disease ){
                                        this.inputOptions[i].partialchecked = true;
                                        this.inputOptions[i].checked=true;
                                        this.inputOptions[i].subdata[j].checked=true;   
                                    }
                            }
                    }
                }
                if(this.type == 'nononcology'){
                    for(let i=0; i <  this.inputOptions2.length ; i++ ){
                            for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                    if( this.inputOptions2[i].subdata[j].value == this.disease ){
                                        this.inputOptions2[i].partialchecked = true;
                                        this.inputOptions2[i].checked=true;
                                        this.inputOptions2[i].subdata[j].checked=true;   
                                    }
                            }
                    }
                }
           /* } else {
                this.selectedvalue = this.selectedvalue.filter(value => value !== this.disease);
            } */
            //this.firstRun = false;
            // this.selectedvalue.push(this.disease);
      //  }
        //}
       
    //}

    handleClick() {
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        console.log('open'+sldsCombobox.classList );
        /*if (!this.dropDownInFocus && (sldsCombobox?(sldsCombobox.classList.contains('slds-is-open')): false) ) {
            this.closeDropbox();
            console.log("handle blur");
        } */
        sldsCombobox.classList.toggle("slds-is-open");
        
    }
    handleMouseleave() {
        this.dropDownInFocus = false;
        console.log('this.dropDownInFocus leave before>>>',this.dropDownInFocus);
        console.log("Mouse leave");
        this.closeDropbox();        
        console.log('this.dropDownInFocus leave after>>>',this.dropDownInFocus);
    }
    handleMouseEnter() {
        this.dropDownInFocus = true;
        console.log('this.dropDownInFocus enter after>>>',this.dropDownInFocus);
        console.log("Mouse enter");
    }
    handleBlur() {
        console.log("handle blur");
        console.log('this.dropDownInFocu handle blur>>>',this.dropDownInFocus);
        if (!this.dropDownInFocus) {
            this.closeDropbox();
        }        
    }
    closeDropbox() {
        console.log('close dropbox');
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        sldsCombobox.classList.remove("slds-is-open");
        console.log("close dropbox");
    }

    handleClickMob(){
        console.log('handleClickMob');
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        sldsCombobox.classList.remove("slds-is-open");
        console.log("close dropbox mob");
        if(screen.width<768){
            this.dropDownInFocus = false;
        }
    }

    handleonClickMob(){
        console.log('handleonClickMob');
        if(screen.width<768){
            this.dropDownInFocus = true;
            console.log('this.dropDownInFocus 768>>',this.dropDownInFocus);
        }
    }

    handleSelection(event) {
        console.log('Handler Selection Dropdown');
        let selectvalue = event.currentTarget.dataset.value;
        console.log({selectvalue});
        this.fireDataLayerEvent('filter', 'step_1', selectvalue,  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        let headvalues = [];
        let checkboxselect = this.template.querySelector('[data-id="' +selectvalue + '"]');
        
            checkboxselect.firstChild.classList.toggle("slds-is-selected");

            if (checkboxselect.firstChild.classList.contains('slds-is-selected')) {
               // this.selectedvalue.push(selectvalue);
                
                if(this.type == 'nononcology'){
                      for(let i=0; i <  this.inputOptions2.length ; i++ ){
                          headvalues.push(this.inputOptions2[i].label );
                      }
                    for(let i=0; i <  this.inputOptions2.length ; i++ ){
                            if(this.inputOptions2[i].label == selectvalue ){
                                this.inputOptions2[i].checked = true;
                                this.inputOptions2[i].partialchecked = false;
                                for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                    if(!(this.selectedvalue.includes(this.inputOptions2[i].subdata[j].value))){
                                        
                                         let checkboxselectSub = this.template.querySelector('[data-id="' +this.inputOptions2[i].subdata[j].value + '"]');
                                         if (! (checkboxselectSub.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectSub.firstChild.classList.toggle("slds-is-selected");
                                                this.selectedvalue.push(this.inputOptions2[i].subdata[j].value);
                                                this.inputOptions2[i].subdata[j].checked = true;
                                                this.inputOptions2[i].partialchecked = false;
                                         }
                                    }
                                }
                                       
                            }
                    }
                
                    if(!(headvalues.includes(selectvalue))){

                                    this.selectedvalue.push(selectvalue);
                                    for(let i=0; i <  this.inputOptions2.length ; i++ ){
                                         for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                             if( this.inputOptions2[i].subdata[j].label == selectvalue ){
                                               
                                                this.inputOptions2[i].subdata[j].checked = true;
                                                this.inputOptions2[i].partialchecked = true;
                                                let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions2[i].label + '"]');
                                                 if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                                
                                             }
                                         }
                                     }

                                     for(let i=0; i <  this.inputOptions2.length ; i++ ){
                                         let checkedSubValues = [];
                                         for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                             if(this.inputOptions2[i].subdata[j].checked){
                                                 checkedSubValues.push(this.inputOptions2[i].subdata[j].label);
                                             }
                                         
                                         }
                                         for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                          
                                             if( this.inputOptions2[i].subdata.length == checkedSubValues.length  ){
                                               
                                                this.inputOptions2[i].checked = true;
                                                this.inputOptions2[i].partialchecked = false;
                                                 let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions2[i].label + '"]');
                                                 if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                             }
                                             else if( checkedSubValues.length == 0){
                                                 this.inputOptions2[i].checked = false;
                                                 this.inputOptions2[i].partialchecked = false;
                                                  let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions2[i].label + '"]');
                                                 if ((checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                             }
                                             else{
                                                 this.inputOptions2[i].checked = false;
                                                 this.inputOptions2[i].partialchecked = true;
                                                  let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions2[i].label + '"]');
                                                    if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                        checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                    }
                                             }
                                         }
                                     }

                                    
                    }   
                }
                else if(this.type == 'oncology'){
                      for(let i=0; i <  this.inputOptions.length ; i++ ){
                          headvalues.push(this.inputOptions[i].label );
                      }
                    for(let i=0; i <  this.inputOptions.length ; i++ ){
                            if(this.inputOptions[i].label == selectvalue ){
                                this.inputOptions[i].checked = true;
                                this.inputOptions[i].partialchecked = false;
                                for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                    if(!(this.selectedvalue.includes(this.inputOptions[i].subdata[j].value))){
                                        
                                         let checkboxselectSub = this.template.querySelector('[data-id="' +this.inputOptions[i].subdata[j].value + '"]');
                                         if (! (checkboxselectSub.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectSub.firstChild.classList.toggle("slds-is-selected");
                                                this.selectedvalue.push(this.inputOptions[i].subdata[j].value);
                                                this.inputOptions[i].subdata[j].checked = true;
                                                this.inputOptions[i].partialchecked = false;
                                         }
                                    }
                                }
                                       
                            }
                    }
                
                    if(!(headvalues.includes(selectvalue))){

                                    this.selectedvalue.push(selectvalue);
                                    for(let i=0; i <  this.inputOptions.length ; i++ ){
                                         for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                             if( this.inputOptions[i].subdata[j].label == selectvalue ){
                                               
                                                this.inputOptions[i].subdata[j].checked = true;
                                                this.inputOptions[i].partialchecked = true;
                                                let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions[i].label + '"]');
                                                 if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                                
                                             }
                                         }
                                     }

                                     for(let i=0; i <  this.inputOptions.length ; i++ ){
                                         let checkedSubValues = [];
                                         for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                             if(this.inputOptions[i].subdata[j].checked){
                                                 checkedSubValues.push(this.inputOptions[i].subdata[j].label);
                                             }
                                         
                                         }
                                         for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                          
                                             if( this.inputOptions[i].subdata.length == checkedSubValues.length  ){
                                               
                                                this.inputOptions[i].checked = true;
                                                this.inputOptions[i].partialchecked = false;
                                                 let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions[i].label + '"]');
                                                 if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                             }
                                             else if( checkedSubValues.length == 0){
                                                 this.inputOptions[i].checked = false;
                                                 this.inputOptions[i].partialchecked = false;
                                                  let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions[i].label + '"]');
                                                 if ((checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                             }
                                             else{
                                                 this.inputOptions[i].checked = false;
                                                 this.inputOptions[i].partialchecked = true;
                                                  let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions[i].label + '"]');
                                                    if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                        checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                    }
                                             }
                                         }
                                     }

                                    
                    }   
                }
                else{

                }  
            } 
            else {
                this.selectedvalue = this.selectedvalue.filter(value => value !== selectvalue);
                if((this.type == 'nononcology')){
                    for(let i=0; i <  this.inputOptions2.length ; i++ ){
                            //parent
                            if(this.inputOptions2[i].label == selectvalue ){
                                for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                    this.selectedvalue = this.selectedvalue.filter(value => value !== this.inputOptions2[i].subdata[j].value);
                                    let checkboxselectSub = this.template.querySelector('[data-id="' +this.inputOptions2[i].subdata[j].value + '"]');
                                         if ( (checkboxselectSub.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectSub.firstChild.classList.toggle("slds-is-selected");
                                                this.inputOptions2[i].subdata[j].checked = false;
                                                this.inputOptions2[i].partialchecked=false;
                                                this.inputOptions2[i].checked=false;
                                         }
                                }   
                            }//subdata
                            else{
                               
                                 for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                     if(this.inputOptions2[i].subdata[j].value == selectvalue){
                                         this.inputOptions2[i].subdata[j].checked = false;
                                         this.inputOptions2[i].partialchecked=true;
                                        
                                     }
                                     
                                   
                                }
                                let checkedSubValues = [];
                                let headvalue;
                                for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                    if(this.inputOptions2[i].subdata[j].checked ){
                                        checkedSubValues.push(this.inputOptions2[i].subdata[j].label);
                                    }
                                    if(this.inputOptions2[i].subdata[j].value == selectvalue){
                                    headvalue = this.inputOptions2[i].label;
                                    }
                                }
                                if(checkedSubValues.length == 0){
                                    if(headvalue == this.inputOptions2[i].label ){
                                    let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions2[i].label + '"]');
                                     if ( (checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                this.inputOptions2[i].checked = false;
                                                this.inputOptions2[i].partialchecked=false;
                                         }
                                    }
                                }


                            }
                    }    
                     
                }
                 if((this.type == 'oncology')){
                    for(let i=0; i <  this.inputOptions.length ; i++ ){
                            //parent
                            if(this.inputOptions[i].label == selectvalue  ){
                                for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                    this.selectedvalue = this.selectedvalue.filter(value => value !== this.inputOptions[i].subdata[j].value);
                                    let checkboxselectSub = this.template.querySelector('[data-id="' +this.inputOptions[i].subdata[j].value + '"]');
                                         if ( (checkboxselectSub.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectSub.firstChild.classList.toggle("slds-is-selected");
                                                this.inputOptions[i].subdata[j].checked = false;
                                                this.inputOptions[i].partialchecked=false;
                                                this.inputOptions[i].checked=false;
                                         }
                                }   
                            }//subdata
                            else{
                               
                                 for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                     if(this.inputOptions[i].subdata[j].value == selectvalue){
                                         this.inputOptions[i].subdata[j].checked = false;
                                         this.inputOptions[i].partialchecked=true;
                                         
                                     }
                                     
                                   
                                }
                                let checkedSubValues = [];
                                let headvalue;
                                for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                    if(this.inputOptions[i].subdata[j].checked ){
                                        checkedSubValues.push(this.inputOptions[i].subdata[j].label);
                                    }
                                     if(this.inputOptions[i].subdata[j].value == selectvalue){
                                        headvalue = this.inputOptions[i].label;
                                     }
                                }
                                if(checkedSubValues.length == 0){
                                    if(headvalue == this.inputOptions[i].label  ){
                                    let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions[i].label + '"]');
                                     if ( (checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                this.inputOptions[i].checked = false;
                                                this.inputOptions[i].partialchecked=false;
                                         }
                                    }
                                }

                            }
                    }
                     
                }
                else{

                }  
            } 
        
        this.handleEvent();
        
    }
    /*
    handleValue(){
        let selectvalue = this.handleselectvalue;
        console.log({selectvalue});
        this.fireDataLayerEvent('filter', 'step_1', selectvalue,  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        let headvalues = [];
        let checkboxselect = this.template.querySelector('[data-id="' +selectvalue + '"]');
        
            checkboxselect.firstChild.classList.toggle("slds-is-selected");

            if (checkboxselect.firstChild.classList.contains('slds-is-selected')) {
               // this.selectedvalue.push(selectvalue);
                
                if(this.type == 'nononcology'){
                      for(let i=0; i <  this.inputOptions2.length ; i++ ){
                          headvalues.push(this.inputOptions2[i].label );
                      }
                    for(let i=0; i <  this.inputOptions2.length ; i++ ){
                            if(this.inputOptions2[i].label == selectvalue ){
                                this.inputOptions2[i].checked = true;
                                this.inputOptions2[i].partialchecked = false;
                                for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                    if(!(this.selectedvalue.includes(this.inputOptions2[i].subdata[j].value))){
                                        
                                         let checkboxselectSub = this.template.querySelector('[data-id="' +this.inputOptions2[i].subdata[j].value + '"]');
                                         if (! (checkboxselectSub.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectSub.firstChild.classList.toggle("slds-is-selected");
                                                this.selectedvalue.push(this.inputOptions2[i].subdata[j].value);
                                                this.inputOptions2[i].subdata[j].checked = true;
                                                this.inputOptions2[i].partialchecked = false;
                                         }
                                    }
                                }
                                       
                            }
                    }
                
                    if(!(headvalues.includes(selectvalue))){

                                    this.selectedvalue.push(selectvalue);
                                    for(let i=0; i <  this.inputOptions2.length ; i++ ){
                                         for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                             if( this.inputOptions2[i].subdata[j].label == selectvalue ){
                                               
                                                this.inputOptions2[i].subdata[j].checked = true;
                                                this.inputOptions2[i].partialchecked = true;
                                                let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions2[i].label + '"]');
                                                 if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                                
                                             }
                                         }
                                     }

                                     for(let i=0; i <  this.inputOptions2.length ; i++ ){
                                         let checkedSubValues = [];
                                         for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                             if(this.inputOptions2[i].subdata[j].checked){
                                                 checkedSubValues.push(this.inputOptions2[i].subdata[j].label);
                                             }
                                         
                                         }
                                         for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                          
                                             if( this.inputOptions2[i].subdata.length == checkedSubValues.length  ){
                                               
                                                this.inputOptions2[i].checked = true;
                                                this.inputOptions2[i].partialchecked = false;
                                                 let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions2[i].label + '"]');
                                                 if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                             }
                                             else if( checkedSubValues.length == 0){
                                                 this.inputOptions2[i].checked = false;
                                                 this.inputOptions2[i].partialchecked = false;
                                                  let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions2[i].label + '"]');
                                                 if ((checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                             }
                                             else{
                                                 this.inputOptions2[i].checked = false;
                                                 this.inputOptions2[i].partialchecked = true;
                                                  let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions2[i].label + '"]');
                                                    if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                        checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                    }
                                             }
                                         }
                                     }

                                    
                    }   
                }
                else if(this.type == 'oncology'){
                      for(let i=0; i <  this.inputOptions.length ; i++ ){
                          headvalues.push(this.inputOptions[i].label );
                      }
                    for(let i=0; i <  this.inputOptions.length ; i++ ){
                            if(this.inputOptions[i].label == selectvalue ){
                                this.inputOptions[i].checked = true;
                                this.inputOptions[i].partialchecked = false;
                                for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                    if(!(this.selectedvalue.includes(this.inputOptions[i].subdata[j].value))){
                                        
                                         let checkboxselectSub = this.template.querySelector('[data-id="' +this.inputOptions[i].subdata[j].value + '"]');
                                         if (! (checkboxselectSub.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectSub.firstChild.classList.toggle("slds-is-selected");
                                                this.selectedvalue.push(this.inputOptions[i].subdata[j].value);
                                                this.inputOptions[i].subdata[j].checked = true;
                                                this.inputOptions[i].partialchecked = false;
                                         }
                                    }
                                }
                                       
                            }
                    }
                
                    if(!(headvalues.includes(selectvalue))){

                                    this.selectedvalue.push(selectvalue);
                                    for(let i=0; i <  this.inputOptions.length ; i++ ){
                                         for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                             if( this.inputOptions[i].subdata[j].label == selectvalue ){
                                               
                                                this.inputOptions[i].subdata[j].checked = true;
                                                this.inputOptions[i].partialchecked = true;
                                                let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions[i].label + '"]');
                                                 if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                                
                                             }
                                         }
                                     }

                                     for(let i=0; i <  this.inputOptions.length ; i++ ){
                                         let checkedSubValues = [];
                                         for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                             if(this.inputOptions[i].subdata[j].checked){
                                                 checkedSubValues.push(this.inputOptions[i].subdata[j].label);
                                             }
                                         
                                         }
                                         for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                          
                                             if( this.inputOptions[i].subdata.length == checkedSubValues.length  ){
                                               
                                                this.inputOptions[i].checked = true;
                                                this.inputOptions[i].partialchecked = false;
                                                 let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions[i].label + '"]');
                                                 if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                             }
                                             else if( checkedSubValues.length == 0){
                                                 this.inputOptions[i].checked = false;
                                                 this.inputOptions[i].partialchecked = false;
                                                  let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions[i].label + '"]');
                                                 if ((checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                     checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                 }
                                             }
                                             else{
                                                 this.inputOptions[i].checked = false;
                                                 this.inputOptions[i].partialchecked = true;
                                                  let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions[i].label + '"]');
                                                    if (!(checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                        checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                    }
                                             }
                                         }
                                     }

                                    
                    }   
                }
                else{

                }  
            } 
            else {
                this.selectedvalue = this.selectedvalue.filter(value => value !== selectvalue);
                if((this.type == 'nononcology')){
                    for(let i=0; i <  this.inputOptions2.length ; i++ ){
                            //parent
                            if(this.inputOptions2[i].label == selectvalue ){
                                for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                    this.selectedvalue = this.selectedvalue.filter(value => value !== this.inputOptions2[i].subdata[j].value);
                                    let checkboxselectSub = this.template.querySelector('[data-id="' +this.inputOptions2[i].subdata[j].value + '"]');
                                         if ( (checkboxselectSub.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectSub.firstChild.classList.toggle("slds-is-selected");
                                                this.inputOptions2[i].subdata[j].checked = false;
                                                this.inputOptions2[i].partialchecked=true;
                                         }
                                }   
                            }//subdata
                            else{
                                 for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                     if(this.inputOptions2[i].subdata[j].value == selectvalue){
                                         this.inputOptions2[i].subdata[j].checked = false;
                                         this.inputOptions2[i].partialchecked=true;
                                     }
                                     
                                   
                                }
                                let checkedSubValues = [];
                                for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                                    if(this.inputOptions2[i].subdata[j].checked ){
                                        checkedSubValues.push(this.inputOptions2[i].subdata[j].label);
                                    }
                                
                                }
                                if(checkedSubValues.length == 0){
                                    let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions2[i].label + '"]');
                                     if ( (checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                this.inputOptions2[i].checked = false;
                                                this.inputOptions2[i].partialchecked=false;
                                         }
                                }




                            }
                    }    
                     
                }
                 if((this.type == 'oncology')){
                    for(let i=0; i <  this.inputOptions.length ; i++ ){
                            //parent
                            if(this.inputOptions[i].label == selectvalue ){
                                for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                    this.selectedvalue = this.selectedvalue.filter(value => value !== this.inputOptions[i].subdata[j].value);
                                    let checkboxselectSub = this.template.querySelector('[data-id="' +this.inputOptions[i].subdata[j].value + '"]');
                                         if ( (checkboxselectSub.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectSub.firstChild.classList.toggle("slds-is-selected");
                                                this.inputOptions[i].subdata[j].checked = false;
                                                this.inputOptions[i].partialchecked=true;
                                         }
                                }   
                            }//subdata
                            else{
                                 for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                     if(this.inputOptions[i].subdata[j].value == selectvalue){
                                         this.inputOptions[i].subdata[j].checked = false;
                                         this.inputOptions[i].partialchecked=true;
                                     }
                                     
                                   
                                }
                                let checkedSubValues = [];
                                for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                                    if(this.inputOptions[i].subdata[j].checked ){
                                        checkedSubValues.push(this.inputOptions[i].subdata[j].label);
                                    }
                                
                                }
                                if(checkedSubValues.length == 0){
                                    let checkboxselectParent = this.template.querySelector('[data-id="' +this.inputOptions[i].label + '"]');
                                     if ( (checkboxselectParent.firstChild.classList.contains('slds-is-selected'))) {
                                                checkboxselectParent.firstChild.classList.toggle("slds-is-selected");
                                                this.inputOptions[i].checked = false;
                                                this.inputOptions[i].partialchecked=false;
                                         }
                                }




                            }
                    }
                     
                }
                else{

                }  
            } 
        
        this.handleEvent();
    } */

    handleremove(event) {
        this.handleselectvalue = event.currentTarget.dataset.value;
        let checkboxselect = this.template.querySelector('[data-id="' + this.handleselectvalue + '"]');
        checkboxselect.firstChild.classList.toggle("slds-is-selected");
        this.selectedvalue = this.selectedvalue.filter(value => value !== this.handleselectvalue);
        //this.handleValue();
        if((this.type == 'nononcology')){
                for(let i=0; i <  this.inputOptions2.length ; i++ ){
                    let headEmpty = true;
                    let headVal;
                    for(let j=0; j < this.inputOptions2[i].subdata.length; j++){

                        if( this.inputOptions2[i].subdata[j].label == this.handleselectvalue  ){
                            this.inputOptions2[i].subdata[j].checked = false;
                            this.inputOptions2[i].subdata[j].partialchecked = false;
                            this.inputOptions2[i].checked = false;
                            this.inputOptions2[i].partialchecked = true;
                              headVal =  this.inputOptions2[i].label; 
                        }
                    }
                    for(let j=0; j < this.inputOptions2[i].subdata.length; j++){

                        if( this.inputOptions2[i].label == headVal ){
                            if( this.inputOptions2[i].subdata[j].checked && this.inputOptions2[i].subdata[j].label != this.handleselectvalue ){
                                headEmpty = false;
                            }
                        }
                    }
                    if(headEmpty && this.inputOptions2[i].label == headVal){
                        //this.selectedvalue = this.selectedvalue.filter(value => value !== this.inputOptions2[i].label);
                        this.inputOptions2[i].checked = false;
                        this.inputOptions2[i].partialchecked = false;
                    }
                }  
        }
        if((this.type == 'oncology')){
                for(let i=0; i <  this.inputOptions.length ; i++ ){
                    let headEmpty = true;
                    let headVal;
                    for(let j=0; j < this.inputOptions[i].subdata.length; j++){

                        if( this.inputOptions[i].subdata[j].label == this.handleselectvalue  ){
                            this.inputOptions[i].subdata[j].checked = false;
                            this.inputOptions[i].subdata[j].partialchecked = false;
                            this.inputOptions[i].checked = false;
                            this.inputOptions[i].partialchecked = true;
                              headVal =  this.inputOptions[i].label; 
                        }
                    }
                    for(let j=0; j < this.inputOptions[i].subdata.length; j++){

                        if( this.inputOptions[i].label == headVal ){
                            if( this.inputOptions[i].subdata[j].checked && this.inputOptions[i].subdata[j].label != this.handleselectvalue ){
                                headEmpty = false;
                            }
                        }
                    }
                    if(headEmpty && this.inputOptions[i].label == headVal){
                        //this.selectedvalue = this.selectedvalue.filter(value => value !== this.inputOptions[i].label);
                        this.inputOptions[i].checked = false;
                        this.inputOptions[i].partialchecked = false;
                    }
                }   
        } 

        this.handleEvent();
    }

    selectall() {
        let checkboxselect = this.template.querySelectorAll('.slds-listbox__item');
        console.log({checkboxselect});
        checkboxselect.forEach((item) => 
            item.firstChild.classList.add("slds-is-selected"),
        );
        if((this.type == 'nononcology')){
                for(let i=0; i <  this.inputOptions2.length ; i++ ){
                    for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                            this.inputOptions2[i].subdata[j].checked = true;
                            this.inputOptions2[i].partialchecked=false;
                            this.inputOptions2[i].checked=true;
                            if(!(this.selectedvalue.includes(this.inputOptions2[i].subdata[j].value))){
                                    this.selectedvalue.push(this.inputOptions2[i].subdata[j].value);
                            }
                            
                        } 
                }
        }
        if((this.type == 'oncology')){
                for(let i=0; i <  this.inputOptions.length ; i++ ){
                    for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                            this.inputOptions[i].subdata[j].checked = true;
                            this.inputOptions[i].partialchecked=false;
                            this.inputOptions[i].checked=true;
                            if(!(this.selectedvalue.includes(this.inputOptions[i].subdata[j].value))){
                                    this.selectedvalue.push(this.inputOptions[i].subdata[j].value);
                            }
                            
                        } 
                }
        }

        console.log('this.selectedvalue==>',this.selectedvalue);
        this.handleEvent();
    }

    clearall() {
        let checkboxselect = this.template.querySelectorAll('.slds-listbox__item');
        console.log({checkboxselect});
        checkboxselect.forEach((item) => 
            item.firstChild.classList.remove("slds-is-selected"),
        );

        if((this.type == 'nononcology')){
                for(let i=0; i <  this.inputOptions2.length ; i++ ){
                    for(let j=0; j < this.inputOptions2[i].subdata.length; j++){
                            this.inputOptions2[i].subdata[j].checked = false;
                            this.inputOptions2[i].partialchecked=false;
                            this.inputOptions2[i].checked=false;
                        } 
                }
                this.selectedvalue = [];
        }
        if((this.type == 'oncology')){
                for(let i=0; i <  this.inputOptions.length ; i++ ){
                    for(let j=0; j < this.inputOptions[i].subdata.length; j++){
                            this.inputOptions[i].subdata[j].checked = false;
                            this.inputOptions[i].partialchecked=false;
                            this.inputOptions[i].checked=false;
                        } 
                }
                this.selectedvalue = [];
        }

        this.handleEvent();
    }

    handleEvent(){
        // handling the changes in array and passing it to parent
        const custEvent = new CustomEvent('selectedoptions', {
             detail :  [...this.selectedvalue].join(', ') 
        });
    this.dispatchEvent(custEvent);
    }
        
    fireDataLayerEvent(category, action, label,module,linkedtext, linkedurl) {
        console.log('event triggered');
       this.dispatchEvent(new CustomEvent('datalayereventmodule', {
          
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
                link_text:linkedtext,
                link_url:linkedurl,
                content_count:'',
                content_saved:'',
                content_appointments:'',
                content_requests:'',
                content_name:this.compoundvalue,
                page_localproductname:'',                
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'scheduleappointment',

           },
           bubbles: true,
           composed: true
       }));
    }
}