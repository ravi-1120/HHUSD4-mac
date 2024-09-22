import { LightningElement, api, track } from 'lwc';
import VeevaConstant from 'c/veevaConstant';

export default class VeevaRawCombobox extends LightningElement {

    // Passed in combobox values need format {value: (unique value), label: ..., icon: (optional icon), disabled: (optional if choice disabled))
    @api errorMsg;
    @api disabled = false;
    @api options;
    @api value;
    @api buttonLabel;
    @api fieldApiName;
    @track hideDropdown = true;

    @api iconSize = "xx-small";
    @api addButtonPadding = false;
    @api hideCheckmarks = false;

    ignoreBlur = false;
    highlightPosition = -1;
    searchTerm = '';

    selectOption(value) {
        if(this.options.find(obj => obj.value === value).disabled) {
            return;
        }
        if(this.value !== value) {
            this.dispatchEvent(new CustomEvent("optionselection", {
                detail: {
                    value
                }
            }));
        }
        this.handleClose();
    }

    handleClose() {
        if (!this.ignoreBlur){
            this.hideDropdown = true;
            this.removeHighlight();
        }
    }

    handleDropdown() {
        if(this.disabled) {
            return;
        }

        if(this.hideDropdown) {
            this.hideDropdown = false;
            if (this.value) {
                this.highlightPosition = this.options.findIndex(obj => obj.value === this.value);
                this.template.querySelector(`[data-id="${this.value}"]`).className = this.focusedOptionClass;
            }
            else {
                this.highlightPosition = -1;
            }
        }
        else {
            this.handleClose();
        }
    }

    handleSelection(event) {
        this.selectOption(event.currentTarget.dataset.id);
    }

    handleInput(event) {
        if(this.hideDropdown) {
            if(event.code === 'ArrowDown' || event.code === 'Enter') {
                event.preventDefault();
                this.handleDropdown();
            }
        }
        else if(!this.hideDropdown && event.key !== 'Tab') {
            event.preventDefault();
            if(event.code === 'Escape' || event.code === 'Backspace') {
                this.handleClose();
            }
            else if(event.code === 'ArrowUp') {
                this.changeHighlightIndex(this.decrementHighlightIndex);
            }
            else if(event.code === 'ArrowDown') {
                this.changeHighlightIndex(this.incrementHighlightIndex);
            }
            else if(event.code === 'Enter') {
                if(this.highlightPosition > -1) {
                    this.selectOption(this.options[this.highlightPosition].value);
                }
                else{
                    this.handleDropdown();
                }
            }
            else {
                this.keystrokeHighlightIndex(event.key);
            }
        }
    }

    removeHighlight() {
        if(this.highlightPosition !== -1) {
            this.template.querySelector(`[data-id="${this.options[this.highlightPosition].value}"]`).className = this.comboboxOptionClass;
        }
    }

    addHighlight() {
        if(!this.options[this.highlightPosition].disabled) {
            this.template.querySelector(`[data-id="${this.options[this.highlightPosition].value}"]`).className = this.focusedOptionClass;
        }
        else {
            this.highlightPosition = -1;
        }
    }


    changeHighlightIndex(indexMoveFunct) {
        this.removeHighlight();
        indexMoveFunct(this);
        this.addHighlight();
        const currElement = this.template.querySelector(`[data-id="${this.options[this.highlightPosition].value}"]`);
        if (currElement){
            currElement.scrollIntoView({ behavior: 'smooth', block: 'nearest'});
        }
    }
    // eslint-disable-next-line class-methods-use-this
    incrementHighlightIndex(self) {
        if(self.highlightPosition >= self.options.length-1) {
            self.highlightPosition = 0;
        }
        else {
            self.highlightPosition++;
        }
        if(self.options[self.highlightPosition].disabled) {
            self.incrementHighlightIndex(self);
        }
    }

    // eslint-disable-next-line class-methods-use-this
    decrementHighlightIndex(self) {
        if(self.highlightPosition < 1) {
            self.highlightPosition = self.options.length-1;
        }
        else {
            self.highlightPosition--;
        }
        if(self.options[self.highlightPosition].disabled) {
            self.decrementHighlightIndex(self);
        }
    }

    keystrokeHighlightIndex(value) {
        if(this._timeout) {
            clearTimeout(this._timeout);
        }

        this.searchTerm += value;
        // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
        this._timeout = setTimeout(() => {
            this.search();
        }, VeevaConstant.DEBOUNCE_DELAY);
    }

    search() {
        this.removeHighlight();
        const pos = this.options.findIndex(obj => obj.label.substr(0, this.searchTerm.length).toLowerCase() === this.searchTerm);
        if(pos > -1) {
            this.highlightPosition = pos;
            this.addHighlight();
        }
        this.searchTerm = '';
    }

    handleMouseOver(event) {
        this.removeHighlight();
        const focusedOption = event.currentTarget.dataset.id;
        this.highlightPosition = this.options.findIndex(obj => obj.value === focusedOption);
        this.addHighlight();
    }

    handleMouseOut() {
        this.removeHighlight();
    }

    handleMouseDown(event){
        if(this.options.find(obj => obj.value === event.currentTarget.dataset.id).disabled) {
            event.preventDefault();
        }
        else {
            this.ignoreBlur = true;
            this.hideDropdown = false;
        }
    }

    handleMouseUp(){
        this.ignoreBlur = false;
    }

    checkDisabled(event) {
        if(this.disabled) {
            event.preventDefault();
        }
    }

    get comboboxOptions() {
        if(!this.options) {
            return null;
        }
        return this.options.map(val => ({
            ...val,
            selected: this.value === val.value ? 'utility:check' : '',
            disabledClass: val.disabled ? 'slds-current-color': ''
        }));
    }

    get selectedObj() {
        if(!this.options) {
            return null;
        }
        return this.options.find(obj => obj.value === this.value);
    }

    get selectedIcon() {
        if(this.selectedObj) {
            return this.selectedObj.icon ? this.selectedObj.icon : '';
        }
        return '';
    }

    get selectedLabel() {
        return this.value ? this.selectedObj.label : this.buttonLabel;
    }

    // Styling
    get dropdownClass() {
        let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        if (!this.hideDropdown) {
            css += ' slds-is-open';
        }
        return css;
    }

    get comboboxOptionClass() {
        const css = 'slds-media slds-media_center slds-listbox__option slds-listbox__option_plain slds-media_small';
        return css;
    }

    get focusedOptionClass() {
        const css = 'slds-media slds-media_center slds-listbox__option slds-listbox__option_plain slds-media_small slds-is-selected slds-has-focus';
        return css;
    }

    get comboboxButtonClass() {
        let css = 'slds-input_faux slds-combobox__input';
        if (this.selectedLabel !== this.buttonLabel){
            css += ' slds-combobox__input-value';
        }
        if(this.disabled) {
            css += ' slds-is-disabled';
            this.template.querySelector('button').tabIndex = -1;
        } 
        
        if(this.errorMsg){
            css += ' slds-has-error';
        }
        if(this.addButtonPadding) {
            css += ' slds-p-vertical_xx-small';
        }
        return css;
    }

    @api focusOn() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
        setTimeout(() => {
          this.template.querySelector('button')?.focus();
        }, 100);
    }

}