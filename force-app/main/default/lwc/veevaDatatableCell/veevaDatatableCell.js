import { LightningElement, api } from 'lwc';

export default class VeevaDatatableCell extends LightningElement {
  @api typeAttributes;
  @api value;
  @api type = 'text';

  get isText() {
    return this.type === 'text';
  }

  get isNumber() {
    return this.type === 'number';
  }

  get isLookup() {
    return this.type === 'lookup';
  }

  get displayValue() {
    return this.value?.displayValue ?? '';
  }

  get rawValue() {
    return this.value?.value ?? null;
  }

  get recordUrl() {
    return this.rawValue ? `/${this.rawValue}` : null;
  }

  get showLockIcon() {
    return !this.editable && this.displayReadOnlyIcon;
  }

  get displayReadOnlyIcon() {
    return this.typeAttributes?.displayReadOnlyIcon;
  }

  get editable() {
    return this.typeAttributes?.editable;
  } 

  // lookup specific 
  get useClickEvent() {
    return this.typeAttributes?.useClickEvent;
  }

  // number specific
  get scale() {
    return this.typeAttributes?.scale;
  }

  get formatter() {
    return this.typeAttributes?.formatter;
  }

  // picklist specific
  get icon() {
    return this.typeAttributes?.iconName;
  }

  get iconVariant() {
    return this.typeAttributes?.iconVariant;
  }

  get helptext() {
    return this.typeAttributes?.helptext;
  }

  get helptextVariant() {
    return this.typeAttributes?.helptextVariant;
  }

  handleLinkClick(event) {
    if (this.useClickEvent) {
      event.preventDefault();
      this.dispatchEvent(
        new CustomEvent('linkclick', {
          bubbles: true,
          composed: true,
          detail: { url: this.recordUrl },
        })
      );
    }
  }
}