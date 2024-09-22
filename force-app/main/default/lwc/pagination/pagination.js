import { LightningElement } from 'lwc';
export default class Pagination extends LightningElement {
                                    
                                    previousHandler() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    nextHandler() {
        console.log('clicked next 1');
        this.dispatchEvent(new CustomEvent('next'));
    }
}