import { api, wire } from 'lwc';
import CALLS_PER_DAY_VOD from '@salesforce/schema/Preferences_vod__c.Calls_Per_Day_vod__c';
import { SERVICES, getService } from 'c/veevaServiceFactory';

import VeevaLegacyDataService from 'c/veevaLegacyDataService';
import LightningModal from 'lightning/modal';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

export default class MyAccountsScheduleCallModal extends LightningModal {
  @api labels;
  @api accountIds;
  @api preferencesId;

  callsPerDay = 8;
  // Create todays date without time.
  todaysDate =  new Date(new Date().toDateString()).toISOString();

  showScheduleNote = false;
  scheduleNote;

  _internalLoading = false;
  isPreferencesLoading = true;

  timeoutId;

  get loading() {
    return this.isPreferencesLoading || this._internalLoading;
  }


  @wire(getRecord, { recordId: '$preferencesId', fields: [CALLS_PER_DAY_VOD] })
  wireRecordInfo({ data, error }) {
    if (data && this.isPreferencesLoading) {
        this.callsPerDay = data.fields.Calls_Per_Day_vod__c.value || 8;
        this.checkCallsPerDay();
        this.isPreferencesLoading = false;
    } else if (error) {
        this.isPreferencesLoading = false;
    }
  }

  async checkCallsPerDay() {
    const response = await this._sendRequest('SCHEDCHECK_ISO');

    if (response) {
      // The response returned is the veeva message and includes HTML so we strip them here.
      this.scheduleNote = response.replace(/<(?:"[^"]*"['"]*|'[^']*'['"]*|[^'">])+>/g, '');
      this.showScheduleNote = true;
    } else {
      this.showScheduleNote = false;
    }
  }

  handleKeyPress(event) {
    event.stopPropagation();
    event.preventDefault();
    return false;
  }

  async handleScheduleCall() {
    this._internalLoading = true;
    const response = await this._sendRequest('SCHED_ISO');

    if (response.success) {
      this.close({ created: true });
    } else {
      this.template.querySelector('c-my-accounts-modal-dispatch').dispatchErrorToast({ message: this.labels.actionError });
    }
    this._internalLoading = false;
  }

  async _sendRequest(event) {
    const legacyDataSvc = new VeevaLegacyDataService(getService(SERVICES.SESSION));

    const dateParts = this._getDateParts(this.template.querySelector('lightning-input[data-id=start-date]')?.value);
    const isoFormattedDateString = this._formatDatePartsToISOStyleOrDefaultToday(dateParts);

    const body = {
      oType: 'callplan',
      event,
      accs: [...this.accountIds].join(','),
      STDT_ISO: isoFormattedDateString,
      CPD: this.callsPerDay,
      CPDVAL: this.callsPerDay,
    };

    return legacyDataSvc.sendRequest('POST', undefined, undefined, body, undefined);
  }

  _getDateParts(value) {
    if (value) {
      // Value is returned from a lightning inpute of type date, can include time and we need to remove it.
      const dateParts = value.replace(/T\d{2}:\d{2}:\d{2}\.\d{3}Z/, '').split('-');
      if (dateParts) {
        return dateParts;
      }
    }
    return undefined;
  }

  _formatDatePartsToISOStyleOrDefaultToday(dateParts) {
    let isoFormattedDateString;
    if (dateParts) {
      isoFormattedDateString = `${dateParts[0]}-${dateParts[1]}-${dateParts[2]}`;
    } else {
      const today = new Date();
      isoFormattedDateString = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`;
    }

    return isoFormattedDateString;
  }

  handleCancel() {
    this.close();
  }

  handleDecrement(event) {
    event.stopPropagation();
    this._updateInputCounter(-1);
  }

  handleIncrement(event) {
    event.stopPropagation();
    this._updateInputCounter(1);
  }

  async _updateInputCounter(newValue) {
    const value = Number(this.template.querySelector('.slds-input_counter').value) + newValue;
    if (value > 0 && value <= 50) {
      this.callsPerDay = value;
      this.template.querySelector('.slds-input_counter').value = value;
      clearTimeout(this.timeoutId);
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.timeoutId = setTimeout(() => {
        this.checkCallsPerDay();
        this._updateCallsPerDayPreference();
      }, 1000);
    }
  }

  async _updateCallsPerDayPreference() {
    await updateRecord({
      fields: {
        Calls_Per_Day_vod__c: this.callsPerDay,
        Id: this.preferencesId,
      },
    });
  }
}