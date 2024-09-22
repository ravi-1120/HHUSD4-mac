import VeevaPageController from 'c/veevaPageController';
import MedicalInquiryRecord from "c/medicalInquiryRecord";
import MedInqConstant from "c/medInqConstant";
import ZvodDeliveryMethodController from "c/zvodDeliveryMethodController";
import MpiSectionController from "c/mpiSectionController";
import VeevaConstant from 'c/veevaConstant';
import getSentEmailRecordTypeId from '@salesforce/apex/MedInqController.getSentEmailRecordTypeId';
import VeevaLayoutService from 'c/veevaLayoutService';
import AssignToUserController from "c/assignToUserController";
import getUserRecordAccess from "@salesforce/apex/UserRecordAccessVod.getUserRecordAccess";
import MedInqMoreActionsCtrl from 'c/medInqMoreActionsCtrl';
import getVeevaSettings from '@salesforce/apex/VeevaCustomSettingsService.getVeevaSettings';
import MedicalInquiryLocationController from 'c/medicalInquiryLocationController';
import ACCOUNT from '@salesforce/schema/Medical_Inquiry_vod__c.Account_vod__c';

VeevaConstant.OBJECT_ICONS.Medical_Inquiry_vod__c = 'custom:custom22';

export default class MedicalInquiryController extends VeevaPageController {

    veevaSettings = {};

    constructor(dataSvc, userInterface, messageSvc, metaStore, appMetricsSvc) {
        super(dataSvc, userInterface, messageSvc, metaStore, appMetricsSvc);
        
        this.messageSvc.loadVeevaMessageCategories(['MEDICAL_INQUIRY']);
    }

    initItemController(meta, record) {
        if (meta.field) {
            switch (meta.field) {
                case MedInqConstant.ZVOD_DELIVERY_METHOD:
                    return new ZvodDeliveryMethodController(meta, this, record);
                case "Assign_To_User_vod__c":
                    return new AssignToUserController(meta, this, this.objectInfo.getFieldInfo(meta.field), record);
                case MedInqConstant.LOCATION:
                    if (this.isChildAccountSupportEnabled() && this.record.isNew) {
                        return new MedicalInquiryLocationController(meta, this, this.objectInfo.getFieldInfo(meta.field), record);
                    }
                    break;
                    
                default:
                    break;
            }
        }
        return super.initItemController(meta, record);
    }

    initTemplate(ctrl) {
        switch (ctrl.fieldApiName) {
            // render as text, not checkbox
            case MedInqConstant.DISCLAIMER:
            case MedInqConstant.ZVOD_DISCLAIMER:
                ctrl.veevaText = true;
                return ctrl;

            case MedInqConstant.ACCOUNT:
                ctrl.editable = this.isAccountFieldEditable(ctrl);
                return super.initTemplate(ctrl);

            case VeevaConstant.FLD_SIGNATURE_DATE_VOD:
                ctrl.editable = false;
                this._sigDateOnLayout = true;
                return super.initTemplate(ctrl);

            case MedInqConstant.GROUP_IDENTIFIER:
                ctrl.editable = false;
                return super.initTemplate(ctrl);

            case MedInqConstant.PRODUCT:
                ctrl.editable = Boolean(ctrl.editable && !ctrl.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD));
                return super.initTemplate(ctrl);

            case MedInqConstant.INQUIRY_TEXT:
                if (ctrl.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD)) {
                    ctrl.editable = false;
                }
                return super.initTemplate(ctrl);

            case MedInqConstant.DELIVERY_METHOD:
                ctrl.editable = Boolean(ctrl.editable && !ctrl.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD));
                return super.initTemplate(ctrl);

            case MedInqConstant.LOCATION:
                if (this.isChildAccountSupportEnabled()) {
                    ctrl.editable = Boolean((!ctrl.data.isFieldSet(MedInqConstant.LOCATION) || ctrl.data.isClone) && this.record.isNew);
                } 
                return super.initTemplate(ctrl);

            default:
                return super.initTemplate(ctrl);
        }
    }

    async addDefaultFieldValues(state, record) {
        await super.addDefaultFieldValues(state, record);
    
        const isAccountViewPageSource = state?.inContextOfRef?.type === "standard__recordPage" &&
                                  state?.inContextOfRef?.attributes?.objectApiName === 'Account';
    
        const isAccountFieldSet = this.record.rawValue(ACCOUNT.fieldApiName);
        const recordId = state?.inContextOfRef?.attributes?.recordId;
    
        if (!isAccountViewPageSource || isAccountFieldSet || !recordId) {
            return;
        }
    
        try {
            const accountRecord = await this.uiApi.getRecord(recordId, [`Account.Name`], true);
            const isValidAccountRecord = accountRecord && accountRecord.id && accountRecord.fields.Name.value;
            const accountInfo = this.objectInfo.getFieldInfo(ACCOUNT.fieldApiName);
    
            if (!isValidAccountRecord || !accountInfo?.referenceToInfos?.length) {
                return;
            }
    
            const reference = {
                name: accountRecord.fields.Name.value,
                apiName: accountInfo.referenceToInfos[0].apiName,
                id: accountRecord.id,
            };
            this.record.setFieldValue(ACCOUNT.fieldApiName, accountRecord.id, reference);
    
        } catch (error) {
            // Do nothing
        }
    }
    
    async initData() {
        this.veevaSettings = await getVeevaSettings({ settingFieldNames: ['Enable_Child_Account_vod__c'] });
    }

    async setButtons() {
        const buttons = await this.getModalButtons();
        await this.addMoreActions(buttons);
        this.page.modalButtons = this.setButtonVariant(buttons);
    }

    async getModalButtons() {
        const buttonPromises = [this.createCancelButton()];
        if (this.action === 'New' || this.action === 'Edit') {
            if (this.isButtonAvailable(VeevaConstant.SAVE_VOD)) {
                buttonPromises.push(this.createSaveButton());
            }
            if (await this.isSubmitButtonAvailable()) {
                buttonPromises.push(this.createSubmitButton());
            }
        }

        return Promise.all(buttonPromises);
    }

    getSectionController(meta) {
        const signals = meta.signals || [];
        if (signals.includes("mpi")) {
            return new MpiSectionController(meta, this).initTemplate();
        }
        return super.getSectionController(meta, this);
    }

    async save(val) {
        const value = val || {};
        const data = value.data || this.getChanges();

        if (!value.submit) {
            if (this._mpiChanges && data && data.data) { // mpi array
                data.data.forEach(each => {
                    if (each && !each.Deleted) {
                        each[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SAVED_VOD;
                    }
                })
            }
            else {
                data[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SAVED_VOD;
            }
        }

        return super.save({
            submit: value.submit,
            data
        });
    }

    processLayout(layout) {
        this._isMpi = layout.sections && layout.sections.find(section => VeevaLayoutService.hasSignal(section, 'mpi'));
        if (this.action === 'New') {
            this.processStatusField(layout);
        }
        this.processAddressVodSection(layout.sections);
        return layout;
    }

    processStatusField(layout) {
        if (layout.sections) {
            layout.sections.forEach(section => {
                section.layoutRows.forEach(row => {
                    row.layoutItems.forEach(item => {
                        if (item.field === VeevaConstant.FLD_STATUS_VOD && !item.editableForNew) {
                            this.record.setFieldValue(VeevaConstant.FLD_STATUS_VOD, '');
                        }
                    });
                });
            });
        }
    }

    processAddressVodSection(sections) {
        let deliveryMethod = null;
        let fields = [];
        let requiredFields = [];
        for (let i = sections.length - 1; i >= 0; i--) {
            const section = sections[i];
            if (section.heading === 'Address_vod') {
                // remove the section
                sections.splice(i, 1);
                const items = VeevaLayoutService.getSectionItems(section);
                fields = items.map(x => x.field);
                requiredFields = items.filter(x => x.required).map(x => x.field);
            }
            if (!deliveryMethod) {
                deliveryMethod = VeevaLayoutService.getSectionItems(section).find(x => x.field === MedInqConstant.ZVOD_DELIVERY_METHOD);
                if (deliveryMethod) {
                    deliveryMethod.options = section.signals || [];
                }
            }
        }
        if (deliveryMethod) {
            if (!fields.length) {
                MedInqConstant.NEW_FIELDS.ana.forEach(x => { if (this.objectInfo.getFieldInfo(x) !== null) { fields.push(x); } })
            }
            deliveryMethod.mailFields = fields;
            if (!requiredFields.length) {
                requiredFields = fields.filter(x => MedInqConstant.REQUIRED_NEW_MAIL_FIELDS.includes(x));
            }
            deliveryMethod.requiredMailFields = requiredFields;
        }
        return deliveryMethod;
    }

    toVeevaRecord(value) {
        return value instanceof MedicalInquiryRecord ? value : new MedicalInquiryRecord(value, this.messageSvc, this._isClone);
    }

    setMpiChanges(value) {
        this._mpiChanges = value;
    }

    setMpiInfo(records, mpiFields) {
        this._mpiRecords = records;
        this._mpiFields = mpiFields;
    }

    getChanges() {
        if (this._mpiChanges) {
            return { data: this._mpiChanges, url: 'Medical_Inquiry_vod__c/mpi' };
        }
        return super.getChanges();
    }

    getPageRefAfterSave(data) {
        let mpiPageRef;
        if (this._mpiChanges && data && data.length) {
            mpiPageRef = data.find(x => (x.Id === this.id) && !x.Deleted) || 
                data.find(x => !x.Deleted) || data[0];
        }
        return mpiPageRef || super.getPageRefAfterSave(data);
    }

    processError(data) {
        if (this._mpiRecords && data && data.length === this._mpiRecords.length) {
            const fieldErrors = {};
            data.forEach((each, index) => {
                const mpiRecordId = this._mpiRecords[index].id;
                (each.recordErrors || []).forEach(msg => this.addRecordError(msg));
                Object.entries(each.fieldErrors || {}).forEach(([field, msg]) => {
                    if (this._mpiFields.includes(field)) {
                        fieldErrors[mpiRecordId] = fieldErrors[mpiRecordId] || {};
                        fieldErrors[mpiRecordId][field] = msg;
                    } else {
                        fieldErrors[this.record.id][field] = msg;
                    }
                });
            });
            if (Object.keys(fieldErrors).length) {
                this.fieldErrors = fieldErrors;
            }
            return;
        }
        super.processError(data);
    }

    async validate(value) { // value is an object
        if (this._isMpi && (!this._mpiRecords || this._mpiRecords.length === 0)) {
            return false;
        }
        if (this._sigDateOnLayout && value.submit) {
            if (!this.record.rawValue(VeevaConstant.FLD_SIGNATURE_DATE_VOD)) {
                await this.setRecordError(MedInqConstant.MSG_SIGNATURE_REQUIRED, MedInqConstant.CAT_MEDICAL_INQUIRY, "Signature Date is required");
                return false;
            }
        }
        return super.validate(value);
    }

    toButtonCtrl(btn, record) {
        if (btn.name === MedInqConstant.SEND_EMAIL_VOD) {
            return this.getSendEmailButton(btn, record);
        }
        if (btn.name === MedInqConstant.RECORD_A_CALL_VOD) {
            return this.getRecordACallButton(btn, record);
        }
        if (btn.name === VeevaConstant.CLONE_VOD) {
            return Promise.resolve({ ...btn });
        }
        return btn && btn.ctrl;
    }

    async getSendEmailButton(btn, record) {
        const recordForButton = record || this.record;

        const recordTypeId = await getSentEmailRecordTypeId();
        if (recordTypeId) {
            const ref = {
                type: 'standard__webPage',
                attributes: {
                    url: `/apex/Send_Approved_Email_vod?oType=approvedEmail&location=Medical_Inquiry_vod&Medical_Inquiry_vod__r.Id=${recordForButton.id}`
                }
            };
            return { ...btn, pageRef: ref };
        }
        return null;
    }

    async getRecordACallButton(btn, record) {
        const recordForButton = record || this.record;

        const accountId = recordForButton.rawValue('Account_vod__c');
        if (!accountId) {
            return null;
        }
        const doNotCall = await this.doNotCall(accountId);
        if (!doNotCall) {
            const ref = {
                type: 'standard__webPage',
                attributes: {
                    url: `/apex/Call_New_vod?queryParams=typ=Medical_Inquiry_vod__c%26id=${recordForButton.id}&MedicalInquiryId=${recordForButton.id}`
                }
            };
            return { ...btn, pageRef: ref };
        }
        return null;
    }

    async doNotCall(accountId) {
        if (!accountId) {
            return true;
        }
        const account = await this.uiApi.getRecord(accountId, ['Account.Do_Not_Call_vod__c'], true);
        const values = account.fields.Do_Not_Call_vod__c || {};
        if ('Yes_vod' === values.value) {
            return true;
        }
        return false;
    }

    getDataForClone() {
        const skips = [...MedInqConstant.CLONE_SKIP_FIELDS];
        if (!this._isMpi) {
            skips.push('Product__c');
        }
        const clonedData = super.getDataForClone(skips);    
        clonedData.cloneFromId = this.record.id;
        return clonedData;
    }
    get disableButtonMenu() {
        return true;
    }
    async getHeaderButtons() {
        let buttons = super.getHeaderButtons();
        if (buttons.length && (!this.record.isSubmitted || this._isMpi)) {
            buttons = buttons.filter(x => !MedInqConstant.CUSTOM_BUTTONS.includes(x.name));
        }
        // If a record is submitted
        if (buttons.length && this.record.isSubmitted) {
            // Filter inaccessible custom buttons
            buttons = await Promise.all(buttons.map(btn => this.isButtonAccessible(btn)));
            buttons = buttons.filter(x => x);
        }
        if (this.record.isLocked && this.objectInfo.updateableField("Lock_vod__c")) {
            buttons.push({ name: 'Unlock', standard: true });
        }
        await this.addMoreActions(buttons);
        let hasRecordDeleteAccess = false;
        let hasRecordEditAccess = false;
        const userRecordAccess = await getUserRecordAccess({ 'recordId': this.record.id});
        if (userRecordAccess){
            hasRecordDeleteAccess = userRecordAccess.HasDeleteAccess;
            hasRecordEditAccess = userRecordAccess.HasEditAccess;
        }
        buttons = this.filterDeleteButton(buttons, hasRecordDeleteAccess);
        buttons = this.filterCloneButton(buttons);
        buttons = this.filterEditButton(buttons, hasRecordEditAccess);
        return buttons;
    }

    async isButtonAccessible(button) {
        let btn = button;
        // Check if a button is a custom button
        if (MedInqConstant.CUSTOM_BUTTONS.includes(btn.name)) {
            // Return button if accessible
            btn = await this.toButtonCtrl(btn);
            return (btn || null);
        }
        // Non-custom buttons are assumed to be accessible all times
        return btn;
    }

    filterDeleteButton(buttons, hasRecordDeleteAccess) {
        let btns = buttons;
        // If record is locked or signature date is set
        if (btns.length && (this.record.isLocked || this.record.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD) || !hasRecordDeleteAccess)) {
            // Remove delete button
            btns = btns.filter(btn => btn.name !== 'Delete');
        }
        return btns;
    }

    filterEditButton(buttons, hasRecordEditAccess) {
        let btns = buttons;
        // If record is locked
        if (btns.length && (this.record.isLocked || !hasRecordEditAccess)) {
            // Remove edit button
            btns = btns.filter(btn => btn.name !== 'Edit');
        }
        return btns;
    }

    filterCloneButton(buttons) {
        let btns = buttons;
        // If user does not have create permission for MI
        if (!this.objectInfo.createable) {
            // Remove clone button
            btns = btns.filter(btn => !VeevaConstant.CLONE_VOD.includes(btn.name));
        }
        return btns;
    }

    async isSubmitButtonAvailable() {
        const statusPicklistValues = await this.getPicklistValues(VeevaConstant.FLD_STATUS_VOD, this.record.recordTypeId);
        const isFlsSatisfied = this.objectInfo.getFieldInfo(VeevaConstant.FLD_LOCK_VOD)
            && this.objectInfo.getFieldInfo(VeevaConstant.FLD_STATUS_VOD);

        // If FLS is not satisfied or if Status picklist does not have Submitted option
        if (!isFlsSatisfied || !statusPicklistValues.values.find(el => el.value === VeevaConstant.SUBMITTED_VOD)) {
            // Remove submit button
            return false;
        }
        return super.isSubmitButtonAvailable();
    }

    setSubmit(data) {
        if (this._mpiChanges && data && data.data) { // mpi array
            data.data.forEach(each => {
                if (each && !each.Deleted) {
                    each[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SUBMITTED_VOD;
                }
            })
        }
        else {
            super.setSubmit(data);
        }
    }

    unlock() {
        let saveData;
        if (this._mpiRecords && this._mpiRecords.length > 0) {
            const dataArr = this._mpiRecords.map(record => ({
                type: this.objectApiName,
                Id: record.id,
                Lock_vod__c: false
            }));
            saveData = {
                "data": dataArr,
                "url": 'Medical_Inquiry_vod__c/mpi'
            };
        }
        return super.unlock(saveData);
    }

    _getWatchKey(fieldName, recordId) {
        let watchKey = fieldName;
        if (this._mpiRecords && this._mpiFields.includes(fieldName)) {
            watchKey = `${recordId}_${fieldName}`;
        } 
        return watchKey;
    }

    async processForLDSCache(data){
        if (this._mpiChanges && data && data.data) {
            const recordIds = data.data
                .filter(record=>record && record.Id && !record.Deleted)
                .map(record=>({recordId: record.Id}));
            if (recordIds && recordIds.length > 0) {
                this.notifyLDSCache(recordIds);
            }
        } else if (data && data.data) {
            const recordIds = data.data
                .filter(record => record && record.Id && !record.Deleted && record.Lock_vod__c === false)
                .map(record => ({ recordId: record.Id }));
            if (recordIds && recordIds.length > 0) {
                this.notifyLDSCache(recordIds);
            }
        } else {
            super.processForLDSCache(data);
        }
    }

    useFlowNavAfterNew(saveAndNew, pageReferenceState) {
        const inContextOfRef = pageReferenceState && pageReferenceState.inContextOfRef;
        const isEditCallContext = inContextOfRef && 
            inContextOfRef.attributes.objectApiName === 'Call2_vod__c' && inContextOfRef.attributes.actionName === 'edit';

        return !saveAndNew && !isEditCallContext && !this.isClone;
    }
    checkSignatureFields() {
        let canShowRequestSig = false;
        if (this.page.layout) {
            const dateOnLayout = this.page.layout.layoutFields.Signature_Date_vod__c;
            const sigDateFls = this.objectInfo.updateableField("Signature_Date_vod__c");
            const sigFls = this.objectInfo.updateableField("Signature_vod__c");
            const sigShareLinkFls = this.objectInfo.updateableField("Signature_Captured_Share_Link_vod__c");
            const sigQrFls = this.objectInfo.updateableField("Signature_Captured_QR_Code_vod__c");
            canShowRequestSig = (sigDateFls && dateOnLayout && sigFls) && (sigShareLinkFls || sigQrFls);
        }
        return canShowRequestSig;
    }

    async getMoreActions() {
        const moreActions = [];
        if (this.checkSignatureFields() && !this.record.rawValue(VeevaConstant.FLD_SIGNATURE_DATE_VOD)) {
            const requestMsg = await this.getMessageWithDefault('REQUEST_SIGNATURE_ENGAGE', 'RemoteMeeting', 'Request Signature');
            moreActions.push({name: 'Request_Signature', label: requestMsg});
        }
        return moreActions;
    }

    async addMoreActions(buttons) {
        const moreActions = await this.getMoreActions();
        if (moreActions.length > 0) {
            buttons.push({name: 'MI_more_actions', ctrl: new MedInqMoreActionsCtrl(moreActions, this)});
        }
    }

    isChildAccountSupportEnabled() {
        return this.veevaSettings.Enable_Child_Account_vod__c && 
                this.objectInfo.updateable &&
                this.objectInfo.fields.Location_vod__c?.updateable &&
                this.objectInfo.fields.Child_Account_vod__c?.updateable; 
    }

    isAccountFieldEditable(ctrl) {
        let isEditable;
        if (this.record.isNew && this.isChildAccountSupportEnabled()) {
            isEditable = Boolean(!(ctrl.data.isFieldSet(MedInqConstant.ACCOUNT) && ctrl.data.isFieldSet(MedInqConstant.LOCATION)) || ctrl.data.isClone);
        } else {
            isEditable = Boolean(this.record.isNew);
        }
        return isEditable;
    }

    
    getPageRefForClose(id, saveAndNew, pageState, data) {
        let pageRef;
        if (pageState && pageState.c__redirectReference) {
            pageRef = JSON.parse(pageState.c__redirectReference);
        } else {
            pageRef = super.getPageRefForClose(id, saveAndNew, pageState, data)
        }
        return pageRef;
    }
}