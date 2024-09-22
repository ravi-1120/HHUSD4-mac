/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-param-reassign */
import { api, LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import vodtheme from '@salesforce/resourceUrl/vodtheme';

export default class EmCombobox extends LightningElement {
    @api label;
    @api options;
    @api widthOverride;
    _selected;
    @api set selected(value) {
        this._selected = value;
        this.updateCheckedOption();
    };
    get selected() {
        return this._selected;
    }

    get selectedLabel() {
        return this.selectedOption?.label ?? '';
    }

    get selectedIcon() {
        return this.selectedOption?.prefixIconName ?? '';
    }

    get selectedOption() {
        return this.options.find(opt => opt.value === this.selected);
    }

    isOpen = false;

    get comboboxInputClass() {
        let css = 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right';
        const color = this.selectedOption?.color;
        if (color) {
            css += ` ${color}`;
        }
        return css;
    }

    get inputClass() {
        let css = 'input-value slds-input_faux slds-combobox__input slds-combobox__input-value';
        const color = this.selectedOption?.color;
        if (color) {
            css += ` ${color}`;
        }
        if (this.widthOverride) {
            css += ' width-override';
        }
        return css;
    }

    async connectedCallback() {
        await loadStyle(this, vodtheme);
        this.options = this.options.map(item => ({
                ...item,
                checked: item.value === this.selected
            }));
    }

    renderedCallback() {
        this.template.querySelector('input.input-value')?.addEventListener('keydown', this.handleKeyDown.bind(this));
        this.buttonMenu = this.template.querySelector('lightning-button-menu.button-menu');
    }

    handleKeyDown(event) {
        if (event.keyCode === 13) { // Enter
            this.handleClick();
        }
    }

    handleClick() {
        if (!this.isOpen) {
            this.buttonMenu?.click();
        }
    }

    menuOpened() {
        this.isOpen = true;
    }

    menuClosed() {
        setTimeout(() => {
            this.isOpen = false;
        }, 200);
    }

    updateCheckedOption() {
        this.options = this.options.map(item => {
            const opt = {
                ...item,
                checked: item.value === this.selected
            }
            return opt;
        });
    }
    
    handleSelection(event) {
        this.menuClosed();
        this.selected = event?.detail?.value;
        this.dispatchEvent(new CustomEvent('select', {
            detail: { value: this.selected }
        }));
    }
}