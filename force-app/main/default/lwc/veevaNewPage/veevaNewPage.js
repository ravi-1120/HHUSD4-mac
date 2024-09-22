import { api, track, wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import VeevaToastEvent from "c/veevaToastEvent";
import { getPageController } from "c/veevaPageControllerFactory";
import VeevaPageReference from "c/veevaPageReference";
import { NavigationMixin } from 'lightning/navigation';
import VeevaMainPage from 'c/veevaMainPage';
import VeevaUtils from 'c/veevaUtils';
import VeevaConstant from 'c/veevaConstant';
import VeevaRecordCreateError from 'c/veevaRecordCreateError';
import { getService, SERVICES } from 'c/veevaServiceFactory';

// VeevaNewPage is used for overriding the New button.
// It sets the default field values.
// In addition, it sets the lookup field value from which the New action starts.
// Know issue: Salesforce @wire caches New page https://success.salesforce.com/issues_view?id=a1p3A000000JWUgQAO
export default class VeevaNewPage extends NavigationMixin(VeevaMainPage) {
    @api isFlowScreen;
    @track isSaving;
    @api recordCreateError;
    @api showRecordCreateError;
    @api justDispatchClose = false;

    @track page = { requests: [], action: 'New' };

    pageName = VeevaConstant.NEW_LWC;
    objType = null;

    uiApi = getService(SERVICES.UI_API);

    @api get pageReference() {
        return this._pageReference;
    }
    set pageReference(value) {
        this._pageReference = VeevaPageReference.getPageReference(value);
        if (this.pageCtrl && this.pageCtrl.objectInfo && this.pageCtrl.objectInfo.apiName === this.objectApiName) {
            // workaround for Caching issue when Overriding the "New" Action in Lightning Experience
            // manually reset page metadata and record data
            this.page = { requests: [], action: 'New' };
            const { objectInfo } = this.pageCtrl;

            this.pageCtrl = getPageController(this.objectApiName);
            this.pageCtrl.page = this.page;
            this.pageCtrl.objectInfo = objectInfo;
            this.initRecordCreate();
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
    wiredObjectInfo({ error, data }) {
      if (data) {
          this.pageCtrl.isFlowScreen = this.isFlowScreen;
          this.pageCtrl.objectInfo = JSON.parse(JSON.stringify(data));
          this.initRecordCreate();
      }
      if (error) {
         this.setError(error);
      }
    }

    async initRecordCreate() {
        const objInfo = this.pageCtrl && this.pageCtrl.objectInfo;
        if (this._pageReference && objInfo) {
            if (this._pageReference.state && !this._pageReference.state.recordTypeId) {
                this._pageReference.state.recordTypeId = objInfo.defaultRecordTypeId;
            }

            try {
                // try to initialize record
                await this.pageCtrl.initRecordCreate(this._pageReference);
                this._tempId = VeevaUtils.getRandomId();
            } catch (error) {
                // handle VeevaRecordCreateError
                if (error instanceof VeevaRecordCreateError) {
                    this.recordCreateError = error;
                    this.showRecordCreateError = true;
                } else {
                   throw error;
                }
            }
        }
    }

    handleRecordCreateErrorModalClose = () => {
        // hide error modal
        this.showRecordCreateError = false;

        // close the new page
        this.handleClose(null, null, this.recordCreateError.redirectRef);
    };

    async handleClose(event, id, redirectRef) {
        this.isSaving = false;
        if (event && event.type === 'close') {
            event.stopPropagation();
        }
        const createdId = event?.detail?.id || id;
        const saveAndNew = event?.detail?.saveAndNew || event?.saveAndNew;

        if (createdId) {
            const urlPromise = this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: createdId,
                    actionName: 'view',
                },
            });
            let url;
            // Prevents unnecessary uiApi call when the name has been defined
            let name = this.pageCtrl.getPageSubtitle();
            if (name != null) {
                url = await urlPromise;
            } else {
                const namePromise = this.uiApi.getRecord(createdId, [`${this.objectApiName}.Name`]);            
                const resp = await Promise.all([urlPromise, namePromise]);
                [url] = resp;
                name = resp[1]?.fields?.Name?.value;
            }
            this.dispatchEvent(await VeevaToastEvent.recordCreated(this.pageCtrl.getPageTitle(), name, url));
        }
    
        if (this.justDispatchClose) {
            this.dispatchEvent(new CustomEvent('close', {
                detail: {
                    ...event.detail,
                    saveAndNew: saveAndNew ?? false
                }
            }));
            return;
        }

        let redirectRefToUse = redirectRef;
        if (!redirectRefToUse) {
            redirectRefToUse = this.pageCtrl.getPageRefForClose(createdId, saveAndNew, this.pageReference.state);
        }
    
        if (this.isFlowScreen) {
            const eventObj = {
                detail: {
                    pageRef: redirectRefToUse,
                    useFlowNavAfterNew: this.pageCtrl.useFlowNavAfterNew(saveAndNew, this.pageReference.state),
                    saveAndNew,
                },
            };
            this.dispatchEvent(new CustomEvent('close', eventObj));
        } else {
            this[NavigationMixin.Navigate](redirectRefToUse);
        }
    }
  

    setError(error) {
        this.dispatchEvent(VeevaToastEvent.error(error));
    }
}