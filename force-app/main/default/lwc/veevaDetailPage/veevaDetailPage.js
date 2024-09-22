import { wire, api, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import VeevaToastEvent from 'c/veevaToastEvent';
import { getPageController } from 'c/veevaPageControllerFactory';
import { fireEvent } from 'c/pubsub';
import VeevaConstant from 'c/veevaConstant';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import VeevaMainPage from 'c/veevaMainPage';
import VeevaUtils from 'c/veevaUtils';
import veevaButtonAction from '@salesforce/messageChannel/Veeva_Button_Action__c';

export default class VeevaDetailPage extends NavigationMixin(VeevaMainPage) {
  pageName = VeevaConstant.VIEW_LWC;
  objType = null;
  buttonActionSubscription;

  @api disableSpinner = false;

  @wire(MessageContext)
  messageContext;

  connectedCallback() {
    super.connectedCallback();
    this.buttonActionSubscription = subscribe(this.messageContext, veevaButtonAction, message => {
      this._handleButtonMessage(message);
    });
  }

  _handleButtonMessage(message) {
    const buttonMatchesPage = message.recordId === this.pageCtrl.id && message.pageMode === this.pageCtrl.action;
    if (buttonMatchesPage) {
      if (message.action === 'saverecord') {
        this.handleSaveRecord(message.parameters);
      }
    }
  }

  disconnectedCallback() {
    if (this.buttonActionSubscription) {
      unsubscribe(this.buttonActionSubscription);
      this.buttonActionSubscription = null;
    }
  }

  @track _objectApiName;
  @api get objectApiName() {
    return this._objectApiName;
  }
  set objectApiName(value) {
    this.pageCtrl = getPageController(value);
    this.pageCtrl.page = this.page;
    this._objectApiName = value;
    this.objType = value;
  }
  @api recordId;
  @track page = { requests: [], action: 'View' }; // track Page UI state
  @track showLayout;
  @track fields;
  // Add flag to track updates from wired method
  @track recordUpdateFlag = false;

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.page.currentPageReference = currentPageReference;
  }

  @wire(getObjectInfo, { objectApiName: '$_objectApiName' })
  async wiredObjectInfo({ error, data }) {
    if (data) {
      this.pageCtrl.objectInfo = JSON.parse(JSON.stringify(data));
      this.fields = this.pageCtrl.getQueryFields();
      this.optionalFields = this.pageCtrl.getOptionalQueryFields();
    }
    if (error) {
      this.setError(error);
    }
  }

  @wire(getRecord, { recordId: '$recordId', fields: '$fields', optionalFields: '$optionalFields' })
  async wiredObjectDetails({ error, data }) {
    if (data) {
      this.pageCtrl.record = JSON.parse(JSON.stringify(data));
      await this.pageCtrl.initPageLayout();
      this.recordUpdateFlag = !this.recordUpdateFlag;
      const redirectPageRef = await this.pageCtrl.getRedirectPageRef();
      if (redirectPageRef) {
        this[NavigationMixin.Navigate](redirectPageRef, true);
      } else {
        fireEvent(this, VeevaConstant.PUBSUB_RECORD_READY, this.pageCtrl);
        fireEvent(this, VeevaConstant.PUBSUB_LAYOUT_READY, this.pageCtrl);
        this.dispatchEvent(new CustomEvent('hidespinner'));
        this.showLayout = true;
        this.isPageReady = true;
      }
    }
    if (error) {
      this.setError(error);
    }
  }

  async handleSaveRecord(parameters) {
    const [error, data] = await VeevaUtils.to(this.pageCtrl.save({ submit: parameters.submit }));
    if (error) {
      this.setError({
        message: error,
      });
    } else if (data) {
      const redirectTo = {
        type: 'standard__recordPage',
        attributes: {
          recordId: data.Id,
          objectApiName: this.pageCtrl.objectApiName,
          actionName: 'view',
        },
      };
      this[NavigationMixin.Navigate](redirectTo);
    }
  }

  setError(error) {
    this.dispatchEvent(VeevaToastEvent.error(error));
  }

  get showSpinner() {
    return !this.disableSpinner && (!this.page.layout || this.page.requests.length);
  }

  get show() {
    return this.page.layout && this.showLayout;
  }
}