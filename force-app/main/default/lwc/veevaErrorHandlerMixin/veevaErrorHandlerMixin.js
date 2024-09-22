import { api } from 'lwc';
import { getNestedFieldErrors, focusOn } from 'c/veevaPageFieldErrors'; 

const VeevaErrorHandlerMixin = (SuperClass) =>
    class extends SuperClass {
        @api currentElementSelector;
        @api validityElementsSelector;

        @api focusOn(path) {
            focusOn(this, path);
        }
    
        @api checkValidity() {
            return !this.getFieldErrors().length;
        }
    
        @api getFieldErrors() {
            return (this.currentElementSelector) ? getNestedFieldErrors(this.getDataValidityElements(), this.currentElementSelector) : [];
        }

        @api getDataValidityElements() {
            return (this.validityElementsSelector) ? this.template.querySelectorAll(this.validityElementsSelector) : [];
        }
    };

export default VeevaErrorHandlerMixin;