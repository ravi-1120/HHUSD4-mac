import PicklistController from 'c/picklistController'
import LOCALE from '@salesforce/i18n/locale';
import documentedInterestExpirationDateController from './documentedInterestExpirationDateController.html';

export default class DocumentedInterestExpirationDateController extends PicklistController {
    _expirationDate;
    _previousExpirationDate;

    initTemplate() {
        this.template = documentedInterestExpirationDateController;
        this.excludeNone = true;
        this.editable = true;

        return super.initTemplate();
    }

    track(element, funcName) {
        this.pageCtrl.track('Scientific_Interest_vod__c', element, funcName);
    }

    get disabled() {
        return !this.meta.editable || this.pageCtrl.isNew || (!this.pageCtrl.isNew && !this.pageCtrl.isEdit);
    }

    set selected(value) {
        if (this.pageCtrl.getRenewalRecord()) {
            this.pageCtrl.setRenewalRecord(null);
            this.pageCtrl.setFieldValue('Expiration_Date_vod__c', this._previousExpirationDate.toISOString());
        }

        if(value === 'renew') {
            const currentExpireDate = this.data?.fields.Expiration_Date_vod__c;
            this._previousExpirationDate = currentExpireDate;
            const currentExpireDateValue = this.getUTCDate(currentExpireDate.value);
            const futureExpireDate = new Date(currentExpireDateValue.getTime());
            futureExpireDate.setMonth(futureExpireDate.getMonth() + this.expirationDuration);
            const renewalRecord = this._buildRenewalRecord(futureExpireDate);
            this.pageCtrl.setRenewalRecord(renewalRecord);

            const today = new Date();
            const yesterday = today.setDate(today.getDate() - 1);
            this.pageCtrl.setFieldValue('Expiration_Date_vod__c', new Date(yesterday).toISOString());
        } else if(value === 'expire') {
            const today = new Date();
            this.pageCtrl.setFieldValue('Expiration_Date_vod__c', today.toISOString());
        } else if(value === 'noExpirationDate') {
            this.pageCtrl.setFieldValue('Expiration_Date_vod__c', null);
        }
    }

    _buildRenewalRecord(futureExpireDate) {
        const {record, objectInfo} = this.pageCtrl;
        const createableRecordValues = record.getCreatableValues(objectInfo);
        createableRecordValues.Expiration_Date_vod__c = futureExpireDate.toISOString();
        return createableRecordValues;
    }

    async options() {
        await this.intializeOptions();
        return this.buildExpirationControlOptions();
    }

    buildExpirationControlOptions() {
        const options = {values: []};
        if((this.data?.isNew && !this._controllingVal) || (!this.expirationDuration && !this.data.fields.Expiration_Date_vod__c.value)) {
            const option = {
                label: this.noExpirationMessage,
                value: 'noExpirationDate',
                validFor: [],
              };

              options.values.push(option);

              if(!this.data?.isNew) {
                options.values.push({label: this.expireTodayMessage, value: 'expire'});
              }
        } else if(this.data?.isNew && this._controllingVal) {
            options.values.push({
                label: Intl.DateTimeFormat(LOCALE, { dateStyle: 'long'}).format(this._expirationDate),
                value: this._expirationDate.toISOString()
            });
        } else {
            const today = new Date();
            const renewedExpirationDate = today.setMonth(today.getMonth() + this.expirationDuration);
            const formattedExpirationDate = Intl.DateTimeFormat(LOCALE, {dateStyle: 'long'}).format(new Date(renewedExpirationDate));

            options.values.push({
                label: this.currentExpirationMessage.replace('{0}', Intl.DateTimeFormat(LOCALE, { dateStyle: 'long'}).format(this._expirationDate)),
                value: this._expirationDate.toISOString()
            });
            options.values.push({
                label: this.renewMessage.replace('{0}', formattedExpirationDate),
                value: 'renew'
            });
            options.values.push({
                label: this.expireTodayMessage,
                value: 'expire'
            });
        }
        return options;
    }

    async getSelectedOrDefaultValue() {
        if(this.data?.fields.Expiration_Date_vod__c?.value) {
            this._expirationDate = this.getUTCDate(this.data.fields.Expiration_Date_vod__c.value);
        } else if(this._controllingVal) {
            await this.fetchExpirationDate();
            this.picklists = null;
        }

        if (this.data?.isNew && !this._controllingVal || !this._expirationDate) {
            this.picklists = null;
            return 'noExpirationDate';
        }
        return this._expirationDate.toISOString();
    }

    getLabelForValue(value) {
        if(value === 'noExpirationDate') {
            return value;
        }
        return Intl.DateTimeFormat(LOCALE, { dateStyle: 'long'}).format(this._expirationDate);
    }

    getUTCDate(dateString) {
        let date = dateString;
        if(dateString.indexOf('T') > 0) {
            date = dateString.substring(0, dateString.indexOf('T'));
        }
        return new Date(`${date}T00:00:00`);
    }

    async intializeOptions() {
        if(!this.initialized) {
            await this.fetchMessages();
            this.expirationDuration = await this.fetchExpirationDuration(this.data.fields.Scientific_Interest_vod__c.value);
            this._expirationDate = this.data.fields.Expiration_Date_vod__c.value ? this.getUTCDate(this.data.fields.Expiration_Date_vod__c.value) : null;
            this.initialized = true;
        }
    }

    async fetchMessages() {
        this.noExpirationMessage = await this.pageCtrl.getMessageWithDefault('NO_EXPIRATION', 'MEDICAL', 'No Expiration');
        this.renewMessage = await this.pageCtrl.getMessageWithDefault('RENEW_TO', 'MEDICAL', 'Renew to {0}');
        this.currentExpirationMessage = await this.pageCtrl.getMessageWithDefault('CURRENT_EXPIRATION', 'MEDICAL', 'Current Expiration {0}');
        this.expireTodayMessage = await this.pageCtrl.getMessageWithDefault('EXPIRE_TODAY', 'MEDICAL', 'Expire today')
    }

    async fetchExpirationDuration(scientificInterestId) {
        const expirationDateRecord = await this.pageCtrl.uiApi.getRecord(scientificInterestId, ['Scientific_Interest_vod__c.DI_Expiration_Duration_vod__c']);

        return expirationDateRecord?.fields?.DI_Expiration_Duration_vod__c?.value;
    }

    async fetchExpirationDate() {
        const t = this;

        this.expirationDuration = await this.fetchExpirationDuration(this.controllingValue);
        if(this.expirationDuration) {
            const today = new Date();
            const expDate = today.setMonth(today.getMonth() + this.expirationDuration);

            const calculatedExpirationDate = new Date(expDate);
            
            t._expirationDate = calculatedExpirationDate;
            t.pageCtrl.setFieldValue('Calculated_Expiration_Date_vod__c', calculatedExpirationDate.toISOString())
        }
    }
}