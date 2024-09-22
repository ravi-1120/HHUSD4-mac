import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import VeevaConstant from 'c/veevaConstant';
import { getService } from 'c/veevaServiceFactory';
import fetchNotesAttachmentsFiles from '@salesforce/apex/NotesAttachmentsFilesController.fetchNotesAttachmentsFiles';
import styleOverride from '@salesforce/resourceUrl/vod_lightning_file_upload_style_override';
import { VeevaMessageRequest } from 'c/veevaMessageService';

import FileRowObject from './fileRowObject';


const MAX_VISIBLE_RECORD = 6;

export default class VeevaNotesAndAttachmentsList extends NavigationMixin(LightningElement) {
  @api recordId;
  @api hasMoreRecords = false;

  @track readOnly;
  @track labels;
  @track notesAttachmentsFiles = [];
  @track viewAllUrl = '#';  
    
  fileUploadStyleOverrideLoaded = false;

  connectedCallback() {
    registerListener(VeevaConstant.PUBSUB_RECORD_READY, this.handleRecordReady, this);
    this.redirectUrl = {
      type: 'standard__recordRelationshipPage',
      attributes: {
        recordId: this.recordId,
        relationshipApiName: 'CombinedAttachments',
        actionName: 'view',
      },
    };
    // Generate View All's href value so user can open in a new tab
    this[NavigationMixin.GenerateUrl](this.redirectUrl).then(url => {
      this.viewAllUrl = url;
    });
  }

  async renderedCallback() {
    if (this.labels && !this.fileUploadStyleOverrideLoaded) {
      await loadStyle(this, styleOverride);
      this.fileUploadStyleOverrideLoaded = true;
    }
  }

  disconnectedCallback() {
    unregisterAllListeners(this);
  }

  handleUploadFinished() {
    this.fetchNotesAttachmentsFiles(this.recordId);
  }

  redirectToListView() {
    this[NavigationMixin.Navigate](this.redirectUrl);
  }

  handleViewAllClick(event) {
    // Do not follow href link
    event.preventDefault();
    // Prevent click bubbling up in the DOM
    event.stopPropagation();
    // Navigate to list view page
    this.redirectToListView();
  }

  get headerCss() {
    const noActionClass = this.readOnly ? 'link-no-action' : '';
    return `slds-card__header-link baseCard__header-title-container ${noActionClass}`;
  }

  get recordCountLabel() {
    let recordCountLabel = '';

    if (this.notesAttachmentsFiles) {
      recordCountLabel = this.notesAttachmentsFiles.length;
      
      if (this.hasMoreRecords) {
        recordCountLabel += '+';
      }

      recordCountLabel = `(${recordCountLabel})`;
    }

    return recordCountLabel;
  }

  get hasRecords() {
    return this.notesAttachmentsFiles.length > 0;
  }

  async handleRecordReady(pageCtrl) {
    this.readOnly = !pageCtrl.objectInfo.updateable || pageCtrl.record.isLocked;

    if (await pageCtrl.shouldDisplayAttachmentsList()) {
      await this.fetchLabels(pageCtrl);
      this.fetchNotesAttachmentsFiles(pageCtrl.id);
    }
  }

  async fetchLabels(pageCtrl) {
    const messageService = getService('messageSvc');
    const relatedLists = await pageCtrl.fetchRelatedListInfo();
    const headerLabel = relatedLists.find(relatedList => relatedList.objectApiName === 'CombinedAttachment')?.label;

    const notelabelPromise = pageCtrl.uiApi.objectInfo('Note').then(noteObjInfo => noteObjInfo.label);

    const msgRequest = new VeevaMessageRequest();
    msgRequest.addRequest('ATTACHMENT', 'ATTACHMENT', 'Attachment', 'attachmentLabel');
    msgRequest.addRequest('KB', 'TABLET', 'KB', 'kiloByteLabel');
    msgRequest.addRequest('MB', 'TABLET', 'MB', 'megaByteLabel');
    msgRequest.addRequest('LTNG_VIEW_ALL', 'Lightning', 'View All', 'viewAllLabel');
    msgRequest.addRequest('UPLOAD_FILE', 'Attachment', 'Upload File', 'uploadFileLabel');

    const veevaMessagePromise = messageService.getMessageMap(msgRequest);

    const [ noteLabel, veevaMessages ] = await Promise.all([notelabelPromise, veevaMessagePromise]);

    this.labels = {
      headerLabel,
      noteLabel,
      ...veevaMessages,
    };
  }

  async fetchNotesAttachmentsFiles(recordId) {
    // fetch Notes, Attachments, & Files
    // fetch MAX_VISIBLE_RECORD + 1 record to determine if there's more
    const allResult = await fetchNotesAttachmentsFiles({ recordId, maxNum: MAX_VISIBLE_RECORD + 1 });

    // if we get more than MAX_VISIBLE_RECORD, splice and set hasMoreRecords to true
    this.hasMoreRecords = allResult.splice(MAX_VISIBLE_RECORD).length > 0;

    this.notesAttachmentsFiles = allResult.map(entry => new FileRowObject(entry.data, entry.type, this.labels));
  }
}