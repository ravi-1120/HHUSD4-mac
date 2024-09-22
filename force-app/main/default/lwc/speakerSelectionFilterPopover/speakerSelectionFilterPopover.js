import { api, LightningElement } from 'lwc';

export default class SpeakerSelectionFilterPopover extends LightningElement {

    @api ctrl;
    @api set selected(selectedFilters) {
        this._selected = selectedFilters;
        this.init();
    }
    get selected() {
        return this._selected;
    }
    
    loading;
    applyLabel;
    cancelLabel;
    title;

    get showFilters() {
        return this.filters?.length > 0;
    }

    async init() {
        try {
            this.loading = true;
            await this.getMessages();
            this.options = await this.ctrl.getOptions();
            this.filters = this.ctrl.process(this.options, this.selected);
        } finally {
            this.loading = false;
        }
    }

    async getMessages() {
        const [applyLabel, cancelLabel, title] = await Promise.all([
            { key: 'APPLY', category: 'Common', defaultMessage: 'Apply' },
            { key: 'CANCEL', category: 'Common', defaultMessage: 'Cancel' },
            { key: 'ADD_FILTER', category: 'TABLET', defaultMessage: 'Add Filter' }
        ].map(msg => this.ctrl.pageCtrl.getMessage(msg)));
        this.applyLabel = applyLabel;
        this.cancelLabel = cancelLabel;
        this.title = title;
    }

    handleSelection(event) {
        this.ctrl.handleSelection(event);
    }

    apply() {
        this.dispatchEvent(new CustomEvent('apply', {
            detail: {
                filters: this.ctrl.getAppliedFilters()
            }
        }));
    }

    cancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}