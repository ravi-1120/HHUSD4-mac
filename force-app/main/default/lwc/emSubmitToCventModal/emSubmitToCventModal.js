import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import SubmitToCventService from './submitToCventService';

const STATES = {
  LOADING: 'loading',
  ERROR: 'error',
  SUCCESS: 'success',
}

export default class EmSubmitToCventModal extends LightningModal {
  @api recordId;

  componentInitialized = false;
  labels = {};
  state = STATES.LOADING;

  get loading() {
    return this.state === STATES.LOADING;
  }

  get error() {
    return this.state === STATES.ERROR;
  }

  get success() {
    return this.state === STATES.SUCCESS;
  }

  connectedCallback() {
    if (!this.componentInitialized) {
      this.componentInitialized = true;
      this.init();
    }
  }

  init() {
    this.disableClose = true;
    this.loadMessages();
    this.submitToCvent();
  }

  async loadMessages() {
    const messageSvc = getService(SERVICES.MESSAGE);
    this.labels = await messageSvc
      .createMessageRequest()
      .addRequest('OK', 'Common', 'OK', 'okay')
      .addRequest('CREATE_MEETING_REQUEST', 'EVENT_MANAGEMENT', 'Create Meeting Request', 'header')
      .addRequest(
        'CREATE_MEETING_REQUEST_FAILURE',
        'EVENT_MANAGEMENT',
        'Unable to Create Meeting Request in Cvent. Contact your Administrator if the problem continues.',
        'error'
      )
      .addRequest('CREATE_MEETING_REQUEST_SUCCESS', 'EVENT_MANAGEMENT', 'Meeting Request Created in Cvent', 'success')
      .sendRequest();
  }

  async submitToCvent() {
    const submitToCventSvc = new SubmitToCventService();
    try {
      const response = await submitToCventSvc.createMeetingRequest(this.recordId);
      if (response?.status !== 'SUCCESS') {
        throw response;
      }
      this.state = STATES.SUCCESS;
    } catch (error) {
      this.state = STATES.ERROR;
    } finally {
      this.disableClose = false;
      if (this.success) {
        getRecordNotifyChange([{ recordId: this.recordId }]);
      }
    }
  }

  handleOkay() {
    this.close();
  }
}