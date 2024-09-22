import VeevaNotesAttachmentsRelatedListController from 'c/veevaNotesAttachmentsRelatedListController';

export default class EmEventMaterialNotesAttachmentsRelatedListController extends VeevaNotesAttachmentsRelatedListController {
    // eslint-disable-next-line no-unused-vars 
    handleUploadFinished(files) {
        // refresh record page to reflect updated Has_Attachment_vod value
        this.pageCtrl.notifyLDSCache([{ recordId: this.pageCtrl.recordId }]);
    }
}