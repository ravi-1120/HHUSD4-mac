import { LightningElement, api, track } from 'lwc';
import MedInqConstant from 'c/medInqConstant';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class MedInqDelivery extends VeevaErrorHandlerMixin(LightningElement) {
  @api ctrl;
  @track methods = { optionalMethods: [] };
  @track methodClassUndo = '';
  initialValues;
  currentElementSelector = 'c-med-inq-delivery';
  validityElementsSelector = 'c-med-inq-delivery-method';

  @api
  get recordUpdateFlag() {
    return this._recordUpdateFlag;
  }

  set recordUpdateFlag(value) {
    this._recordUpdateFlag = value;
    this.ctrl.getMethods().then(methods => {
      this.methods = { optionalMethods: [] };
      this.methods = methods;
    });
  }

  async connectedCallback() {
    this.ctrl.pageCtrl.track(MedInqConstant.DELIVERY_METHOD, this, 'deliveryMethodChanged');
    this.ctrl.pageCtrl.track(MedInqConstant.ACCOUNT, this, 'accountChanged');
    this.methods = await this.ctrl.getMethods();
    this.initialValues = this.ctrl.getAllValues();
  }

  async deliveryMethodChanged(value, source) {
    await this.resetMethods(value);
    this.methodClassUndo = 'undo';

    if (source === 'UndoClick') {
      this.methodClassUndo = '';
      this.undoValues();
    }
  }

  async undoValues() {
    await this.resetMethods();
    this.ctrl.setAllValues(this.initialValues);
  }

  async accountChanged() {
    await this.resetMethods();
  }

  async resetMethods(value) {
    // clear this.methods first, to trigger the tracked methods.optionalMethods
    this.methods = { optionalMethods: [] };
    this.methods = await this.ctrl.getMethods(value);
    this.ctrl.clearAllValues();
  }
}