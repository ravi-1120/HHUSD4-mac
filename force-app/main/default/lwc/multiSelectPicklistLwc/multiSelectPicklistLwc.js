import {LightningElement, api, track} from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import productDetailCSS from '@salesforce/resourceUrl/productDetailCSS';
export default class MultiSelectPicklistLwc extends LightningElement {

    /* 
        component receives the following params:
        label - String with label name;
        disabled - Boolean value, enable or disable Input;
        options - Array of objects [{label:'option label', value: 'option value'},{...},...];
    
        to clear the value call clear() function from parent:
        let multiSelectPicklist = this.template.querySelector('c-multi-select-pick-list');
        if (multiSelectPicklist) {
           multiSelectPicklist.clear();
        }
   
        to get the value receive "valuechange" event in parent;
        returned value is the array of strings - values of selected options;
        example of usage:
        <c-multi-select-pick-list options={marketAccessOptions}
                                   onvaluechange={handleValueChange}
                                   label="Market Access">
        </c-multi-select-pick-list>
        handleValueChange(event){
            console.log(JSON.stringify(event.detail));
        }
    */


    @api label = "Default label";
    _disabled = false;
    @api
    get disabled(){
        return this._disabled;
    }
    set disabled(value){
        this._disabled = value;
        this.handleDisabled();
    }
    @track inputOptions;
    @api
    get options() {
        return this.inputOptions.filter(option => option.value !== 'All');
    }
    set options(value) {
        // let options = [
        //     {
        //         value: 'All',
        //         label: 'All'
        //     }
        // ];
        // this.inputOptions = options.concat(value);
        // console.log('inputOptions value : '+JSON.stringify(value));
        this.inputOptions = value;
    }
    
    @api
    clear(){
        // this.handleAllOption();
    }
    value = [];		 
    //Modified by Sabari as per Figma Design
    @track inputValue = 'Search';
    @track updatedValue ='Search';
    // @track inputValue;
    hasRendered;
    renderedCallback() {
        if (!this.hasRendered) {
            //  we coll the logic once, when page rendered first time
            this.handleDisabled();
        }
        this.hasRendered = true;
        Promise.all([
            loadStyle(this, productDetailCSS),
            ]).then(() => {
                console.log('Files loaded');
            })
            .catch(error => {
            console.log(error.body.message);
           });
    }
    handleDisabled(){
        let input = this.template.querySelector("input");
        if (input){
            input.disabled = this.disabled;
        }
    }
    comboboxIsRendered;
    handleClick() {
        this.handleload();
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        sldsCombobox.classList.toggle("slds-is-open"); 
        //Modified by Sabari as per Figma Design
        this.inputValue = 'Search';
        if (!this.comboboxIsRendered){
            // let allOption = this.template.querySelector('[data-id="All"]');
            // allOption.firstChild.classList.add("slds-is-selected");
            this.comboboxIsRendered = true;
        }
    }

    handleload(){
        this.options = this.inputOptions.filter(option => option.value !== 'All');
    }

    handleSelection(event) {
        let value = event.currentTarget.dataset.value;
        // if (value === 'All') {
        //     this.handleAllOption();
        // }
        // else {
        //     this.handleOption(event, value);
        // }
        this.handleOption(event, value);
        let input = this.template.querySelector("input");	
        //Modified by Sabari as per Figma Design
        var scrollPosition = window.scrollY;
        input.focus();
        window.scrollTo(0,scrollPosition);
        this.sendValues();
    }

    

    sendValues(){
        let values = [];
        for (const valueObject of this.value) {
            values.push(valueObject.value);
        }
        console.log('values : '+values);
        this.dispatchEvent(new CustomEvent("valuechange", {
            detail: values
        }));
    }

    handleAllOption(){
        this.value = [];
        this.inputValue = 'All';
        let listBoxOptions = this.template.querySelectorAll('.slds-is-selected');
        for (let option of listBoxOptions) {
            option.classList.remove("slds-is-selected");
        }
        let allOption = this.template.querySelector('[data-id="All"]');
        allOption.firstChild.classList.add("slds-is-selected");
        this.closeDropbox();
    }
    
    handleOption(event, value){
        console.log('handleoption1:' , JSON.stringify(event.currentTarget));
        console.log('handleOption2:' ,event);
        console.log('handleoptionvalue:' , value);
        let listBoxOption = event.currentTarget.firstChild;
        if (listBoxOption.classList.contains("slds-is-selected")) {
            console.log('in if');
            this.value = this.value.filter(option => option.value !== value);
            console.log('thefiltervaluesone>>' + this.value);
        }
        else {
            console.log('in else');
            // let allOption = this.template.querySelector('[data-id="All"]');
            // allOption.firstChild.classList.remove("slds-is-selected");
            let option = this.options.find(option => option.value === value);
            this.value.push(option);
            console.log('thefiltervaluestwo>>' + this.value);
        }
        if (this.value.length > 1) {   
            //Modified by Sabari as per Figma Design
            this.updatedValue = this.value.length + ' cancer types selected';
        }
        else if (this.value.length === 1) {	
            //Modified by Sabari as per Figma Design
          //  this.updatedValue = this.value[0].label;
          //Modified by Rajeswari
               this.updatedValue = this.value.length + ' cancer type selected';
        }
        else {			
            //Modified by Sabari as per Figma Design
            this.updatedValue = 'Search';
        }
        listBoxOption.classList.toggle("slds-is-selected");
        // let checkid = event.currentTarget.dataset.id;
        // console.log('idofchekbox:' + checkid);
        // const checkbox = document.getElementById(checkid);
        // checkbox.checked = !checkbox.checked;
    }
    dropDownInFocus = false;
    handleBlur() {
        if (!this.dropDownInFocus) {
            //Modified by Sabari as per Figma Design
            this.inputValue = this.updatedValue;
            this.closeDropbox();
        }
    }

    handleMouseleave() {
        this.dropDownInFocus = false;
    }
    handleMouseEnter() {
        this.dropDownInFocus = true;
    }
    closeDropbox() {
        let sldsCombobox = this.template.querySelector(".slds-combobox");
        sldsCombobox.classList.remove("slds-is-open");
    }
}