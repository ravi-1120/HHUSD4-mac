import { api, LightningElement } from 'lwc';
import canSelectClmCallRecordType from '@salesforce/apex/S4LRecordTypeSelectorController.canSelectClmCallRecordType';
import getEditableSelectorConfig from '@salesforce/apex/S4LRecordTypeSelectorController.getEditableSelectorConfig';
import getDefaultRecordType from '@salesforce/apex/S4LRecordTypeSelectorController.getDefaultRecordType';

export default class S4lRecordTypeSelector extends LightningElement {

    @api labels;
    @api account;

    loading = true;
    selected = null;

    @api checkValidity() {
        if(this.editable) {
            const dropdown = this.template.querySelector('lightning-combobox');
            if(!this.selected) {
                dropdown.setCustomValidity(this.labels.thisFieldIsRequired);
            } else {
                dropdown.setCustomValidity('');
            }
            return dropdown.reportValidity();
        } 
            return this.selected;
        
    }

    async connectedCallback() {
        this.editable = await canSelectClmCallRecordType();
        if(this.editable) {
            // get all the available record types
            const selectorResult = await getEditableSelectorConfig({accountId:this.account});
            this.loadPicklist(selectorResult);
        } else {
            // get default record type
            const defaultRecordType = await getDefaultRecordType({accountId:this.account});
            this.loadLabel(defaultRecordType);
        }
    }

    loadPicklist (selectorResult) {
        if(selectorResult && selectorResult.recordTypes && selectorResult.recordTypes.length) {
            const options = [];
            for(const rt of selectorResult.recordTypes) {
                options.push({
                    'label': rt.name,
                    'value': rt.id
                });
            }
            this.recordTypeLabel = selectorResult.label;
            this.dropdownOptions = options;
            this.loading = false;

            this.selected = selectorResult.recordType.id;
            this.dispatchSelection();
        } else {
            this.handleCannotRecordCall();
        }
    }

    loadLabel (defaultRecordType) {
        if(defaultRecordType && defaultRecordType.recordType && defaultRecordType.recordType.id) {
            this.recordTypeLabel = defaultRecordType.label;
            this.defaultRecordTypeLabel = defaultRecordType.recordType.name;
            this.loading = false;

            this.selected = defaultRecordType.recordType.id;
            this.dispatchSelection();
        } else {
            this.handleCannotRecordCall();
        }
    }

    handleChange = function(e) {
        this.selected = e.detail.value;
        this.dispatchSelection();
        this.checkValidity();
    }

    handleCannotRecordCall = function() {
        this.dispatchEvent(new CustomEvent('failure'));
    }

    dispatchSelection = function () {
        this.dispatchEvent(new CustomEvent('select', {
            detail:{selected: this.selected}
        }));
    }

}