import VeevaPageController from 'c/veevaPageController';
import VeevaConstant from 'c/veevaConstant';
import MedicalInsightRecord from 'c/medicalInsightRecord';
import ACCOUNT_FIELD from '@salesforce/schema/Medical_Insight_vod__c.Account_vod__c'
import DATE_FIELD from '@salesforce/schema/Medical_Insight_vod__c.Date_vod__c';
import STATUS_FIELD from '@salesforce/schema/Medical_Insight_vod__c.Status_vod__c';
import UNLOCK_FIELD from '@salesforce/schema/Medical_Insight_vod__c.Unlock_vod__c';
import getUserRecordAccess from "@salesforce/apex/UserRecordAccessVod.getUserRecordAccess";
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class MedicalInsightController extends VeevaPageController {
    
    constructor(dataSvc, userInterface, messageSvc, metaStore, appMetricsSvc) {
        super(dataSvc, userInterface, messageSvc, metaStore, appMetricsSvc);
        
        this.messageSvc.loadVeevaMessageCategories(['Medical']);
    }

    addDefaultFieldValues(state) {
        super.addDefaultFieldValues(state);
        if (this.record.fields[DATE_FIELD.fieldApiName] && !this.record.rawValue(DATE_FIELD.fieldApiName)) {
            this.setFieldValue(DATE_FIELD.fieldApiName, this.getCurrentISODateString());
        }
    }

    async getHeaderButtons() {
        let buttons = super.getHeaderButtons();
        if (this.record.isSubmitted) {
            if (this._isUnlockable()) {
                buttons.push({ name: 'Unlock', standard: true });
            }
        } 
        let hasRecordDeleteAccess = false;
        let hasRecordEditAccess = false;
        const userRecordAccess = await getUserRecordAccess({ 'recordId': this.record.id});
        if (userRecordAccess){
            hasRecordDeleteAccess = userRecordAccess.HasDeleteAccess;
            hasRecordEditAccess = userRecordAccess.HasEditAccess;
        }
        buttons = this.filterDeleteButton(buttons, hasRecordDeleteAccess);
        buttons = this.filterEditButton(buttons, hasRecordEditAccess);
        return buttons;
    }

    toVeevaRecord(value) {
        return value instanceof MedicalInsightRecord ? value : new MedicalInsightRecord(value);
    }

    filterDeleteButton(buttons, hasRecordDeleteAccess) {
        let filteredButtons = buttons;
        if (buttons.length && (this.record.isLocked || !hasRecordDeleteAccess)) {
            filteredButtons = buttons.filter(btn => btn.name !== 'Delete');
        }
        return filteredButtons;
    }

    filterEditButton(buttons, hasRecordEditAccess) {
        let filteredButtons = buttons;
        if (buttons.length && (this.record.isLocked || !hasRecordEditAccess)) {
            filteredButtons = buttons.filter(btn => btn.name !== 'Edit');
        }
        return filteredButtons;
    }

    isButtonAvailable(btnName) {
        let available = super.isButtonAvailable(btnName);
        if (btnName === VeevaConstant.SAVE_VOD) {
            available = true;
        }
        return available;
    }

    isSubmitButtonAvailable(){
        let canSubmit = super.isSubmitButtonAvailable();
        if (canSubmit) {
            canSubmit = this.objectInfo.updateableField(STATUS_FIELD.fieldApiName);
        }
        return canSubmit;
    }

    getPageRefForSaveAndNew(id, pageState) {
        const pageRef = super.getPageRefForSaveAndNew(id, pageState);
        let defaultFieldValues = {};
        if (pageState.defaultFieldValues) {
            defaultFieldValues = JSON.parse(pageState.defaultFieldValues);
        }
        defaultFieldValues[ACCOUNT_FIELD.fieldApiName] = { value: this.record.value(ACCOUNT_FIELD.fieldApiName).value };
        Object.assign(pageRef.state, {
            defaultFieldValues
        })
        return pageRef;
    }

    async save(value) {
        const saveValue = value || {};
        const data = saveValue.data || this.getChanges();

        if (!saveValue.submit && !data[VeevaConstant.FLD_STATUS_VOD]) { 
            data[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SAVED_VOD;
        }

        return super.save({
            submit: saveValue.submit,
            data
        });
    }

    setSubmit(data) {
        super.setSubmit(data);
        // The classic CRM pass true of Override_Lock_vod__c when submit the medical insight. So align this logic to Lightning.
        if (this.action === 'New' || this.action === 'Edit') {
            data.Override_Lock_vod__c = true;
        } 
    }

    unlock() {
        return super.unlock({
            type: this.objectApiName,
            Id: this.id,
            Status_vod__c: VeevaConstant.SAVED_VOD,
            Override_Lock_vod__c: true
        });
    }

    _isUnlockable() {
        return this.objectInfo.updateableField(UNLOCK_FIELD.fieldApiName) && this._statusUpdateable();
    }

    _statusUpdateable() {
        return this.objectInfo.updateableField(STATUS_FIELD.fieldApiName);
    }

    useFlowNavAfterNew(saveAndNew, pageReferenceState) {
        const inContextOfRef = pageReferenceState && pageReferenceState.inContextOfRef;
        const isEditCallContext = inContextOfRef && 
            inContextOfRef.attributes.objectApiName === 'Call2_vod__c' && inContextOfRef.attributes.actionName === 'edit';

        return !saveAndNew && !isEditCallContext;
    }
    
    getCurrentISODateString() {
        // create date string using user's SF time zone and in US locale format (MM/DD/YYYY)
        const userCurrentDate = new Date().toLocaleDateString("en-US", { timeZone: TIME_ZONE });
        const userCurrentDateComponents = userCurrentDate.split("/");
        const month = `0${userCurrentDateComponents[0]}`.slice(-2);
        const day = `0${userCurrentDateComponents[1]}`.slice(-2);
        const year = userCurrentDateComponents[2];
        return `${year}-${month}-${day}`;
    }
}