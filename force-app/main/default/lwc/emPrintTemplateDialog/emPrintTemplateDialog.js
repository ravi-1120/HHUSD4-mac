import { LightningElement, api, track } from 'lwc';
import VeevaToastEvent from 'c/veevaToastEvent';
import PrintTemplateSvc from './printTemplateSvc';

export default class EmPrintTemplateDialog extends LightningElement {
  @api recordId;
  @api meta;
  @track templates = [];
  button;
  cancelButtonLabel;
  disableButtons = false;
  noTemplateSelectedLabel;
  noTemplatesLabel;
  previewCache = {};
  previewError;
  previewLoading = false;
  recordTypeName;
  selected;
  templateSelectLabel;
  templatesLabel;
  templatesLoading = false;

  get dialogHeader() {
    return this.button?.label;
  }

  get disableGenerateButton() {
    return this.disableButtons || !this.preview;
  }

  get noTemplateSelected() {
    return !this.noTemplates && !this.preview && !this.previewError && !this.previewLoading;
  }

  get noTemplates() {
    return !this.templates?.length;
  }

  get preview() {
    if (this.selected?.catalogId && this.previewCache) {
      return this.previewCache[this.selected.catalogId];
    }
    return undefined;
  }

  connectedCallback() {
    this.button = this.meta.button;
    this.messageSvc = this.meta.messageSvc;
    this.printTemplateSvc = new PrintTemplateSvc(this.meta.dataSvc);
    this.recordTypeName = this.meta.recordTypeName;

    this.getTemplates();
  }

  closeDialog() {
    this.dispatchEvent(new CustomEvent('close'));
  }

  selectTemplate(event) {
    if (this.previewLoading) {
      return;
    }
    if (this.selected) {
      this.selected.ariaCurrent = 'false';
    }
    this.selected = this.templates[event.currentTarget.dataset.index];
    if (this.selected) {
      this.selected.ariaCurrent = 'page';
      this.getPreview();
    }
  }

  async getTemplates() {
    this.templatesLoading = true;

    const [response] = await Promise.allSettled([this.printTemplateSvc.getTemplates(this.recordId, this.recordTypeName), this.getMessages()]);
    if (response.status === 'fulfilled' && response.value) {
      const responseValue = response.value;
      if (responseValue.message) {
        this.dispatchEvent(VeevaToastEvent.error({ message: responseValue.message }));
      }
      this.templates = responseValue.data;
    }

    this.templatesLoading = false;
  }

  async getPreview() {
    this.previewError = null;
    if (this.previewCache[this.selected.catalogId]) {
      return;
    }
    this.previewLoading = true;

    try {
      const response = await this.printTemplateSvc.getPreview(this.recordId, this.recordTypeName, this.selected.catalogId, this.selected.Id);
      if (response?.data?.image) {
        this.previewCache[this.selected.catalogId] = `data:image;base64,${response.data.image}`;
      } else {
        throw new Error('no image');
      }
    } catch (error) {
      this.setPreviewError(this.noGeneratePreviewMsg);
    } finally {
      this.previewLoading = false;
    }
  }

  async generatePdf() {
    this.disableButtons = true;
    this.previewError = null;
    this.previewLoading = true;

    try {
      const response = await this.printTemplateSvc.generatePdf(this.recordId, this.recordTypeName, this.selected.catalogId, this.selected.Id);
      if (response.status !== 0) {
        throw new Error('pdf generation failed');
      }
      this.dispatchEvent(
        VeevaToastEvent.successMessage(
          this.recordTypeName === 'Print_Sign_In_Template_vod' ? this.generateSignInConfirmedMsg : this.generateInvitesConfirmedMsg
        )
      );
      this.closeDialog();
    } catch (error) {
      this.setPreviewError(this.noGenerateFileMsg);
    } finally {
      this.disableButtons = false;
      this.previewLoading = false;
    }
  }

  async getMessages() {
    [
      this.cancelButtonLabel,
      this.generateInvitesConfirmedMsg,
      this.generateSignInConfirmedMsg,
      this.noGenerateFileMsg,
      this.noGeneratePreviewMsg,
      this.noTemplateSelectedLabel,
      this.noTemplatesLabel,
      this.templateSelectLabel,
      this.templatesLabel,
    ] = await Promise.all([
      this.messageSvc.getMessageWithDefault('CANCEL', 'Common', 'Cancel'),
      this.messageSvc.getMessageWithDefault(
        'GENERATE_INVITES_CONFIRMED',
        'EVENT_MANAGEMENT',
        'Generating invitations. This may take several minutes. When complete, you can view and print the invitations from the Attachments section.'
      ),
      this.messageSvc.getMessageWithDefault(
        'GENERATE_SIGN_IN_CONFIRMED',
        'EVENT_MANAGEMENT',
        'Generating Sign In Sheet. This may take several minutes. When complete, you can view and print the sign in sheet from the Attachments section.'
      ),
      this.messageSvc.getMessageWithDefault(
        'NO_GENERATE_FILE',
        'EVENT_MANAGEMENT',
        'The file for {0} could not be generated because the attachment is not available. Please contact your system administrator.'
      ),
      this.messageSvc.getMessageWithDefault(
        'NO_GENERATE_PREVIEW',
        'EVENT_MANAGEMENT',
        'The preview for {0} could not be generated. Please contact your system administrator.'
      ),
      this.messageSvc.getMessageWithDefault('NO_TEMPLATE_SELECTED', 'Common', 'No template selected'),
      this.messageSvc.getMessageWithDefault('NO_TEMPLATES_AVAILABLE', 'Common', 'No templates available'),
      this.messageSvc.getMessageWithDefault('TEMPLATE_SELECT', 'EVENT_MANAGEMENT', 'Select a template below to see a preview:'),
      this.messageSvc.getMessageWithDefault('TEMPLATES', 'Common', 'Templates'),
    ]);
  }

  setPreviewError(msg) {
    const templateName = this.selected.name.replace(/</g, '&lt;');
    const errorMsg = msg.replace(/</g, '&lt;');
    this.previewError = errorMsg.replace('{0}', `<u>${templateName}</u>`);
    const previewArea = this.template.querySelector('.preview-area');
    if (previewArea) {
      previewArea.scrollTop = 0;
    }
  }
}