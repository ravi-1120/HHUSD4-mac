import { LightningElement, api, track } from 'lwc';
//import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import exceptionMessage from '@salesforce/label/c.NIC_Exception_Message';
import exceptionMessageBody from '@salesforce/label/c.NIC_Exception_Message_Body';
import SCHEDULE_CALL_BACK_HEADER_MESSAGE from '@salesforce/label/c.Schedule_Callback_Header_Message';
import SCHEDULE_CALL_BACK_HEADER from '@salesforce/label/c.Schedule_Callback_Header';
import SCHEDULE_CALL_BACK_FOTTER from '@salesforce/label/c.Schedule_Callback_Footer';
import CALL_ME_NOW_HEADER from '@salesforce/label/c.Call_Me_Now_Header';
import CALL_ME_NOW_LOGGEDIN_AGENT_AVIALABLE_HEADER_MESSAGE from '@salesforce/label/c.Call_Me_Now_Agent_Available_Message';
import CALL_ME_NOW_LOGGEDIN_AGENT_NOT_AVIALABLE_HEADER_MESSAGE from '@salesforce/label/c.Call_Me_Now_Agent_Not_Available_Message';
import CALL_ME_NOW_FOTTER from '@salesforce/label/c.Call_Me_Now_Footer';
import ICS_CALENDAR_BODY from '@salesforce/label/c.AMO_ICS_calendar_body';
import Product_Access_Inquiry_Header from '@salesforce/label/c.AMO_Product_Access_Inquiry_Header';
import Product_Access_Inquiry_Body from '@salesforce/label/c.AMO_Product_Access_Inquiry_Body';
import Product_Access_Inquiry_Footer from '@salesforce/label/c.AMO_Product_Access_Inquiry_Footer';

const DOWNLOAD_CAL = 'dowload calendar';
const EVT_ACTION = 'click';
const WEBLINK_EVT_ACTION = 'The Merck Access Program Weblink';


export default class AppointmentMessageComponent extends LightningElement {
    @track trackisSchedulable = false;
    @track trackisCallMeNow = false;
    @api calloutResponse;
    @api
    get isSchedulable() {
        return this.trackisSchedulable;
    }
    set isSchedulable(value) {
        console.log('isSchedulable->' + value);
        this.trackisSchedulable = (value == true) ? true : false;
        console.log('this.trackisSchedulable-->' + this.trackisSchedulable);
    }
    @track header;
    @track headerMessage;
    @track fotter;
    @api
    get isCallMeNow() {
        return this.trackisCallMeNow;
    }
    set isCallMeNow(value) {
        this.trackisCallMeNow = value;
    }
    @api appointmentDateTime;
    @api selectedTemplate;
    @api agentAvailability;
    @track isNICException = false;
    @api selectedProduct;

    /*channelName = '/event/NIC_Exception__e';
    receivedMessage;
    subscription = {}; */
    label = {
        exceptionMessage,
        Product_Access_Inquiry_Header,
        Product_Access_Inquiry_Body,
        Product_Access_Inquiry_Footer,
        exceptionMessageBody
    }


    connectedCallback() {
        console.log('trackisCallMeNow-->' + this.trackisCallMeNow);
        if (this.isSchedulable) {
            if (this.calloutResponse.responseStatusCode == 200 && this.calloutResponse.spawnId != undefined) {
                if (this.trackisCallMeNow != true) {
                    this.header = SCHEDULE_CALL_BACK_HEADER;
                    this.headerMessage = SCHEDULE_CALL_BACK_HEADER_MESSAGE;
                    this.fotter = SCHEDULE_CALL_BACK_FOTTER;
                    var tempappiontmentDateTime = JSON.parse(JSON.stringify(this.appointmentDateTime));
                    tempappiontmentDateTime.dateLabel = (tempappiontmentDateTime.dateLabel.substring(tempappiontmentDateTime.dateLabel.indexOf(',') + 1));
                    this.appointmentDateTime = tempappiontmentDateTime;
                }
                else {
                    this.header = CALL_ME_NOW_HEADER;
                    if (this.agentAvailability != undefined) {
                        this.agentAvailability.skillActivity.forEach(ele => {
                            if (ele.agentsAvailable > 0 && ele.agentsLoggedIn > 0) {
                                this.headerMessage = CALL_ME_NOW_LOGGEDIN_AGENT_AVIALABLE_HEADER_MESSAGE;
                                this.fotter = '';
                            }
                            else if (ele.agentsLoggedIn > 0 && ele.agentsAvailable == 0) {
                                this.headerMessage = CALL_ME_NOW_LOGGEDIN_AGENT_NOT_AVIALABLE_HEADER_MESSAGE;
                                this.fotter = CALL_ME_NOW_FOTTER;
                            }
                            else {
                                this.headerMessage = CALL_ME_NOW_LOGGEDIN_AGENT_NOT_AVIALABLE_HEADER_MESSAGE;
                                this.fotter = CALL_ME_NOW_FOTTER;
                            }
                        });

                    }
                }
            }
            else {
                this.trackisSchedulable = '';
                this.isNICException = true;
            }
        }

        //this.registerErrorListener();
        // this.handleSubscribe();
    }

    handleBack(event) {
        this.dispatchEvent(new CustomEvent('back'));

    }

    handleGetHtmlContent(htmlContent) {
        const container = this.template.querySelector('data-id="templateMessage"');

        container.innerHTML = htmlContent;
    }


    handleDownload() {
        this.handleDataLayerEvent();
        var scheduledDateTime = this.appointmentDateTime.dateValue + 'T' + this.appointmentDateTime.timeSlotValue;
        console.log('schduledDateTime-->' + scheduledDateTime);
        var body = '<h1> This is a calendar hold for your scheduled call with a Merck Associate. </h1><br/><hr size="3" width="100%" color="#00857C">  <br/>';
        body += '<b style="color: rgb(0, 133, 124); font-family: Invention, sans-serif; font-size: medium;">The associate will reach out to you directly.</b>';
        body += '<br/><br/>This service is for US health care professionals only.';//<br/><br/>To report and Adverse Event or Product Quality complaint, ';
        //body += 'please call ';
        //body += '<b style="color: rgb(0, 133, 124); font-family: Invention, sans-serif; font-size: small;">&nbsp;1-800-627-6372.</b>';
        body += '<br/><br/>This meeting is automatically generated. <br/><br/><p style="color:rgb(128,128,128); font-family: Invention,sans-serif;font-size: 12px;"> Copyright &#169; 2023 Merck & Co., Inc., Rahway, NJ, USA and its affiliates. All rights reserved. <br/>US-NON-17263 10/23</p>';
        var subject = "Call with an Ask Merck Associate";
        var icsMSG = "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//salesforce.com//Calendar//EN\nBEGIN:VEVENT\n";
        icsMSG += "DTSTAMP:" + this.configureDateTime(new Date().toISOString());
        icsMSG += "\nSUMMARY:" + subject + "\nCATEGORIES:salesforce.com\n";
        icsMSG += "DESCRIPTION: This is a calendar hold for your scheduled call with a Merck Associate.\n";
        icsMSG += "X-ALT-DESC;FMTTYPE=text/html:" + body + "\n";
        icsMSG += "CREATED:" + this.configureDateTime(new Date().toISOString());
        icsMSG += "\nLAST-MODIFIED:" + this.configureDateTime(new Date().toISOString());
        icsMSG += "\nSTATUS:CONFIRMED\n";
        icsMSG += "DTSTART:" + this.configureDateTime(scheduledDateTime);
        icsMSG += "\nDURATION:PT15M\nEND:VEVENT\nEND:VCALENDAR";
        var link = this.template.querySelector('[data-id="downloadLink"]');
        link.href = ("data:text/calendar;charset=utf8," + escape(icsMSG));
        //console.log('icsMesa-->' + icsMSG);
        // window.open("data:text/calendar;charset=utf8," + escape(icsMSG));
    }


    configureDateTime(datetime) {
        var aDate = new Date(datetime);
        var pre =
            aDate.getFullYear().toString() +
            ((aDate.getMonth() + 1) < 10 ? "0" + (aDate.getMonth() + 1).toString() : (aDate.getMonth() + 1).toString()) +
            ((aDate.getDate() + 1) < 10 ? "0" + aDate.getDate().toString() : aDate.getDate().toString());
        // console.log((aDate.getHours() % 12) < 10 ? "0" : '');

        // var post = ((aDate.getHours() % 12) < 10 ? "0" : '').toString() + (aDate.getHours() % 12).toString() + aDate.getMinutes().toString() + "00";
        var post = String(aDate.getHours()).padStart(2, '0') + String(aDate.getMinutes()).padStart(2, '0') + "00";
        var contactDateTime = pre + "T" + post;
        console.log('contactDateTime-->' + contactDateTime);
        return contactDateTime;
    }

    handleDataLayerEvent() {
        var evt = { 'event_category': DOWNLOAD_CAL, 'event_action': EVT_ACTION };
        const selectedTimeslotEvent = new CustomEvent("downloadics", {
            detail: evt
        });
        this.dispatchEvent(selectedTimeslotEvent);
    }

    handleProductAccessClick() {
        var tempEventCategory = WEBLINK_EVT_ACTION +' for '+ this.selectedProduct.label;
        var evt = { 'event_category': tempEventCategory, 'event_action': EVT_ACTION };
        const webLinkEvent = new CustomEvent("merckaccessweblink", {
              detail: evt
          });
          this.dispatchEvent(webLinkEvent);
    }

    /*handleSubscribe() {
        const messageCallback = (response) => {
            this.handleResponse(response);
        }

        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }

    handleResponse(response) {
        if (response != undefined) {
            this.trackisSchedulable = false;
            this.isNICException = true;
        }
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, response => {
        });
    }

    registerErrorListener() {
        onError(error => {
        });
    }

    messageReceived(event){
        if(event.detail){
            this.trackisSchedulable = false;
            this.isNICException = true;
        }
    } */
}