/* eslint-disable class-methods-use-this */
import filterTemplate from '../templates/speakerSelectionFilter.html';

const MANDATORY_VOD = 'Mandatory_vod';

export default class SpeakerSelectionFilterPopoverController {

    filters = [];
    selectedFilters = [];

    constructor(pageCtrl) {
        this.pageCtrl = pageCtrl;
    }

    async getOptions() {
        return this.pageCtrl.getFilterOptions();
    }
    
    process(options, existingFilters) {
        this.mandatoryFilters = [];
        this.selectedFilters = existingFilters?.length > 0 ? [].concat(existingFilters) : [];
        const filters = [];
        if (options?.length > 0) {
            options.forEach(filterGroup => {
                if (filterGroup?.options?.length > 0) {
                    const fGroup = {...filterGroup};
                    fGroup.options = filterGroup.options.map(option => {
                        const copy = {...option};
                        copy.mandatory = option.filterType === MANDATORY_VOD;
                        copy.checked = copy.mandatory || this.selectedFilters.some(filter => filter.value === option.value);
                        return copy;
                    }).sort(this.sortFilters);
                    filters.push(fGroup);
                }
            });
        }
        this.filters = filters;
        return this.filters;
    }

    sortFilters(o1, o2) {
        if (o1.mandatory && !o2.mandatory) {
            return -1;
        }
        if (!o1.mandatory && o2.mandatory) {
            return 1;
        }
        // either both mandatory or not mandatory at this point, order by label
        return o1.label.localeCompare(o2.label);
    }

    getAppliedFilters() {
        return this.selectedFilters;
    }

    handleSelection(event) {
        const { target } = event;
        if (event.detail.checked) {
            this.selectedFilters.push({
                label: target.label,
                value: target.value,
                removeable: !target.disabled
            });
        } else {
            const idx = this.selectedFilters.findIndex(filter => filter.value === target.value);
            if (idx > -1) {
                this.selectedFilters.splice(idx, 1);
            }
        }
    }

    getTemplate() {
        return filterTemplate;
    }
}