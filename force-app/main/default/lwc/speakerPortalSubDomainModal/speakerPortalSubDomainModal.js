import { LightningElement, api, track } from 'lwc';
import { getService } from 'c/veevaServiceFactory';
import SpeakerPortalDataService from 'c/speakerPortalDataService'

export default class SpeakerPortalSubDomainModal extends LightningElement {
  @api orgInfo;

  @track messageMap = {};
  @track recordErrors = [];
  @track fieldErrors = [];

  DOMAIN_PATTERN = '^(?:[a-zA-Z0-9]|-(?!-)){0,62}[a-zA-Z0-9]$';

  speakerPortalDataSvc;

  async connectedCallback() {
    this.messageMap = await this.loadVeevaMessages();
    this.speakerPortalDataSvc = new SpeakerPortalDataService(getService('sessionSvc'));
  }

  async loadVeevaMessages() {
    const messageSvc = getService('messageSvc');
    return messageSvc
      .createMessageRequest()
      .addRequest('EDIT_SUB_DOMAIN', 'SPEAKER_PORTAL', 'Edit Subdomain', 'editSubDomainLabel')
      .addRequest('SUB_DOMAIN_FIELD', 'SPEAKER_PORTAL', 'Subdomain', 'subDomainFieldLabel')
      .addRequest('SUB_DOMAIN_INVALID_VALUE', 'SPEAKER_PORTAL', 'Subdomain must only contain single dashes and alphanumeric characters', 'subDomainInvalidValueLabel')
      .addRequest('SUB_DOMAIN_IN_USE', 'SPEAKER_PORTAL', 'Subdomain is already in use', 'subDomainInUseLabel')
      .addRequest('GEN_SAVE_ERROR', 'EVENT_MANAGEMENT', 'We were unable to save the record', 'genSaveErrorLabel')
      .addRequest('CANCEL', 'Common', 'Cancel', 'cancelLabel')
      .addRequest('SAVE', 'Common', 'Save', 'saveLabel')
      .sendRequest();
  }

  closeDialog() {
    this.dispatchEvent(new CustomEvent('close'));
  }

  async save() {
    const domainElement = this.template.querySelector('lightning-input[data-id=subdomain]');
    const domainValue = domainElement.value;

    this.recordErrors = [];
    this.fieldErrors = [];
    domainElement.setCustomValidity('');

    // Only check subdomain validation on save to avoid focus issues
    if(domainValue && !domainValue.match(this.DOMAIN_PATTERN)) {
      domainElement.setCustomValidity(this.messageMap.subDomainInvalidValueLabel);
    }
    
    if (domainElement.reportValidity()) {
      try {
        const body = {domain : domainValue};
        const response = await this.speakerPortalDataSvc.updateOrgInfo(body);
        this.dispatchEvent(new CustomEvent('save', { detail: response.data }));
      } catch (error) {
        if (error?.data?.[0].errorId === '400.OR3') {
          domainElement.setCustomValidity(this.messageMap.subDomainInUseLabel);
          this.fieldErrors = [...this.fieldErrors, 
            {
              fieldLabel: domainElement.label,
              element: domainElement
            }
          ];
          domainElement.reportValidity();
        } else {
          this.recordErrors.push(this.messageMap.genSaveErrorLabel);
        }
      }
    } else {
      this.fieldErrors = [...this.fieldErrors, 
        {
          fieldLabel: domainElement.label,
          element: domainElement
        }
      ];
    }
  }

  handleErrorPopup(event) {
    const { fieldError } = event.detail;
    if (fieldError.element) {
      fieldError.element.focus();
    }
  }
}