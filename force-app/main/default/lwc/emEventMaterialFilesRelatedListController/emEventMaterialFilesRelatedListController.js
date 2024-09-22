import VeevaFilesRelatedListController from 'c/veevaFilesRelatedListController';

export default class EmEventMaterialFilesRelatedListController extends VeevaFilesRelatedListController {
    // eslint-disable-next-line no-unused-vars 
    handleUploadFinished(files) {
        // refresh record page to reflect updated Has_Attachment_vod value
        this.pageCtrl.notifyLDSCache([{ recordId: this.pageCtrl.recordId }]);
    }
}