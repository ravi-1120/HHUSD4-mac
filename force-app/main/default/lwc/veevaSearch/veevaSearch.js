import { LightningElement, api, track } from 'lwc';
import VeevaLightningSearch from "c/veevaLightningSearch";

// TODO: discrepancy between this and Salesforce's search
export default class VeevaSearch extends LightningElement {
    @api ctrl;
    @api set searchTerm(val) {
        this._searchTerm = val;
        this.records = [];
    }

    get searchTerm() {
        return this._searchTerm;
    }

    @api customIcons = false;
    @track records = [];
    @track labelCancel;
    @track columns;
    @track resultTitle;
    @track label;
    @track nextPageUrl;
    @track isLoadingMore;
    isObjectSearchPopup = true;
    showDefault = false;
    loading = true;

    get modalSize() {
      return this.columns?.length === 1 ? 'veeva-narrow' : 'large';
    }

    async connectedCallback() {
        if (this.ctrl.meta && this.ctrl.meta.useLgtnModal) {
            // Loading lightning-based veeva-search if necessary
            // Otherwise, proceeding as usual

            const response = VeevaLightningSearch.open({
                ctrl: this.ctrl,
                searchTerm: this.searchTerm,
                customIcons: this.customIcons
            });
            response.then((closeResult) => {
                if (closeResult) {
                    this.handleLookupSelection({ detail: closeResult });
                }
                this.handleClose();
            })
        } else {
            this.showDefault = true;
            this.enableInfiniteLoading = false;
            await Promise.all(
                [this.loadMessages(), this.setLabels(), this.setColumnsAndSearch()]
            );
        }
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
        this.loading = true;
        const { columns, response } = await this.ctrl.getColumnsAndSearch(this.searchTerm);
        this.columns = columns || [];
        this.setRecords(response || {});
        this.loading = false;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent("searchclose", { detail: { search: false, term: '' } }));
    }

    handleLookupSelection(event) {
        this.dispatchEvent(new CustomEvent("searchselection", { detail: event.detail }));
    }

    handleRowSelection(event) {
        this.dispatchEvent(new CustomEvent("searchselection", { detail: event.detail }));
    }

    startSearch(event) {
        event.stopPropagation();
        this.searchTerm = event.detail.term;
        if (!this.loading) {
            this.searchRecords();
        }
    }

    async searchRecords() {
        this.loading = true;
        const response = await this.ctrl.searchWithColumns(this.searchTerm);
        this.setRecords(response);
        this.loading = false;
    }

    setRecords(response) {
        if (!response.records) {
            return;
        }

        this.records = this.records.concat(response.records);
        this.infiniteLoadingParam = this.ctrl.getInfiniteLoadingParam(response, this.records);
        this.enableInfiniteLoading = this.ctrl.isInfiniteLoadingEnabled(response);
    }

    async handleLoadMoreData() {
        if (this.enableInfiniteLoading && !this.isLoadingMore) {
            this.isLoadingMore = true;
            const response = await this.ctrl.searchWithColumns(this.searchTerm, this.infiniteLoadingParam);
            this.setRecords(response);
            this.isLoadingMore = false;
        }
    }

    get hideCheckbox() {
        return true;
    }
}