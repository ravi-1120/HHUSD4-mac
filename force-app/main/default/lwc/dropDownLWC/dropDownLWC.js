import { LightningElement, track, api } from 'lwc';
const DROP_DOWN_CLASS = 'slds-listbox__item ';
const DROP_DOWN_OPEN = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';
const DROP_DOWN_CLOSE = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
export default class DropDownLWC extends LightningElement {

    @track trackoptionsToDisplay;
    @api
    get optionsToDisplay() {
        return this.trackoptionsToDisplay;
    }
    @api title;
    set optionsToDisplay(value) {
        var tempOptions = JSON.parse(JSON.stringify(value));
        tempOptions.forEach(ele => {
            ele.class = this.dropdownList;
            ele.isChecked = false;
        });
        this.trackoptionsToDisplay = tempOptions;
        //console.log(JSON.stringify(this.trackoptionsToDisplay));
    }
    @track label = '';
    @track openDropDown = false;
    @track placeholder = 'Select an option';

    get dropDownClass() {
        return (this.openDropDown == true ? DROP_DOWN_OPEN : DROP_DOWN_CLOSE);
    }

    //@track dropdownList = 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta';
    @track dropdownList = 'slds-media slds-listbox__option slds-media_center slds-media_small slds-listbox__option_plain';
    @track focusTracker = -1;

    openDropDown(event) {
        this.toggleOpenDropDown(true);
    }

    toggleOpenDropDown(toggleState) {
        this.openDropDown = toggleState;
    }

    optionsClickHandler(event) {
        const value = event.target.closest('li').dataset.value;
        const label = event.target.closest('li').dataset.label;
        var isCheck = event.currentTarget.dataset.id;
        //console.log('isCHeck-->' + isCheck);
        //this.setValues(value, label);
        this.toggleOpenDropDown(false);
        var allOptions = this.trackoptionsToDisplay;
        const dropDownDetail = {};
        dropDownDetail["value"] = value;
        dropDownDetail["label"] = label;
        dropDownDetail["title"] = this.title;
        this.label = label;
        for (let i = 0; i < allOptions.length; i++) {
            if (allOptions[i].label === label) {
                allOptions[i].isChecked = true;
                // allOptions[i].class = 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta slds-is-selected';
                allOptions[i].class = 'slds-media slds-listbox__option slds-media_center slds-media_small slds-listbox__option_plain slds-is-selected';
            }
            else {
                allOptions[i].isChecked = false;
                allOptions[i].class = this.dropdownList;
            }
        }
        this.trackoptionsToDisplay = allOptions;
        this.updateDropDownValue(dropDownDetail);
    }

    updateDropDownValue(dropDownDetail) {
        const dropDownEvent = new CustomEvent("dropdownchange", {
            detail: dropDownDetail,
        });
        this.dispatchEvent(dropDownEvent);
    }

    handleInputClick(event) {
        var isOpen = (this.openDropDown == true) ? false : true;
        this.toggleOpenDropDown(isOpen);
    }
    get isDropdownOpen() {
        return (this.openDropDown ? true : false);
    }

    handleKeyUp(event) {
        if (this.trackoptionsToDisplay.length > 0) {
            var key = 'which' in event ? event.which : event.keyCode;
            //console.log("handleKeyUp =  " + key);
            if (key === 40 || key === 38) {
                this.defocusItem();
                var optionsLength = this.trackoptionsToDisplay.length;
                if (key === 40) {
                    if (this.focusTracker < optionsLength - 1) {
                        this.focusTracker++;
                    }
                }
                else {
                    if (this.focusTracker > 0) {
                        this.focusTracker--;
                    }
                }
                this.focusItem();
            }
            else if (key === 13) {
                // Enter - is it for dropDown or select a result item
                this.dropDownItemSelected(event);
            }
            else if (key === 27 || key === 8) {
                // Back space or escape
            }
        }
    }

    defocusItem() {
        if (this.focusTracker >= 0) {
            var dropDownResItem = this.trackoptionsToDisplay[this.focusTracker];
            var textInput = this.template.querySelector('[data-value=\'' + dropDownResItem.value + '\']');
            textInput.className = DROP_DOWN_CLASS + 'deFocusList';
        }
    }

    focusItem() {
        //console.log(this.focusTracker);
        if (this.focusTracker >= 0) {
            let dropDownResItem = this.trackoptionsToDisplay[this.focusTracker];
            //console.log(JSON.stringify(dropDownResItem));
            try {
                const textInput = this.template.querySelector('[data-value=\'' + dropDownResItem.value + '\']');
                textInput.className = DROP_DOWN_CLASS + 'listItemFocus';
            } catch (error) {
                console.error(error);
            }
        }
    }

    dropDownItemSelected(event) {
        if (this.focusTracker >= 0 && this.trackoptionsToDisplay.length > 0) {
            let dropDownResItem = this.trackoptionsToDisplay[this.focusTracker];
            //console.log('dropDownItemSelected dropDownResItem ' + JSON.stringify(dropDownResItem));
            //this.dropDownResults = [];
            var dropDownDetail = { 'label': dropDownResItem.label, 'value': dropDownResItem.value, 'title': this.title };
            this.toggleOpenDropDown(false);
            var allOptions = this.trackoptionsToDisplay;
            this.label = dropDownDetail.label;
            for (let i = 0; i < allOptions.length; i++) {
                if (allOptions[i].label == dropDownDetail.label) {
                    allOptions[i].isChecked = true;
                    // allOptions[i].class = 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta slds-is-selected';
                    allOptions[i].class = 'slds-media slds-listbox__option slds-media_center slds-media_small slds-listbox__option_plain slds-is-selected';
                }
                else {
                    allOptions[i].isChecked = false;
                    allOptions[i].class = this.dropdownList;
                }
            }
            this.trackoptionsToDisplay = allOptions;
            this.updateDropDownValue(dropDownDetail);
        }
    }


    closeDropDown(event) {
        if (event.relatedTarget && event.relatedTarget.tagName == "UL" && event.relatedTarget.className.includes('customClass')) {
            console.log(JSON.stringify(event.relatedTarget.className));
            if (this.openDropDown) {
                this.template.querySelector('.slds-combobox__input').focus();
            }
        }
        else {
            this.toggleOpenDropDown(false);
        }
    }

    @api refreshLabel(){
        this.label = '';
    }
}