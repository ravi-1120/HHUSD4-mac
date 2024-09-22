import { LightningElement, api } from 'lwc';

const HIERARCHY = 'hierarchy';
const ICON = {
  [HIERARCHY]: {
    iconName: 'utility:hierarchy',
  },
  warning: {
    iconName: 'utility:warning',
    iconClass: 'slds-button_icon-error',
  },
};
export default class EmCustomButtonIconColumn extends LightningElement {
  @api get value() {
    return this._value;
  }
  set value(value) {
    this._value = value;
    this.setIcon();
  }
  @api typeAttributes;
  iconName;
  iconClass;
  _value;

  get display() {
    return this.value;
  }

  get type() {
    return this.value?.type;
  }

  get tooltip() {
    return this.value?.tooltip;
  }

  get clickEvent() {
    return this.type === HIERARCHY;
  }

  setIcon() {
    if (this.type) {
      const { iconName, iconClass } = ICON[this.type];
      this.iconName = iconName;
      this.iconClass = iconClass;
    }
  }

  handleClick() {
    if (this.clickEvent) {
      this.dispatchEvent(
        new CustomEvent(HIERARCHY, {
          bubbles: true,
          composed: true,
          detail: {
            id: this.typeAttributes.id,
          },
        })
      );
    }
  }
}