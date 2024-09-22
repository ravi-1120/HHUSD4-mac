import VeevaPageController from 'c/veevaPageController';
import isInUse from '@salesforce/apex/VeevaScientificInterest.isInUse';

export default class ScientificInterestController extends VeevaPageController {
    constructor(dataSvc, userInterface, messageSvc, metaStore, appMetricsSvc) {
        super(dataSvc, userInterface, messageSvc, metaStore, appMetricsSvc);
        
        this.messageSvc.loadVeevaMessageCategories(['MEDICAL']);
    }

    async save(value = {}) {
        if(this.hasProductChanged() || this.hasDetailGroupChanged()) {
            const isUsed = await isInUse({scientificInterestId: this.id});
            if(isUsed) {
                const noUpdateMessage = await this.getNoUpdateMessage();
                this.addRecordError(noUpdateMessage);
                const errors = { recordErrors: this._recordErrors, fieldErrors: this.fieldErrors };
                return Promise.reject(errors);;
            }
        }
        this.clearErrors();
        return super.save(value);
    }

    hasProductChanged() {
        return this.record.old.Product_vod__c && this.record.fields.Product_vod__c?.value !== this.record.old.Product_vod__c;
    }

    hasDetailGroupChanged() {
        return this.record.old.Detail_Group_vod__c && this.record.fields.Detail_Group_vod__c?.value !== this.record.old.Detail_Group_vod__c;
    }

    async getNoUpdateMessage() {
        const noUpdateMessage = await this.getMessageWithDefault('NO_UPDATE_FIELD', 'MEDICAL', '{0} can not be updated.');
        let label = '';
        if(this.hasProductChanged()) {
            label = this.objectInfo.getFieldInfo('Product_vod__c').label;
        } else {
            label = this.objectInfo.getFieldInfo('Detail_Group_vod__c').label;
        }
        return noUpdateMessage.replace('{0}', label);
    }
}