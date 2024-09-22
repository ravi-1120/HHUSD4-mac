import { LightningElement, api, track } from "lwc";
import VeevaMessageService from 'c/veevaMessageService';
import VeevaAccountSearchController from "./veevaAccountSearchController";

export default class VeevaAccountSearch extends LightningElement {
    @track searchRecords;
    @track searchTerm;
    @track selected = {};
    @track msgAccount;
    @track toggleClearButton = true;
    @api ctrl;
 
    @api 
    get showClearButton() {
        return this.toggleClearButton;
    }
    set showClearButton(value) {
        this.toggleClearButton = value;
    }

    @api checkValidity() {
        const errors = [...this.template.querySelectorAll('c-veeva-lookup')].filter(item => item.checkValidity() === false);
        return !errors.length;
    }

    async connectedCallback() {
        const messageSvc = new VeevaMessageService();
        const [msgAccount] = await Promise.all([
            messageSvc.getMessageWithDefault('Account', 'Common', 'Account')
        ]);
        this.msgAccount = msgAccount;
    }

    handleSearchMode(event) {
        this.searchTerm = event.detail.term;
    }

    handleSearchSelection(event) {
        this.searchRecords = null;
        this.searchTerm = '';
        this.selected = event.detail;

        const accountSearchEvent = new CustomEvent("accountselected", { detail: event.detail });
        this.dispatchEvent(accountSearchEvent);
    }

    handleSearchClose() {
        this.searchTerm = '';
    }
    
    handleClearLookup() {
        this.selected = {};
        this.searchRecords = null;
        
        const accountSearchClear = new CustomEvent("searchcleared");
        this.dispatchEvent(accountSearchClear);
    }

    async handleInput(event) {
        const response = await this.ctrl.search(event.target.value);
        this.searchRecords = response.records;
    }


    get comboboxClass() {
        const css = this.selected.id ? ' slds-input-has-icon_left-right' : ' slds-input-has-icon_right';
        return `slds-combobox__form-element slds-input-has-icon${css}`;
    }

    get dropdownClass() {
        const css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        return css;
    }

    get selectedIconClass() {
        return 'slds-icon_container slds-combobox__input-entity-icon';
    }
}
export { VeevaAccountSearchController };