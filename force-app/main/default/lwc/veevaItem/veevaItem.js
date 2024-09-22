import { LightningElement, api, track } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';
import VeevaItemTemplate from './veevaItem.html';

export default class VeevaItem extends VeevaErrorHandlerMixin(LightningElement) {
  @api pageCtrl;
  @api record;
  @api item;
  @track hasBeenUpdated = false;
  @track ctrl = {};
  initialValue;

  @api get itemKey(){
    return this._itemKey;
  }

  set itemKey(key){
    this._itemKey = key;
    this.currentElementSelector = `[data-veeva-item-id='${this._itemKey}']`;
  }

  validityElementsSelector = '[data-validity]';

  @api
  get recordUpdateFlag() {
    return this._recordUpdateFlag;
  }

  set recordUpdateFlag(value) {
    this._recordUpdateFlag = value;
    this.ctrl = this.pageCtrl.getItemController(this.item, this.record);
    const bothBlank =
      (this.initialValue === undefined || this.initialValue === null) && (this.ctrl.rawValue === undefined || this.ctrl.rawValue === null);
    if (this.initialValue === this.ctrl.rawValue || bothBlank) {
      this.clearUndoUi();
    }
  }

  displayUndoUi() {
    this.hasBeenUpdated = true;
  }

  clearUndoUi() {
    this.hasBeenUpdated = false;
  }

  shouldDisplayHighlighting(event) {
    // Highlighting should not display in view or read only mode
    if (this.ctrl.actionView || this.ctrl.readonly) {
      return false;
    }

    // Checks whether the field change was caused by a controlling field change
    if (event.detail === 'ControllingFieldChanged') {
      // Highlighting should not display if the field's value did not change
      if (this.initialValue === this.ctrl.rawValue || (!this.initialValue && !this.ctrl.rawValue)) {
        return false;
      }
    }
    return true;
  }

  connectedCallback() {
    this.initialValue = this.ctrl.rawValue;
  }

  handleFieldChange(event) {
    // Adds undo button + highlighting
    if (this.shouldDisplayHighlighting(event)) {
      this.displayUndoUi();
    }

    if (event.detail === 'UndoClick') {
      this.handleUndoClick();
    }
  }

  handleUndoClick() {
    // SetFieldValue pushes the initialValue to the record
    this.ctrl.setFieldValue(this.initialValue, null, 'UndoClick');
    // Removes undo button + highlighting
    this.clearUndoUi();

    // Resetting the itemController to trigger a component refresh of this field
    // LWC does not properly watch tracked components when initialized with new
    this.resetController();

    // The standard lwc page checks the validity of the field.
    // Here checkValidity() is called to align with that behavior.
    /* eslint-disable-next-line @lwc/lwc/no-async-operation */
    setTimeout(() => {
      this.checkValidity();
    }, 200);
  }

  resetController() {
    this.ctrl = this.pageCtrl.getItemController(this.item, this.record, true);
  }

  render() {
    return (this.ctrl && this.ctrl.template) || VeevaItemTemplate;
  }

  get showUndo() {
    return this.hasBeenUpdated && !this.ctrl.disabled;
  }

  @api refreshComponent(key) {
    if (this.ctrl.shouldRefreshComponent && this.ctrl.shouldRefreshComponent(key)) {
      this.resetController();
    }
  }
}