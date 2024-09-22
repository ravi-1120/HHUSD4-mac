import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { createRecord, getRecordCreateDefaults } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getService } from "c/veevaServiceFactory";
import { ImplicitAccessError, NoFeatureAccessError } from "c/removeFromTerritoryErrors";
import RemoveFromTerritoryLayoutParser from "c/removeFromTerritoryLayoutParser";
import VeevaToastEvent from 'c/veevaToastEvent';

import getUserAccountTerritories from "@salesforce/apex/VeevaRemoveFromTerritoryController.getUserAccountTerritories";
import getDCRModeAndRecordTypeId from '@salesforce/apex/VeevaRemoveFromTerritoryController.getDCRModeAndRecordTypeId';

import DATA_CHANGE_REQUEST_OBJ from "@salesforce/schema/Data_Change_Request_vod__c";
import DCR_RECORD_TYPE_ID from "@salesforce/schema/Data_Change_Request_vod__c.RecordTypeId";
import DCR_TERRITORY_FIELD from "@salesforce/schema/Data_Change_Request_vod__c.Territory_vod__c";
import DCR_TERRITORY_LABEL_FIELD from "@salesforce/schema/Data_Change_Request_vod__c.Territory_Label_vod__c";
import DCR_STATUS_FIELD from "@salesforce/schema/Data_Change_Request_vod__c.Status_vod__c";
import DCR_ACCOUNT_FIELD from "@salesforce/schema/Data_Change_Request_vod__c.Account_vod__c";
import DCR_EXTERNAL_STATUS_FIELD from "@salesforce/schema/Data_Change_Request_vod__c.External_Status_vod__c";
import DCR_SENT_DATETIME_FIELD from "@salesforce/schema/Data_Change_Request_vod__c.Sent_Datetime_vod__c";
import DCR_NETWORK_CUST_MASTER_MODE_FIELD from "@salesforce/schema/Data_Change_Request_vod__c.Network_Customer_Master_Mode_vod__c";
import DCR_CHALLENGE_REASONS_FIELD from "@salesforce/schema/Data_Change_Request_vod__c.Challenge_Reasons_vod__c";

export default class RemoveFromTerritoryForm extends LightningElement {
    @api recordId;

    @track territoryOptions;
    @track challengeReasonsOptions;

    submitButtonLabel = "Submit";
    cancelButtonLabel = "Cancel";
    removeFromTerritoryTitle = "Remove from Territory";
    removeFromTerritoryWarningLabel = "Removing this account can cause other related accounts to be removed from your territory.";
    removeFromTerritoryAccountAccessTitle = "Account Access";
    removeFromTerritoryImplicitAccessWarningText = "You have implicit access to this account and it is not assigned to your territory. Please contact an administrator to remove visibility.";
    noFeatureAccessText = "Unable to access this feature.";
    requestSubmissionSuccessText = "Your Remove from Territory request has been submitted successfully"

    _selectedTerritories = [];
    _selectedReasons = [];

    isSubmitted = false;
    error;
    messageService;
    
    territoryPicklistDisabled;
    territoryLabel;
    defaultTerritories;
    territoryIdToLabel;

    challengeReasonsEditable;
    challengeReasonsLabel;
    challengeReasonsOnLayout;
    challengeReasonsRequired;
    challengeReasonsFieldApiName;
    defaultChallengeReasons;

    dcrObjectApiName;
    removeFromTerritoryRecordTypeId;

    get showChallengeReasonsPicklist() {
        return this.challengeReasonsOnLayout && this.challengeReasonsEditable;
    }

    get formOptionsPopulated() {
        return this.territoryOptions?.length > 0 && (!this.showChallengeReasonsPicklist || this.challengeReasonsOptions?.length > 0);
    }

    get showRequestForm() {
        return this.recordId && !this.error && this.formOptionsPopulated;
    }

    get modalTitle() {
        return this.showRequestForm ? this.removeFromTerritoryTitle : "";
    }

    get formIsInvalid() {
        return this._selectedTerritories.length === 0 || (this.showChallengeReasonsPicklist && this.challengeReasonsRequired && this._selectedReasons.length === 0);
    }

    get territoryPicklistSize() {
        return this.showChallengeReasonsPicklist ? "6" : "12";
    }

    get loading() {
        return !this.showRequestForm && !this.error;
    }

    async connectedCallback() {
        this.messageService = getService("messageSvc");

        const [
            submitButtonLabel,
            cancelButtonLabel,
            removeFromTerritoryTitle,
            removeFromTerritoryWarningLabel,
            requestSubmissionSuccessText
        ] = await Promise.all([
            this.messageService.getMessageWithDefault("SUBMIT", "Common", this.submitButtonLabel),
            this.messageService.getMessageWithDefault("CANCEL", "Common", this.cancelButtonLabel),
            this.messageService.getMessageWithDefault("REMOVE_FROM_TERRITORY_TITLE", "Feedback", this.removeFromTerritoryTitle),
            this.messageService.getMessageWithDefault("REMOVE_FROM_TERRITORY_WARNING", "Feedback", this.removeFromTerritoryWarningLabel),
            this.messageService.getMessageWithDefault("REMOVE_FROM_TERRITORY_SUBMIT_TOAST", "Feedback", this.requestSubmissionSuccessText)
        ]);

        this.submitButtonLabel = submitButtonLabel;
        this.cancelButtonLabel = cancelButtonLabel;
        this.removeFromTerritoryTitle = removeFromTerritoryTitle;
        this.removeFromTerritoryWarningLabel = removeFromTerritoryWarningLabel;
        this.requestSubmissionSuccessText = requestSubmissionSuccessText;
    }

    @wire(getDCRModeAndRecordTypeId)
    getDCRModeAndRecordTypeId({error, data}) {
        const STANDARD_DCR_MODE = '1';
        const MULTISTAGE_DCR_MODE = '2';

        try {
            if (error) {
                throw new NoFeatureAccessError(error);
            } else if (data) {
                const { dcrMode, recordTypeId } = data;
                
                if (!(dcrMode === STANDARD_DCR_MODE || dcrMode === MULTISTAGE_DCR_MODE)) {
                    throw new NoFeatureAccessError("Data Change Requests are not enabled in this org.");
                } else if (recordTypeId) {
                    this.dcrObjectApiName = DATA_CHANGE_REQUEST_OBJ.objectApiName;
                    this.removeFromTerritoryRecordTypeId = recordTypeId;
                } else {
                    throw new NoFeatureAccessError("Cannot access the Remove from Territory DCR record type.");
                }
            }
        } catch (e) {
            this.setError(e);
        }
    }

    @wire(getRecordCreateDefaults, { objectApiName: "$dcrObjectApiName", recordTypeId: "$removeFromTerritoryRecordTypeId" })
    parseUserPermissionsToObjectAndLayout({error, data}) {
        try {
            if (error) {
                throw new NoFeatureAccessError(error);
            } else if (data) {
                if (!this.isSubmitted) {
                    const dcrObjectInfo = data.objectInfos.Data_Change_Request_vod__c;
                    const userCanAccessRecordType = dcrObjectInfo.recordTypeInfos[this.removeFromTerritoryRecordTypeId].available;

                    if (dcrObjectInfo && dcrObjectInfo.createable && dcrObjectInfo.updateable && userCanAccessRecordType) {
                        const dcrFields = dcrObjectInfo.fields;
                        if (this.checkDCRFieldPermissions(dcrFields)) {
                            this.territoryLabel = dcrFields.Territory_Label_vod__c.label;
                            this.populateTerritoryOptions();

                            if (dcrFields.Challenge_Reasons_vod__c?.updateable) {
                                this.challengeReasonsLabel = dcrFields.Challenge_Reasons_vod__c.label;
                                this.challengeReasonsFieldApiName = DCR_CHALLENGE_REASONS_FIELD;
                                this.challengeReasonsEditable = true;
                            }
                        } else {
                            throw new NoFeatureAccessError("User missing required DCR field permissions.");
                        }
                    } else {
                        throw new NoFeatureAccessError("User missing required DCR object-level permissions.");
                    }

                    const dcrLayoutParser = new RemoveFromTerritoryLayoutParser(data.layout);
                    this.challengeReasonsOnLayout = dcrLayoutParser.hasChallengeReasonsField;
                    this.challengeReasonsRequired = dcrLayoutParser.challengeReasonsRequired;
                }
            }
        } catch (e) {
            this.setError(e);
        }
    }

    checkDCRFieldPermissions(dcrFields) {
        const statusFld = dcrFields.Status_vod__c;
        const externalStatusFld = dcrFields.External_Status_vod__c;
        const customerNetworkModeFld = dcrFields.Network_Customer_Master_Mode_vod__c;
        const accountFld = dcrFields.Account_vod__c;
        const territoryFld = dcrFields.Territory_vod__c;
        const territoryLabelFld = dcrFields.Territory_Label_vod__c;
        const sentDatetimeFld = dcrFields.Sent_Datetime_vod__c;

        return (statusFld && statusFld.updateable 
            && externalStatusFld && externalStatusFld.updateable 
            && customerNetworkModeFld && customerNetworkModeFld.updateable 
            && accountFld && accountFld.updateable
            && territoryFld && territoryFld.updateable
            && territoryLabelFld && territoryLabelFld.updateable
            && sentDatetimeFld && sentDatetimeFld.updateable);
    }

    async populateTerritoryOptions() {
        if (this.recordId) {
            try {
                this.territoryOptions = [];
                this.defaultTerritories = [];

                const userAccountTerritories = await getUserAccountTerritories({accountId: this.recordId})
                    .catch(error => { throw new ImplicitAccessError(error) });

                this.territoryOptions = userAccountTerritories.map(alignment => ({
                    label: alignment.Territory2.Name,
                    value: alignment.Territory2Id
                }));

                this.territoryIdToLabel = new Map(this.territoryOptions.map(option => ([option.value, option.label])));

                if (this.territoryOptions.length === 1) {
                    const territory = this.territoryOptions[0];
                    this.defaultTerritories.push(territory.value);
                    this._selectedTerritories.push(territory.value);
                    this.territoryPicklistDisabled = true;
                } else if (this.territoryOptions.length < 1) {
                    throw new ImplicitAccessError("The user does not have any common territory assignments with this account.")
                }
            } catch (e) {
                this.setError(e);
            }
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$removeFromTerritoryRecordTypeId", fieldApiName: "$challengeReasonsFieldApiName" })
    getChallengeReasonPicklistValues({error, data}) {
        if (error) {
            this.setError(new NoFeatureAccessError(error));
        } else if (data) {
            this.defaultChallengeReasons = [];
            this.challengeReasonsOptions = [];

            this.challengeReasonsOptions = data.values.map(entry => ({
                label: entry.label,
                value: entry.value
            }));

            if (data.defaultValue) {
                this._selectedReasons.push(data.defaultValue.value);
                this.defaultChallengeReasons.push(data.defaultValue.value);
            }
        }
    }

    setError(e) {
        this.error = e;
    }

    async handleSubmit() {
        try {
            this.isSubmitted = true;
            await this.createDealignmentRequestRecords();
            this.dispatchEvent(VeevaToastEvent.successMessage(this.requestSubmissionSuccessText));
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.isSubmitted = false;
            this.dispatchEvent(VeevaToastEvent.error(error));
        }
    }

    createDealignmentRequestRecords() {
        const recordsToCreate = this._selectedTerritories.map(territoryId => {
            const territoryName = this.territoryIdToLabel.get(territoryId);
            const record = {
                apiName: DATA_CHANGE_REQUEST_OBJ.objectApiName,
                fields: {
                    [DCR_RECORD_TYPE_ID.fieldApiName]: this.removeFromTerritoryRecordTypeId,
                    [DCR_ACCOUNT_FIELD.fieldApiName]: this.recordId,
                    [DCR_TERRITORY_FIELD.fieldApiName]: territoryId,
                    [DCR_TERRITORY_LABEL_FIELD.fieldApiName]: territoryName,
                    [DCR_STATUS_FIELD.fieldApiName]: "Submitted_vod",
                    [DCR_EXTERNAL_STATUS_FIELD.fieldApiName]: "CHANGE_PENDINGREVIEW",
                    [DCR_NETWORK_CUST_MASTER_MODE_FIELD.fieldApiName]: 0,
                    [DCR_SENT_DATETIME_FIELD.fieldApiName]: new Date(Date.now())
                }
            };

            if (this.showChallengeReasonsPicklist) {
                record.fields[DCR_CHALLENGE_REASONS_FIELD.fieldApiName] = this._selectedReasons.join(";;");
            }

            return record;
        });

        return Promise.all(recordsToCreate.map(record => createRecord(record)));
    }

    handleTerritorySelectionChange(e) {
        this._selectedTerritories = e.detail.value;
    }

    handleChallengeReasonSelectionChange(e) {
        this._selectedReasons = e.detail.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}