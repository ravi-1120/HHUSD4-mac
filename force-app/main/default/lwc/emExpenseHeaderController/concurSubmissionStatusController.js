import PicklistController from 'c/picklistController';
import template from './concurSubmissionStatusFieldTemplate.html';

export default class ConcurSubmissionStatusController extends PicklistController {

    initTemplate() {
        if (!this.editable) {
            this.template = template;
        }
        return super.initTemplate();
    }
}