import { LightningElement, api, track } from 'lwc';

export default class VeevaSearchResults extends LightningElement {
    @api messageSvc;
    @api searchRecords;
    @api columns;
    @api enableInfiniteLoading;
    @api hideCheckbox;
    _resultTitle;
    _searchTerm;
    noRecordsMsg;

    @track labelNoRecords;
    @track labelResult;
    @track labelResults;

    async connectedCallback() {
        await this.loadMessages();
    }

    async loadMessages() {
        const messages = await this.messageSvc.createMessageRequest()
          .addRequest('LOOKUP_SEARCH_NO_RESULTS', 'Lightning', 'No results for "{0}" in {1}', 'noRecordsMsg')
          .addRequest('RESULTS', 'Common', '{0} Results', 'resultsMsg')
          .addRequest('RESULT', 'Common', 'Result', 'resultMsg')
          .sendRequest();

        this.noRecordsMsg = messages.noRecordsMsg;
        this.labelNoRecords = this.noRecordsMsg.replace('{0}', `${ this.searchTerm }`).replace('{1}', `${ this.resultTitle }`);
        this.labelResults = messages.resultsMsg;
        this.labelResult = messages.resultMsg;

    }

    handleKeyDown(event) {
        if (event.key === 'Enter') {
            const id = event.path.find(item => item.dataset?.rowKeyValue)?.dataset.rowKeyValue;
            this.dispatchRowSelection({id});
        }
    }

    handleRowSelection(event) { 
        event.stopPropagation();
        this.dispatchRowSelection(event.detail.selectedRows[0]);
    }

    dispatchRowSelection(row) {
        const selected = this.searchRecords.find(result => result.id === row.id) || {};
        this.dispatchEvent(new CustomEvent('rowselection', { detail: selected }));
    }


    handleLoadMore() {
        this.dispatchEvent(new CustomEvent('loadmoredata'));
    }

    get count() {
        return this.searchRecords && this.searchRecords.length;
    }

    get countsLabel() {
        let resultStr = this.labelResults;
        if (this.count === 1) {
            resultStr = `{0} ${this.labelResult}`;
        }
        const plusCharacter = this.enableInfiniteLoading ? '+' : '';
        return this.count && resultStr ? resultStr.replace('{0}', `${this.count}${plusCharacter}`) : '';
    }

    get noResults() {
        return this.count === 0;
    }

    @api
    get resultTitle() {
        return this._resultTitle;
    }

    set resultTitle(value) {
        this._resultTitle = value;
        if (this.labelNoRecords) {
            this.labelNoRecords = this.noRecordsMsg.replace('{0}', `${ this.searchTerm }`).replace('{1}', `${ this.resultTitle }`);
        }
    }

    @api
    get searchTerm() {
        return this._searchTerm;
    }

    set searchTerm(value) {
        this._searchTerm = value;
        if (this.labelNoRecords) {
            this.labelNoRecords = this.noRecordsMsg.replace('{0}', `${ this.searchTerm }`).replace('{1}', `${ this.resultTitle }`);
        }
    }
}