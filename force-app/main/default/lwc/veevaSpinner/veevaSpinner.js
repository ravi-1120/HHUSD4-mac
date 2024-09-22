import { api, LightningElement } from 'lwc';

export default class VeevaSpinner extends LightningElement {
    @api size;
    @api isBlocking = false;
    _spinnerStyle;
    @api
    get spinnerStyle() {
        if (!this._spinnerStyle) {
            return "spinner-container"
        }
        return this._spinnerStyle;
    }
    set spinnerStyle(style) {
        this._spinnerStyle = style;
    }
}