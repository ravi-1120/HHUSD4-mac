import { wire, api, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPageController } from 'c/veevaPageControllerFactory';
import { NavigationMixin } from 'lightning/navigation';
import VeevaUtils from 'c/veevaUtils';
import VeevaPageReference from 'c/veevaPageReference';
import { getRecord } from 'lightning/uiRecordApi';
import VeevaMainPage from 'c/veevaMainPage';
import VeevaConstant from 'c/veevaConstant';
import VeevaToastEvent from 'c/veevaToastEvent';

export default class VeevaEditPage extends NavigationMixin(VeevaMainPage) {
    @api recordId;
    @api isFlowScreen; 
    @api justDispatchClose = false;

    @track show;
    @track fields;
    @track page = { requests: [], action: 'Edit' }; // page UI state
    
    pageName = VeevaConstant.EDIT_LWC;
    objType = null;
    redirectInProgress = false;

    connectedCallback() {
        super.connectedCallback();
        this.redirectInProgress = false;
    }

    @api get pageReference() {
        return this._pageReference;
    }

    set pageReference(value) {
        this._pageReference = VeevaPageReference.getPageReference(value);
        // workaround for Caching issue when Overriding the "Edit" Action in Lightning Experience,
        // and attempting to edit a submitted record more than once
        if (this.pageCtrl && this.pageCtrl.record) {
            this.redirectOrShow();
        }
    }

    @api get objectApiName() {
        return this._objectApiName;
    }

    set objectApiName(value) {
        this.pageCtrl = getPageController(value);
        this.pageCtrl.page = this.page;
        this._objectApiName = value;
        this.objType = value;
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    async wiredObjectInfo({ error, data }) {
        if (data) {
            this.pageCtrl.objectInfo = JSON.parse(JSON.stringify(data));
            this.fields = this.pageCtrl.getQueryFields();
            this.optionalFields = this.pageCtrl.getOptionalQueryFields();
        }
        if (error) {
            this.setError(error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fields', optionalFields: '$optionalFields' })
    async wiredObjectDetails({ error, data }) {
        if (data) {
            const oldRecord = this.pageCtrl.record;
            this.pageCtrl.isFlowScreen = this.isFlowScreen;
            this.pageCtrl.record = JSON.parse(JSON.stringify(data));
            if (oldRecord) {
                // flipping recordUpdateFlag will assign this.pageCtrl.record to the fieldController.record variables, keeping them in sync
                this.page.recordUpdateFlag = !this.page.recordUpdateFlag;
            }
            await this.pageCtrl.updateRecordStatus(this.pageReference);
            this.page.title = await this.pageCtrl.getEditPageTitle();
            await this.pageCtrl.initPageLayout();
            this.redirectOrShow();
        }
        if (error) {
            this.setError(error);
        }
    }

    async redirectOrShow() {
        const redirectPageRef = await this.pageCtrl.getRedirectPageRef();
        if (redirectPageRef && !this.redirectInProgress) {
            if (!this.pageCtrl.canEdit) {
                const toast = await VeevaToastEvent.notAllowedToEdit();
                this.dispatchEvent(toast);
            }
            this.redirect(redirectPageRef, true);
        } else {
            this.show = true;
            this.dispatchEvent(new CustomEvent('loaded'));
        }
    }

    redirect(pageRef, replaceBrowserHistory = false) {
        if (this.redirectInProgress) {
            return;
        }
        this.redirectInProgress = true;
        this[NavigationMixin.Navigate](pageRef, replaceBrowserHistory);
    }

    handleClose(parameters, id) {
        this.isSaving = false;
        const saveAndNew = parameters.detail?.saveAndNew || parameters.saveAndNew;
        if (this.justDispatchClose) {
            parameters.stopPropagation();
            this.dispatchEvent(new CustomEvent('close', {
                detail: {
                    ...parameters.detail,
                    saveAndNew: saveAndNew ?? false
                }
            }));
            return;
        }
        const savedId = parameters.detail?.id || id;
        const navigateId = VeevaUtils.validSfdcId(savedId) ? savedId : this.recordId;
        const redirectTo = this.pageCtrl.getPageRefForClose(navigateId, saveAndNew, this.pageReference.state);
    
        if (this.isFlowScreen) {
            let flowContext = redirectTo?.state?.inContextOfRef;
            if (typeof flowContext === 'string') {
                flowContext = JSON.parse(window.atob(flowContext));
            }
            const eventObj = {
                detail: { flowContext, saveAndNew, useFlowNavAfterEdit: this.pageCtrl.useFlowNavAfterEdit() },
                bubbles: true,
                composed: true,
            };
            this.dispatchEvent(new CustomEvent('close', eventObj));
        } else {
            this.redirect(redirectTo);
        }
    }

    setError(error) {
        this.dispatchEvent(VeevaToastEvent.error(error));
    }
}