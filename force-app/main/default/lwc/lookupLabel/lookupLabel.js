import { api, LightningElement } from 'lwc';

export default class LookupLabel extends LightningElement {

    @api lookupRecord;
    @api field;

    get label() {
        let recordLabel = '';
        if (this.lookupRecord && this.field) {
            recordLabel = this.lookupRecord[this.field] || '';
        }
        return recordLabel;
    }

}