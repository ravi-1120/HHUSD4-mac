import { LightningElement, api, track } from "lwc";
import VeevaConstant from "c/veevaConstant";
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { getFieldErrors } from 'c/veevaPageFieldErrors';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class VeevaLightningInput extends VeevaErrorHandlerMixin(LightningElement) {
    @api
    inputAddon;
    
    @api get ctrl() {
        return this._ctrl;
    }
    set ctrl(value) {
        this.value = "";
        this._ctrl = value;
        if(value.timezone) {
          this.timezone = value.timezone;
        } else {
          this.timezone = TIME_ZONE;
        }
        this.retrieveValue();
        this.disabled = this._ctrl.disabled;
    }

    @track _ctrl;
   
    async retrieveValue(){
        const result = await this.ctrl.value;
        this.display = result.displayValue || result.value;
        this.value = result.value;
    }

    get fractionDigits() {
        return this.ctrl.digits ?? 2;
    }

    set timezone(value) {
      this._timezone = value;
    }

    get timezone() {
      return this._timezone;
    }

    get showInputAddon() {
      return this.ctrl.inputAddon;
    }

    get inputAddonClass() {
      return this.ctrl.inputAddon ? 'slds-input-has-fixed-addon' : '';
    }

    @track display;
    @track value;
    @track disabled = false;

    handleChange(event) {
        event.preventDefault();
        window.clearTimeout(this.delayTimeout);
        const {value} = event.target;
        // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
        this.delayTimeout = setTimeout(() => {
            this.ctrl.setFieldValue(value);
            if (this.ctrl.shouldValidateOnChange()){
                this.checkValidity();
             }
        }, VeevaConstant.DEBOUNCE_DELAY);
    }

    @api checkValidity() {
      const element = this.getDataValidityElements();
      element.setCustomValidity('');
      if (element.checkValidity()) {
        this.ctrl.validate();
        element.setCustomValidity(this.ctrl.getError());
      }
      return element.reportValidity();
    }
  
    getDataValidityElements() { // override getDataValidityElements veevaErrorHandlerMixin    
      return this.template.querySelector('lightning-input');
    }
  
    @api focusOn() { // override focusOn veevaErrorHandlerMixin    
      // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
      setTimeout(() => {
        this.getDataValidityElements()?.focus();
      }, 100);
    }
  
    @api getFieldErrors() { // override getFieldErrors veevaErrorHandlerMixin    
      return getFieldErrors(this, 'c-veeva-lightning-input');
    }    
}