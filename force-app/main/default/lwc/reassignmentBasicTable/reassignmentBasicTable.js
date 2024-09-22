import { LightningElement, api} from 'lwc';

export default class ReassignmentBasicTable extends LightningElement {
    @api title;
    @api tableDataSvc;
    @api tableColumns;
    @api tableData;
    @api totalCount;

    limit = 10;
    offset = 0;
    msgLoaded = false;

    labelPrevious;
    labelNext;
    recordNumMsg;

    get tableContainerClass() {
        return this.title ? 'bPageBlock' : ''
    }

    get datatableClass() {
        return this.title ? 'slds-m-around_x-small' : '';
    }

    get hasNext() {
        return this.offset + this.limit < this.totalCount;
    }

    get hasPrevious() {
        return this.offset > 0 && this.offset - this.limit >= 0;
    }

    get previousClass() {
        return this.hasPrevious ? 'slds-p-around_x-small' : 'slds-p-around_x-small disabled';
    }

    get nextClass() {
        const nextClasses = 'slds-p-around_x-small slds-m-left_x-small';
        return this.hasNext ? nextClasses : `${nextClasses} disabled`;
    }

    get totalPageNum() {
        return Math.ceil(this.totalCount/this.limit);
    }

    get pageNum() {
        const currentPageNum = parseInt((this.offset + this.limit) / this.limit, 10);
        return `${currentPageNum}/${this.totalPageNum}`
    }

    get recordNum() {
        return this.recordNumMsg.replace('{0}', this.totalCount);
    }

    async connectedCallback() {
        await this.getCommonMsgs();
        this.msgLoaded = true;
    }

    async getCommonMsgs() {
        const {messageSvc} =  this.tableDataSvc;
        const [labelPrevious, labelNext, recordNumMessage]
        = await Promise.all([
            messageSvc.getMessageWithDefault('PREVIOUS', 'Common', '上一页'),
            messageSvc.getMessageWithDefault('NEXT', 'Common', '下一页'),
            messageSvc.getMessageWithDefault('RECORD_NUM_IN_LIST', 'WeChat', '总条数: {0}')
        ]);
        this.labelPrevious = `< ${labelPrevious}`;
        this.labelNext = `${labelNext} >`;
        this.recordNumMsg = recordNumMessage;
    }

    goToPrevious() {
        if (!this.hasPrevious) {
            return;
        }
        this.offset -= this.limit;
        this.dispatchLoadDataEvent();
    }

    goToNext() {
        if (!this.hasNext) {
            return;
        }
        this.offset += this.limit;
        this.dispatchLoadDataEvent();
    }

    dispatchLoadDataEvent () {
        this.dispatchEvent(new CustomEvent('loaddata', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: { data: {offset: this.offset} }
        }));
    }

    async actionHandler(event) {
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent('actionclicked', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: event.detail
        }))
    }
}