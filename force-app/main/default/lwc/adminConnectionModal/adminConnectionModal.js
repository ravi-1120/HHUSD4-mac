import { LightningElement, api } from 'lwc';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';

export default class AdminConnectionModal extends LightningElement {
    @api modalDataSvc;
    @api connectionData;
    @api isEdit;
    @api systemType;
    @api modalMessageMap;
    @api recordTypeId;
    @api ctrl;
    @api syncSettingsPicklistValues;
    saveNew = false;
    fieldErrors = [];
    recordErrors = [];
    options = [];
    syncSettings = [];
    
    connectedCallback() {
        this.syncSettings = this.connectionData.syncSettings;
    }

    handleChange(e) {
        this.syncSettings = e.detail.value;
    }

    closeDialog() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    validateRequiredFields() {
        this.resetErrors();
        const fieldLabels = [];
        this.template.querySelectorAll("[data-validity]").forEach(element => {
            element.setCustomValidity('');
            if (!element.checkValidity()) {
                element.setCustomValidity(this.modalMessageMap.requiredFieldErrorLabel);
                fieldLabels.push({fieldLabel: element.label});
            }
            element.reportValidity();
        });
        return fieldLabels;
    }

    resetErrors() {
        this.fieldErrors = [];
        this.recordErrors = [];
    }

    save() {
        const fieldLabels = this.validateRequiredFields();
        if(fieldLabels?.length){
            this.fieldErrors = fieldLabels;
        } else if(this.isEdit) {
            this.update();
        }else {
            const systemId = this.template.querySelector('[data-id="systemId"]')?.value ?? '';
            const recordInput = this.ctrl.constructSaveCrmBody(systemId, this.recordTypeId, this.syncSettings);
            createRecord(recordInput)
                .then(connection => {
                    this.saveToMC(this.saveNew, connection.id, systemId);
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

    update() {
        const systemId = this.template.querySelector('[data-id="systemId"]')?.value ?? '';
        const recordInput = this.ctrl.constructUpdateCrmBody(systemId, this.connectionData.sfId, this.syncSettings);
        updateRecord(recordInput)
            .then(() => {
                this.saveToMC(false, this.connectionData.sfId, systemId);
            })
            .catch(() => {
                this.recordErrors = [this.modalMessageMap.genericPopoverErrorLabel];
            });
    }

    saveToMC(saveAndNew, connectionId, systemId) {
        const elements = [];
        this.ctrl.modalFields.forEach(field => {
            const element = this.template.querySelector(`[data-id="${field}"]`);
            if(element) {
                elements.push(element);
            }
        })
        const body = this.ctrl.constructSaveMcBody(elements);
        this.modalDataSvc.upsertCredential(this.systemType, body).then(response => {
            if(response === '' && saveAndNew) {
                this.dispatchEvent(new CustomEvent('savenew', { detail: {sfId: connectionId, systemId} }));
            } else if(response === '') {
                this.dispatchEvent(new CustomEvent('save', { detail: {sfId: connectionId, systemId} }));
            } else {
                this.recordErrors = [this.modalMessageMap.genericPopoverErrorLabel];
            }
        });

    }

    get modalTitle() {
        return this.isEdit?  this.modalMessageMap.editConnectionTitle : this.modalMessageMap.newConnectionTitle ;
    }
}