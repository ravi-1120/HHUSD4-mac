import getRelatedAccountDataInRange from "@salesforce/apex/VeevaMyScheduleController.getRelatedAccountDataInRange";
import ICON_PATH from '@salesforce/resourceUrl/calendarIcons';

export default class CallConflictManager {
    #callDatesByAccount;
    callScheduleConflictThreshold;

    constructor(callScheduleConflictThreshold, callObjectInfo) {
        this.callScheduleConflictThreshold = callScheduleConflictThreshold;
        this.#callDatesByAccount = {};
        this.callIdsByAccount = {};
        this.idsToDates = {};
        this.callObjectInfo = callObjectInfo;
    }

    async checkForCallsInRelatedAccounts(formattedDateRange, accountIds, callIds) {
        if (!accountIds || accountIds.length < 1) {
            return;
        }
        try {
            this.populateExistingCallsByAccount(accountIds, callIds);
            const relatedAccountData = await getRelatedAccountDataInRange({ currentStart: formattedDateRange.startDate, currentEnd: formattedDateRange.endDate, accountIds, callIds });
            if (relatedAccountData) {
                Object.entries(relatedAccountData).forEach(([accountId, callMap]) => {
                    const callMapDates = Object.values(callMap);
                    const callMapIds = Object.keys(callMap);
                    if (accountId in this.#callDatesByAccount) {
                        this.#callDatesByAccount[accountId].push(...callMapDates.map(d => new Date(`${d}T00:00:00`).toISOString()));
                        this.callIdsByAccount[accountId].push(...callMapIds);
                    } else {
                        this.#callDatesByAccount[accountId] = callMapDates.map(d => new Date(`${d}T00:00:00`).toISOString());
                        this.callIdsByAccount[accountId] = callMapIds;
                    }
                    
                    Object.entries(callMap).forEach(([ids, dates]) => {
                        this.idsToDates[ids] = dates;
                    });
                });
            }
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error(`Failed to receive information on calls for other users with accounts the current user has calls with. This will only impact the display of call conflict icons. Error: ${e?.body?.message}`);
        }
    }

    get callDatesByAccount() {
        return this.#callDatesByAccount;
    }

    updateCallDatesByAccount(callsToAdd = [], callsToRemove = []) {
        this._removeCallDatesByAccount(callsToRemove);
        this._addCallDatesByAccount(callsToAdd);
    }

    needsConflictIcon(eventData) {
        eventData.datesConflict = false;
        if (!this.callScheduleConflictThreshold && (eventData.hasUnscheduledRemoteMeeting || eventData.uninvitedRemoteAttendeeNumber)) {
            return true;
        }
        const callDatesForAccount = this._getCallDatesForAccount(eventData.accountId);
        if (!eventData.accountId || !eventData.name || !this.callScheduleConflictThreshold || !callDatesForAccount || callDatesForAccount.length < 1
            || (this.callScheduleConflictThreshold && !this.callObjectInfo?.fields?.zvod_Call_Conflict_Status_vod__c)) {
            return false;
        }
        const todayDate = new Date(eventData.startDate);
        const newDateForward = this._getFutureConflictThreshold(todayDate);
        const newDateBackward = this._getPastConflictThreshold(todayDate);

        // there needs to be two instances of a call with the same account either today or within the conflict window set by the veeva setting
        const conflictingDates = callDatesForAccount.filter(callDate => callDate > newDateBackward && callDate < newDateForward);
        const datesConflict = conflictingDates.length > 1;
        if (datesConflict) {
            eventData.datesConflict = true;
        }
        return (eventData.hasUnscheduledRemoteMeeting || eventData.uninvitedRemoteAttendeeNumber) || datesConflict;
    }
    
    populateExistingCallsByAccount(accountIds, callIds) {
        Object.entries(this.callIdsByAccount).forEach(([accountId, callList]) => {
            if (accountIds.includes(accountId)) {
                callIds.push(...callList);
            }
        });
    }

    static getCallsWithAccount(calendarEvents) {
        return calendarEvents.filter(eventData => eventData.objectType === 'Call2_vod__c' && eventData.accountId);
    }

    static addCallConflictElement(container) {
        if (container.getElementsByClassName("warning").length > 0) {
            return;
        }
        const iconElt = document.createElement('div');
        iconElt.className = "icon-container";
        const iconImgElt = document.createElement('img');
        iconImgElt.className = "event-icon warning";
        iconImgElt.alt = "warning icon";
        iconImgElt.src = `${ICON_PATH}/warningIcon.svg`;
        iconElt.appendChild(iconImgElt)
        container.appendChild(iconElt);
    }

    static padNumber(num) { 
        return num < 10 ? `0${num}` : num;
    }

    static getDateStr(date) {
        return `${date.getFullYear()}-${CallConflictManager.padNumber(date.getMonth()+1)}-${CallConflictManager.padNumber(date.getDate())}`; 
    }

    _removeCallDatesByAccount(oldCalls) {
        if (!oldCalls || oldCalls.length < 1) {
            return;
        }

        oldCalls.forEach(eventData => {
            const idIndex = this.callIdsByAccount[eventData.accountId]?.indexOf(eventData.id);
            if (idIndex > -1) {
                const dateIndex = this.#callDatesByAccount[eventData.accountId]?.indexOf(this.idsToDates[eventData.id]);
                if (dateIndex > -1) {
                    this.#callDatesByAccount[eventData.accountId].splice(dateIndex, 1);
                    this.callIdsByAccount[eventData.accountId].splice(idIndex, 1);
                    delete this.idsToDates[eventData.id];
                }
            }
        });
    }

    _addCallDatesByAccount(newCalls) {
        if (!newCalls || newCalls.length < 1) {
            return;
        }
        newCalls.forEach(eventData => {
            const dateString = eventData.startDate.toISOString();
            if (eventData.accountId in this.#callDatesByAccount && !this.callIdsByAccount[eventData.accountId].includes(eventData.data.id)) {
                this.#callDatesByAccount[eventData.accountId].push(dateString);
                this.callIdsByAccount[eventData.accountId].push(eventData.data.id);
                this.idsToDates[eventData.data.id] = dateString;
            } else if (!(eventData.accountId in this.#callDatesByAccount)) {
                this.#callDatesByAccount[eventData.accountId] = [dateString];
                this.callIdsByAccount[eventData.accountId] = [eventData.data.id];
                this.idsToDates[eventData.data.id] = dateString;
            } else {
                const dateIndex = this.#callDatesByAccount[eventData.accountId]?.indexOf(this.idsToDates[eventData.data.id]);
                this.#callDatesByAccount[eventData.accountId][dateIndex] = dateString;
                this.idsToDates[eventData.data.id] = dateString;
            }
        });
    }

    _getCallDatesForAccount(accountId) {
        if (!accountId || !this.#callDatesByAccount[accountId]) {
            return [];
        }
        return this.#callDatesByAccount[accountId].map(eventString => new Date(eventString));
    }

    _getFutureConflictThreshold(currentDate) {
        const newDate = new Date(currentDate);
        newDate.setDate(currentDate.getDate() + this.callScheduleConflictThreshold);
        newDate.setHours(0);
        newDate.setMinutes(0);
        return newDate;
    }

    _getPastConflictThreshold(currentDate) {
        const newDate = new Date(currentDate);
        newDate.setDate(currentDate.getDate()  - this.callScheduleConflictThreshold);
        newDate.setHours(23);
        newDate.setMinutes(59);
        return newDate;
    }
}