import { api, LightningElement } from 'lwc';
import { getPopoverController } from 'c/emSelectionPageControllerFactory';
import defaultTemplate from './selectionPagePopover.html';

export default class SelectionPagePopover extends LightningElement {

    @api pageCtrl;
    @api type;
    @api record;
    @api selected;
    @api relatedList;

    get ctrl() {
        return getPopoverController(this.relatedList, this.pageCtrl, this.type);
    }

    render() {
        return this.ctrl.getTemplate() || defaultTemplate;
    }
    
    handleEvent(event) {
        this.dispatchEvent(new CustomEvent(event.type,
            {
                detail: event.detail
            }
        ));
    }
}