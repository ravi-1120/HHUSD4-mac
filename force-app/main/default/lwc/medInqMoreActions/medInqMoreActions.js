import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import veevaHandleSaveResponse from '@salesforce/messageChannel/Veeva_Handle_Save_Response__c';
import { MessageContext, publish, subscribe, unsubscribe } from 'lightning/messageService';
import veevaButtonAction from '@salesforce/messageChannel/Veeva_Button_Action__c';
import MEDINQ_OBJ from '@salesforce/schema/Medical_Inquiry_vod__c'
import startFlow from '@salesforce/messageChannel/Start_Flow__c';
import VeevaUserInterfaceAPI from 'c/veevaUserInterfaceAPI';

export default class MedInqMoreActions extends LightningElement {
    @api controller
    flowStarted = false;
    @wire(MessageContext)
    messageContext;

    @wire(CurrentPageReference)
    pageReference;

    @track hasLoadedMsg = false;
    buttonActionSubscription;
    @api
    get medicalInquiryController() {
        return this._medicalInquiryController;
    }
    set medicalInquiryController(ctrl) {
        this._medicalInquiryController = ctrl;
        this.setMessage();
    }
    async setMessage() {
        this.titleMsg = await this.medicalInquiryController.getMessageWithDefault(
            "CALL_MORE_ACTIONS",
            "CallReport",
            "More Actions"
        );
        this.hasLoadedMsg = true;
    }
    connectedCallback() {
        this.handleSaveResponseSubscription = subscribe(
            this.messageContext,
            veevaHandleSaveResponse,
            (message) => {
                if (message) {
                    // implement lightning flow here
                    this.flowStarted = true;
                    this.launchFlow(message.createdId ?? message.recordId);
                }
            }
        );
    }

    disconnectedCallback(){
        if (this.buttonActionSubscription) {
            unsubscribe(this.buttonActionSubscription);
            this.buttonActionSubscription = null;
        }
    }

    async onClick(event) {
        // add signature setup page start flow here eventually
        // handle implicit save here for now
        const mode = this.medicalInquiryController.action;
        if (event.currentTarget.value === "Request_Signature" && (mode === "Edit" || mode === "New")) {
            const saveResponseMessage = {
                component: 'medInqMoreActions',
                objectName: MEDINQ_OBJ.objectApiName,
                recordId: this.medicalInquiryController.id
            };
            publish(this.messageContext, veevaButtonAction, {
                action: 'saverecord',
                recordId: this.medicalInquiryController.id,
                pageMode: mode,
                parameters: {
                    saveResponseMessage
                }
            });
        }
    else if (event.currentTarget.value === "Request_Signature" && mode === "View") {
            this.flowStarted = true;
            await this.launchFlow(this.medicalInquiryController.record.id);
        }
    }
                
    async launchFlow(recordId) {
        const pageAction = this.medicalInquiryController.action;
        const flowVariables = await this.initFlowVariables(pageAction, recordId);
        const flowObject = {
            flowVariables,
            flowName: 'VeevaRemoteSignatureFlow'
        };
        const exitMode = (pageAction === "New") ? "edit" : pageAction.toLowerCase();
        flowObject.inContextOfRef =  { 
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: 'Medical_Inquiry_vod__c',
                actionName: exitMode,
                redirect: false
            },
        }

         // CRM-308928
        //  When 'Request Signature' is selected from a medical inquiry that was created from a call,
        // include a page reference to the call in the state attribute of inContextRef. This value 
        // is retrieved in medicalInquiryController's getPageRefForClose method. When the call entry point
        // was used the Call2_vod__c.value will be populated and the page action will be 'New'.
        const callId = this.medicalInquiryController.record.fields.Call2_vod__c?.value || null;
        if (callId && pageAction === 'New') {
            flowObject.inContextOfRef.state = {
                c__redirectReference: this.createRedirectReference(callId, 'Call2_vod__c', 'view', false)
            } 
        } else if (this.pageReference?.state?.c__redirectReference) {
            flowObject.inContextOfRef.state = {
                c__redirectReference: this.pageReference.state.c__redirectReference
            } 
        }
        publish(this.messageContext, startFlow, flowObject);
    }

    createRedirectReference(recordId, objectApiName, actionName, redirect) {
        const redirectReference = { 
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName,
                actionName,
                redirect
            }
        }
        return JSON.stringify(redirectReference);
    }

    async initFlowVariables(mode, recordId) {
        let groupId;
        let acctName;
        if (mode === "New") {
            const userInterfaceApi = new VeevaUserInterfaceAPI([]);
            const result = await userInterfaceApi.getRecord(recordId, ['Medical_Inquiry_vod__c.Group_Identifier_vod__c', 'Medical_Inquiry_vod__c.Account_vod__r']);
            if (result.fields.Group_Identifier_vod__c) {
                groupId = result.fields.Group_Identifier_vod__c.value;
            }
            acctName = result.fields.Account_vod__r.displayValue;
        } else {
            if (this._medicalInquiryController._record.fields.Group_Identifier_vod__c) {
                groupId = this._medicalInquiryController._record.fields.Group_Identifier_vod__c.value;
            }
            acctName = this._medicalInquiryController._record.fields.Account_vod__r.displayValue;
        }
        const acctId = this._medicalInquiryController._record.fields.Account_vod__c.value;
        const flowVariables = [
            {
                name: 'objectApiNameVariable',
                value: 'Medical_Inquiry_vod__c',
                type: 'String'
            },
            {
                name: 'shareLinkFlsValue',
                value: this.medicalInquiryController.objectInfo.updateableField("Signature_Captured_Share_Link_vod__c"),
                type: 'Boolean'
            },
            {
                name: 'qrCodeFlsValue',
                value: this.medicalInquiryController.objectInfo.updateableField("Signature_Captured_QR_Code_vod__c"),
                type: 'Boolean'
            },
            {
                name: 'accountNameVariable',
                value: acctName,
                type: 'String'
            },
            {
                name: 'accountIdVariable',
                value: acctId,
                type: 'String'
            },
            {
                name: 'recordIdVariable',
                value: recordId,
                type: 'String'
            },
            {
                name: 'recordTypeIdVariable',
                value: this._medicalInquiryController.record.recordTypeId,
                type: 'String'
            }
        ];
        if (groupId) {
            const groupVariable = {
                name: 'groupIdentifierVariable',
                value: groupId,
                type: 'String'
            }
            flowVariables.push(groupVariable);
        }
        return flowVariables;
    }

}