import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { MessageContext, subscribe, unsubscribe, publish } from 'lightning/messageService';
import VeevaUtils from 'c/veevaUtils';
import { VeevaMessageRequest } from 'c/veevaMessageService';
import { getNestedFieldErrors, processFieldErrorsNotOnLayout } from 'c/veevaPageFieldErrors';
import veevaButtonAction from '@salesforce/messageChannel/Veeva_Button_Action__c';
import veevaHandleSaveResponse from '@salesforce/messageChannel/Veeva_Handle_Save_Response__c';
import componentRefreshMessage from '@salesforce/messageChannel/Component_Refresh_Message__c';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';
import VeevaConfirmationLightningModal from 'c/veevaConfirmationLightningModal';
import VeevaLayoutService from 'c/veevaLayoutService';

const GRID_CLASS = 'slds-grid slds-gutters modal-page-grid';
const DETAIL_GRID_PAGE = ' slds-col detail-content modal-page-col';
const SIDEBAR_GRID_PAGE = 'slds-col sidebar modal-page-col';

export default class VeevaModalPage extends VeevaErrorHandlerMixin(NavigationMixin(LightningElement)) {
  @api pageCtrl;
  @api page;
  @api recordUpdateFlag;
  @api pageReference;

  @track isSaving;
  @track recordErrors = [];
  @track fieldErrors = [];
  messageMap = {};

  get hasRequiredFieldInLayout() {
    return VeevaLayoutService.hasRequiredFieldInLayout(this.page?.layout);
  }

  get gridClass() {
    return this.showSideBar ? GRID_CLASS : '';
  }

  get detailGridPage() {
    let classList = 'slds-p-around_medium';
    if (this.showSideBar) {
      classList += DETAIL_GRID_PAGE + this.sideBarCtrl.getDetailPageRatio();
    }
    return classList;
  }

  get sideBarGridPage() {
    return this.showSideBar ? SIDEBAR_GRID_PAGE + this.sideBarCtrl.getSideBarRatio() : '';
  }

  get modalSize() {
    return this.sideBarCtrl.hasContent ? this.sideBarCtrl.getSideBarModalSize() : 'medium';
  }

  get sideBarButtonVariant() {
    return this.sideBarOpen ? 'brand' : 'border-filled';
  }

  get showSideBar() {
    return this.sideBarCtrl.hasContent && this.sideBarOpen;
  }

  sideBarCtrl = {};
  renderEvent = {};
  renderedOnce = true;
  sideBarInitialized = false;
  sideBarOpen = true;

  validityElementsSelector = 'c-veeva-section';

  @wire(MessageContext)
  messageContext;

  constructor() {
    super();
    this.renderEvent.start = +new Date();
  }

  async connectedCallback() {
    this.refreshComponentSubscription = subscribe(this.messageContext, componentRefreshMessage, message => this._refreshComponent(message));

    this.buttonActionSubscription = subscribe(this.messageContext, veevaButtonAction, message => this._handleButtonMessage(message));
    this.setSideBar(this.pageCtrl.hasSideBar());

    const msgRequest = new VeevaMessageRequest();
    msgRequest.addRequest('REQUIRED_INFORMATION', 'Common', 'Required Information', 'requiredFieldMessage');
    this.messageMap = await this.pageCtrl.getMessageMap(msgRequest);
  }

  _handleButtonMessage(message) {
    const buttonMatchesPage = message.recordId === this.pageCtrl.id && message.pageMode === this.pageCtrl.action;
    if (buttonMatchesPage) {
      if (message.action === 'saverecord') {
        this.handleSaveRecord(message.parameters);
      }
    }
  }

  _refreshComponent(message) {
    const validMessage = message.recordId === this.pageCtrl.id && message.pageMode === this.pageCtrl.action && message.keyToRefresh;
    if (validMessage) {
      this.refreshComponent(message.keyToRefresh);
    }
  }

  disconnectedCallback() {
    if (this.buttonActionSubscription) {
      unsubscribe(this.buttonActionSubscription);
      this.buttonActionSubscription = null;
    }

    if (this.refreshComponentSubscription) {
      unsubscribe(this.refreshComponentSubscription);
      this.refreshComponentSubscription = null;
    }

    this.clearPageError();
  }

  /**
   * Sets UI fields with reportValididty errors
   * Returns a map of fields to fieldErrors
   */
  @api getFieldErrors() {
    return getNestedFieldErrors(this.getDataValidityElements());
  }

  refreshComponent(key) {
    const children = this.getDataValidityElements();
    children.forEach(child => {
      if (child.refreshComponent) {
        child.refreshComponent(key);
      }
    });
  }

  get waiting() {
    return !this.page.layout || this.page.requests.length;
  }

  handleErrorPopup(event) {
    const { fieldError } = event.detail;
    const pathCopy = fieldError?.path ? [...fieldError.path] : [];
    this.focusOn(pathCopy);
  }

  async handleSaveRecord(parameters) {
    this.clearPageError();
    this.isSaving = true;

    let fieldErrors = this.getFieldErrors();

    if (fieldErrors.length > 0) {
      // UI errors such as 'required'
      this.setPageError(fieldErrors);
      return;
    }
    const valid = await this.pageCtrl.validate({ submit: parameters.submit });
    if (!valid) {
      // model errors
      this.setPageError(fieldErrors);
      return;
    }

    const preSaveConfirmationData = await this.pageCtrl.performPreSaveConfirmationLogic();
    if (preSaveConfirmationData?.showConfirmationModal) {
      const isConfirmed = await VeevaConfirmationLightningModal.open(preSaveConfirmationData.content);
      if (!isConfirmed) {
        this.setPageError(fieldErrors);
        return;
      }
    }
    const [error, data] = await VeevaUtils.to(this.pageCtrl.save({ submit: parameters.submit, pageRef: this.pageReference }));
    if (error) {
      fieldErrors = this.getFieldErrors();
      // save errors from database
      this.setPageError(fieldErrors);
      return;
    }

    if (parameters.saveResponseMessage) {
      const message = { ...parameters.saveResponseMessage };
      message.createdId = data.Id;
      publish(this.messageContext, veevaHandleSaveResponse, message);
      this.isSaving = false;
    } else {
      // refresh (refreshApex does not work)
      this.isSaving = false;
      this.dispatchEvent(
        new CustomEvent('close', {
          detail: {
            id: data.Id,
            data,
            ...parameters,
          },
        })
      );
    }
  }

  @api clearPageError() {
    this.recordErrors = null;
    this.fieldErrors = null;
    this.pageCtrl.clearErrors();
  }

  setPageError(fieldErrors) {
    this.isSaving = false;
    processFieldErrorsNotOnLayout(
      fieldErrors,
      this.pageCtrl.fieldErrors,
      this.pageCtrl.recordErrors,
      this.pageCtrl.objectInfo.fields,
      this.pageCtrl.id
    );
    this.recordErrors = [...(this.pageCtrl.recordErrors || [])];
    this.fieldErrors = [...(fieldErrors || [])];
  }

  renderedCallback() {
    if (this.renderedOnce && !this.waiting) {
      this.renderedOnce = false;
      this.dispatchEvent(
        new CustomEvent('pageready', {
          bubbles: true,
        })
      );
    }
    this.setSideBar(this.pageCtrl.hasSideBar());
  }

  setSideBar(hasSideBar) {
    if (hasSideBar === true && this.sideBarInitialized === false) {
      this.sideBarCtrl = this.pageCtrl.getSideBarController();
      this.sideBarInitialized = true;
    }
  }

  handleCloseSideBar() {
    this.sideBarOpen = false;
  }

  toggleSideBar() {
    this.sideBarOpen = !this.sideBarOpen;
  }

  handleClose() {
    this.clearPageError();
  }
}