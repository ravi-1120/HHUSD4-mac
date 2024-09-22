/* eslint-disable no-console */
import { api, track, LightningElement } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import S4lUtils from 'c/s4lUtils';

import getVeevaCustomSettings from "@salesforce/apex/MCAConvertToCallController.getVeevaCustomSettings";
import reconcileWithExistingCall from "@salesforce/apex/MCAConvertToCallController.reconcileWithExistingCall";

import ENABLE_CHILD_ACCOUNT from "@salesforce/schema/Veeva_Settings_vod__c.Enable_Child_Account_vod__c";

export default class S4lAddToExistingCall extends LightningElement {

    // input
    @api mcaId;
    // output
    @api exitEarly;
    @api createdCallId;

    loading = true;
    labels = {};
    alertModalData = {
        isVisible: false
    };

    @track selectedCall = null;
    loadingCall = false;

    showAttendeeSection = false;

    disableSaveButton = false;

    async connectedCallback() {
        // eslint-disable-next-line no-return-assign
        Promise.all([this.getMessages(), this.loadSettings()]).then(() => this.loading = false);
    }

    async loadSettings() {
        this.settings = await getVeevaCustomSettings();
    }

    get isChildAccountEnabled() {
        return this.settings[ENABLE_CHILD_ACCOUNT.fieldApiName] === true;
    }

    async getMessages() {
        this.labels = await S4lUtils.getMessages();
    }

    handleCallLoading() {
        // user made a call selection, but Call Account validation or supplementary information may be still loading
        // hide the attendee section (if it's already showing), disable the save button, & show a spinner
        this.loadingCall = true;
        this.hideAttendeeSection();
        this.disableSaveButton = true;
    }

    handleCallSelection(event) {
        this.loadingCall = false;
        // callInfo's keys = 'id', 'recordTypeId', 'isUniqueActivity', 'accountId', 'accountIsPersonAccount'
        const {callInfo} = event.detail;
        this.selectedCall = callInfo;
        // only show attendee section when the Call Account is a business account & Call's record type page layout has unique activity configured
        this.showAttendeeSection = !callInfo.accountIsPersonAccount && callInfo.isUniqueActivity;
        this.disableSaveButton = false;
    }

    handleCallSelectionError() {
        // reset loading/ selection status so user can make another call selection
        this.loadingCall = false;
        this.disableSaveButton = false;
        this.selectedCall = null;
        this.hideAttendeeSection();
    }

    get selectedCallId () {
        return this.selectedCall? this.selectedCall.id : null;
    }

    get selectedCallAccountId() {
        return this.selectedCall? this.selectedCall.accountId : null;
    }

    /* attendee section */

    hideAttendeeSection() {
        this.showAttendeeSection = false;
    }

    /* handle footer buttons */

    handlePrevious() {
        this.goBack();
    }

    handleCancel() {
        this.exitEarly = true;
        this.goToNext();
    }

    handleSave() {
        this.disableSaveButton = true;
        if(this.preSaveValidation()) {
            this.reconcile();
        } else {
            this.disableSaveButton = false;
        }
    }

    /* reconcile */

    get selectedAttendees() {
        const attendeeSections = [...this.template.querySelectorAll('c-s4l-attendee-section')];
        if(this.showAttendeeSection && attendeeSections && attendeeSections.length && attendeeSections[0].getSelectedAttendees) {
            return attendeeSections[0].getSelectedAttendees();
        }
        return [];
    }

    async reconcile() {
        try {
            const viewedMediaAttendees = {};
            const attendees = this.selectedAttendees;
            if(attendees && attendees.length) {
                for(const attendee of attendees) {
                    viewedMediaAttendees[attendee.id] = {
                        Id: attendee.childAccountId,
                        Parent_Account_vod__c: attendee.parentId
                    };
                }
            }
            const result = await reconcileWithExistingCall({
                mcaId: this.mcaId,
                callId: this.selectedCall? this.selectedCall.id : null,
                viewedMediaAttendees,
                isUniqueActivity: this.selectedCall? this.selectedCall.isUniqueActivity : false,
                isSD: this.selectedCall.isSD
            });
            if(result != null) {
                this.createdCallId = result;
                this.goToNext();
            } else {
                this.handleReconciliationError();
            }
        } catch(err) {
            console.error(err);
            this.handleReconciliationError(err);
        }
    }

    preSaveValidation() {
        const hasDataValidityError = [...this.template.querySelectorAll('[data-validity]')].filter(item => item.checkValidity() === false).length;
        return !hasDataValidityError;
    }

    handleReconciliationError(err) {
        const reconErrorModalData = this.getReconciliationErrorModalData(err);
        this.showAlertModal(reconErrorModalData.title, reconErrorModalData.message, this.hideAlertModal);
        this.showReconciliationError = true;
        this.disableSaveButton = false;
    }

    getReconciliationErrorModalData (err) {
        if (err && err.body.message && err.body.message.indexOf('call signature date populated') > -1) {
            return S4lUtils.getReconciliationSignedCallErrorModalData(this.labels);
        } 
        return S4lUtils.getReconciliationErrorModalData(this.labels);
    }

    /* utils */

    goToNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    goBack() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    showAlertModal(title, message, handler) {
        this.alertModalData = {
            title,
            messages: [message],
            onCloseHandler: handler,
            isVisible: true
        };
    }

    hideAlertModal() {
        this.alertModalData = {
            isVisible: false
        };
    }
}