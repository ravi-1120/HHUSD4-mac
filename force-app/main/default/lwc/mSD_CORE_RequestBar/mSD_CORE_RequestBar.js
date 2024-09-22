import { api, LightningElement, track } from 'lwc';

export default class MSD_CORE_RequestBar extends LightningElement {

    reqsubcls = 'rp-main-cls rp-br-request-sbmtd';
    appschcls = 'rp-main-cls rp-br-apmt-schdl';
    presattcls = 'rp-main-cls rp-br-apmt-tchdl';
    reqrescls = 'rp-main-cls rp-br-apmt-cmpltd';
    reqsubdotcls = 'dot-class';
    appschdotcls = 'dot-class';
    preattdotcls = 'dot-class';
    reqresdotcls = 'dot-class';
    @track progressbarvalue;

    /* This Function used for updating progressbar as per status */
    @api
    updateStatusBar(reqvalue) {
        try {
            this.progressbarvalue = reqvalue;
            console.log('this.progressbarvalue --->' , this.progressbarvalue);
            if (this.progressbarvalue == 'Request Submitted') {
                this.reqsubdotcls = 'dot-class active-dot-cls';
            } else if (this.progressbarvalue == 'Appointment Scheduled') {
                this.reqsubcls = 'rp-main-cls rp-br-request-sbmtd active-border-cls';
                this.appschcls = 'rp-main-cls rp-br-apmt-schdl rp-bar-halfline';
                this.reqsubdotcls = 'dot-class active-dot-cls';
                this.appschdotcls = 'dot-class active-dot-cls';
            } else if (this.progressbarvalue == 'Presentation Attended') {
                this.reqsubcls = 'rp-main-cls rp-br-request-sbmtd active-border-cls';
                this.appschcls = 'rp-main-cls rp-br-apmt-schdl active-border-cls';
                this.presattcls = 'rp-main-cls rp-br-apmt-tchdl rp-bar-halfline';
                this.reqsubdotcls = 'dot-class active-dot-cls';
                this.appschdotcls = 'dot-class active-dot-cls';
                this.preattdotcls = 'dot-class active-dot-cls';
            } else if (this.progressbarvalue == 'Received post-presentation materials') {
                this.reqsubcls = 'rp-main-cls rp-br-request-sbmtd active-border-cls';
                this.appschcls = 'rp-main-cls rp-br-apmt-schdl active-border-cls';
                this.presattcls = 'rp-main-cls rp-br-apmt-tchdl active-border-cls';
                this.reqrescls = 'rp-main-cls rp-br-apmt-cmpltd active-border-cls';
                this.reqsubdotcls = 'dot-class active-dot-cls';
                this.appschdotcls = 'dot-class active-dot-cls';
                this.preattdotcls = 'dot-class active-dot-cls';
                this.reqresdotcls = 'dot-class active-dot-cls';
            } else {

            }
        } catch (error) {
            console.log({ error });
        }
    }
}