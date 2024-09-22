import VeevaRecord from "c/veevaRecord";
import MedInqConstant from "c/medInqConstant";
import { getService, SERVICES } from 'c/veevaServiceFactory';
import VeevaUserInterfaceApi from 'c/veevaUserInterfaceAPI';
import { DeliveryService } from './deliveryService';

export default class MedicalInquiryRecord extends VeevaRecord {

    _msgSvc;
    _vDataSvc;
    _sessionSvc;
    userInterfaceApi;
    sigPageOLS;
    isClone;

    constructor(value, messageSvc, vDataSvc, isClone) {
        super(value);
        this._msgSvc = messageSvc;
        this._vDataSvc = getService(SERVICES.DATA);
        if (vDataSvc) {
            this._vDataSvc = vDataSvc;
        }
        this.userInterfaceApi = new VeevaUserInterfaceApi([]);
        this.isClone = isClone;
    }

    displayValue(field) {
        let result = '';
        const fldName = field && field.apiName;
        if (fldName === MedInqConstant.ZVOD_DISCLAIMER) {
            result = super.displayValue(MedInqConstant.DISCLAIMER);
            if (!result) {
                result = this.getDisclaimerFromSigPage();
            }
        } else if (fldName === MedInqConstant.GROUP_IDENTIFIER && this.isClone) {
            return result;
        } else if (fldName !== MedInqConstant.GROUP_IDENTIFIER || this.id) {
            result = super.displayValue(field);
        }
        return result;
    }
    async setPromisedDisclaimer(result) {
        const disclaimerResult = await result;
        this.setFieldValue(MedInqConstant.DISCLAIMER, disclaimerResult.disclaimer);
        return disclaimerResult.disclaimer;
    }
    async getDisclaimerFromSigPage() {
        const objectType = "'Medical_Inquiry_vod'";
        if (this.fields.Account_vod__c && this.fields.Account_vod__c.value) {
            const result = await this._vDataSvc.sendRequest('GET','/api/v1/hcpproxy/disclaimer-pages', {accountId: this.fields.Account_vod__c.value, objectType}, null, 'getDisclaimer', null);
            return this.processSigPage(result);
        }
        this.sigPageOLS = await this.getSigPageOLS();
        if (this.sigPageOLS) {
            return '';
        }
        return this.getDisclaimerVM();
    }

    get delivery() {
        if (!this.deliveryOptions) {
            Object.assign(this, DeliveryService);
        }
        return this;
    }
    async getDisclaimerVM() {
        const result = await this._msgSvc.getMessageWithDefault('DISCLAIMER', 'MEDICAL_INQUIRY', '');
        this.setFieldValue(MedInqConstant.DISCLAIMER, result);
        return result;
    }
    async processSigPage(result) {
        const objectType = "'Medical_Inquiry_vod'";
        const sigPages = result.data.signatureResponses;
        let sigPageId;
        const useVeevaMessage = false;
        if (sigPages) {
            const disclaimerLanguages = result.data.signatureResponses.map((sigPage) => ({
                value: sigPage.Language_vod__c,
                label: sigPage.translatedLanguage
            }));
            if (disclaimerLanguages && disclaimerLanguages.length > 0 && result.data.userIndex >= 0) {
                const disclaimerLanguage = disclaimerLanguages[result.data.userIndex].value;
                if (disclaimerLanguage) {
                    const disclaimerSigResponse = sigPages.find(sigResponse => sigResponse.Language_vod__c === disclaimerLanguage);
                    sigPageId = disclaimerSigResponse?.Id;
                }
            }
            if (sigPageId) {
                const languageResult = this._vDataSvc.sendRequest('GET', '/api/v1/hcpproxy/language-messages',{id: sigPageId, useVeevaMessage, objectType}, null, 'getMessage', null);
                return this.setPromisedDisclaimer(languageResult);
            } 
            return '';
        } 
        return this.getDisclaimerVM();
        
    }
    async getSigPageOLS() {
        const result = await this.userInterfaceApi.objectInfo("Signature_Page_vod__c");
        return !Array.isArray(result);
    }
}