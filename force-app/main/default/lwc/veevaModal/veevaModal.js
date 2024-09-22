import { LightningElement, api } from 'lwc';
import { getService, SERVICES } from 'c/veevaServiceFactory';

const BASE_Z_INDEX = 9000;

export default class VeevaModal extends LightningElement {
  static openModals = 0;

  @api size = 'small';
  @api close = 'close';
  @api maxHeight = false;
  @api composed = false;
  @api overrideOverflow = false;
  @api displayOverflow = false;
  @api hideHeader = false;
  @api hideFooter = false;
  @api hideCloseIcon = false;
  @api minimizeWidth = false;

  _modalIndex;
  _headerClass;
  _footerClass;
  _titleClass;
  closeWindowLabel;

  async connectedCallback() {
    this._modalIndex = VeevaModal.openModals;
    VeevaModal.openModals += 1;
    this.closeWindowLabel = await getService(SERVICES.MESSAGE).getMessageWithDefault('LTNG_CLOSE_WINDOW', 'Lightning', 'Close this window');
  }

  renderedCallback() {
    const additionalZ = this._modalIndex * 2;

    const backdrop = this.template.querySelector('.slds-backdrop');
    const modal = this.template.querySelector('.slds-modal');
    backdrop.style['z-index'] = BASE_Z_INDEX + additionalZ;
    modal.style['z-index'] = BASE_Z_INDEX + 1 + additionalZ;
  }

  disconnectedCallback() {
    VeevaModal.openModals -= 1;
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent(this.close, { bubbles: true, composed: this.composed }));
  }

  get modalClass() {
    const classes = ['slds-modal slds-fade-in-open veeva-modal'];
    if (this.size.indexOf('veeva-') === 0) {
      // outer modal shouldn't get the veeva size, default to small
      classes.push(`veeva-modal_${this.size}`);
    } else {
      // use the salesforce-provided size
      classes.push(`slds-modal_${this.size}`);
    }

    return classes.join(' ');
  }

  get containerClass() {
    let css = 'slds-modal__container';
    if (this.minimizeWidth) {
      css += ' min-width-container';
    } else {
      css += ' veeva-modal__container';
    }
    return css
  }

  get contentClass() {
    let css = 'slds-modal__content slds-p-horizontal--medium';
    if (this.maxHeight) css += ' max-height-content';

    if (this.overrideOverflow) {
      css += ' override-overflow';
    } else if (this.displayOverflow) {
      css += ' display-overflow';
    }

    if (!this.minimizeWidth) {
      css += ' small-vertical-padding';
    }

    return css;
  }

  get headerClass() {
    if (this.hideHeader) {
      return 'slds-modal__header slds-modal__header_empty';
    }
    if (this._headerClass) {
      return this._headerClass;
    }
    return 'slds-modal__header';
  }

  @api
  set headerClass(style) {
    if (style === 'error') {
      this._headerClass = 'slds-modal__header failed-response-header';
    } else if (style === 'success') {
      this._headerClass = 'slds-modal__header success-response-header';
    } else if (style === 'request') {
      this._headerClass = 'slds-modal__header signing-requesting-header';
    }
  }

  @api
  get footerClass() {
    if (this.hideFooter) {
      return 'slds-modal__footer slds-hide';
    }
    if (this._footerClass) {
      return this._footerClass;
    }
    return 'slds-modal__footer';
  }
  set footerClass(style) {
    if (style === 'hideFooterBar') {
      this._footerClass = 'slds-modal_footer hide-footer-bar';
    }
  }

  @api
  get titleClass() {
    if (!this._titleClass) {
      return 'slds-text-heading--medium slds-hyphenate';
    }
    return this._titleClass;
  }
  set titleClass(style) {
    if (style) {
      this._titleClass = style;
    }
  }
}