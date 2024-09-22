/* eslint-disable no-console */
import { api, LightningElement } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import S4lUtils from 'c/s4lUtils';

import { getPageController } from "c/veevaPageControllerFactory";
import { VeevaAccountSearchController } from "c/veevaAccountSearch";
import validateAccount from "@salesforce/apex/S4LAccountValidator.validateAccount";

import getVeevaCustomSettings from "@salesforce/apex/MCAConvertToCallController.getVeevaCustomSettings";
import reconcile from "@salesforce/apex/MCAConvertToCallController.reconcile";

import ACCOUNT_IS_PERSON from "@salesforce/schema/Account.IsPersonAccount";
import ENABLE_CHILD_ACCOUNT from "@salesforce/schema/Veeva_Settings_vod__c.Enable_Child_Account_vod__c";
import canSelectClmCallRecordType from '@salesforce/apex/S4LRecordTypeSelectorController.canSelectClmCallRecordType';

export default class S4lCreateNewCall extends LightningElement {

    // input
    @api mcaId;
    @api mcaDataMapStr;
    // output
    @api exitEarly;
    @api createdCallId;

    loading = true;
    labels = {};

    recordTypeUniqueActivityFlag = {};

    startTime = new Date().getTime();
    alertModalData = {
        isVisible: false
    };

    // account section flags/ information
    showAccountSelector = true;
    validAccountSelected = false;
    allowAccountSearchToBeCleared = true;

    selectedAccountId = null;
    // only used for displaying record type error
    selectedAccountName = null;

    // only set to true when PersonAccount is selected and child account is enabled
    showLocationSelectorSection = false;
    selectedLocation = null;

    showAttendeeSection = false;

    // error flags
    accountRequiredError = false;
    recordTypeRequiredError = false;
    locationRequiredError = false;

    disableSaveButton = false;
    isUniqueActivity = false;
    canSelectClmCallRT = false;

    // set up methods

    constructor () {
        super();
        const pageCtrl = getPageController('pageCtrl');
        pageCtrl.uiApi.requests = [];
        this._pageCtrl = pageCtrl;
        this.accountSearchCtrl = new VeevaAccountSearchController(this._pageCtrl);
        this.getMessages();
        this.loadSettings();
        
    }

    async connectedCallback(){
        this.canSelectClmCallRT = await canSelectClmCallRecordType();
    }

    async getMessages() {
        this.labels = await S4lUtils.getMessages();
        this.loading = false;
    }

    async loadSettings() {
        this.settings = await getVeevaCustomSettings();
    }

    get isChildAccountEnabled() {
        return this.settings[ENABLE_CHILD_ACCOUNT.fieldApiName] === true;
    }

    // account searchbox methods

    focusAccountSearch() {
        // remove the "This Field is Required" error when user tries to search for account again
        this.setAccountSearchBoxClass(false);
    }

    handleSelectAccount(event) {
        const accountId = event.detail.id;
        if(!this.canSelectClmCallRT) {
            // the clear btn of account search should be hidden until account data is loaded.
            this.allowAccountSearchToBeCleared = false;
        }
        try {
            validateAccount({'mcaId': this.mcaId, 'accountId': accountId})
                .then((result) => {
                    this.setAccountSearchBoxClass(false);
                    if(result) {
                        console.error(result);
                        this.showAccountAlert(S4lUtils.constructModalDataForAccountAlert(this.labels, result));
                    } else {
                        this.selectedAccountId = accountId;
                        this.selectedAccountName = event.detail.name;
                        this.fetchSupplementaryAccountInformation();
                    }
                }).catch(err => {
                    console.error(err);
                    this.showAccountAlert(this.getReconciliationErrorModalData());
                });
        } catch (err) {
            console.error(err);
            this.showAccountAlert(this.getReconciliationErrorModalData());
        }
    }

    showAccountAlert(modalData) {
        this.showAlertModal(modalData.title, modalData.message, this.closeAccountAlertModal);
        this.showAccountSelector = false;
    }

    async fetchSupplementaryAccountInformation() {
        // asynchronous fetch supplementary account information (while we load the record type section and pending user input)
        this.supplementaryAccountInfo = {};
        if(this.selectedAccountId) {
            const account = await this._pageCtrl.uiApi.getRecord(this.selectedAccountId, [
                `${ACCOUNT_IS_PERSON.objectApiName  }.${  ACCOUNT_IS_PERSON.fieldApiName}`
            ]);
            if(account && account.fields) {
                for(const key of Object.keys(account.fields)) {
                    this.supplementaryAccountInfo[key] = account.fields[key].value;
                }
            }
            // the record type selector section should be display when callback of account data is ready.
            this.validAccountSelected = true;
        }
    }

    get isPersonAccountSelected() {
        return this.supplementaryAccountInfo[ACCOUNT_IS_PERSON.fieldApiName] === true;
    }

    closeAccountAlertModal() {
        this.handleClearAccount();
        this.showAccountSelector = true;
    }

    handleClearAccount() {
        this.resetAccountSelection();
        this.resetRecordTypeSelection();
        this.resetLocationSelection();
        this.resetAttendeeSelection();
    }

    resetAccountSelection() {
        this.selectedAccountId = null;
        this.selectedAccountName = null;
        this.hideAlertModal();
        this.supplementaryAccountInfo = {};
        this.validAccountSelected = false;
    }

    setAccountSearchBoxClass(showError) {
        this.accountRequiredError = showError;
        let comboboxClass = 'input-valid';
        if(showError) {
            comboboxClass = 'input-error';
        }
        this.accountSearchBoxClass = comboboxClass;
    }

    // record type selector methods

    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.detail.selected;
        this.recordTypeRequiredError = false;

        const isPersonAccount = this.isPersonAccountSelected;

        if(this.isChildAccountEnabled && isPersonAccount) {
            this.showLocationSelectorSection = true;
            this.allowAccountSearchToBeCleared = true;
        } else if(!isPersonAccount) {
            this.getIsUniqueActivityFlag(this.selectedRecordTypeId).then(data => {
                this.showAttendeeSection = data;
            }).finally(() => {
                this.allowAccountSearchToBeCleared = true;
            });
        } else {
            this.allowAccountSearchToBeCleared = true;
        }
    }

    handleNoRecordTypeFailure() {
        this.showAccountSelector = false;
        // show cannot record call alert
        const recordTypeAlertModalData = S4lUtils.getReconciliationErrorModalData(this.labels);
        this.resetAccountSelection();
        this.showAlertModal(recordTypeAlertModalData.title, recordTypeAlertModalData.message, this.closeAccountAlertModal);
    }

    resetRecordTypeSelection() {
        this.selectedRecordTypeId = null;
        this.recordTypeRequiredError = false;
        this.hideAlertModal();
    }

    // location section methods

    handleSelectLocation(event) {
        const handleSelectLocation = event.detail.selected;
        this.selectedLocation = handleSelectLocation;
        this.locationRequiredError = false;
    }

    setLocationNotRequired() {
        this.resetLocationSelection();
    }

    resetLocationSelection() {
        this.selectedLocation = null;
        this.locationRequiredError = false;
        this.showLocationSelectorSection = false;
    }

    // attendees section methods

    resetAttendeeSelection () {
        this.showAttendeeSection = false;
    }

    // footer buttons handlers

    handlePrevious() {
        this.goBack();
    }

    handleCancel() {
        this.exitEarly = true;
        this.goToNext();
    }

    handleSave() {
        this.disableSaveButton = true;
        this.validateInputBeforeSave().then(isValid => {
            if(isValid) {
                this.apexReconcile();
            } else {
                this.disableSaveButton = false;
            }
        }).catch(e => {
            console.error(e);
            this.handleReconciliationError();
        });
    }

    // reconciliation methods

    async validateInputBeforeSave() {
        // can't use 'required' for the account search modal (veeva lookup)
        // because the error behavior/ message doesn't match this feature's UX design
        const validAccount = this.validAccountSelected;
        const hasDataValidityError = [...this.template.querySelectorAll('[data-validity]')].filter(item => item.checkValidity() === false).length;
        const validAttendees = await this.validateAttendees();
        if(!validAccount) {
            const cmpErrors = [...this.template.querySelectorAll('c-veeva-account-search')].filter(item => item.checkValidity() === false);
            if(!cmpErrors.length) {
                // add "This Field is Required" error only when the account search component doesn't
                // already have the "Select an option from the picklist or remove the search term" error
                this.setAccountSearchBoxClass(true);
            }
        }
        return validAccount && !hasDataValidityError && validAttendees;
    }

    get selectedAttendees() {
        const attendeeSections = [...this.template.querySelectorAll('c-s4l-attendee-section')];
        if(this.showAttendeeSection && attendeeSections && attendeeSections.length && attendeeSections[0].getSelectedAttendees) {
            return attendeeSections[0].getSelectedAttendees();
        }
        return [];
    }

    async validateAttendees() {
        const attendees = this.selectedAttendees;
        const isUAFieldOnLayout = await this.getIsUniqueActivityFlag(this.selectedRecordTypeId);
        this.isUniqueActivity = isUAFieldOnLayout && !this.isPersonAccountSelected;
        if(attendees && attendees.length) {
            if(this.isPersonAccountSelected) {
                return false;
            }
            if(!this.isUniqueActivity) {
                return false;
            }
        }
        return true;
    }

    async getIsUniqueActivityFlag(callRecordTypeId) {
        let recordTypeIsUniqueActivity = this.recordTypeUniqueActivityFlag[callRecordTypeId];
        if(recordTypeIsUniqueActivity === null || recordTypeIsUniqueActivity === undefined) {
            recordTypeIsUniqueActivity = await S4lUtils.doesLayoutHasUniqueActivityField(this._pageCtrl.uiApi, callRecordTypeId);
            this.recordTypeUniqueActivityFlag[callRecordTypeId] = recordTypeIsUniqueActivity;
        }
        return recordTypeIsUniqueActivity;
    }

    async apexReconcile() {
        try {
            const attendeeLocations = {};
            const attendees = this.selectedAttendees;
            if(attendees && attendees.length) {
                for(const attendee of attendees) {
                    attendeeLocations[attendee.id] = {
                        Id: attendee.childAccountId,
                        Parent_Account_vod__c: attendee.parentId
                    };
                }
            }
            const result = await reconcile({
                mcaId: this.mcaId,
                accountId: this.selectedAccountId,
                callRecordTypeId: this.selectedRecordTypeId,
                location: this.selectedLocation,
                attendeeLocations,
                isUniqueActivity: this.isUniqueActivity
            });
            if(result != null) {
                this.createdCallId = result;
                this.goToNext();
            } else {
                this.handleReconciliationError();
            }
        } catch (err) {
            console.error(err);
            this.handleReconciliationError();
        }
    }

    handleReconciliationError() {
        const reconErrorModalData = this.getReconciliationErrorModalData();
        this.showAlertModal(reconErrorModalData.title, reconErrorModalData.message, this.hideAlertModal);
        this.showReconciliationError = true;
        this.disableSaveButton = false;
    }

    getReconciliationErrorModalData () {
        return S4lUtils.getReconciliationErrorModalData(this.labels);
    }

    // shared util methods

    goToNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    goBack() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    hideAlertModal() {
        this.alertModalData = {
            isVisible: false
        };
    }

    showAlertModal(title, message, handler) {
        this.alertModalData = {
            title,
            messages: [message],
            onCloseHandler: handler,
            isVisible: true
        };
    }
}