import { api } from 'lwc';
import EmBaseRelatedList from 'c/emBaseRelatedList';

export default class EmRelatedListPanel extends EmBaseRelatedList {
  @api objectApiName;
  @api recordId;

  noRelatedListsMessage = null;

  async populateRelatedLists(payload) {
    await super.populateRelatedLists(payload);
    if (this.relatedLists.length === 0) {
      this.pageCtrl.getMessageWithDefault('NO_RELATED_LISTS', 'EVENT_MANAGEMENT', 'No related lists to display').then(data => {
        this.noRelatedListsMessage = data;
      });
    } else {
      this.noRelatedListsMessage = null;
    }
  }
}