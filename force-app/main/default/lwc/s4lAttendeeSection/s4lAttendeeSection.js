import { api, track, LightningElement } from 'lwc';

import { MAX_ATTENDEE_COUNT } from "c/s4lAttendeeSearch";

export default class S4lAttendeeSection extends LightningElement {

    @api labels;
    @api mcaId;
    @api selectedCallId;
    @api selectedAccountId;
    @api title;
    @api addAttendeesButtonLabel;
    @api attendeeSearchModalTitle;
    @api attendeeSearchModalSaveBtnLabel;
    @api isChildAccountEnabled;
    @api isSignDetailsOnLayout;

    showLimitationReachedAlert = false;
    showRequiredError = false;

    showAttendeeSearchModal = false;

    @track selectedAttendees = [];
    get selectedAttendeeIds() {
        return this.selectedAttendees.map(attendee => attendee.id);
    }

    @api getSelectedAttendees() {
        return this.selectedAttendees;
    }

    @api checkValidity() {
        const isValid = this.selectedAttendees && this.selectedAttendees.length;
        if(!isValid) {
            this.showRequiredError = true;
        }
        return !!isValid;
    }

    get attendeeMaxAlertMessage() {
        return [this.labels.onlyAddNAttendees2.replace("{0}", MAX_ATTENDEE_COUNT)];
    }

    // launch the modal for s4lAttendeeSearch component
    launchAttendeeSearchModal() {
        if(this.selectedAttendees.length >= MAX_ATTENDEE_COUNT) {
            this.showLimitationReachedAlert = true;
        } else {
            this.showAttendeeSearchModal = true;
        }
    }

    closeLimitationReachedAlert() {
        this.showLimitationReachedAlert = false;
    }

    // handle 'add' event from s4lAttendeeSearch
    handleAddAttendees(e) {
        this.showAttendeeSearchModal = true;
        this.showRequiredError = false;
        const {added} = e.detail;
        added.filter(newAttendee => !this.selectedAttendeeIds.includes(newAttendee.id))
            .forEach(newAttendee => this.selectedAttendees.push(newAttendee));
        this.showAttendeeSearchModal = false;
    }

    // handle 'close' event from s4lAttendeeSearch
    handleCloseAddAttendeeModal() {
        this.showAttendeeSearchModal = false;
    }

    // handle user action of clicking on the trash can icon to 'delete' selected recipient
    handleDeleteAttendee(e) {
        const toDeleteId = e.target.value;
        if(this.selectedAttendees && this.selectedAttendees.length) {
            const foundIndex = this.selectedAttendees.findIndex(attd => attd.id === toDeleteId);
            if(foundIndex !== -1) {
                this.selectedAttendees.splice(foundIndex, 1);
            }
        }
    }
}