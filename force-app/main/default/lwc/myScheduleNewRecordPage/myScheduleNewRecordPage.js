import { api } from "lwc";
import VeevaNewPage from "c/veevaNewPage";
import VeevaConfirmationLightningModal from "c/veevaConfirmationLightningModal";
import { VeevaMessageRequest } from 'c/veevaMessageService';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import MODAL_STYLES from '@salesforce/resourceUrl/myScheduleNewRecordPage';
import VeevaToastEvent from 'c/veevaToastEvent';
import { getService, SERVICES } from 'c/veevaServiceFactory';

export default class MyScheduleNewRecordPage extends NavigationMixin(VeevaNewPage) {

    @api weekendDays;
    @api settings;

    translatedLabels;
    _pageCtrl;
    _objectName;
    _recordTypeId;

    uiApi = getService(SERVICES.UI_API);

    async connectedCallback() {
        const msgRequest = new VeevaMessageRequest();
        msgRequest.addRequest('Warning', 'Common', 'Warning', 'warningLabel');
        msgRequest.addRequest('TOT_WEEKEND_WARNING_START', 'TOT', 'The time/date of this record starts on the weekend. Do you still want to save this record?', 'totWeekendWarningStartLabel');

        [this.translatedLabels] = await Promise.all([this.pageCtrl.messageSvc.getMessageMap(msgRequest), loadStyle(this, MODAL_STYLES)]);
    }

    async handleClose(event, id) { // override VeevaNewPage handleClose function which navigates us away from current page; let mySchedule.js handle the display of modal
        const createdId = event?.detail?.id || id;
        if (createdId) {
            const urlPromise = this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: createdId,
                    actionName: 'view',
                },
            });
            
            // Only Time Off Territory and Unavailable Time records are created through here LEX MySchedule
            // Neither of those have user-defined names, so we will always have to retrieve the name via uiApi.getRecord
            const namePromise = this.uiApi.getRecord(createdId, [`${this.pageCtrl.record.apiName}.Name`]);            
            const resp = await Promise.all([urlPromise, namePromise]);
            const [url] = resp;
            const name = resp[1]?.fields?.Name?.value;
            this.dispatchEvent(await VeevaToastEvent.recordCreated(this.pageCtrl.getPageTitle(), name, url));
        }
        
        if (event?.detail?.data?.keepNewRecordModalOpen) {
            return;
        }
        const recordId = event?.detail?.id || id;
        const saveAndNew = event?.detail?.saveAndNew || event?.saveAndNew;
        this.dispatchEvent(new CustomEvent('newrecordmodalclose', { 
            detail : {
                recordId,
                saveAndNew
            }
        }));
        if (saveAndNew) {
            await this.initRecordCreate();
            this.page.recordUpdateFlag = !this.page.recordUpdateFlag;
        }
    }

    async handleCreateTotClick(date) {
        if (this.settings.preventTotWeekend === 1 && this.weekendDays.includes(date.getDay())) {
            return VeevaConfirmationLightningModal.open({
                title: this.translatedLabels.warningLabel,
                messages: [this.translatedLabels.totWeekendWarningStartLabel],
                size: 'small'
            });
        } 
        return true;
    }

    @api
    get pageCtrl() {
        return this._pageCtrl;
    }

    set pageCtrl(newPageCtrl) {
        // override page controller's save function after a new page controller was created following an objectApiName change
        this._pageCtrl = newPageCtrl;
        const saveFn = this._pageCtrl.save.bind(this._pageCtrl);
        this._pageCtrl.save = async (value = {}) => {
            const data = value.data || this.pageCtrl.getChanges();
            if (Object.keys(data).length < 1) { // ensure we always have something to send to our data service when we click "save" if no fields are filled out
                data.type = this.pageCtrl.objectApiName;
                data.RecordTypeId =  this.recordTypeId;
                return saveFn({ data });
            }
            if (data.type === 'Time_Off_Territory_vod__c' && data.Date_vod__c) {
                const totDate = new Date(data.Date_vod__c.replaceAll('-', '/'));
                const result = await this.handleCreateTotClick(totDate);
                if (!result) {
                    return { keepNewRecordModalOpen: true };
                }
            }
            return saveFn(value);
        };
    }

    @api
    get objectName() {
        return this._objectName;
    }

    set objectName(apiName) {
        this._objectName = apiName;
        this.pageReference = {
            state: {
                recordTypeId: this.recordTypeId
            },
            attributes: { objectApiName: apiName }
        };
        this.objectApiName = apiName;
    }

    @api
    get recordTypeId() {
        return this._recordTypeId;
    }

    set recordTypeId(id){
        if (this.pageReference.state) {
            this.pageReference.state.recordTypeId = id;
        }
        this._recordTypeId = id;
    }

}