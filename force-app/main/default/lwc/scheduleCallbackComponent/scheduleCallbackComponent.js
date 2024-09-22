import { LightningElement, api, track } from 'lwc';
import scheduleCallbackLabel from '@salesforce/label/c.AMO_Schedule_Callback_Label';
import nextWeekLabel from '@salesforce/label/c.AMO_Next_Week_Label';
import previousWeekLabel from '@salesforce/label/c.AMO_Previous_Week_Label';
const BUTTON_ACTIVE_STATE = 'color: #00857C;font-size: 15px;font-weight: bold;letter-spacing: 0.09px;line-height: 16px;cursor: pointer; font-family: Invention;';
const BUTTON_INACTIVE_STATE = 'color: #757575;font-size: 15px;font-weight: bold;letter-spacing: 0.09px;line-height: 16px;font-family: Invention;';

export default class ScheduleCallbackComponent extends LightningElement {
    //@api dtList;
    label = {
        scheduleCallbackLabel,
        nextWeekLabel,
        previousWeekLabel
    };
    @track showScheduleCalender = false;
    @track isPrevDisabled = false;
    @track isNextDisabled = false;
    @track trackDateList;
    @track cuurdte = new Date().toISOString();
    @api holidaysList;
    @api businessHours;
    //@api schedulingGroup;
    @track selectedDate = {};
    @track counter = 0;
    @track startTime;
    @track endTime;
    buttonActiveState = BUTTON_ACTIVE_STATE;
    buttonInactive = BUTTON_INACTIVE_STATE;
    @track buttonPreStyle;
    @track buttonNextStyle = BUTTON_ACTIVE_STATE;

    @track initialDtList;
    @track scheduledGroup;

    @api
    get schedulingGroup() {
        return this.scheduledGroup;
    }
    set schedulingGroup(value) {
        console.log('Group Name: '+value);
        var groupChange = this.scheduledGroup != value && this.scheduledGroup != undefined ? true:false;
        if(this.initialDtList != undefined && groupChange){
            this.setDateList(this.initialDtList);
        }
        this.scheduledGroup = value;
    }

    @api
    get dtList() {
        return this.trackDateList;
    }
    set dtList(value) {
        this.setDateList(value);
    }

    setDateList(value){
        this.isPrevDisabled = false;
        this.buttonPreStyle = BUTTON_ACTIVE_STATE;
        var tempValue = JSON.parse(JSON.stringify(value));
        this.initialDtList = value;
        if (tempValue.length > 0) {
            //console.log('last index-->' + tempValue[tempValue.length - 1].dateValue);
            console.log('dt List--->' + JSON.stringify(tempValue));
            var tmpcurrDate = new Date();
            let dayOfWeek = tmpcurrDate.toLocaleDateString('en-US', { weekday: 'long' });
            var weekEnd = (dayOfWeek == 'Sunday' || dayOfWeek == 'Saturday') ? true : false;
            if (weekEnd) { tmpcurrDate = new Date(tmpcurrDate.setDate(tmpcurrDate.getDate() + 1)) };
            console.log('currDate-->' + new Date(tmpcurrDate));
            console.log('dayOfWeek-->' + dayOfWeek);
            var first = (tmpcurrDate.getDate() - tmpcurrDate.getDay()) + 1;
            console.log(first + ' ' + weekEnd);
            var firstday = new Date(tmpcurrDate.setDate(first)).toISOString();
            console.log('first-->' + firstday);
            tempValue.forEach(element => {
                if (this.cuurdte.substr(0, this.cuurdte.indexOf('T')) == element.dateValue ||
                    (weekEnd == true && firstday.substr(0, firstday.indexOf('T')) == element.dateValue)) {
                    this.isPrevDisabled = true;
                    this.buttonPreStyle = BUTTON_INACTIVE_STATE;
                }
                if (this.holidaysList != undefined && this.holidaysList.length > 0) {
                    if (this.holidaysList.includes(element.dateValue)) {
                        element.showdate = false;
                    }
                }
            });
            console.log('ispreviosdiabled-->' + this.isPrevDisabled);
            this.trackDateList = [];
            this.trackDateList = tempValue;
            console.log('dt List final--->' + JSON.stringify(this.trackDateList));
            this.showScheduleCalender = true;
        }
    }

    showHideDay(event) {
        console.log('currenttarget-->' + event['currentTarget'].dataset.targetId);
        let targetId = parseInt(event['currentTarget'].dataset.targetId);
        console.log('targetId-->' + targetId);
        var dList = JSON.parse(JSON.stringify(this.trackDateList));
        for (var i = 0; i < this.trackDateList.length; i++) {
            if (targetId == i) {
                this.selectedDate = this.trackDateList[i];
                console.log('showhidelist-->' + JSON.stringify(dList[i]));
                console.log('this.businessHours-->' + JSON.stringify(this.businessHours));
                this.businessHours.forEach(businessHrsEle => {
                    if (businessHrsEle.weekName == dList[i].dateLabel.substr(0, dList[i].dateLabel.indexOf(','))) {
                        this.startTime = businessHrsEle.startTime;
                        this.endTime = businessHrsEle.endTime;
                    }
                });
                dList[i]['showTimes'] = (dList[i]['showTimes'] ? false : true);
            }
            else {
                dList[i]['showTimes'] = false;
            }
        }
        console.log('selcetddate->' + JSON.stringify(this.selectedDate));
        console.log('temp list->' + dList);
        this.trackDateList = [];
        this.trackDateList = dList;
        console.log('dtlist final-->' + JSON.stringify(this.trackDateList));
    }

    goPrev(event) {
        if (!this.isPrevDisabled) {
            this.showScheduleCalender = false;
            this.counter = this.counter - 1;
            this.isNextDisabled = (this.counter >= 3 ? true : false);
            var currlabel = event.target.dataset.id;
            console.log('label->' + currlabel);
            this.buttonNextStyle = (this.counter >= 3 ? BUTTON_INACTIVE_STATE : BUTTON_ACTIVE_STATE);
            const nextOrPreviousWeekEvent = new CustomEvent("nextorpreviousweek", {
                detail: currlabel
            });
            this.dispatchEvent(nextOrPreviousWeekEvent);
            // let nextButton = this.template.querySelector('[data-id=\'Next Week\']');
            //  nextButton.style = (this.counter >= 3 ? BUTTON_INACTIVE_STATE : BUTTON_ACTIVE_STATE);
        }
    }

    goNext(event) {
        if (!this.isNextDisabled) {
            this.showScheduleCalender = false;
            this.counter = this.counter + 1;
            this.isNextDisabled = (this.counter >= 3 ? true : false);
            var currlabel = event.target.dataset.id;
            console.log('label->' + currlabel);
            this.buttonNextStyle = (this.counter >= 3 ? BUTTON_INACTIVE_STATE : BUTTON_ACTIVE_STATE);
            const nextOrPreviousWeekEvent = new CustomEvent("nextorpreviousweek", {
                detail: currlabel
            });
            this.dispatchEvent(nextOrPreviousWeekEvent);
            // let nextButton = this.template.querySelector('[data-id=\'' + currlabel + '\']');
            //  nextButton.style = (this.counter >= 3 ? BUTTON_INACTIVE_STATE : BUTTON_ACTIVE_STATE);
        }
    }

    showForm(event) {
        if (event.detail != undefined) {
            console.log('targetId->' + event.detail);
            let targetId = event.detail;
            let selectedDateTime = { "dateLabel": this.selectedDate.dateLabel, "dateValue": this.selectedDate.dateValue, "timeSlotLabel": targetId.label, "timeSlotValue": targetId.value + ':00' };
            console.log('timeslotevn-->' + this.selectedDate);
            const selectedTimeslotEvent = new CustomEvent("selectedtimeslot", {
                detail: selectedDateTime
            });
            this.dispatchEvent(selectedTimeslotEvent);
        }
    }
}