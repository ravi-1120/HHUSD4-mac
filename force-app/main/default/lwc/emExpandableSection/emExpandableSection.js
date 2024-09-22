/* eslint-disable @locker/locker/distorted-xml-http-request-window-open */
import { api, LightningElement } from 'lwc';

const OPEN_ICON = "utility:chevrondown";
const CLOSE_ICON = "utility:chevronright";
const OPEN_CLASS = "slds-section slds-is-open";
const CLOSE_CLASS = "slds-section slds-is-close";

export default class EmExpandableSection extends LightningElement {

    @api title;
    @api open = false;

    get expanderIcon() {
        return this.open ? OPEN_ICON : CLOSE_ICON;
    }

    get sectionClass() {
        return this.open ? OPEN_CLASS : CLOSE_CLASS;
    }

    toggleSection() {
        this.open = !this.open;
    }
}