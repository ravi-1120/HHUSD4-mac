import { api, track, LightningElement } from 'lwc';

import VeevaUtils from 'c/veevaUtils';
import { getPageController } from "c/veevaPageControllerFactory";

import getUserTerritory from '@salesforce/apex/MCAConvertToCallController.getUserTerritory';

import queryChildCallAccountAndSignatureDate from '@salesforce/apex/S4LCallSearchController.queryChildCallAccountAndSignatureDate';

import getChildCallChildAccounts from '@salesforce/apex/S4LChildAccountService.getChildCallChildAccounts';
import getSuggestedChildAccounts from '@salesforce/apex/S4LChildAccountService.getSuggestedChildAccounts';
import refineToChildAccountSearchResult from '@salesforce/apex/S4LChildAccountService.refineToChildAccountSearchResult';

import getSuggestedAttendees from '@salesforce/apex/S4LAttendeeService.getSuggestedAttendees';
import getAddresses from '@salesforce/apex/S4LAttendeeService.getAddresses';
import searchAccounts from '@salesforce/apex/S4LAttendeeService.searchAccounts';

import validateAccounts from "@salesforce/apex/S4LAccountValidator.validateAccounts";

const MAX_RECOMMENDED_ATTENDEES = 50;
const ATTENDEES_PER_BATCH = 200;
const MAX_ATTENDEE_RESULT_COUNT = 100000;

const MAX_ATTENDEE_COUNT = 100;

export {MAX_ATTENDEE_COUNT};

export default class S4lAttendeeSearch extends LightningElement {

    @api modalTitle;
    @api saveBtnLabel;
    @api mcaId;
    @api call;
    @api account;
    @api labels;
    @api isChildAccountEnabled;
    @api alreadySelectedAttendeesId;
    @api isSignDetailsOnLayout;

    loading = true;
    showLimitationReachedAlert = false;
    showAttendeeViolationAlert = false;

    searchTerm = '';
    lastSearchResultTerm = '';

    childCallAccountsReady = false;
    @track childCallAccounts = [];

    recommendedAttendeesReady = false;
    @track recommendedAttendees = [];

    searchCommitted = false;
    @track searchResultAttendees = [];

    @track selectedAttendees = {};

    validSelectedAttendees = [];

    hasSignatureErrorMessage = '';
    childCallAccountsWithSignature = [];

    get totalSelectedCount() {
        return this.alreadySelectedAttendeesId.length + Object.keys(this.selectedAttendees).length;
    }

    get displayChildCallAccounts() {
        return this.childCallAccountsReady && this.childCallAccounts.length > 0 && !this.searchCommitted;
    }

    get displayRecommendedAccounts() {
        return this.recommendedAttendeesReady && this.recommendedAttendees.length > 0 && !this.searchCommitted;
    }

    get displaySearchResult() {
        return !this.displayRecommendedAccounts && this.searchCommitted;
    }

    get isAllRecommendedSelected() {
        return this._isAllSelected(this.recommendedAttendees);
    }

    async connectedCallback() {
        this.callTerritory = await getUserTerritory({accountId: this.account});
        if(this.call) {
            // first load all available Child Call Accounts
            await this.loadAllChildCallAccounts();
            await this.getErrorMessage();
        }
        if(!this.displayChildCallAccounts) {
            this.loadAllRecommendedAttendees();
        }
    }

    async getErrorMessage() {
        const veevaMessageSvc = getPageController('messageSvc');
        this.hasSignatureErrorMessage = await veevaMessageSvc.getMessageWithDefault('CLM_ATTENDEE_SIGNED_FOR_DETAILS', 'CallReport','Signature received. Additional products cannot be added.');
    }

    /* child call accounts  */

    async loadAllChildCallAccounts() {
        if(this.isChildAccountEnabled) {
            const childCalls = await getChildCallChildAccounts({callId: this.call});
            await this._parseChildCallChildAccounts(childCalls);
        } else {
            const childCalls = await queryChildCallAccountAndSignatureDate({callId: this.call})
            await this._parseChildCalls(childCalls);
        }
    }

    async _parseChildCalls(childCalls) {
        const parsedChildCallAttendees = childCalls.filter(childCall => childCall && childCall.Account_vod__r && childCall.Account_vod__r.Id)
                                .map(childCall => this._convertNonChildAccountAttendee(childCall))
                                .filter(childCallAttendee => !this._shouldSkipAttendee(childCallAttendee));
        await this._setChildCallAccounts(parsedChildCallAttendees);
    }

    async _parseChildCallChildAccounts(childCalls) { 
        const parsedChildAccounts = childCalls.filter(childCall => childCall.Child_Account_vod__r && childCall.Child_Account_vod__r.Id)
            .map(childCall => this._convertChildAccountCallAttendee(childCall))
            .filter(childAccount => !this._shouldSkipAttendee(childAccount));
        await this._setChildCallAccounts(parsedChildAccounts);
    }

    async _setChildCallAccounts(parsedCcas) {
        if(parsedCcas && parsedCcas.length) {
            this.childCallAccounts = await this._addSupplementalInfoForAttendees(parsedCcas);
            this.childCallAccountsReady = true;
            this.loading = false;
        }
    }

    get isAllAccountsOnCallSelected () {
        return this._isAllSelected(this.childCallAccounts);
    }

    selectAllChildCallAccounts() {
        this._selectAll(this.childCallAccounts);
    }

    deselectAllChildCallAccounts() {
        this._deselectAll(this.childCallAccounts);
    }

    /* recommended attendees */

    async loadAllRecommendedAttendees() {
        if(this.isChildAccountEnabled) {
            getSuggestedChildAccounts({accountId: this.account})
                .then(data => this._parseSuggestedChildAccountAttendeesResult(data));
        } else {
            getSuggestedAttendees({accountId: this.account, params: [], qLimit: MAX_RECOMMENDED_ATTENDEES, atfTerritory: null})
                .then(data => this._parseSuggestedAttendeesResult(data));
        }
    }

    async _parseSuggestedChildAccountAttendeesResult(caAttendees) {
        const recommendedCAAttendees = caAttendees.filter(attendee => attendee && attendee.Child_Account_vod__c)
                                            .map(attendee => this._convertChildAccountAttendee(attendee))
                                            .filter(attendee => !this._shouldSkipAttendee(attendee));
        this._setRecommendedAttendees(recommendedCAAttendees);
    }

    async _parseSuggestedAttendeesResult(attendees) {
        this._setRecommendedAttendees(this._parseNonChildAccountAttendees(attendees));
    }

    _parseNonChildAccountAttendees (attendees) {
        return attendees.filter(attendee => attendee.data && attendee.data.Id)
            .map(attendee => this._convertAttendee(attendee.data.Id, attendee.data.Formatted_Name_vod__c))
            .filter(attendee => !this._shouldSkipAttendee(attendee));
    }

    async _setRecommendedAttendees(parsedAttendees) {
        this.recommendedAttendees = await this._addSupplementalInfoForAttendees(parsedAttendees);
        this.recommendedAttendeesReady = true;
        this.loading = false;
    }

    async _addSupplementalInfoForAttendees(parsedAttendees) {
        const addressIdField = this.isChildAccountEnabled? 'parentId' : 'id';
        const attendeeIds = parsedAttendees.map(attendee => attendee[addressIdField]);
        const accountToAddress = await getAddresses({accountIds: attendeeIds, territory: this.callTerritory});
        parsedAttendees.forEach(attendee => {
            const attendeeId = attendee.id;
            const addressId = attendee[addressIdField];
            attendee.supplementalInfo = this._formatAddress(accountToAddress[addressId]);
            attendee.checked = this._isSelected(attendeeId);
        });
        return parsedAttendees;
    }

    _convertAttendee(id, name) {
        return {
            id,
            formattedName: name
        };
    }

    _convertNonChildAccountAttendee(childCall) {
        const attendee = this._convertAttendee(childCall.Account_vod__r.Id, childCall.Account_vod__r.Formatted_Name_vod__c);
        this.checkForSignatureError(attendee, childCall);
        return attendee;
    }

    _convertChildAccountCallAttendee(childCall) {
        const attendee = this._convertChildAccountAttendee(childCall.Child_Account_vod__r);
        this.checkForSignatureError(attendee, childCall);
        return attendee;
    }

    checkForSignatureError(attendee, childCall) {
        attendee.hasSignatureError = this.isSignDetailsOnLayout && childCall.Signature_Date_vod__c != null;
        attendee.childCallAttendeeClass = 'slds-text-body_regular';
        if (attendee.hasSignatureError) {
            attendee.childCallAttendeeClass += ' has-signature-disable'
            this.childCallAccountsWithSignature.push(attendee.id);
        } 
    }

    _convertChildAccountAttendee(childAccount) {
        const attendee = this._convertAttendee(childAccount.Child_Account_vod__c, childAccount.Parent_Child_Name_vod__c);
        attendee.childAccountId = childAccount.Id;
        attendee.sortByValue = childAccount.Parent_Child_Furigana_vod__c;
        attendee.parentId = childAccount.Parent_Account_vod__c;
        return attendee;
    }

    // the add attendee modal should skip any attendees that are already selected
    _shouldSkipAttendee(attendee) {
        return this.alreadySelectedAttendeesId.includes(attendee.id);
    }

    _formatAddress(address) {
        let addressText = '';
        if (address) {
            addressText = address.Name;
            if (address.Address_line_2_vod__c) {
                addressText += `, ${  address.Address_line_2_vod__c}`;
            }
            if (address.City_vod__c) {
                addressText += `, ${  address.City_vod__c}`;
            }
            if (address.State_vod__c) {
                addressText += `, ${  address.State_vod__c}`;
            }
            if (address.Zip_vod__c) {
                addressText += ` ${  address.Zip_vod__c}`;
            }
            if (address.Country_vod__c) {
                addressText += `, ${  address.Country_vod__c}`;
            }
        }
        return addressText;
    }

    handleSearchTermChange(event) {
        const newSearchTerm = event.detail.value;
        if(newSearchTerm.length === 0) {
            this.lastSearchResultTerm = '';
            this.searchCommitted = false;
        }
        this.searchTerm = newSearchTerm;
    }

    search() {
        if(VeevaUtils.isValidSearchTerm(this.searchTerm) && this.searchTerm !== this.lastSearchResultTerm) {
            this.searchResultAttendees = [];
            this.searchCommitted = true;
            this.loading = true;
            this._executeSearch(this.searchTerm).then(result => {
                if(this.isChildAccountEnabled) {
                    this._refineToChildAccountSearchResult(result);
                } else {
                    this._parseSearchAttendeesResult(result);
                    this.lastSearchResultTerm = this.searchTerm;
                }
            });
        }
    }

    async _refineToChildAccountSearchResult(accountSearchResult) {
        const resultAccountIds = accountSearchResult.filter(found => found && found.data && found.data.Id).map(found => found.data.Id);
        refineToChildAccountSearchResult({accountId: this.account, matchedAccountIds: resultAccountIds})
            .then(filteredAccounts => {
                this._parseSearchChildAccountAttendeesResult(filteredAccounts);
                this.lastSearchResultTerm = this.searchTerm;
            })
    }

    _parseSearchChildAccountAttendeesResult(caAttendees) {
        const parsedAttendees = caAttendees.filter(attendee => attendee && attendee.Child_Account_vod__c)
                                        .map(attendee => this._convertChildAccountAttendee(attendee))
                                        .filter(attendee => !this._shouldSkipAttendee(attendee));
        this._setSearchResult(parsedAttendees);
    }

    _parseSearchAttendeesResult(attendees) {
        this._setSearchResult(this._parseNonChildAccountAttendees(attendees));
    }

    async _setSearchResult (parsedAttendees) {
        this.searchResultAttendees = await this._addSupplementalInfoForAttendees(parsedAttendees);
        this.checkSignatureErrorForSearchedAttendees();
        this.loading = false;
    }

    checkSignatureErrorForSearchedAttendees() {
        this.searchResultAttendees.forEach(attendee => {
            attendee.childCallAttendeeClass = 'slds-text-body_regular';
            if (this.childCallAccountsWithSignature.includes(attendee.id)) {
                attendee.hasSignatureError = true;
                attendee.childCallAttendeeClass += ' has-signature-disable';
            }
        })
    }

    async _executeSearch(searchTerm) {
        let result = [];
        let offset = 0;
        let done = false;
        while(!done) {
            // eslint-disable-next-line no-await-in-loop
            const currentResult = await searchAccounts({
                searchText: searchTerm,
                qLimit: ATTENDEES_PER_BATCH,
                offset,
                skipAccountId: this.account
            });
            if(currentResult && currentResult.length) {
                result = result.concat(result, currentResult);
                if(currentResult.length < ATTENDEES_PER_BATCH || result.length >= MAX_ATTENDEE_RESULT_COUNT) {
                    done = true;
                } else {
                    offset += ATTENDEES_PER_BATCH;
                }
            } else {
                done = true;
            }
        }
        return result;
    }

    handleSelect(event) {
        const {checked} = event.target;
        const exceedCount = this._calculateExceedCount(1);
        if(checked && exceedCount > 0) {
            this._triggerLimitReachError(exceedCount);
        } else {
            const attendeeId = event.target.value;
            this._select(this.childCallAccounts, attendeeId, checked);
            this._select(this.recommendedAttendees, attendeeId, checked);
            this._select(this.searchResultAttendees, attendeeId, checked);
        }
    }

    _select (attendeeList, id, checked) {
        if(attendeeList && attendeeList.length) {
            for(const attendee of attendeeList) {
                if(attendee.id === id) {
                    if(checked) {
                        this._addAttendee(attendee);
                    } else {
                        this._removeAttendee(attendee);
                    }
                    // attendeeList.find(a => a.id === id).forEach(a => a.checked = checked);
                    attendee.checked = checked;
                }
            }
        }
    }

    _isSelected(id) {
        return Object.keys(this.selectedAttendees).includes(id);
    }

    _addAttendee(attendee) {
        if(!this._isSelected(attendee.id)) {
            this.selectedAttendees[attendee.id] = attendee;
        }
    }

    _removeAttendee(attendee) {
        delete this.selectedAttendees[attendee.id];
    }

    selectAllRecommended() {
        this._selectAll(this.recommendedAttendees);
    }

    deselectAllRecommended() {
        this._deselectAll(this.recommendedAttendees);
    }

    _isAllSelected(attendees) {
        if(attendees && this.selectedAttendees) {
            for(const attendee of attendees) {
                if(!this._isSelected(attendee.id) && !attendee.hasSignatureError){
                    return false;
                }
            }
        }
        return true;
    }

    _selectAll(attendees) {
        if(attendees && attendees.length) {
            // if there's still quota to add more attendees
            const addableSize = MAX_ATTENDEE_COUNT - this.totalSelectedCount;
            if(addableSize > 0) {
                // select the first N attendee (up to MAX_ATTENDEE_COUNT)
                for(const attendee of attendees) {
                    if(this.totalSelectedCount < MAX_ATTENDEE_COUNT && !attendee.hasSignatureError) {
                        this._addAttendee(attendee);
                        attendee.checked = true;
                    }
                }
            }
        }
    }

    _deselectAll(attendees) {
        if(attendees && attendees.length) {
            attendees.forEach(a => {
                this._removeAttendee(a);
                a.checked = false;
            });
        }
    }

    _calculateExceedCount(toAddSize) {
        return (this.totalSelectedCount + toAddSize) - MAX_ATTENDEE_COUNT;
    }

    _triggerLimitReachError(exceedCount) {
        this.limitationMessage = [this.labels.onlyAddNAttendees
            .replace('{1}', MAX_ATTENDEE_COUNT)
            .replace('{0}', exceedCount)];
        this.showLimitationReachedAlert = true;
    }

    closeLimitationReachedAlert() {
        this.showLimitationReachedAlert = false;
    }

    _addAttendees(toAddArray) {
        this.dispatchEvent(new CustomEvent('add', {detail: { added: toAddArray } }));
    }

    saveAddedAttendees() {
        const addedAttendeesId = Object.keys(this.selectedAttendees);
        validateAccounts({mcaId: this.mcaId, accountIds: addedAttendeesId}).then(validationResults => {
            if(validationResults && Object.keys(validationResults).length) {
                this._triggerAttendeeViolationError(validationResults);
                this._preserveValidAttendees(this.selectedAttendees, validationResults);
            } else {
                const added = Object.values(this.selectedAttendees);
                this._addAttendees(added);
            }
        });
    }

    saveValidSelectedAttendees() {
        this._addAttendees(this.validSelectedAttendees);
    }

    _preserveValidAttendees(selected, validationResults) {
        const violatedAttendeeIds = Object.keys(validationResults);
        this.validSelectedAttendees = Object.values(selected)
            .filter(selectedAttendee => !violatedAttendeeIds.includes(selectedAttendee.id));
    }

    _triggerAttendeeViolationError(validationResults) {
        const violatedIds = Object.keys(validationResults);
        this.violatedAttendeeNames = Object.values(this.selectedAttendees)
            .filter(selected => violatedIds.includes(selected.id))
            .sort((a, b) => this._getNonnullString(a.sortByValue).localeCompare(this._getNonnullString(b.sortByValue)))
            .map(attendee => attendee.formattedName);
        this.attendeeViolationMessage = [this.labels.cannotAddAttendeeBecause.replace('{0}', '')];
        this.showAttendeeViolationAlert = true;
    }

    _getNonnullString(value) {
        return value != null? value : '';
    }

    closeAttendeeViolationAlert(event) {
        event.stopPropagation();
        this.showAttendeeViolationAlert = false;
    }

    closeAddAttendeeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}