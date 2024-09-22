import LightningModal from 'lightning/modal';
import { api } from 'lwc';

export default class VeevaLightningSearch extends LightningModal {
    @api ctrl;
    @api searchTerm;
    @api customIcons = false;

    searchRecords;
    _nextPageUrl;
    enableInfiniteLoading
    labelCancel;
    columns;
    resultTitle;
    label = 'Search';
    isObjectSearchPopup = true;
    _isLoadingMore;

    async connectedCallback() {
        this.enableInfiniteLoading = false;
        await Promise.all(
            [this.loadMessages(), this.setLabels(), this.setColumnsAndSearch()]
        );
    }

    async loadMessages() {
        this.labelCancel = await this.ctrl.pageCtrl.getMessageWithDefault(
            'CANCEL', 'Common', 'Cancel'
        );
    }

    async setLabels() {
        this.objectInfo = await this.ctrl.getTargetObjectInfo();
        this.resultTitle = this.objectInfo.labelPlural;
        this.label = this.ctrl.field.label;
    }

    async setColumnsAndSearch() {
        this.columns = await this.ctrl.getColumns();
        await this.getSearchRecords();
    }

    async getSearchRecords() {
        if (this.searchTerm) {
            this._nextPageUrl = null;
            const response = await this.ctrl.searchWithColumns(this.searchTerm);
            this.searchRecords = response.records
            this._nextPageUrl = response.nextPageUrl;
            this.enableInfiniteLoading = !!response.nextPageUrl;
        }
    }

    closeModal() {
        this.close();
    }

    handleLookupSelection(event) {
        this.close(event.detail);
    }

    handleRowSelection(event) {
        this.close(event.detail);
    }

    handleSearch(event) {
        event.stopPropagation();
        this.searchTerm = event.detail.term;
        this.getSearchRecords();
    }

    async handleLoadMoreData() {
        if (this._nextPageUrl && !this._isLoadingMore) {
            this._isLoadingMore = true;
            const response = await this.ctrl.searchWithColumns(this.searchTerm, this._nextPageUrl);
            this.searchRecords = this.searchRecords.concat(response.records);
            this._nextPageUrl = response.nextPageUrl;
            this.enableInfiniteLoading = !!response.nextPageUrl;
            this._isLoadingMore = false;
        }
    }

    get hideCheckbox() {
        return true;
    }
}