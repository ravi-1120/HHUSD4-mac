import { LightningElement, api } from 'lwc';

export default class ReassignmentProgressBar extends LightningElement {
    @api progressSteps;
    @api progressInfos;
}