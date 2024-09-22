import { LightningElement, api, track} from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';

export default class AdminMappingModal extends LightningElement {
    @api modalMessageMap;
    @api ctrl;
    @api recordTypeId;
    @api modalTitle;
    @api crmFieldLabel;
    @api connectionFieldLabel;
    @api crmLookupFieldPlaceholder;
    @track disableTextField = true;

    saveNew = false;
    crmFieldValue;
    vaultFieldValue;
    fieldErrors = [];
    recordErrors = [];

    closeDialog() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    toggleDisableTextField(value) {
        this.disableTextField = value;
    }

    handleCrmSearchSelection(event) {
        this.crmFieldValue = event.detail.id;
        this.ctrl.connectionLookupCtrl.disabled = false;
        this.ctrl.connectionLookupCtrl.selectedCrmFieldType = event.detail.type;
        this.template.querySelectorAll('c-veeva-lookup')[1]?.handleClearLookup();
        if(this.ctrl.connectionLookupCtrl.showTextField) {
            this.toggleDisableTextField(false);
        }
    }

    handleVaultSearchSelection(event) {
        this.vaultFieldValue = event.detail.id;
    }

    handleTextOnChange(event) {
        this.vaultFieldValue = event.detail.value;
    }

    handleClearCrmValue() {
        this.crmFieldValue = '';
        this.template.querySelectorAll('c-veeva-lookup')[1]?.handleClearLookup();
        this.ctrl.connectionLookupCtrl.disabled = true;
        this.ctrl.connectionLookupCtrl.selectedCrmFieldType = '';
        if(this.ctrl.connectionLookupCtrl.showTextField) {
            this.template.querySelector('lightning-input[data-id=connectionTextField]').value = '';
            this.toggleDisableTextField(true);
        }
    }

    handleClearVaultValue() {
        this.vaultFieldValue = '';
    }

    save() {
        const fieldLabelsObj = this.validateFields();
        if(fieldLabelsObj?.length){
            this.fieldErrors = fieldLabelsObj;
        } else {
            const recordInput = this.ctrl.constructSaveBody(this.crmFieldValue, this.vaultFieldValue, this.recordTypeId);
            createRecord(recordInput)
                .then(() => {
                    if(this.saveNew) {
                        this.dispatchEvent(new CustomEvent('savenew', { detail: this.ctrl.mapping }));
                    } else {
                        this.dispatchEvent(new CustomEvent('save', { detail: this.ctrl.mapping }));
                    }
                })
                .catch(() => {
                    this.recordErrors = [this.modalMessageMap.genericPopoverErrorLabel];
                })
                .finally(() => {
                    this.saveNew = false;
                });
        }
    }

    saveAndNew() {
        this.saveNew = true;
        this.save();
    }

    validateFields() {
        this.fieldErrors = [];
        this.recordErrors = [];
        const fieldLabelsObj = [];
        if(!this.crmFieldValue) {
            fieldLabelsObj.push({fieldLabel: this.crmFieldLabel});
        }
        if(!this.vaultFieldValue || this.ctrl?.connectionLookupCtrl?.isDuplicateField(this.vaultFieldValue)) {
            fieldLabelsObj.push({fieldLabel:this.connectionFieldLabel});
        }
        this.template.querySelectorAll('c-veeva-lookup').forEach(element => {
            element.checkValidity();
        });
        return fieldLabelsObj;
    }
}