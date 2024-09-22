import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';

export default class VeevaListFilterPopover extends LightningElement {
  @api selected;
  @api filterGroups;

  loading;
  selectedFilters = {};
  msgMap = {};

  get showFilters() {
    return this.filters?.length > 0;
  }

  connectedCallback() {
    // eslint-disable-next-line @locker/locker/distorted-window-set-timeout, @lwc/lwc/no-async-operation
    setTimeout(() => {
      document.addEventListener('click', (this._handler = this.closePopover.bind(this)));
    }, 0);
    this.init();
  }

  disconnectedCallback() {
    document.removeEventListener('click', this._handler);
  }

  async init() {
    try {
      this.loading = true;
      this.selectedFilters = this.selected ? JSON.parse(JSON.stringify(this.selected)) : {};
      await this.getMessages();
      this.initModel();
    } finally {
      this.loading = false;
    }
  }

  closePopover() {
    this.dispatchEvent(new CustomEvent('close'));
  }

  stopClickPropagation(event) {
    event.stopPropagation();
  }

  async getMessages() {
    this.msgMap = await getService('messageSvc')
      .createMessageRequest()
      .addRequest('APPLY', 'Common', 'Apply', 'applyLabel')
      .addRequest('ADD_FILTER', 'TABLET', 'Add Filter', 'addFilterLabel')
      .addRequest('RESET', 'Common', 'Reset', 'resetLabel')
      .sendRequest();
  }

  initModel() {
    this.filterSelectedValues();
    const filters = [];
    if (this.filterGroups?.length > 0) {
      this.filterGroups.forEach(filterGroup => {
        if (filterGroup?.options?.length > 0) {
          const fGroup = { ...filterGroup };
          fGroup.options = filterGroup.options.map(option => {
            const opt = { ...option };
            opt.checked = this.selectedFilters?.[filterGroup.fieldName]?.includes(option.value) ?? false;
            return opt;
          });
          filters.push(fGroup);
        }
      });
    }
    this.filters = filters;
  }

  filterSelectedValues() {
    const newSelectedFilters = {};
    Object.entries(this.selectedFilters).forEach(([selectedFilterField, selectedFilterValues]) => {
      const filterGroup = this.filterGroups?.find(filter => selectedFilterField === filter.fieldName);
      const validSelectedValues = filterGroup?.options?.map(filter => filter.value).filter(filterValue => selectedFilterValues.includes(filterValue));
      if (validSelectedValues?.length > 0) {
        newSelectedFilters[selectedFilterField] = validSelectedValues;
      }
    });
    this.selectedFilters = newSelectedFilters;
  }

  handleSelection(event) {
    const { value } = event.target;
    const { filterGroup } = event.target.dataset;
    if (!this.selectedFilters[filterGroup]) {
      this.selectedFilters[filterGroup] = [];
    }
    if (event.detail.checked) {
      this.selectedFilters[filterGroup].push(value);
    } else {
      const idx = this.selectedFilters[filterGroup].indexOf(value);
      if (idx > -1) {
        this.selectedFilters[filterGroup].splice(idx, 1);
      }
      if (this.selectedFilters[filterGroup].length === 0) {
        delete this.selectedFilters[filterGroup];
      }
    }
  }

  apply() {
    this.dispatchEvent(
      new CustomEvent('apply', {
        detail: {
          filters: this.selectedFilters,
        },
      })
    );
  }

  reset() {
    this.selectedFilters = {};
    this.apply();
  }
}