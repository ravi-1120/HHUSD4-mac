import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';
import { VeevaMessageRequest } from 'c/veevaMessageService';

const MESSAGES = [
    {key: 'SORTED_BY', category: 'Common', defaultMessage: 'Sorted by {0}', label: 'sortedByVeevaMessage'},
    {key: 'SELECTED_ROWS', category: 'Common', defaultMessage: '{0} Selected', label: 'selectedRowsVeevaMessage'},
    {key: 'RESULTS', category: 'Common', defaultMessage: '{0} Results', label: 'resultsVeevaMessage'} 
];
export default class CountSortedByLabel extends LightningElement {

    @api resultLimit = 50; // Default 50 limit
    @api set selected(value) {
        this._selected = value;
        this.updateMessage();
    }
    get selected() {
        return this._selected;
    }

    @api set results(value) {
        this._results = value;
        this.updateMessage();
    }
    get results() {
        return this._results;
    }

    @api set sortedBy(value) {
        this._sortedBy = value;
        this.updateMessage();
    }
    get sortedBy() {
        return this._sortedBy;
    }
    @api sortDirection;
    message;

    constructor() {
        super();
        this.messageService = getService('messageSvc');
    }

    async getMessages() {
        const vmr = new VeevaMessageRequest();
        MESSAGES.forEach(({key, category, defaultMessage, label}) => vmr.addRequest(key, category, defaultMessage, label));
        const msgMap = await this.messageService.getMessageMap(vmr);
        Object.entries(msgMap).forEach(([msgId, message]) => {
            this[msgId] = message;
        });
    }

    connectedCallback() {
        this.getMessages().then(() => this.updateMessage());
    }

    updateMessage() {
        const labels = [];
        const limit = this.resultLimit;
        if (!isNaN(parseInt(this.results, 10))) {
            const num = this.results > limit ? `${limit}+` : this.results;
            if (this.resultsVeevaMessage) {
                labels.push(this.resultsVeevaMessage.replace('{0}', num));
            }
        }

        if (this.selectedRowsVeevaMessage) {
            labels.push(`${this.selectedRowsVeevaMessage?.replace('{0}', this.selected ?? 0)}`);
        }

        if (this.sortedBy) {
            labels.push(`${this.sortedByVeevaMessage?.replace('{0}', this.sortedBy)}`);
        }
        this.message = labels.filter(label => label).join(' • ');
    }

    get sortDirectionIcon() {
        let icon = 'utility:up';
        if (this.sortDirection === 'desc') {
            icon = 'utility:down';
        }
        return icon;
    }

    
}