import { api, track, LightningElement } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

import { getPageController } from "c/veevaPageControllerFactory";
import { VeevaAccountSearchController } from "c/veevaAccountSearch";
import validateAccount from "@salesforce/apex/S4LAccountValidator.validateAccount";

import getVeevaCustomSettings from "@salesforce/apex/MCAConvertToCallController.getVeevaCustomSettings";
import reconcile from "@salesforce/apex/MCAConvertToCallController.reconcile";

import ACCOUNT_IS_PERSON from "@salesforce/schema/Account.IsPersonAccount";
import ZVOD_UNIQUE_ACTIVITY from "@salesforce/schema/Call2_vod__c.zvod_Unique_Group_Activities_vod__c";

import ENABLE_CHILD_ACCOUNT from "@salesforce/schema/Veeva_Settings_vod__c.Enable_Child_Account_vod__c";
import { MAX_ATTENDEE_COUNT } from "c/s4lAttendeeSearch";

export default class ConvertToCallByCreateNewCallVod extends LightningElement {

    @api recordId;
    @api ready;

    // input
    @api mcaId;
    @api mcaDataMapStr;
    // output
    @api exitEarly;
    @api createdCallId;

    labels = {};

    startTime = new Date().getTime();

    // account section flags/ information
    showAccountSelector = true;
    showAccountAlertModal = false;
    get validAccountSelected () {
        return this.selectedAccountId != null;
    }
    selectedAccountId = null;
    // only used for displaying record type error
    selectedAccountName = null;

    // only set to true when PersonAccount is selected and child account is enabled
    showLocationSelectorSection = false;
    selectedLocationId = null;

    showAttendeeSection = false;
    showAddAttendeeModal = false;
    @track selectedAttendees = [];
    get selectedAttendeeIds() {
        return this.selectedAttendees.map(attendee => attendee.id);
    }
    showAttendeeMaxAlert = false;
    get attendeeMaxAlertMessage() {
        return [this.labels.onlyAddNAttendees2.replace("{0}", MAX_ATTENDEE_COUNT)];
    }

    // error flags
    accountRequiredError = false;
    recordTypeRequiredError = false;
    locationRequiredError = false;

    showReconciliationError = false;

    disableSaveButton = false;
    isUniqueActivity = false;

    // set up methods

    constructor () {
        super();
        let pageCtrl = getPageController('pageCtrl');
        pageCtrl.uiApi.requests = [];
        this._pageCtrl = pageCtrl;
        this.accountSearchCtrl = new VeevaAccountSearchController(this._pageCtrl);
        this.getMessages();
        this.loadSettings();
    }

    async getMessages() {
        this.labels = {};
        for (const [key, msg] of Object.entries(MESSAGES)) {
            this.labels[key] = await this._pageCtrl.getMessageWithDefault(msg.key, msg.category, msg.defaultMessage);
        }
        this.ready = true;
    }

    async loadSettings() {
        this.settings = await getVeevaCustomSettings();
    }

    get isChildAccountEnabled() {
        return this.settings[ENABLE_CHILD_ACCOUNT.fieldApiName] === true;
    }

    // account searchbox methods

    focusAccountSearch = function() {
        // remove the "This Field is Required" error when user tries to search for account again
        this.setAccountSearchBoxClass(false);
    }

    handleSelectAccount = function(event) {
        let accountId = event.detail.id;
        try {
            validateAccount({'mcaId': this.mcaId, 'accountId': accountId})
                .then((result) => {
                    this.setAccountSearchBoxClass(false);
                    if(result) {
                        console.error(result);
                        this.showAccountAlert(this.constructModalDataForAccountAlert(result));
                    } else {
                        this.selectedAccountId = accountId;
                        this.selectedAccountName = event.detail.name;
                        this.fetchSupplementaryAccountInformation();
                    }
                }).catch(err => {
                    console.error(err);
                    this.showAccountAlert(this.gerReconciliationErrorModalData());
                });
        } catch (err) {
            console.error(err);
            this.showAccountAlert(this.gerReconciliationErrorModalData());
        }
    }

    showAccountAlert(modalData) {
        this.accountAlertModalData = modalData;
        this.showAccountAlertModal = true;
        this.showAccountSelector = false;
    }

    async fetchSupplementaryAccountInformation() {
        // asynchronous fetch supplementary account information (while we load the record type section and pending user input)
        this.supplementaryAccountInfo = {};
        if(this.selectedAccountId) {
            let account = await this._pageCtrl.uiApi.getRecord(this.selectedAccountId, [
                ACCOUNT_IS_PERSON.objectApiName + '.' + ACCOUNT_IS_PERSON.fieldApiName
            ]);
            if(account && account.fields) {
                for(let key of Object.keys(account.fields)) {
                    this.supplementaryAccountInfo[key] = account.fields[key].value;
                }
            }
        }
    }

    get isPersonAccountSelected() {
        return this.supplementaryAccountInfo[ACCOUNT_IS_PERSON.fieldApiName] === true;
    }

    constructModalDataForAccountAlert = function(result) {
        let errorCode = result.errorCode;
        if(errorCode === 'PRODUCT_ERROR') {
            return this.constructModalData(this.labels.productRestriction,
                this.substituteMessage(this.labels.restrictedPresentation, [result.accountFormattedName, result.productName, result.clmPresentationName]));
        } else if(errorCode === 'SEGMENT_ERROR') {
            return this.constructModalData(this.labels.segmentRestriction,
                this.substituteMessage(this.labels.retrictedSegmentPresentation, [result.accountFormattedName]));
        } else {
            console.error('Unknown errorCode: ' + errorCode);
            return this.gerReconciliationErrorModalData();
        }
    }

    closeAccountAlertModal = function() {
        this.handleClearAccount();
        this.showAccountSelector = true;
    }

    handleClearAccount = function() {
        this.resetAccountSelection();
        this.resetRecordTypeSelection();
        this.resetLocationSelection();
        this.resetAttendeeSelection();
    }

    resetAccountSelection() {
        this.selectedAccountId = null;
        this.selectedAccountName = null;
        this.showAccountAlertModal = false;
        this.supplementaryAccountInfo = {};
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

    handleRecordTypeChange = function(event) {
        this.selectedRecordTypeId = event.detail.selected;
        this.recordTypeRequiredError = false;

        const isPersonAccount = this.isPersonAccountSelected;

        if(this.isChildAccountEnabled && isPersonAccount) {
            this.showLocationSelectorSection = true;
        } else if(!isPersonAccount) {
            this.doesLayoutHasUniqueActivityField(this.selectedRecordTypeId).then(data => {
                this.showAttendeeSection = data;
                if(!data) {
                    // reset attendees
                    this.selectedAttendees = [];
                }
            });
        }
    }

    async doesLayoutHasUniqueActivityField(selectedRecordTypeId) {
        let layout = await this._pageCtrl.uiApi.getPageLayoutNoButtons(ZVOD_UNIQUE_ACTIVITY.objectApiName, 'View', selectedRecordTypeId);
        return this.isFieldOnLayout(layout, ZVOD_UNIQUE_ACTIVITY.fieldApiName);
    }

    isFieldOnLayout (layout, fieldName) {
        if(layout && fieldName) {
            for(let section of layout.sections) {
                for(let row of section.layoutRows) {
                    for(let item of row.layoutItems) {
                        let component = item.layoutComponents.find(x => x.componentType === 'Field');
                        if (component && component.apiName === fieldName) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    handleNoRecordTypeFailure = function() {
        this.showAccountSelector = false;
        // show cannot record call alert
        this.recordTypeAlertModalData = this.constructModalData(
            this.labels.cannotRecordCall,
            this.substituteMessage(this.labels.recordingCallNotAllowedForAccount, [this.selectedAccountName])
        );
        this.resetAccountSelection();
        this.showRecordTypeAlertModal = true;
    }

    resetRecordTypeSelection() {
        this.selectedRecordTypeId = null;
        this.recordTypeRequiredError = false;
        this.showRecordTypeAlertModal = false;
    }

    // location section methods

    handleSelectLocation = function(event) {
        const handleSelectLocation = event.detail.selected;
        this.selectedLocationId = handleSelectLocation;
        this.locationRequiredError = false;
    }

    setLocationNotRequired = function() {
        this.resetLocationSelection();
    }

    resetLocationSelection() {
        this.selectedLocationId = null;
        this.locationRequiredError = false;
        this.showLocationSelectorSection = false;
    }

    // attendees section methods

    resetAttendeeSelection () {
        this.showAttendeeSection = false;
        this.selectedAttendees = [];
    }

    launchAttendeeModal = function() {
        if(this.selectedAttendees.length >= MAX_ATTENDEE_COUNT) {
            this.showAttendeeMaxAlert = true;
        } else {
            this.showAddAttendeeModal = true;
        }
    }

    handleAddAttendees = function(e) {
        this.showAddAttendeeModal = true;
        const added = e.detail.added;
        added.filter(newAttendee => !this.selectedAttendeeIds.includes(newAttendee.id))
            .forEach(newAttendee => this.selectedAttendees.push(newAttendee));
        this.showAddAttendeeModal=false;
    }

    handleCloseAddAttendeeModal = function() {
        this.showAddAttendeeModal = false;
    }

    handleDeleteAttendee = function(e) {
        const toDeleteId = e.target.value;
        if(this.selectedAttendees && this.selectedAttendees.length) {
            let foundIndex = this.selectedAttendees.findIndex(attd => attd.id === toDeleteId);
            if(foundIndex !== -1) {
                this.selectedAttendees.splice(foundIndex, 1);
            }
        }
    }

    closeAttendeeMaxAlert = function() {
        this.showAttendeeMaxAlert = false;
    }

    // footer buttons handlers

    handleCancel = function() {
        this.exitEarly = true;
        this.goToNext();
    }

    handleSave = function() {
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
        const validAccount = this.validAccountSelected;
        const validRecordType = this.selectedRecordTypeId != null;
        const validLocation = !this.showLocationSelectorSection || this.selectedLocationId != null;
        const validAttendees = await this.validateAttendees();
        if(!validAccount) {
            const cmpErrors = [...this.template.querySelectorAll('c-veeva-account-search')].filter(item => item.checkValidity() === false);
            if(!cmpErrors.length) {
                // add "This Field is Required" error only when the account search component doesn't
                // already have the "Select an option from the picklist or remove the search term" error
                this.setAccountSearchBoxClass(true);
            }
        } else if(!validRecordType) {
            this.recordTypeRequiredError = true;
        } else if(!validLocation) {
            this.locationRequiredError = true;
        }
        return validAccount && validRecordType && validLocation && validAttendees;
    }

    async validateAttendees() {
        const attendees = this.selectedAttendees;
        this.isUniqueActivity = await this.doesLayoutHasUniqueActivityField(this.selectedRecordTypeId);
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

    async apexReconcile() {
        try {
            const attendeeLocationIds = {};
            if(this.selectedAttendeeIds.length) {
                for(const attendee of this.selectedAttendees) {
                    attendeeLocationIds[attendee.id] = attendee.parentId || null;
                }
            }
            let result = await reconcile({
                mcaId: this.mcaId,
                accountId: this.selectedAccountId,
                callRecordTypeId: this.selectedRecordTypeId,
                locationId: this.selectedLocationId,
                attendeeLocationIds: attendeeLocationIds,
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
        this.reconErrorModalData = this.gerReconciliationErrorModalData();
        this.showReconciliationError = true;
        this.disableSaveButton = false;
    }

    gerReconciliationErrorModalData () {
        return this.constructModalData(
            this.labels.convertCallErrorTitle,
            this.labels.convertCallError
        );
    }

    closeReconErrorModal () {
        this.showReconciliationError = false;
    }

    // shared util methods

    goToNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    substituteMessage = function(message, params) {
        let result = message;
        for(let i = 0; i < params.length; i++) {
            result = result.replace(`{${i}}`, params[i]);
        }
        return result;
    }

    constructModalData = function(title, message) {
        return {title: title, messages: [message]};
    }
}

const MESSAGES = {
    convertToCall: {
        key: "CONVERT_TO_CALL",
        category: "CLM",
        defaultMessage: "Convert To Call"
    },
    selectAnOption: {
        key: "SELECT_AN_OPTION",
        category: "CLM",
        defaultMessage: "Select an Option"
    },
    addAttendees: {
        key: "ADD_ATTENDEES",
        category: "CLM",
        defaultMessage: "Add Attendees"
    },
    cannotAddAttendeeBecause: {
        key: "CANNOT_ADD_ATTENDEES_BECAUSE",
        category: "CLM",
        defaultMessage: "The following accounts cannot be added as attendees because of either product restrictions or segmentation: {0}"
    },
    convertCallError: {
        key: "CONVERT_CALL_ERROR",
        category: "CLM",
        defaultMessage: "There was an error converting to a call. Please try again or contact your admin."
    },
    convertCallErrorTitle: {
        key: "CONVERT_CALL_ERROR_TITLE",
        category: "CLM",
        defaultMessage: "Convert to Call Error"
    },
    attendeeLimitReached: {
        key: "ATTENDEE_LIMIT_REACHED",
        category: "CLM",
        defaultMessage: "Attendee Limit Reached"
    },
    onlyAddNAttendees: {
        key: "ONLY_ADD_N_ATTENDEES",
        category: "CLM",
        defaultMessage: "You can only add {1} attendees, please remove {0} selected attendees."
    },
    onlyAddNAttendees2: {
        key: "ONLY_ADD_N_ATTENDEES2",
        category: "CLM",
        defaultMessage: "You can only add {0} attendees, please remove attendees before adding more."
    },
    attendeeRestriction: {
        key: 'ATTENDEE_RESTRICTION',
        category: 'CLM',
        defaultMessage: "Attendee Restriction"
    },
    searchAccounts: {
        key: "SEARCH_ACCOUNTS",
        category: "CLM",
        defaultMessage: "Search Accounts"
    },
    thisFieldIsRequired: {
        key: "THIS_FIELD_IS_REQUIRED",
        category: "Common",
        defaultMessage: "This Field is Required"
    },
    segmentRestriction: {
        key: "RESTRICTED_SEGMENT_ALERT_TITLE",
        category: "Common",
        defaultMessage: "Segment Restriction"
    },
    retrictedSegmentPresentation: {
        key: "RESTRICTED_SEGMENT_PRESENTATION",
        category: "CLM",
        defaultMessage: "{0} is not in the appropriate segment(s) and therefore cannot view this presentation."
    },
    productRestriction: {
        key: "RESTRICTED_PRODUCT_ALERT_TITLE",
        category: "Common",
        defaultMessage: "Product Restriction"
    },
    restrictedPresentation: {
        key: "RESTRICT_PRESENTATION",
        category: "CallReport",
        defaultMessage: "{0} is unable to be presented the product {1} in presentation {2}"
    },
    recommendedAccounts: {
        key: "RECOMMENDED_ACCOUNTS",
        category: "Common",
        defaultMessage: "Recommended Accounts"
    },
    add: {
        key: "ADD",
        category: "Common",
        defaultMessage: "Add"
    },
    save: {
        key: "SAVE",
        category: "Common",
        defaultMessage: "Save"
    },
    close: {
        key: "CLOSE",
        category: "Common",
        defaultMessage: "Close"
    },
    cancel: {
        key: "CANCEL",
        category: "Common",
        defaultMessage: "Cancel"
    },
    continue: {
        key: "CONTINUE",
        category: "Common",
        defaultMessage: "Continue"
    },
    search: {
        key: "SEARCH",
        category: "Common",
        defaultMessage: "Search"
    },
    selectAll: {
        key: "SELECT_ALL",
        category: "MyAccounts",
        defaultMessage: "Select All"
    },
    deselectAll: {
        key: "DESELECT_ALL",
        category: "Common",
        defaultMessage: "Deselect All"
    },
    attendees: {
        key: "ATTENDEES",
        category: "Common",
        defaultMessage: "Attendees"
    },
    cannotRecordCall: {
        key: "CANNOT_RECORD_CALL_TITLE",
        category: "Common",
        defaultMessage: "Cannot Record Call"
    },
    recordingCallNotAllowedForAccount: {
        key: "RECORDING_CALL_NOT_ALLOWED_FOR_ACCOUNT",
        category: "Common",
        defaultMessage: "Recording a call is not allowed for {0}"
    }
};