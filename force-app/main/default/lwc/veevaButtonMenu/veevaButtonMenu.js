import { LightningElement, api } from 'lwc';

const BOTTOM_BUFFER = 10;

export default class VeevaButtonMenu extends LightningElement {
  // Sets slds-dropdown_*
  @api menuAlignment;
  // Sets slds-dropdown_length-*
  @api overflowLength;
  // Show menu above trigger button if no space available below
  @api allowMenuAboveButton = false;
  @api title = 'Down';
  @api disableButton;

  showDropdown = false;
  _handler;

  disconnectedCallback() {
    document.removeEventListener('click', this._handler);
  }

  handleClick(event) {
    event.stopPropagation();
    this.showDropdown = !this.showDropdown;


    if (this.showDropdown) {
      // Create listener for clicks outside menu LWC
      document.addEventListener('click', (this._handler = this.closeDropdown.bind(this)));
      const button = this.template.childNodes[0];
      const dropdown = this.template.childNodes[0].childNodes[1];

      if (!this.menuAlignment) {
        dropdown.style.right = 'auto';
        const dropdownLeft = button.offsetLeft - dropdown.offsetWidth + button.offsetWidth;
        dropdown.style.left = `${dropdownLeft}px`;
      }

      if (this.allowMenuAboveButton && button.offsetTop + button.offsetHeight + dropdown.offsetHeight + BOTTOM_BUFFER > window.innerHeight) {
        const dropdownTop = button.offsetTop - dropdown.offsetHeight - 5;
        dropdown.style.top = `${dropdownTop}px`;
      }
    } else {
      this.dispatchEvent(new CustomEvent("dropdownclosed"));
    }
  }

  handleInput(event) {
    if(!this.showDropdown) {
      if(event.code === 'ArrowDown' || event.code === 'ArrowUp' || event.code === 'Enter') {
        event.preventDefault();
        this.handleClick(event);
        this.focusFirstElement();
      }
    }
    else if(event.key !== 'Tab') {
      event.preventDefault();

      if(event.code === 'Escape') {
        this.closeDropdown();
      }
      else if(event.code === 'ArrowUp') {
        this.moveFocusUp(event);
      }
      else if(event.code === 'ArrowDown') {
        this.moveFocusDown(event);
      }
      else if(event.code === 'Enter') {
        event.target.click();
        this.focusFirstElement();
      }
    }
  }

  closeDropdown() {
    document.removeEventListener('click', this._handler);
    this.showDropdown = false;
    this.dispatchEvent(new CustomEvent("dropdownclosed"));
  }

  moveFocusUp(event){
    if (event.target.previousElementSibling){
      event.target.previousElementSibling.focus();
    } else {
      const buttons = this.getButtons();
      buttons[buttons.length - 1]?.focus();
    } 
  }

  moveFocusDown(event){
    if (event.target.nextElementSibling){
      event.target.nextElementSibling.focus();
    } else {
      this.getButtons()[0]?.focus();
    } 
  }
  
  handleMouseOver(){
    this.template.querySelector('lightning-button-icon')?.focus();
  }

  async focusFirstElement(){
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      this.getButtons()[0]?.focus();
    }, 0);
  }

  getButtons(){
    return this.querySelectorAll('.focusable_element, lightning-menu-item');
  }

  get dropdownLength() {
    let lengthCss = '';
    switch (this.overflowLength) {
      case '5':
        lengthCss = `slds-dropdown_length-5`;
        break;
      case '7':
        lengthCss = `slds-dropdown_length-7`;
        break;
      case '10':
        lengthCss = 'slds-dropdown_length-10';
        break;
      default:
        break;
    }
    return lengthCss;
  }

  get dropdownCss() {
    const alignment = this.menuAlignment || 'left';
    // Instead of using if:true directive, using visibility CSS property
    // In order to hide parent menu, while keeping child modal open
    let hiddenClass = 'hideMenu';
    if (this.showDropdown) {
      hiddenClass = '';
    }
    return `slds-dropdown slds-dropdown_actions slds-dropdown_${alignment} ${this.dropdownLength} ${hiddenClass}`;
  }
}