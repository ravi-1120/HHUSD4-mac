import { LightningElement, api } from 'lwc';
import EmConcurStatus from './emConcurStatus';

export default class EmConcurSubmissionStatusField extends LightningElement {
    @api ctrl;
    statusIcon;
    statusIconVariant;
    helpText;

    async connectedCallback() {
        const submissionStatus = EmConcurSubmissionStatusField.getConcurStatus(this.value);
        this.statusIcon = submissionStatus.icon;
        this.statusIconVariant = submissionStatus.iconVariant;
        if (submissionStatus.helptext?.key) {
            const {key, category, defaultMessage} = submissionStatus.helptext;
            this.helpText = await this.ctrl.pageCtrl.messageSvc.getMessageWithDefault(key, category, defaultMessage);
        }
        
    }

    get label() {
        return this.ctrl.displayValue;
    }

    get value() {
        return this.ctrl.rawValue;
    }

    static getConcurStatus(status) {
        return new EmConcurStatus(status);
    }
}