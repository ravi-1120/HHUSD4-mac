export default class VeevaSignatureController {
    metadata;
    logo = "";
    vDataService;
    sessionSvc;
    channelId;
    channelDomain;
    channelStatus;
    link;
    signinType;
    signaturePageDisplayName;
    requestHeaders;
    selectedShareLink;
    selectedQrCode;
    isShareLink = true;
    isQrLoaded = false;
    qrCodeResult;
    errorTimeout = null;
    disableLanguageOptions = true;
    metadataNotLoaded = true;
    stopPollingEarly = false;
    base64Prefix = "data:image/jpg;base64,";
    constructor (dataSvc, sessionSvc) {
        this.vDataService = dataSvc;
        this.sessionService = sessionSvc;
        this.requestHeaders = {
            'Access-Control-Allow-Origin':'*',
            sfSession: this.sessionService._vodInfo.sfSession,
            sfEndpoint: this.sessionService._vodInfo.sfEndpoint
        }
    }
    dataURIToBlob(dataURI) {
        const byteString = atob(dataURI);
        const ia = new Uint8Array(byteString.length);
        for (let i = 0; i < byteString.length; i++){
            ia[i] = byteString.charCodeAt(i);
        }
        return new Blob([ia], { type: "image/jpeg" });
    }
    async acceptSignature(selectedMethodValue, recordIdValue, signatureViewValue, signatureDateValue, objectApiNameValue) {
        if (selectedMethodValue === "shareLink") {
            this.selectedShareLink = true;
        } else {
            this.selectedQrCode = true;
        }
        const changes = {
            data: [{
                Id: recordIdValue,
                Signature_vod__c: signatureViewValue,
                Signature_Date_vod__c: new Date(parseInt(signatureDateValue,10)).toISOString(),
                Signature_Captured_Share_Link_vod__c : this.selectedShareLink,
                Signature_Captured_QR_Code_vod__c: this.selectedQrCode,
                type: objectApiNameValue
            }],
        }
        await this.vDataService.save(changes);
    }
    buildSignatureRequest(params) {
        const signatureRequest = {
            signinInfo: {
                salesforceCallId: params.recordIdValue,
                engageId: "",
                zoomUserId: "",
                channelId: this.channelId,
                connectionType: "SHARE_LINK"
            },
            signinType: params.signinType,
            transactionObject: {
                name: params.objectApiNameValue,
                salesforceId: params.recordIdValue
            },
            signee: this.name,
            messageInvalidSignature: params.messageInvalidSignatureValue
        };
        if (params.disclaimerValue) {
            signatureRequest.disclaimer = {
                label: params.disclaimerHeaderValue,
                value: params.disclaimerValue
            }
        }
        return signatureRequest;
    }
    async fetchMetadata(params) {
        const path = '/api/v1/hcpproxy/rem-sig-metadata';
        this.metadata = await this.vDataService.sendRequest('GET', path, params, null, 'getMetadata', null);
        if (this.metadata.data.logoUrl) {
            this.logo = this.base64Prefix + this.metadata.data.logoUrl;
        }
        if (this.metadata.data.signatureResponses) {
            this.disclaimerLanguages = this.metadata.data.signatureResponses.map((sigPage) => ({
                    value: sigPage.Language_vod__c,
                    label: sigPage.translatedLanguage
                }));
            if (this.disclaimerLanguages.length) {
                this.disableLanguageOptions = false;
                if (this.metadata.data.userIndex) {
                    this.disclaimerLanguage = this.disclaimerLanguages[this.metadata.data.userIndex].value;
                } else {
                    this.disclaimerLanguage = this.disclaimerLanguages[0].value;
                }
                this.languageValue = this.disclaimerLanguage;
            }
        }
        if (this.metadata.data.signaturePageDisplayName) {
            this.signaturePageDisplayName = this.metadata.data.signaturePageDisplayName;
        }
        if (this.metadata.data.credentials) {
            this.credentials = this.metadata.data.credentials;
        }
        if (this.metadata.data.salutation) {
            this.salutation = this.metadata.data.salutation;
        }
        this.metadataNotLoaded = false;
    }
    async next(disclaimerLanguage, oType) {
        let sigPageId;
        if (disclaimerLanguage) {
            const sigResponses = this.metadata.data.signatureResponses;
            const disclaimerSigResponse = sigResponses.find(sigResponse => sigResponse.Language_vod__c === disclaimerLanguage);
            sigPageId = disclaimerSigResponse?.Id;
        }
        return this.vDataService.sendRequest('GET', '/api/v1/hcpproxy/language-messages',{id: sigPageId, useVeevaMessage: this.metadata.data.useVeevaMessage, objectType: oType}, null, 'getMessage', null);
    }
    async createChannelAndLink(recordIdValue, linkValue, channelId) {
        if (!linkValue) {
            const result = await this.vDataService.sendRequest(
                'POST', '/api/v1/hcp-proxy/channels', null, {origin: "ONLINE", transactionType: this.isShareLink?"MI_Sign_SL_vod":"MI_Sign_QR_vod", externalInfo: {salesforceCallId: recordIdValue, salesforceMobileId: ""}},
                null, this.requestHeaders);
            this.channelId = result.data.channelId;
            this.channelDomain = result.data.channelDomain;
            this.channelStatus = result.data.channelStatus;
            if(result.data.shortUrl && result.data.shortUrl !== 'Unspecified_vod') {
                this.link = result.data.shortUrl;
            } else {
                this.link = `${this.channelDomain  }/samples/#/share-link/${  this.channelId}`;
            }
        } else {
            this.link = linkValue;
            if (channelId) {
                this.channelId = channelId;
            }
        }
        if (!this.isShareLink) {
            this.qrCodeResult = await this.vDataService.sendRequest('GET', '/api/v1/layout3/data/Medical_Inquiry_vod__c/qrCode', {url: this.link}, null, 'qrCode', this.requestHeaders);
            if (this.qrCodeResult) {
                this.qrCodeResult = this.base64Prefix + this.qrCodeResult;
            }
            this.isQrLoaded = true;
        }
    }
    async pollForChannel(channelId) {
        this.pollingInterval = 1000;
        const channelToPoll = (channelId) || this.channelId;
        while (!this.stopPolling && !this.stopPollingEarly) {
            // eslint-disable-next-line no-await-in-loop
            const result = await this.vDataService.sendRequest('GET', `/api/v1/hcp-proxy/channels/${  channelToPoll}`, null, null, 'pollChannel', this.requestHeaders);
            this.errorTimeout = null;
            if (result.data.channelStatus !== 'CONNECTED') {
                if (this.pollingInterval === 1000 && new Date().getTime() - this.pollingStartTime > this.tenMinuteDifference) {
                    this.pollingInterval = 5000;
                }
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                window.setTimeout(() => {}, this.pollingInterval);
            } else {
                this.stopPolling = true;
            }
        }
    }
    async signatureSendRequest(params) {
        this.name = (this.salutation ? `${this.salutation} ` : "") + params.accountNameValue + (this.credentials ? `, ${this.credentials}`: "");
        const signatureRequest = await this.buildSignatureRequest(params);
        const formData = new FormData();
        let imageData = this.logo.replace(this.base64Prefix,"");
        if (!imageData) {
            imageData = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
        }
        const file = this.dataURIToBlob(imageData);
        formData.append('signatureRequest', JSON.stringify(signatureRequest));
        formData.append('file', file, 'image.jpg');
        const headers = {
            'Access-Control-Allow-Origin':'*',
            sfSession:  this.sessionService._vodInfo.sfSession,
            sfEndpoint: this.sessionService._vodInfo.sfEndpoint,
        };
        const result = await this.vDataService.sendMultiformRequest('POST', '/api/v2/hcp-proxy/signature-requests', null, "signatureRequest", formData, headers);
        this.errorTimeout = null;
        this.signInId = result.data.signinId;
        this.pollForSigResult = result;
        this.pollingInterval = 1000;
        this.pollingStartTime = new Date().getTime();
        this.stopPolling = false;

    }
    async pollForSignature(signInIdValue) {
        const signInId = (signInIdValue) || this.signInId;
        this.pollingInterval = 1000;
        let result;
        let sigStatus = (this.pollForSigResult) ? this.pollForSigResult.data.sigStatus : "";
        while (sigStatus !== "RECEIVED" && !this.stopPolling && !this.stopPollingEarly) {
            // eslint-disable-next-line no-await-in-loop
            result = await this.vDataService.sendRequest('GET', `/api/v1/hcp-proxy/signatures/${signInId}`, null, null, 'pollForSignature', this.requestHeaders);
            this.errorTimeout = null;
            sigStatus = result.data.sigStatus;
            if (sigStatus !== 'RECEIVED') {
                if (result.data.sigStatus === 'FAILED' || result.data.sigStatus === 'DECLINED') {
                    this.stopPolling = true;
                    return result;
                }
                    if (this.pollingInterval === 1000 && new Date().getTime() - this.pollingStartTime > this.tenMinuteDifference) {
                        this.pollingInterval = 5000;
                    }
                    // eslint-disable-next-line @lwc/lwc/no-async-operation
                    window.setTimeout(() => {}, this.pollingInterval);

            } else {
                return result;
            }
        }
        return result;
    }
    async cancelEngageRequest(signInIdValue) {
        if (signInIdValue) {
            await this.vDataService.sendRequest('DELETE', `/api/v2/hcp-proxy/signature-requests/${  signInIdValue}`, null, null, 'cancelRequest', this.requestHeaders);
        }
    }
    async closeChannel(channelId) {
        return this.vDataService.sendRequest('DELETE', `/api/v1/hcp-proxy/channels/${  channelId}`, null, null, 'closeChannel', this.requestHeaders);
    }
}