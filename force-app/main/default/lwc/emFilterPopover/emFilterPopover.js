import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';

export default class EmFilterPopover extends LightningElement {
    @api set selected(selectedFilters) {
        this.selectedFilters = selectedFilters ? JSON.parse(JSON.stringify(selectedFilters)) : {};
        this.init();
    }
    get selected() {
        if (!this.selectedFilters) {
            this.selectedFilters = {};
        }
        return this.selectedFilters;
    }
    @api filterGroups;
    
    loading;
    applyLabel;
    cancelLabel;
    title;
    messages;

    get showFilters() {
        return this.filters?.length > 0;
    }

    constructor() {
        super();
        this.messageService = getService('messageSvc');
        this.messages = this.getMessages();
    }

    connectedCallback() {
        this.init();
    }

    async init() {
        try {
            this.loading = true;
            await this.messages;
            this.initModel();
        } finally {
            this.loading = false;
        }
    }

    async getMessages() {
        const [applyLabel, cancelLabel, title] = await Promise.all([
            { key: 'APPLY', category: 'Common', defaultMessage: 'Apply' },
            { key: 'CANCEL', category: 'Common', defaultMessage: 'Cancel' },
            { key: 'ADD_FILTER', category: 'TABLET', defaultMessage: 'Add Filter' }
        ].map(({ key, category, defaultMessage }) => this.messageService.getMessageWithDefault(key, category, defaultMessage)));
        this.applyLabel = applyLabel;
        this.cancelLabel = cancelLabel;
        this.title = title;
    }

    initModel() {
        const filters = [];
        if (this.filterGroups?.length > 0) {
            this.filterGroups.forEach(filterGroup => {
                if (filterGroup?.options?.length > 0) {
                    const fGroup = {...filterGroup};
                    fGroup.options = filterGroup.options.map(option => {
                        const opt = {...option};
                        opt.checked = this.selected?.[filterGroup.id]?.includes(option.value) ?? false;
                        return opt;
                    });
                    filters.push(fGroup);
                }
            });
        }
        this.filters = filters;
    }

    handleSelection(event) {
        const { value } = event.target;
        const { filterGroup } = event.target.dataset;
        if (!this.selected[filterGroup]) {
            this.selected[filterGroup] = [];
        }
        if (event.detail.checked) {
            this.selected[filterGroup].push(value);
        } else {
            const idx = this.selected[filterGroup].indexOf(value);
            if (idx > -1) {
                this.selected[filterGroup].splice(idx, 1);
            }
        }
    }

    apply() {
        this.dispatchEvent(new CustomEvent('apply', {
            detail: {
                filters: this.selected
            }
        }));
    }

    cancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}