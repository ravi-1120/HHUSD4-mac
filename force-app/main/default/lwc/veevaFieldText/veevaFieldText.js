import { LightningElement, api, track } from 'lwc';
import VeevaConstant from 'c/veevaConstant';
import TIME_ZONE from '@salesforce/i18n/timeZone';

// This class is created because lightning-input does not wrap long text and does not support scale in decimal number display
export default class VeevaFieldText extends LightningElement {
    @track value;

    @api
    get ctrl(){
        return this._ctrl;
    }

    set ctrl(value){
        this._ctrl = value;
        this.setValue();
    }

    async setValue() {
        let val;
        if (this.isNumber || this.dateTimeNeedsFormatting) {
            val = await this._ctrl.rawValue;
        } else {
            // some implementations of displayValue (like in medicalInquiryRecord.js) return promises;
            // so we need to await the results
            val = await this._ctrl.displayValue;
        }
        this.value = val;
    }

    get isNumber() {
        // Use lightning-formatted-number only for new mode to match salesforce behavior
        // as formatted-text works for view and edit based on displayValue
        // if currency field was returned via soql query, displayValue is just a number and needs to use lightning-formatted-number
        if (this.currencyNeedsFormatting) {
            return true;
        }
        return VeevaConstant.FIELD_TYPE_NUMBER.includes(this._dataType);
    }

    get currencyNeedsFormatting(){
        return this.isCurrency && this.ctrl.record.isNew;
    }

    get isPhone() {
        return this._dataType === 'Phone'
    }

    get isEmail() {
        return this._dataType === 'Email'
    }

    get isCurrency() {
        return this._dataType === 'Currency';
    }

    get dateTimeNeedsFormatting() {
        return ['Date', 'DateTime'].includes(this._dataType);
    }

    get isRichText() {
        return (this.ctrl.field && (this.ctrl.field.extraTypeInfo === 'RichTextArea' || this.ctrl.field.htmlFormatted));
    }

    get isText() {
        return !(this.isNumber || this.isPhone || this.isEmail || this.dateTimeNeedsFormatting || this.isRichText);
    }

    get formatter() {
        let formatter;
        if (this.isCurrency) {
            // For new page, if multicurrency org, read-only currency fields display the number only, 
            // while single currency orgs display with currency symbol
            formatter = this.ctrl.data.fields.CurrencyIsoCode ? 'decimal' : 'currency'; 
        } else if (this.isNumber) {
            formatter = VeevaConstant.FIELD_TYPE_TO_FORMATTER[this._dataType] || 'decimal';
        }
        return formatter;
    }

    get timeFormat() {
        let format;
        if (this._dataType === 'DateTime') {
            format = '2-digit';
        }
        return format;
    }

    get timeZone() {
        let timeZone;
        if (this._dataType === 'Date') {
            timeZone = 'UTC';
        } else if(this._dataType === 'DateTime' && this.ctrl.timezone) {
            timeZone = this.ctrl.timezone;
        } else if(this._dataType === 'DateTime') {
            timeZone = TIME_ZONE;
        }
        return timeZone;
    }

    get _dataType() {
        return this.ctrl && this.ctrl.dataType;
    }
}