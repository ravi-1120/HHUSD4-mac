import VeevaRelatedListController from 'c/veevaRelatedListController';
import VeevaFilesRelatedListController from 'c/veevaFilesRelatedListController';
import VeevaNotesAttachmentsRelatedListController from 'c/veevaNotesAttachmentsRelatedListController';
import VeevaNotesRelatedListController from 'c/veevaNotesRelatedListController';
import VeevaTasksRelatedListController from 'c/veevaTasksRelatedListController';

export default class RelatedListControllerFactory {
  static relatedListController = (meta, pageCtrl) => {
    if (meta.relationship === 'AttachedContentDocuments') {
      return new VeevaFilesRelatedListController(meta, pageCtrl);
    }
    if (meta.relationship === 'CombinedAttachments') {
      return new VeevaNotesAttachmentsRelatedListController(meta, pageCtrl);
    }
    if (meta.relationship === 'AttachedContentNotes') {
      return new VeevaNotesRelatedListController(meta, pageCtrl);
    }
    if (meta.relationship === 'OpenActivities' || meta.relationship === 'ActivityHistories') {
      return new VeevaTasksRelatedListController(meta, pageCtrl);
    }
    return new VeevaRelatedListController(meta, pageCtrl);
  };
}