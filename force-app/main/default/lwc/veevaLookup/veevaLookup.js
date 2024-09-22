/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api, track } from 'lwc';
import VeevaUtils from 'c/veevaUtils';
import VeevaConstant from 'c/veevaConstant';
import { getFieldErrors } from 'c/veevaPageFieldErrors';

const SEARCH = 'search';
const RECENT = 'recent';
export default class VeevaLookup extends LightningElement {
  @api startTerm;
  @api label;
  @api customIcons = false;
  @api isObjectSearchPopup = false;
  @api async refreshSelectedValue() {
    if (!this.searchTerm) {
      const selObj = this.ctrl.selected;
      await this.populateMissingName(selObj, this.ctrl.nameField, this.ctrl.pageCtrl.uiApi);
      this.selected = selObj;
    }
  }

  @track selected = {};
  @track searchTerm;
  @track searchRecords = [];
  @track hasFocus = false;

  @api suggestion = '';
  @api recentResults = '';

  _suggestionLabel = '';
  _recentLabel = '';

  _ctrl;
  _invalidLookupMsg;
  _timeout;
  _checkValidityOnRender = false;
  ignoreBlur = false;
  highlightIndex = 0;
  hideDropdown = true;
  isAccountRecordTypeIdLookup;

  get displayCustomIcons() {
    return this.customIcons || this.isAccountRecordTypeIdLookup;
  }

  @api
  get ctrl() {
    return this._ctrl;
  }

  set ctrl(value) {
    this._ctrl = value;
    this.refreshSelectedValue();
  }

  get variant() {
    let variant = 'label-hidden';
    if (this.label) {
      variant = '';
    }
    return variant;
  }

  get lookupIconClickable() {
    return !this.selected.id && this.ctrl.pageCtrl.lookupIconClickable;
  }

  /**
   * Flag to note whether to check for validity on renderedCallback.
   * Set this to true if veevaLookup needs to be validated on render.
   *
   * @type {boolean}
   */
  @api
  get checkValiditiyOnRender() {
    return this._checkValidityOnRender;
  }

  set checkValiditiyOnRender(value) {
    this._checkValidityOnRender = value;
  }

  get suggestionLabel() {
    return this.suggestion || this._suggestionLabel;
  }

  set suggestionLabel(value) {
    this._suggestionLabel = value;
  }

  get recentLabel() {
    return this.recentResults || this._recentLabel;
  }

  set recentLabel(value) {
    this._recentLabel = value;
  }

  async connectedCallback() {
    this.searchTerm = this.startTerm || '';
    this.initialSelectedObj = {};
    await this.refreshSelectedValue();
    await this.setInvalidLookupMsg();

    const labels = await this._ctrl.getSearchLabels?.() || {};
    this._suggestionLabel = labels.suggestionLabel || '';
    this._recentLabel = labels.recentLabel || '';
  }

  async renderedCallback() {
    // only run `checkValidity` if the flag is set and the lookup message has been fetched
    if (this._checkValidityOnRender && this._invalidLookupMsg) {
      this.checkValidity();
      this._checkValidityOnRender = false;
    }
  }

  // eslint-disable-next-line class-methods-use-this
  async populateMissingName(selectedObj, nameField, uiApi) {
    const isLabelMissing = selectedObj.id && (!selectedObj.name || selectedObj.id === selectedObj.name);
    if (isLabelMissing && selectedObj.apiName) {
      const data = await VeevaUtils.to(uiApi.getRecord(selectedObj.id, [`${selectedObj.apiName}.${nameField}`], true));
      const value = data?.[1]?.fields?.[nameField]?.displayValue || data?.[1]?.fields?.[nameField]?.value;
      if (value) {
        this.ctrl.saveMissingNameToRecord(value);
        selectedObj.name = value;
      }
    }
  }

  handleMouseDown() {
    this.ignoreBlur = true;
    this.hideDropdown = false;
  }

  handleMouseUp() {
    this.ignoreBlur = false;
  }

  handleMouseOut() {
    if (this.searchRecords.length > 0) {
      this.removeHighlight();
    }
  }

  resetHighlight(record) {
    if (record.showHighlight) {
      record.showHighlight = false;
      record.listboxOptionClass = 'slds-media slds-media_center slds-listbox__option slds-listbox__option_entity';
    }
  }

  @api async handleClearLookup() {
    this.selected = {};
    this.searchTerm = '';
    this.hideDropdown = false;
    // eslint-disable-next-line @locker/locker/distorted-window-set-timeout
    setTimeout(() => {
      this.template.querySelector('[data-input-term]').focus();
    }, 0);
    this.dispatchEvent(new CustomEvent('clearlookup'));
  }

  async handleFocus() {
    this.hasFocus = true;
    await this.search();
  }

  handleInput(event) {
    if (this.shouldShowDropdown) {
      if (event.code === 'Escape') {
        this.searchRecords = [];
      } else if (event.code === 'ArrowUp' && this.searchRecords.length > 0) {
        this.changeHighlightIndex(this.decrementHighlightIndex);
      } else if (event.code === 'ArrowDown' && this.searchRecords.length > 0) {
        this.changeHighlightIndex(this.incrementHighlightIndex);
      }
    } else if (event.code === 'ArrowDown' || event.code === 'Enter') {
      this.hideDropdown = false;
    }
  }

  handleDeleteBackspaceInput(event) {
    if (event.code === 'Delete' || event.code === 'Backspace') {
      this.handleClearLookup();
      this.hideDropdown = true;
    }
  }

  handleEnterInput(event) {
    if (event.code === 'Enter' && this.searchRecords.length > 0 && this.shouldShowDropdown) {
      const currElement = this.template.querySelector('.slds-has-focus');
      if (currElement) {
        currElement.click();
      }
    }
  }

  handleSearchTermChange(event) {
    if (this._timeout) {
      clearTimeout(this._timeout);
    }

    this.hideDropdown = false;
    this.searchTerm = event.target.value;
    // eslint-disable-next-line @locker/locker/distorted-window-set-timeout
    this._timeout = setTimeout(() => {
      this.search();
    }, VeevaConstant.DEBOUNCE_DELAY);
  }

  changeHighlightIndex(indexMoveFunct) {
    this.removeHighlight();

    indexMoveFunct(this);
    if (this.searchRecords[this.highlightIndex].id === RECENT) {
      indexMoveFunct(this);
    }
    this.addHighlight();

    const currElement = this.template.querySelectorAll(`[data-recordid="${this.searchRecords[this.highlightIndex].id}"]`)[0];
    if (currElement) {
      currElement.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }

  incrementHighlightIndex(self) {
    if (self.highlightIndex < self.searchRecords.length - 1) {
      self.highlightIndex++;
    } else {
      self.highlightIndex = 0;
    }
  }

  decrementHighlightIndex(self) {
    if (self.highlightIndex > 0) {
      self.highlightIndex--;
    } else {
      self.highlightIndex = self.searchRecords.length - 1;
    }
  }

  removeHighlight() {
    this.searchRecords[this.highlightIndex].showHighlight = false;
    this.searchRecords[this.highlightIndex].listboxOptionClass = 'slds-media slds-media_center slds-listbox__option slds-listbox__option_entity';
  }

  addHighlight() {
    this.searchRecords[this.highlightIndex].showHighlight = true;
    this.searchRecords[this.highlightIndex].listboxOptionClass =
      'slds-media slds-media_center slds-listbox__option slds-listbox__option_entity slds-has-focus';
  }

  async setInvalidLookupMsg() {
    this._invalidLookupMsg = await this.ctrl.pageCtrl.getMessageWithDefault(
      'LTNG_INVALID_LOOKUP_ERROR',
      'Lightning',
      'Select an option from the picklist or remove the search term'
    );
  }

  async search() {
    this.rejectCancelSearchPromise?.('cancel search');
    const cancelSearchPromise = new Promise((_resolve, reject) => {
      this.rejectCancelSearchPromise = reject;
    });
    let displayRecords;
    let records;
    try {
      records = await Promise.race([this.getRecords(), cancelSearchPromise]);
    } catch (err) {
      return;
    }
    records.forEach(record => {
      record.name = record.name ? record.name : record[this._ctrl.nameField];
    });
    if (VeevaUtils.isValidSearchTerm(this.searchTerm)) {
      let name;
      if (this.isObjectSearchPopup) {
        name = await this.ctrl.searchTermInPopup(this.searchTerm);
      } else {
        name = await this.ctrl.searchTerm(this.searchTerm);
      }
      const showAllLabel = { id: SEARCH, name, icon: 'utility:search', xsmall: true };
      const filtered = records.filter(
        searchItem => searchItem.name.toLowerCase().indexOf(this.searchTerm.toLowerCase()) !== -1 && searchItem.id !== SEARCH
      );
      this._formatResultText(filtered);
      if (this.searchTerm.length < 3 && filtered.length > 0) {
        const recentItemsLabel = { id: RECENT, name: this.recentLabel };
        displayRecords = [showAllLabel, recentItemsLabel, ...filtered];
      } else {
        displayRecords = [showAllLabel, ...filtered];
      }
      displayRecords[0].showHighlight = true;
      this.highlightIndex = 0;
    } else {
      if (this.searchTerm.length > 0) {
        const filtered = records.filter(
          searchItem => searchItem.name.toLowerCase().indexOf(this.searchTerm.toLowerCase()) !== -1 && searchItem.id !== SEARCH
        );
        this._formatResultText(filtered);
        displayRecords = filtered;
      } else {
        records.forEach(searchItem => {
          searchItem.match = '';
        });
        displayRecords = records;
      }
      if (displayRecords.length > 0) {
        const recentItemsLabel = { id: RECENT, name: this.recentLabel };
        displayRecords = [recentItemsLabel, ...displayRecords];
        displayRecords[1].showHighlight = true;
        this.highlightIndex = 1;
      }
    }
    for (const item of displayRecords) {
      item.listboxOptionClass = item.showHighlight
        ? 'slds-media slds-media_center slds-listbox__option slds-listbox__option_entity slds-has-focus'
        : 'slds-media slds-media_center slds-listbox__option slds-listbox__option_entity';
    }
    // access displayRecords[1] because displayRecords[0] is called "Recent Record Types"
    this.isAccountRecordTypeIdLookup = displayRecords?.[1]?.veevaIcon;

    this.searchRecords = displayRecords;
  }

  _formatResultText(results) {
    results.forEach(searchItem => {
      const matchInd = searchItem.name.toLowerCase().indexOf(this.searchTerm.toLowerCase());
      const postSearchTermInd = matchInd + this.searchTerm.length;
      searchItem.preMatch = searchItem.name.substring(0, matchInd);
      searchItem.match = searchItem.name.substring(matchInd, postSearchTermInd);
      searchItem.postMatch = searchItem.name.substring(postSearchTermInd);
    });
  }

  async getRecords() {
    let response = await this.ctrl.search(this.searchTerm);
    if (response.records && response.records.length > 0) {
      return response.records;
    }
    if (this.searchTerm.length === 1) {
      response = await this.ctrl.search('');
      if (response.records && response.records.length > 0) {
        return response.records;
      }
    }
    return [];
  }

  handleSearchIconClick(event) {
    event.preventDefault();
    this.dispatchEvent(new CustomEvent('searchmode', { detail: { search: true, term: this.searchTerm } }));
  }

  async handleResultClick(event) {
    event.preventDefault();
    const recordId = event.currentTarget.dataset.recordid;
    if (recordId === SEARCH) {
      this.dispatchEvent(new CustomEvent('searchmode', { detail: { search: true, term: this.searchTerm } }));
    } else if (recordId !== RECENT) {
      this.setSelected(recordId);
      this.dispatchEvent(new CustomEvent('lookupselection', { detail: this.selected }));
      // eslint-disable-next-line @locker/locker/distorted-window-set-timeout
      setTimeout(() => {
        const selectedTerm = this.template.querySelector('[data-select-term]');
        // Due to the focus being called after a small delay, it possible that the selected value
        // may be cleared prior to us focusing on this value. So we will only focus if the selectTerm is not null
        selectedTerm?.focus();
      }, 100);
    }
  }

  handleClose() {
    if (!this.ignoreBlur) {
      // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
      setTimeout(() => {
        this.resetSearch(); // does not reset searchTerm per SF behavior
        this.checkValidity();
      }, 0);
      this.hideDropdown = true;
    }
  }

  setSelected(recordId) {
    this.selected = this.searchRecords.find(result => result.id === recordId) || {};
    this.searchTerm = '';
    this.resetSearch();
  }

  resetSearch() {
    this.searchRecords = [];
    this.hasFocus = false;
  }

  @api checkValidity() {
    const element = this.template.querySelector('lightning-input');
    if (!element) {
      return true;
    }
    this.clearCustomValidityError(element);
    if (element.checkValidity()) {
      this.ctrl.validate();
      element.setCustomValidity(this.ctrl.getError());
    }
    this.checkForUnselectedRecord(element);
    return element.reportValidity();
  }

  clearCustomValidityError(element) {
    // If there was a custom error before, reset it
    if (element.validity.customError) {
      element.setCustomValidity('');
    }
  }

  checkForUnselectedRecord(element) {
    if (this.searchTerm.length !== 0 && !this.selected.id && !this.isObjectSearchPopup) {
      element.setCustomValidity(this._invalidLookupMsg);
    }
  }

  // styles
  get comboboxClass() {
    const css = this.selected.id ? ' slds-input-has-icon_left-right' : ' slds-input-has-icon_right';
    return `slds-combobox__form-element slds-input-has-icon${css}`;
  }

  get selectedIconClass() {
    return 'slds-icon_container slds-combobox__input-entity-icon';
  }

  get inputTextClass() {
    const css = this.hasFocus ? ' slds-has-focus' : '';
    return `slds-input slds-combobox__input${css}`;
  }

  get searchIconClass() {
    let searchIcon = 'veeva-search__icon';
    if (this.label) {
      searchIcon += '_label';
    }
    return `veeva-input__icon slds-input__icon_right ${searchIcon}`;
  }

  get clearButtonClass() {
    return 'slds-button slds-button_icon slds-input__icon slds-input__icon_right';
  }

  get listboxClass() {
    const classes = ['slds-dropdown', 'slds-dropdown_length-with-icon-5', 'slds-dropdown_fluid', 'slds-p-around_none', 'veeva-list-box'];

    if (this.label) {
      classes.push('veeva-list-box__lower');
    }

    return classes.join(' ');
  }

  get containerClass() {
    return `slds-combobox_container`;
  }

  get shouldShowDropdown() {
    return this.hasFocus && !this.selected.id && !this.hideDropdown;
  }

  get dropdownClass() {
    let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    if (this.shouldShowDropdown) {
      css += ' slds-is-open';
    }
    return css;
  }

  @api focusOn() {
    // override focusOn veevaErrorHandlerMixin
    // eslint-disable-next-line @locker/locker/distorted-window-set-timeout
    setTimeout(() => {
      this.template.querySelector('lightning-input')?.focus();
    }, 100);
  }

  @api getFieldErrors() {
    // override getFieldErrors veevaErrorHandlerMixin
    return getFieldErrors(this, 'c-veeva-lookup');
  }
}