import { api, LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import vodtheme from '@salesforce/resourceUrl/vodtheme';

export default class MyAccountsViews extends LightningElement {
  @api labels = {};
  @api disabled;
  @api options = [];
  @api value;

  get views() {
    if (!this.options) {
      return [];
    }
    return this.getOptionsWithChecked(this.options.filter(option => option.type === 'VIEW' && option.source !== 'LOCATION'));
  }

  get childAccountViews() {
    if (!this.options) {
      return [];
    }
    return this.getOptionsWithChecked(this.options.filter(option => option.type === 'VIEW' && option.source === 'LOCATION'));
  }

  get accountLists() {
    if (!this.options) {
      return [];
    }
    return this.getOptionsWithChecked(this.options.filter(option => option.type === 'ACCOUNT_LIST')).map(option => ({
      ...option,
      style: `--sds-c-icon-color-foreground-default: var(--veeva-vod-theme-${option.color});`,
    }));
  }

  get hasViews() {
    return this.views.length > 0;
  }

  get hasChildAccountViews() {
    return this.childAccountViews.length > 0;
  }

  get hasAccountLists() {
    return this.accountLists.length > 0;
  }

  get selectedOption() {
    if (!this.options) {
      return null;
    }
    return this.options.find(obj => obj.value === this.value);
  }

  get selectedHasColor() {
    return this.selectedOption?.color != null;
  }

  get selectedLabel() {
    return this.selectedOption?.label;
  }

  get selectedStyle() {
    return this.accountLists.find(item => item.value === this.value)?.style;
  }

  async connectedCallback() {
    await loadStyle(this, vodtheme);
  }

  getOptionsWithChecked(options) {
    return options.map(option => ({ ...option, checked: this.value === option.value }));
  }

  setFocus() {
    const selectedIndex = this.options.indexOf(this.selectedOption);
    if (selectedIndex !== -1) {
      const currElement = this.template.querySelector(`[data-id="${this.options[selectedIndex].value}"]`);
      if (currElement){
        currElement.focus();
      }
    }
  }

  handleViewSelection(event) {
    const { value } = event.detail;
    if (this.value !== value) {
      this.dispatchEvent(
        new CustomEvent('change', {
          detail: {
            value,
          },
        })
      );
    }
  }
}