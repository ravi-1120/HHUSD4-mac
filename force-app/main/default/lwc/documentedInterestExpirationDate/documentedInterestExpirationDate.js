import { LightningElement, api, track } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class DocumentedInterestExpirationDate extends VeevaErrorHandlerMixin(LightningElement) {
    @track value;
    @api ctrl;
}