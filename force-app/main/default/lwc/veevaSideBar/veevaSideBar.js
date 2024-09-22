import { LightningElement, api } from 'lwc';
import VeevaSideBarTemplate from './veevaSideBar.html';

export default class VeevaSideBar extends LightningElement {

    @api sideBarCtrl;

    render() {
        return this.sideBarCtrl?.template || VeevaSideBarTemplate;
    }

}