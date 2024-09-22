import VeevaPageController from 'c/veevaPageController';
import DocumentedInterestCategoryController from "c/documentedInterestCategoryController";
import DocumentedInterestExpirationDateController from 'c/documentedInterestExpirationDateController';
import SCIENTIFIC_INTEREST_FIELD from '@salesforce/schema/Documented_Interest_vod__c.Scientific_Interest_vod__c'
import INTEREST_CATEGORY_FIELD from '@salesforce/schema/Documented_Interest_vod__c.Interest_Category_vod__c'

export default class DocumentedInterestController extends VeevaPageController {
    _renewalRecord = null;

    constructor(dataSvc, userInterface, messageSvc, metaStore, appMetricsSvc) {
        super(dataSvc, userInterface, messageSvc, metaStore, appMetricsSvc);
        
        this.messageSvc.loadVeevaMessageCategories(['MEDICAL']);
    }

    setRenewalRecord(renewalRecord) {
        this._renewalRecord = renewalRecord;
    }

    getRenewalRecord() {
        return this._renewalRecord;
    }

    initItemController(meta, record) {
        if(this.isNew) {
            this.setFieldValue('Status_vod__c', 'New_vod');
        }
        if (meta.field) {
            const field = this.objectInfo.getFieldInfo(meta.field);
            switch (meta.field) {
                case INTEREST_CATEGORY_FIELD.fieldApiName:
                    field.controllerName = SCIENTIFIC_INTEREST_FIELD.fieldApiName;
                    return new DocumentedInterestCategoryController(meta, this, field, record);
                case 'Expiration_Date_vod__c':
                    return new DocumentedInterestExpirationDateController(meta, this, field, record);
                default:
                    break;
            }
        }
        if(this.isEdit) {
            const metaUnproxied = JSON.parse(JSON.stringify(meta));
            metaUnproxied.disabled = true;
            if(metaUnproxied.field === 'Verbal_Acknowledgment_vod__c') {
                metaUnproxied.editable = false;
            }
            return super.initItemController(metaUnproxied, record);
        }
        return super.initItemController(meta, record);
    }

    addDefaultFieldValues(state, record) {
        const recordToUpdate = record || this.record;

        if (state.inContextOfRef?.state?.defaultFieldValues) {
          const values = state.inContextOfRef.state.defaultFieldValues;
          Object.entries(values).forEach(([key, value]) => {
            if (recordToUpdate.fields[key] || this.objectInfo.getFieldInfo(key)) {
              recordToUpdate.fields[key] = value;
              if (key === 'RecordTypeId' && value && value.value) {
                recordToUpdate.recordTypeId = value.value;
              }
            } else {
              recordToUpdate[key] = value;
            }
          });
        }
    }

    async getEditPageTitle() {
        if(this.objectInfo.fields.Expiration_Date_vod__c.updateable) {
            return this.getMessageWithDefault('MANAGE_DOCUMENTED_INTEREST', 'MEDICAL', 'Manage Documented Interest');
        }
        return this.getMessageWithDefault('DOCUMENTED_INTEREST', 'MEDICAL', 'Documented Interest');
    }

    async getPicklistValues(field, recordTypeId) {
        if(field === 'Interest_Category_vod__c') {
            if(this.record.rawValue(SCIENTIFIC_INTEREST_FIELD.fieldApiName)) {
                const value = this.record.rawValue(SCIENTIFIC_INTEREST_FIELD.fieldApiName);
                return this.uiApi.getRecord(value, ['Scientific_Interest_vod__c.Interest_Category_vod__c']).then(record => {
                    const displayValues = record.fields?.Interest_Category_vod__c?.displayValue?.split(';') || [];
                    const rawValues = record.fields?.Interest_Category_vod__c?.value?.split(';') || [];
                    const values = [];
                    for(let i = 0; i < displayValues.length; i++) {
                        values.push(
                            { label: displayValues[i], value: rawValues[i], validFor: [1]}
                        );
                    }
                    return { controllerValues: {[value] : 1}, values };
                });
            }

            const queryRecordTypeId = recordTypeId;
            const picklistsMap = await this.uiApi.getPicklistValuesMap(queryRecordTypeId, this.objectApiName);
            picklistsMap[field].controllerValues = { 'Scientific_Interest_vod__c': 1};
            picklistsMap[field].values.map(v => v.validFor.push(1));
            return (picklistsMap && picklistsMap[field]) || { values: [] };
        }
        return super.getPicklistValues(field, recordTypeId);
    }

    async getModalButtons() {
        const buttonPromises = [this.createCancelButton()];

        const expirationDateUpdatable = this.objectInfo.fields.Expiration_Date_vod__c.updateable;
        if (this.action === 'New' || (this.action === 'Edit' && expirationDateUpdatable)) {
            buttonPromises.push(this.createSaveButton());
        }

        return Promise.all(buttonPromises);
    }

    async save(value = {}) {
        const submitted = 'Submitted_vod';
        this.setFieldValue('Status_vod__c', submitted);

        return super.save(value)
          .then(savedRecord => { 
            if (this._renewalRecord) {
                this._renewalRecord.Status_vod__c = submitted;
                const renewalSave = super.save({
                    submit: value.submit, 
                    data: this._renewalRecord
                });
                this._renewalRecord = null;
                return renewalSave;
            }
            return savedRecord;
          });
    }
}