import VeevaBaseController from 'c/veevaBaseController';
import MedInqConstant from 'c/medInqConstant';
import { getAddressText } from "c/addressVod";
import { MethodLayout } from './methodLayout.js';
import template from './zvodDeliveryMethodController.html';

const METHOD_TO_SIGNAL = { "Mail_vod": "eom", "Urgent_Mail_vod": "eom", "Email_vod": "eoe", "Phone_vod": "eop", "Fax_vod": "eof" };
const SIGNALS = ["eom", "eoe", "eop", "eof"];

export default class ZvodDeliveryMethodController extends VeevaBaseController {

    initTemplate() {
        this.template = template;
        return this;
    }

    async getMethods(value) {
        const deliveryMethod = value || this.data.rawValue(MedInqConstant.DELIVERY_METHOD);
        const primary = await this.primaryMethod(deliveryMethod);
        const optionalMethods = await this.optionalMethods();
        const result = { primaryMethod: primary, optionalMethods };
        optionalMethods.forEach(x => { x.render = !primary || x.signal !== primary.signal; });
        if (primary) {
            primary.primaryOnly = !optionalMethods.filter(x => x.render).length;
        }
        return result;
    }

    clearAllValues() {
        this.data.delivery.clear(Object.values(MedInqConstant.NEW_FIELDS).flat());
    }

    getAllValues() {
        return this.data.delivery.get(Object.values(MedInqConstant.NEW_FIELDS).flat());
    }

    setAllValues(fieldsAndValues) {
        this.data.delivery.set(fieldsAndValues);
    }

    async primaryMethod(method) {
        if (method) {
            const signal = METHOD_TO_SIGNAL[method];
            return this.methodLayout.describeMethod(signal, true);
        }
        return null;
    }

    async optionalMethods() {
        if (!this._optionalMethods) {
            const signals = SIGNALS.filter(x => this.meta.options.includes(x));
            this._optionalMethods = await Promise.all(signals.map(signal =>
                this.methodLayout.describeMethod(signal)));
        }
        return this._optionalMethods;
    }

    get methodLayout() {
        if (!this.describeMethod) {
            Object.assign(this, MethodLayout);
        }
        return this;
    }

    isNewModeNotCloneNotCopy(){
        return this.pageCtrl.isNew && !this.pageCtrl.isClone && !this.data.isMPICopy;
    }

    async selected(method) {
        return this.data.delivery.selectedDelivery(method, await this.statePicklists(), await this.countryPicklists());
    }

    async options(method) {
        let result = await this.data.delivery.deliveryOptions(method);
        if (method === 'eom') {
            const state = await this.statePicklists();
            const country = await this.countryPicklists();

            result.forEach(option => {
                option.label = getAddressText(option, state, country);
                option.value = option.label;
                option.Address_Line_1_vod__c = option.Name;
                delete option.Name;
                option.Address_Line_2_vod__c = option.Address_line_2_vod__c;
                delete option.Address_line_2_vod__c;
            });
        }
        else {
            result = result.map(option => ({ 'label': option, 'value': option }));
        }
        return result;
    }

    handleChange(values, method) {
        this.data.delivery.stampMethodFields(values, method);
    }

    toggleNewOption(method) {
        this.data.delivery.clear(MedInqConstant.NEW_FIELDS[MedInqConstant.SIGNALS_MAP[method]]);
    }

    async statePicklists() {
        if (!this._statePicklists) {
            this._statePicklists = await this.pageCtrl.getPicklistValues(MedInqConstant.STATE, this.recordTypeId);
        }
        return this._statePicklists;
    }

    async countryPicklists() {
        if (!this._countryPicklists) {
            this._countryPicklists = await this.pageCtrl.getPicklistValues(MedInqConstant.COUNTRY, this.recordTypeId);
        }
        return this._countryPicklists;
    }
}