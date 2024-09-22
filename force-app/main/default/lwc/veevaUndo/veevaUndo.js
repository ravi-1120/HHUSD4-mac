import { LightningElement, api } from "lwc";

export default class VeevaUndo extends LightningElement {
    @api showUndo;
    @api isNew;
    
    handleOnClick() {
        this.dispatchEvent(new CustomEvent('undoclick'));
    }

    get classUndo() {
        // undo highlight color is different between new and edit pages
        let css = 'undo edit-page';
        if (this.isNew) {
            css = 'undo new-page';
        }
        return this.showUndo ? css : '';
    }
}