import { LightningElement, track, wire } from 'lwc';

import MSD_CORE_Close from '@salesforce/resourceUrl/MSD_CORE_Close';

export default class MSD_CORE_Dropdown1 extends LightningElement {


    label = 'Select topics you would like to discuss';
    inputValue = '';
    dropDownInFocus = false;
    @track selectedvalue = [];
    @track handleselectvalue;
    closeicon = MSD_CORE_Close;
    @track allrecord = [];

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

    get inputOptions() {
        return [
            { label: 'Cutaneous Tumors', value: 'Cutaneous Tumors', subdata: 
                [
                    { label: 'Melanoma', value: 'Melanoma' },
                    { label: 'Merkel Cell Carcinoma', value: 'Merkel Cell Carcinoma' }
                ]
            },
            { label: 'Lung Cancers', value: 'Lung Cancers', subdata:
                [
                    { label: 'NSCLC', value: 'NSCLC' },
                    { label: 'SCLC', value: 'SCLC' }
                ]
            },
            { label: 'Gastrointestinal Cancers', value: 'Gastrointestinal Cancers', subdata:
                [
                    { label: 'Gastric', value: 'Gastric' },
                    { label: 'Hepatocellular', value: 'Hepatocellular' },
                    { label: 'Billiary', value: 'Billiary' },
                    { label: 'Esophageal', value: 'Esophageal' }
                ]
            },
            { label: 'Genitourinary Cancers', value: 'Genitourinary Cancers', subdata:
                [
                    { label: 'Urothelial', value: 'Urothelial' },
                    { label: 'Renal', value: 'Renal' },
                    { label: 'Prostate', value: 'Prostate' },
                ]
            },
            { label: 'Women\'s Cancers', value: 'Women\'s Cancers', subdata:
                [
                    { label: 'Breast', value: 'Breast' },
                    { label: 'Cervical', value: 'Cervical' },
                    { label: 'Ovarian', value: 'Ovarian' },
                    { label: 'Endometrial', value: 'Endometrial' },
                ]
            },
            { label: 'Hematological Malignancies', value: 'Hematological Malignancies'},
            { label: 'Head and Neck Cancers', value: 'Head and Neck Cancers'},
        ]
    }

    get inputOptions2() {
        return [
            { label: 'Phase 1', value: 'Phase 1', subdata: 
                [
                    { label: 'Cardiovascular MK-2060', value: 'Cardiovascular MK-2060' },
                    { label: 'NASH MK-6024', value: 'NASH MK-6024' },
                    { label: 'NASH MK-3655', value: 'NASH MK-3655' },
                    { label: 'HIV-1 Infection Adult Islatravir Lenacapavir Mk-8591D1', value: 'HIV-1 Infection Adult Islatravir Lenacapavir Mk-8591D1' },
                    { label: 'HIV-1 Infection Adult Islatravir Mk-8591D1', value: 'HIV-1 Infection Adult Islatravir Mk-8591D1' }
                ]
            },
            { label: 'Phase 2', value: 'Phase 2', subdata:
                [
                    { label: 'HIV-1 Infection Doravirine/Islatravir MK-8591A2', value: 'HIV-1 Infection Doravirine/Islatravir MK-8591A2' },
                    { label: 'Anti-Viral COVID 19 molnupiravir MK-44821', value: 'Anti-Viral COVID 19 molnupiravir MK-44821' }
                ]
            },
            { label: 'Under review', value: 'Under review', subdata:
                [
                    { label: 'Cough gefapixant MK-7264', value: 'Cough gefapixant MK-7264' },
                    { label: 'Pneumococcal Infection for pediatric use V114', value: 'Pneumococcal Infection for pediatric use V114' },
                ]
            }
        ]
    }

    connectedCallback() {
        setTimeout(() => {
            console.log('inputOptions-->', this.inputOptions);
            // this.allrecord = this.inputOptions;
        }, 2000);
    }

    handleClick() {
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        sldsCombobox.classList.toggle("slds-is-open");
    }
    handleMouseleave() {
        this.dropDownInFocus = false;
    }
    handleMouseEnter() {
        this.dropDownInFocus = true;
    }
    handleBlur() {
        if (!this.dropDownInFocus) {
            this.closeDropbox();
        }
    }
    closeDropbox() {
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        sldsCombobox.classList.remove("slds-is-open");
    }
    handleSelection(event) {
        this.handleselectvalue = event.currentTarget.dataset.value;
        let checkboxselect = this.template.querySelector('[data-id="' + this.handleselectvalue + '"]');
        console.log({ checkboxselect });
        checkboxselect.firstChild.classList.toggle("slds-is-selected");

        if (checkboxselect.firstChild.classList.contains('slds-is-selected')) {
            this.selectedvalue.push(this.handleselectvalue);
        } else {
            this.selectedvalue = this.selectedvalue.filter(value => value !== this.handleselectvalue);
        }
    }
    handleremove(event) {
        this.handleselectvalue = event.currentTarget.dataset.value;
        let checkboxselect = this.template.querySelector('[data-id="' + this.handleselectvalue + '"]');
        checkboxselect.firstChild.classList.toggle("slds-is-selected");
        this.selectedvalue = this.selectedvalue.filter(value => value !== this.handleselectvalue);
    }

    selectall() {
        let checkboxselect = this.template.querySelectorAll('.slds-listbox__item');
        console.log({checkboxselect});
        checkboxselect.forEach((item) => 
            item.firstChild.classList.add("slds-is-selected"),
        );

        console.log('this.selectedvalue==>',this.selectedvalue);
        
    }

    clearall() {
        let checkboxselect = this.template.querySelectorAll('.slds-listbox__item');
        console.log({checkboxselect});
        checkboxselect.forEach((item) => 
            item.firstChild.classList.remove("slds-is-selected"),
        );
    }
}