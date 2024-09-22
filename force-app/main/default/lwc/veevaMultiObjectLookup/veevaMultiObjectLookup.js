/* eslint-disable @lwc/lwc/no-async-operation */
import { api, track, LightningElement } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class VeevaMultiObjectLookup extends VeevaErrorHandlerMixin(LightningElement) {
  @api
  get ctrl() {
    return this._ctrl;
  }
  set ctrl(value) {
    this._ctrl = value;
    if (!this._ctrl.selectedObject.value) {
      this._ctrl.selectedObject = this.defaultObject;
    }
  }

  @api async refreshSelectedValue() {
    this.template.querySelector(this.validityElementsSelector)?.refreshSelectedValue();
  }

  @track objectListFocus = false;

  @track selected;
  @track _ctrl;

  currentElementSelector = 'c-veeva-multi-object-lookup';
  validityElementsSelector = '[data-validity]';

  suggestionLabel = '';
  recentLabel = '';

  // object list handlers
  handleObjectListFocus() {
    this.objectListFocus = true;
  }

  handleObjectListClose() {
    setTimeout(() => {
      this.objectListFocus = false;
    }, 200);
  }

  async handleObjectListClick(event) {
    const selected = this.objectList.find(object => object.value === event.currentTarget.dataset.objectname);
    if (selected && this._ctrl.selectedObject.value !== selected.value) {
      this._ctrl.selectedObject = selected;
      this.template.querySelector('c-veeva-lookup.veeva-lookup').handleClearLookup();

      const labels = await this._ctrl.getSearchLabels() || {};
      this.suggestionLabel = labels.suggestionLabel || '';
      this.recentLabel = labels.recentLabel || '';
    }
    this.objectListFocus = false;
  }

  bubbleLookupSelection(event) {
    this.dispatchEvent(new CustomEvent('lookupselection', event));
  }

  bubbleSearchMode(event) {
    this.dispatchEvent(new CustomEvent('searchmode', event));
  }

  bubbleClearLookup() {
    this.dispatchEvent(new CustomEvent('clearlookup'));
  }

  get objectList() {
    return (this._ctrl && this._ctrl.meta && this._ctrl.meta.objectList) || [];
  }

  get showLabel() {
    return this._ctrl && this._ctrl.meta && this._ctrl.meta.label;
  }

  get isMultilookup() {
    return this.objectList && this.objectList.length > 1;
  }

  get defaultObject() {
    let defaultObj;
    if (this.objectList.length > 0) {
      defaultObj = this.objectList.find(object => object.defaultValue);
      if (!defaultObj) {
        // use first element as fallback
        [defaultObj] = this.objectList;
      }
    }
    return defaultObj;
  }

  // styles
  get containerClass() {
    let css = 'slds-combobox_container';
    if (this.isMultilookup) {
      css += ' slds-combobox-addon_end';
    }
    return css;
  }

  // multi object styles
  get objectListDropdownClass() {
    let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    if (this.objectListFocus) {
      css += ' slds-is-open';
    }
    return css;
  }

  get comboBoxGroupClass() {
    if (this.isMultilookup) {
      return 'slds-combobox-group';
    }
    return '';
  }
}