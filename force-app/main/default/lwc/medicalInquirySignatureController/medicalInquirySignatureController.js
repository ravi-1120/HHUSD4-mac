import VeevaUserInterfaceApi from 'c/veevaUserInterfaceAPI';
import VeevaSignatureController from 'c/veevaSignatureController';

export default class MedicalInquirySignatureController extends VeevaSignatureController{
    selectedShareLink;
    selectedQrCode;
    miObjectInfo;
    childIds;
    inquiryDeliveryLabels = {};
    inquiryDeliveryKeys = {"Urgent_Mail_vod" : "Urgent Mail", "Mail_vod" : "Mail", "Email_vod" : "Email", "Phone_vod" : "Phone", "Fax_vod" : "Fax" }

    async acceptSignature(selectedMethodValue, recordIdValue, signatureViewValue, signatureDateValue, disclaimerValue, childIds) {
        if (selectedMethodValue === "shareLink") {
            this.selectedShareLink = true;
        } else {
            this.selectedQrCode = true;
        }
        const signatureDate = new Date(parseInt(signatureDateValue, 10)).toISOString();
        let mpiIds;
        if (childIds && childIds.length > 0) {
            mpiIds = childIds.split(",");
        }
        const changes = {
            data: {
                Id: recordIdValue,
                Signature_vod__c: signatureViewValue,
                Signature_Date_vod__c: signatureDate,
                Disclaimer_vod__c: disclaimerValue,
                Signature_Captured_Share_Link_vod__c : this.selectedShareLink,
                Signature_Captured_QR_Code_vod__c: this.selectedQrCode,
                type: "Medical_Inquiry_vod__c"
            },
        }
        if (mpiIds) {
            changes.data = [changes.data];
            const mpiData = mpiIds.filter(id => id !== recordIdValue).map(id => ({
                    Id: id,
                    Signature_vod__c: signatureViewValue,
                    Signature_Date_vod__c: signatureDate,
                    Signature_Captured_Share_Link_vod__c : this.selectedShareLink,
                    Signature_Captured_QR_Code_vod__c: this.selectedQrCode,
                    Disclaimer_vod__c: disclaimerValue,
                    type: "Medical_Inquiry_vod__c"
                }));
            changes.data.push(...mpiData);
            changes.url = 'Medical_Inquiry_vod__c/mpi';
        } else {
            changes.type = 'Medical_Inquiry_vod__c';
        }
        await this.vDataService.save(changes);
        // save MPIs
    }
    async buildSignatureRequest(params) {
        await this.getDeliveryLabels(params.recordTypeValue);
        const signatureRequest = {
            signinInfo: {
                salesforceCallId: params.recordIdValue,
                engageId: "",
                zoomUserId: "",
                channelId: this.channelId,
                connectionType: "SHARE_LINK"
            },
            signinType: "MEDICAL_INQUIRY",
            transactionObject: {
                name: 'Medical_Inquiry_vod__c',
                salesforceId: params.recordIdValue
            },
            signee: this.name,
            messageInvalidSignature: params.messageInvalidSignatureValue
        };

        if (this.signaturePageLocationName) {
            signatureRequest.location = this.signaturePageLocationName;
        }
        
        if (params.disclaimerValue) {
            signatureRequest.disclaimer = {
                label: params.disclaimerHeaderValue,
                value: params.disclaimerValue
            }
        }
        signatureRequest.inquiries = [];
        for (const inquiryId in this.inquiryIdToInfo) {
            if (Object.prototype.hasOwnProperty.call(this.inquiryIdToInfo, inquiryId)) {
                const inquiry = this.inquiryIdToInfo[inquiryId];
                if (inquiry) {
                    const deliveryMethodValue = inquiry.Delivery_Method_vod__c;
                    const inquiryEntry = {
                        product: {
                            inquiryText : inquiry.Inquiry_Text__c
                        },
                        deliveryMethod : {
                            label : this.miObjectInfo.fields.Delivery_Method_vod__c.label,
                            description : this.inquiryDeliveryLabels[deliveryMethodValue]
                        }
                    }
                    if (params.groupIdValue) {
                        inquiryEntry.product.label = inquiry.Product__c
                    }
                    if (!inquiryEntry.product.label) {
                        inquiryEntry.product.label = params.deliveryLabels.requestDetailsLabel;
                    }
                    let deliveryInfo;
                    if (deliveryMethodValue === 'Mail_vod' || deliveryMethodValue === 'Urgent_Mail_vod') {
                        deliveryInfo = {
                            label : params.deliveryLabels.addressLabel,
                            key : "mail",
                            country : inquiry.Country_vod__c,
                            state : inquiry.State_vod__c,
                            "address-line-2" : inquiry.Address_Line_2_vod__c,
                            name : inquiry.Address_Line_1_vod__c,
                            city : inquiry.City_vod__c,
                            zip : inquiry.Zip_vod__c
                        }
                    } else {
                        let inquiryValue;
                        if (deliveryMethodValue === 'Phone_vod') {
                            inquiryValue = inquiry.Phone_Number_vod__c;
                        } else if (deliveryMethodValue === 'Fax_vod') {
                            inquiryValue = inquiry.Fax_Number_vod__c;
                        } else {
                            inquiryValue = inquiry[`${deliveryMethodValue}__c`];
                        }
                        if(inquiryValue){
                            deliveryInfo = {
                                label: params.deliveryLabels[deliveryMethodValue],
                                key: this.inquiryDeliveryKeys[deliveryMethodValue].toLowerCase(),
                                value: inquiryValue
                            }
                        }
                    }
                    inquiryEntry.deliveryInformation = deliveryInfo;
                    signatureRequest.inquiries.push(inquiryEntry);
                }
            }
        }
        return signatureRequest;
    }
    async getDeliveryLabels(recordTypeValue) {
        const userInterfaceApi = new VeevaUserInterfaceApi([]);
        const result = await userInterfaceApi.getPicklistValues(recordTypeValue, 'Medical_Inquiry_vod__c', 'Delivery_Method_vod__c');
        for (let i = 0; i < result.values.length; i++) {
            this.inquiryDeliveryLabels[result.values[i].value] = result.values[i].label;
        }
        const objectInfoResult = await userInterfaceApi.objectInfo('Medical_Inquiry_vod__c');
        this.miObjectInfo = objectInfoResult;
    }
    async fetchMetadata(params) {
        const metadataParams = {
            medInqId: params.recordIdValue,
            groupId: params.groupIdValue,
            accountId: params.accountIdValue
        }
        const path = '/api/v1/hcpproxy/rem-sig-metadata/med-inq';
        this.metadata = await this.vDataService.sendRequest('GET', path, metadataParams, null, 'getMetadata', null);
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

        if (this.metadata.data.signaturePageLocationName) {
            this.signaturePageLocationName = this.metadata.data.signaturePageLocationName;
        }

        if (this.metadata.data.credentials) {
            this.credentials = this.metadata.data.credentials;
        }
        if (this.metadata.data.salutation) {
            this.salutation = this.metadata.data.salutation;
        }
        this.inquiryIdToInfo = this.metadata.data.inquiryIdToInfo;
        this.childIds = this.metadata.data.mpiIds;
        this.metadataNotLoaded = false;
    }
}