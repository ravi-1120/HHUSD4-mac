import { LightningElement, api } from 'lwc';

export default class NoRecordsMessage extends LightningElement {

    @api listData;
    @api ctrl;
    @api msg;
    defaultMessage;

    get msgNoData(){
        return (this.msg) ? this.msg : this.defaultMessage;
    }

    get noResults() {
        return !this.listData || this.listData.length === 0;
    }

    async connectedCallback() {
        this.defaultMessage = await this.ctrl.pageCtrl.getMessageWithDefault(
            'NO_RECORDS', 'Common', 'No Results'
        );
    }
}