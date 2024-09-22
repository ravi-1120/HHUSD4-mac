import { LightningElement, api } from 'lwc';

export default class TerritoryFeedbackCounter extends LightningElement {
    @api value;
    @api counterDatatype;
    @api disableIncrement;
    @api disableDecrement;

    get inputDisplayValue() {
        return this.counterDatatype !== 'number' ? '-' : this.value; 
    }

    handleIncrement() {
        this.dispatchEvent(new CustomEvent('change', {
            detail: { newValue: (this.value + 1) }
        }));
    }

    handleDecrement() {
        this.dispatchEvent(new CustomEvent('change', {
            detail: { newValue: (this.value - 1) }
        }));
    }
}