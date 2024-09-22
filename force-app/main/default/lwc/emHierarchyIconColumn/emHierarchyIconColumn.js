import { LightningElement, api } from 'lwc';

export default class EmHierarchyIconColumn extends LightningElement {
    @api hierarchyAllowed;
    @api typeAttributes;

    handleClick() {
        const { id } = this.typeAttributes;
        this.dispatchEvent(new CustomEvent('hierarchy', { 
            bubbles: true, 
            composed: true, 
            detail: {
                id
            }
        }));
    }
}