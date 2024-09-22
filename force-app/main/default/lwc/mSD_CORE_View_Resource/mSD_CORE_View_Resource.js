import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import mheebookmark from '@salesforce/resourceUrl/viewresourcebookmark';
import leftarrowicon from '@salesforce/resourceUrl/viewresourceleftarrow';

export default class MSD_CORE_View_Resource extends LightningElement {
    mheebookmark = mheebookmark;
    leftarrowicon = leftarrowicon;

    @wire(CurrentPageReference) pageRef;
    
    get iframeUrl() {
        return this.pageRef ? this.pageRef.state.link : '';
    }

    goBack() {
        window.location.href = '/merckmhee/all-resources';
    }
}