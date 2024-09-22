import { LightningElement, api, track} from 'lwc';
import MedInqConstant from "c/medInqConstant";
import VeevaUtils from 'c/veevaUtils';
import VeevaConstant from 'c/veevaConstant';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';
import { getFieldErrors } from 'c/veevaPageFieldErrors';

export default class MedicalInquiryLocation extends VeevaErrorHandlerMixin(LightningElement) {

    
    @api
    get ctrl() {
        return this._ctrl;
    }

    set ctrl(value) {
        this._ctrl = value;
    }

    selectedLocationName = '';
    hideDropdown = true;
    searchTerm = '';
    @track searchRecords = [];
    hasFocus = false;
    hasBeenUpdated = false;
    ignoreBlur = false;
    highlightIndex = 0;
 
    async showOptions() {
        const locationPosition = this.template.querySelector('c-veeva-undo').getBoundingClientRect();
        const heightFromBottom = window.innerHeight - locationPosition.bottom;
        if(heightFromBottom <= 190){
            this.openUpward = true;
        } else {
            this.openUpward = false;
        }
        this.hasFocus = true;
        this.searchTerm = '';
        await this.search();
        this.hideDropdown = !this.hideDropdown;
    }

    async handleResultClick(event){
        const selectedLocation = { name: event.currentTarget.dataset.name, Id: event.currentTarget.dataset.accountid};
        await this.setSelected(selectedLocation);

        if(this.initialValue?.name !== this.selectedLocationName){
            this.displayUndoUi();
        }
        
        this.hideDropdown = true;
    }

    async setSelected(value){
        this.selectedLocationName = value.name;
        this.selectedLocationId = value.Id;
        this.selectedLocationIdUrl = value.Id ? `/${value.Id}` : '';
        this.ctrl.setFieldValue(value.Id);
    }

    async connectedCallback(){
        await this.setLabels();
        this.ctrl.pageCtrl.track(MedInqConstant.ACCOUNT, this, 'accountChanged');
        this.searchTerm = '';
        await this.defaultLocation();
    }


    async setLabels(){
        this.searchLabel = await this.ctrl.pageCtrl.getMessageWithDefault('SEARCH', 'Common', 'Search');
        const selectLabel = await this.ctrl.pageCtrl.getMessageWithDefault('SELECT_FIELD', 'Common', 'Select {0}');
        this.selectLocationLabel = selectLabel.replace('{0}', this.ctrl.field.label);
        this.completeFieldLabel = await this.ctrl.pageCtrl.getMessageWithDefault('COMPLETE_THIS_FIELD', 'Lightning', 'Complete this field.');
    }

    async search() {
        let displayRecords;
        const records = await this.getRecords();
        if (VeevaUtils.isValidSearchTerm(this.searchTerm) || this.searchTerm.length > 0) {
            const filtered = records.filter(searchItem => searchItem.name.toLowerCase().indexOf(this.searchTerm.toLowerCase()) !== -1)
            this._formatResultText(filtered);
            displayRecords = [...filtered];
        } else {
            records.forEach(searchItem => {
                searchItem.match = '';
            });
            displayRecords = [...records];
        }
        if(this.selectedLocationId){
            const locationIndex = displayRecords.findIndex(record => record.Id === this.selectedLocationId);
            if(locationIndex >=0){
                displayRecords[locationIndex].showHighlight = true;
                displayRecords[locationIndex].isSelected = true;
                this.highlightIndex = locationIndex;
            }
        }
        for(const item of displayRecords){
            item.listboxOptionClass = item.showHighlight ? "slds-media slds-media_center slds-listbox__option slds-listbox__option_entity slds-has-focus" : "slds-media slds-media_center slds-listbox__option slds-listbox__option_entity";
        }
        this.searchRecords = displayRecords;
    }

    async defaultLocation() {
        if (this.ctrl.readonly) {
            const savedLocation = await this.ctrl.savedLocation();
            if (savedLocation) {
                this.setSelected(savedLocation);
            } else if (this.ctrl.data.fields[MedInqConstant.LOCATION].value && this.ctrl.data.fields[MedInqConstant.LOCATION].displayValue) {
                const defaultLocation = {
                    name: this.ctrl.data.fields[MedInqConstant.LOCATION].displayValue,
                    Id: this.ctrl.data.fields[MedInqConstant.LOCATION].value 
                };
                this.setSelected(defaultLocation);

            } else {
                this.setLocationNull();
            }
        } else {
            await this.search();
            if (this.searchRecords.length > 0) { 
                const savedLocation = await this.ctrl.savedLocation();
                const primaryParent = this.searchRecords.find(location => location.primaryParent);
                const defaultLocation = savedLocation || primaryParent || this.searchRecords[0];
                this.setSelected(defaultLocation);
                this.initialValue = defaultLocation;
            } else {
                this.setLocationNull();
            }
        }
    }

    setLocationNull() {
        this.initialValue = null;
        this.setSelected({Id: null, name: null});
    }

    @api
    checkValidity() {
        this.hasFieldError = false;
        this.fieldErrorMsg = '';

        if( this.ctrl.required && (this.selectedLocationName === '' || this.selectedLocationName === null)){
            this.fieldErrorMsg = this.completeFieldLabel;
            this.hasFieldError = true;
        } else if(this.ctrl.getError()){
            this.fieldErrorMsg = this.ctrl.getError();
            this.hasFieldError = true; // represents error is present
        }

        return !this.hasFieldError
    }

    handleMouseDown(){
        this.ignoreBlur = true;
        this.hideDropdown = false;
    }

    handleMouseUp(){
        this.ignoreBlur = false;
    }

    handleMouseOut(){
        if (this.searchRecords.length > 0){
            this.removeHighlight();
        }
    }

    handleInput(event) {
        if (this.shouldShowDropdown){
            if(event.code === 'Escape'){
                this.searchRecords = [];
            } else if(event.code === 'ArrowUp' && this.searchRecords.length > 0){
                    this.changeHighlightIndex(this.decrementHighlightIndex);
            } else if(event.code === 'ArrowDown' && this.searchRecords.length > 0){
                    this.changeHighlightIndex(this.incrementHighlightIndex);
            }
        } else if(event.code === 'ArrowDown' || event.code === 'Enter'){
                this.hideDropdown = false;
            }
    }

    handleEnterInput(event){
        if(event.code === 'Enter' && this.searchRecords.length > 0 && this.shouldShowDropdown){
            const currElement = this.template.querySelector(".slds-has-focus");
            if (currElement){
                currElement.click();
            }
        }
    }

    handleSearchTermChange(event){
        if (this._timeout) {
            clearTimeout(this._timeout);
        }
        
        this.hideDropdown = false;
        this.searchTerm = event.detail.value;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._timeout = setTimeout(() => {
            this.search();
        }, VeevaConstant.DEBOUNCE_DELAY);
    }

    changeHighlightIndex(indexMoveFunct){
        this.removeHighlight();

        indexMoveFunct(this);
        this.addHighlight();

        const currElement = this.template.querySelectorAll(`[data-accountid="${this.searchRecords[this.highlightIndex].Id}"]`)[0];
        if (currElement){
            currElement.scrollIntoView({ behavior: 'smooth', block: 'nearest'});
        }
    }

    incrementHighlightIndex(self){
        if (self.highlightIndex <self.searchRecords.length-1){
            self.highlightIndex++;
        } else {
            self.highlightIndex = 0;
        }
    }

    decrementHighlightIndex(self){
        if (self.highlightIndex > 0){
            self.highlightIndex--;
        } else {
            self.highlightIndex = self.searchRecords.length-1;
        }
    }

    removeHighlight(){
        this.searchRecords[this.highlightIndex].showHighlight = false;
        this.searchRecords[this.highlightIndex].listboxOptionClass = "slds-media slds-media_center slds-listbox__option slds-listbox__option_entity";
    }

    addHighlight(){
        this.searchRecords[this.highlightIndex].showHighlight = true;
        this.searchRecords[this.highlightIndex].listboxOptionClass = "slds-media slds-media_center slds-listbox__option slds-listbox__option_entity slds-has-focus";
    }

    _formatResultText(results) {
        results.forEach(searchItem => {
            const matchInd = searchItem.name.toLowerCase().indexOf(this.searchTerm.toLowerCase());
            const postSearchTermInd = matchInd + this.searchTerm.length;
            searchItem.preMatch = searchItem.name.substring(0, matchInd);
            searchItem.match = searchItem.name.substring(matchInd, postSearchTermInd);
            searchItem.postMatch = searchItem.name.substring(postSearchTermInd);
        });
    }

    async getRecords() {
        let response = await this.ctrl.search(this.searchTerm);
        if (response && response.length > 0) {
            return response;
        }
        if (this.searchTerm.length === 1){
            response = await this.ctrl.search();
            if (response && response.length > 0) {
                return response;
            }
        }
        return [];
    }

    handleClose() {
        if (!this.ignoreBlur){
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this.resetSearch();
                this.checkValidity();
            }, 0);
            this.hideDropdown = true;
        }
    }

    resetSearch() {
        this.searchRecords = [];
        this.hasFocus = false;
    }


    // styles
    get shouldShowDropdown(){
        return this.hasFocus && !this.hideDropdown;
    }

    get dropdownClass() {
        let css = 'slds-popover slds-dropdown-trigger slds-dropdown-trigger_click slds-m-top_x-small';
        if (this.shouldShowDropdown) {
            css += ' slds-is-open';
        }
        if(this.openUpward){
            css += ' open-upward slds-nubbin_bottom-right';
        }else {
            css += ' slds-nubbin_top-right';
        }
        
        return css;
    }

    get buttonCssClass(){
        let css = 'slds-input_faux slds-combobox__input slds-combobox__input-value';
        if (this.hasFieldError){
            css += ' slds-has-error';
        }
        return css;
    }


    get showUndo() {
        return this.hasBeenUpdated && !this.ctrl.disabled;
    }

    displayUndoUi() {
        this.hasBeenUpdated = true;
    }

    clearUndoUi() {
        this.hasBeenUpdated = false;
    }

    async handleUndoClick() {
        await this.setSelected(this.initialValue);
        this.clearUndoUi();
        this.checkValidity();
    }

    get showURL() {
        return this.ctrl.readonly;
    }

    @api focusOn() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
          this.template.querySelector('button')?.focus();
        }, 100);
      }
    
    @api getFieldErrors() {
        return getFieldErrors(this, 'c-call-location');
    }

    async accountChanged() {
        this.clearUndoUi();
        await this.search();
        await this.defaultLocation();
    }
}