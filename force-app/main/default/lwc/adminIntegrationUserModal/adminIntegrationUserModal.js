import { LightningElement, api } from 'lwc';

export default class AdminIntegrationUserModal extends LightningElement {
    @api modalDataSvc;
    @api userData;
    @api modalTitle;
    @api orgId;
    @api systemType;
    @api modalMessageMap;
    fieldErrors = [];
    recordErrors = [];

    closeDialog() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    async save() {
        const body = new URLSearchParams({
            systemId: this.orgId,
            username: this.template.querySelector('lightning-input[data-id=username]').value,
            password: this.template.querySelector('lightning-input[data-id=password]').value,
            isSandbox: this.template.querySelector('lightning-input[data-id=sandbox]').checked
        }).toString();
        const fieldLabels = this.validateRequiredFields();
        if(fieldLabels?.length){
            this.fieldErrors = fieldLabels;
        } else {
            const saveResponse = await this.modalDataSvc.upsertCredential(this.systemType, body);
            if(saveResponse === '') {
                this.dispatchEvent(new CustomEvent('save'));
            } else {
                this.recordErrors = [this.modalMessageMap.genericPopoverErrorLabel];
            }
        }
    }

    validateRequiredFields() {
        this.fieldErrors = [];
        this.recordErrors = [];
        const fieldLabels = [];
        this.template.querySelectorAll('.validation').forEach(element => {
            element.setCustomValidity('');
            if (!element.checkValidity()) {
                element.setCustomValidity(this.modalMessageMap.requiredFieldErrorLabel);
                fieldLabels.push({fieldLabel: element.label});
            }
            element.reportValidity();
        });
        return fieldLabels;
    }
}