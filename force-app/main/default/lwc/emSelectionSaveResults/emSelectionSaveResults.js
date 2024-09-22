import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

const INSERT_FAILS = 'insertFails';
const DELETE_FAILS = 'deleteFails';

export default class EmSelectionSaveResults extends NavigationMixin(LightningElement) {

    @api set saveResults(data) {
        this._saveResults = data;
        if (data) {
            this.saveData = JSON.parse(data);
        }
    };
    get saveResults() {
        return this._saveResults;
    }

    hideInsertErrors = true;
    hideDeleteErrors = true;

    insertSuccesses;
    insertErrorObjectLabel
    insertErrorMessageDetails;
    failedInsertMessage1;
    failedInsertMessage2;
    insertErrors;

    deleteSuccesses;
    deleteErrorObjectLabel
    deleteErrorMessageDetails
    failedDeleteMessage1;
    failedDeleteMessage2;
    deleteErrors;

    get hasInsertErrors() {
        return this.failedInsertMessage1 && this.failedInsertMessage2;
    }

    get hasDeleteErrors() {
        return this.failedDeleteMessage1 && this.failedDeleteMessage2;
    }

    get addSuccessMsg() {
        return this.saveData?.messages.addSuccessMsg;
    }

    get deleteSuccessMsg() {
        return this.saveData?.messages.deleteSuccessMsg;
    }

    get addFailMsg() {
        return this.saveData?.messages.addFailMsg;
    }

    get deleteFailMsg() {
        return this.saveData?.messages.deleteFailMsg;
    }

    get icon() {
        return this.saveData?.icon;
    }

    getObjectLabel(count) {
        return count > 1 ? this.saveData?.objectLabelPlural : this.saveData?.objectLabel;
    }

    connectedCallback() {
        if (this.saveData?.insertCount > 0) {
            const {insertCount} = this.saveData;
            this.insertSuccesses = this.addSuccessMsg.replace('{0}', insertCount).replace('{1}', this.getObjectLabel(insertCount));
        }
        if (this.saveData?.failedInsertCount > 0) {
            const {failedInsertCount} = this.saveData;
            [this.failedInsertMessage1, this.failedInsertMessage2] = this.addFailMsg.replace('{0}', failedInsertCount).split('{1}');
            this.insertErrorObjectLabel = this.getObjectLabel(failedInsertCount);
            this.insertErrors = this.saveData.failedInsertRecords;
            this.insertErrorMessageDetails = this.saveData.failedInsertMessage;
        }
        if (this.saveData?.deleteCount > 0) {
            const {deleteCount} = this.saveData;
            this.deleteSuccesses = this.deleteSuccessMsg.replace('{0}', deleteCount).replace('{1}', this.getObjectLabel(deleteCount));
        }
        if (this.saveData?.failedDeleteCount > 0) {
            const {failedDeleteCount} = this.saveData;
            [this.failedDeleteMessage1, this.failedDeleteMessage2] = this.deleteFailMsg.replace('{0}', failedDeleteCount).split('{1}');
            this.deleteErrorObjectLabel = this.getObjectLabel(failedDeleteCount);
            this.deleteErrors = this.saveData.failedDeleteRecords;
            this.deleteErrorMessageDetails = this.saveData.failedDeleteMessage;
        }
    }

    toggleDetails(event) {
        const id = event.target.getAttribute('data-id');
        if (id === INSERT_FAILS) {
            this.hideInsertErrors = !this.hideInsertErrors;
        } else if (id === DELETE_FAILS) {
            this.hideDeleteErrors = !this.hideDeleteErrors;
        }
    }

    close() {
        this.dispatchEvent(new FlowNavigationFinishEvent());
    }
}