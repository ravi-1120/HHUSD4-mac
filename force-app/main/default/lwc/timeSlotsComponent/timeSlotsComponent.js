import { LightningElement, api, track } from 'lwc';
import getScheduledSlots from '@salesforce/apex/AppointmentSchedulerController.getScheduledSlots';
import generateTimeSlots from '@salesforce/apex/TimeZoneUtil.generateTimeSlots';

const SELECTED_TIMESLOT_STYLE = 'color: white;background-color: #00857c;border-color: #00857c; width: 100%; font-size: 13.5px; font-weight: 400';
const TIMESLOT_STYLE = 'color: #00857c;background-color: white;border-color: #00857c; width: 100%; font-size: 13.5px; font-weight: 400';
const ACTIVE_TAB_CLASS = "slds-tabs_default__item slds-is-active";
const INACTIVE_TAB_CLASS = "slds-tabs_default__item";
export default class TimeSlotsComponent extends LightningElement {
    @api startTime;
    @api endTime;
    /* @track timeslots = ['8:00', '8:15', '8:30', '8:45', '9:00', '9:15', '9:30', '9:45', '10:00', '10:15', '10:30', '10:45', '11:00', '11:15', '11:30', '11:45', '12:00', '12:15', '12:30', '12:45', '1:00',
         '1:15', '1:30', '1:45', '2:00', '2:15', '2:30', '2:45', '3:00', '3:15', '3:30', '3:45', '4:00', '4:15', '4:30', '4:45', '5:00', '5:15', '5:30', '5:45', '6:00', '6:15', '6:30', '6:45', '7:00', '7:15', '7:30', '7:45', '08:00'];
    */
    @track timeslots = [];
    @track morningSlots = [];
    @track afternoonSlots = [];
    @track evengSlots = [];
    @api scheduleDate;
    @track trackSchedulingGroup;
    @api
    get schedulingGroup() {
        return this.trackSchedulingGroup;

    }
    set schedulingGroup(value) {
        this.trackSchedulingGroup = value;
        this.configureAvailableSlots();
        // this.handleTimeSlotsByTimeZone();
    }
    @track showSpinner = false;
    @track showMorningSlots = false;
    @track showAfterNoonSlots = false;
    @track showEveningSlots = false;

    isMorningTabActive = true;
    isAfternoonTabActive = false;
    isEveningTabActive = false;



    handleSelectedSlot(event) {
        let selectedTimeSlot;
        Array.from(this.template.querySelectorAll(".timeSlotButton")).forEach(row => {
            row.style = TIMESLOT_STYLE;
        });
        const timeSlotButton = this.template.querySelector('[data-value=\'' + event.target.dataset.value + '\']');
        timeSlotButton.style = SELECTED_TIMESLOT_STYLE;
        this.timeslots.forEach(slotEle => {
            if (event.target.dataset.value == slotEle.value) {
                selectedTimeSlot = slotEle;
            }
        });
        this.dispatchEvent(new CustomEvent('selectedtimeslot', {
            detail: selectedTimeSlot
        }));
    }

    createSlots(slotConfig) {
        // Getting values from slotConfig 
        const { configSlotHours, configSlotMinutes, configSlotPreparation, timeArr } = slotConfig;

        let defaultDate = new Date().toISOString().substring(0, 10);
        let slotsArray = []
        let _timeArrStartTime;
        let _timeArrEndTime;
        let _tempSlotStartTime;
        let _endSlot;
        let _startSlot;

        // Loop over timeArr
        for (var i = 0; i < timeArr.length; i++) {
            // Creating time stamp using time from timeArr and default date
            //_timeArrStartTime = (new Date(defaultDate + " " + timeArr[i].startTime)).getTime();
            var basicStartTimeConcat = (defaultDate + " " + timeArr[i].startTime);
            var basicStartTimeFormatted = basicStartTimeConcat.replace(/\s+/g, 'T') + 'Z';
            var start_time = basicStartTimeFormatted.split(/[^0-9]/);
            var start_time_final = new Date(start_time[0], start_time[1] - 1, start_time[2], start_time[3], start_time[4]);
            _timeArrStartTime = start_time_final.getTime();
            //_timeArrEndTime = (new Date(defaultDate + " " + timeArr[i].endTime)).getTime();
            var basicEndTimeConcat = (defaultDate + " " + timeArr[i].endTime);
            var basicEndTimeFormatted = basicEndTimeConcat.replace(/\s+/g, 'T') + 'Z';
            var end_time = basicEndTimeFormatted.split(/[^0-9]/);
            var end_time_final = new Date(end_time[0], end_time[1] - 1, end_time[2], end_time[3], end_time[4]);
            _timeArrEndTime = end_time_final.getTime();

            _tempSlotStartTime = _timeArrStartTime;

            // Loop around till _tempSlotStartTime is less end time from timeArr
            while ((new Date(_tempSlotStartTime)).getTime() < (new Date(_timeArrEndTime)).getTime()) {

                _endSlot = new Date(_tempSlotStartTime);
                _startSlot = new Date(_tempSlotStartTime);

                //Adding minutes and hours from config to create slot and overiding the value of _tempSlotStartTime
                _tempSlotStartTime = _endSlot.setHours(parseInt(_endSlot.getHours()) + parseInt(configSlotHours));
                _tempSlotStartTime = _endSlot.setMinutes(parseInt(_endSlot.getMinutes()) + parseInt(configSlotMinutes));

                // Check _tempSlotStartTime is less than end time after adding minutes and hours, if true push into slotsArr
                if (((new Date(_tempSlotStartTime)).getTime() <= (new Date(_timeArrEndTime)).getTime())) {

                    // DateTime object is converted to time with the help of javascript functions
                    // If you want 24 hour format you can pass hour12 false
                    slotsArray.push({
                        "label": new Date(_startSlot).toLocaleTimeString('en-US', {
                            hour: 'numeric',
                            minute: 'numeric',
                            hour12: true
                        }),
                        "value": new Date(_startSlot).toLocaleTimeString('en-US', {
                            hour: 'numeric',
                            minute: 'numeric',
                            hour12: false
                        })
                    });
                }

                //preparation time is added in last to maintain the break period
                // _tempSlotStartTime = _endSlot.setMinutes(_endSlot.getMinutes() + parseInt(configSlotPreparation));
            }
        }
        return slotsArray;
    }



    configureTimeSlots(startTime, endTime) {

        var slotConfig = {
            "configSlotHours": "00",
            "configSlotMinutes": "15",
            "configSlotPreparation": "00",
            "timeArr": [
                { "startTime": startTime, "endTime": endTime }
                // {"startTime":"16:00", "endTime":"20:00"}
            ]
        }
        return this.createSlots(slotConfig);

    }


    convertTimeto24hrs(time12h) {
        const [time, modifier] = time12h.split(' ');

        let [hours, minutes] = time.split(':');

        if (hours === '12') {
            hours = '00';
        }

        if (modifier === 'PM') {
            hours = parseInt(hours, 10) + 12;
        }
        return `${hours}:${minutes}`;

    }


    configureAvailableSlots() {
        this.showSpinner = true;
        this.timeslots = [];
        this.morningSlots = [];
        this.afternoonSlots = [];
        this.evengSlots = [];
        if (this.startTime != undefined) {
            this.startTime = this.convertTimeto24hrs(this.startTime);
        }
        if (this.endTime != undefined) {
            this.endTime = this.convertTimeto24hrs(this.endTime);
        }
        this.timeslots = this.configureTimeSlots(this.startTime, this.endTime);
        var estTime = this.convertTZ(new Date(), "America/New_York");
        var currDate = estTime.getFullYear() + '-' + String(estTime.getMonth() + 1).padStart(2, '0') + '-' + String(estTime.getDate()).padStart(2, '0');
        //console.log('currdate-->' + this.currDate);
        //console.log('schduleDate-->' + this.scheduleDate);
        var isCurrDate = (currDate == this.scheduleDate) ? true : false;
        
        var currTime = String(estTime.getHours()).padStart(2, '0') + ':' + String(estTime.getMinutes()).padStart(2, '0');
        getScheduledSlots({ schedulingGroupName: this.schedulingGroup, scheduleDate: this.scheduleDate })
            .then(scheduledSlots => {
                if (scheduledSlots != undefined) {
                    var tempScheduledSlots = [];
                    scheduledSlots.forEach(schSlots => {
                        /*JJ_25-01-2024_TimeZoneGMTConvert*/
                        let slot = this.convertTZ(schSlots.StartDateTime,"America/New_York");
                        schSlots.StartDateTime = String(slot.getHours()).padStart(2, '0') + ':' + String(slot.getMinutes()).padStart(2, '0');
                        console.log('slot-->'+schSlots.StartDateTime);
                        // schSlots.StartDateTime = schSlots.StartDateTime.substring(schSlots.StartDateTime.indexOf('T') + 1);
                        // schSlots.StartDateTime = (schSlots.StartDateTime.split(':').slice(0, 2)).join(':');
                        /*JJ_25-01-2024_TimeZoneGMTConvert*/
                        tempScheduledSlots.push(schSlots.StartDateTime);
                    });
                    //this.timeslots = this.timeslots.filter((el) => !tempScheduledSlots.includes(el.value));
                }

                this.timeslots.forEach(ele => {
                    ele['timeSlotAvialable'] = true;
                    if (tempScheduledSlots.length > 0) {
                        if (tempScheduledSlots.includes(ele.value)) {
                            ele['timeSlotAvialable'] = false;
                        }
                    }
                    if (isCurrDate) {
                        if (ele.value < currTime) {
                            ele['timeSlotAvialable'] = false;
                        }
                    }
                    //if(ele.value < currTime){ele['timeSlotAvialable'] = false;}
                    (ele.value < '12:00') ? this.morningSlots.push(ele) : '';
                    (ele.value < '18:00' && ele.value >= '12:00') ? this.afternoonSlots.push(ele) : '';
                    (ele.value >= '18:00') ? this.evengSlots.push(ele) : '';
                });
                //console.log('morningSlots--->' + JSON.stringify(this.morningSlots));
                this.morningSlots.forEach(mrngSlots => {
                    if (mrngSlots.timeSlotAvialable) {
                        this.showMorningSlots = true;
                    }
                });
                this.afternoonSlots.forEach(anSlots => {
                    if (anSlots.timeSlotAvialable) {
                        this.showAfterNoonSlots = true;
                    }
                });
                this.evengSlots.forEach(eveSlots => {
                    if (eveSlots.timeSlotAvialable) {
                        this.showEveningSlots = true;
                    }
                });

                this.setDefaultTab();

                this.showSpinner = false;
            })
            .catch(error => {
                console.log('err->' + JSON.stringify(error));
                this.showSpinner = false;
            });
    }

    convertTZ(date, tzString) {
        return new Date((typeof date === "string" ? new Date(date) : date).toLocaleString("en-US", { timeZone: tzString }));
    }


    handleTimeSlotsByTimeZone() {
        this.showSpinner = true;
        var configDetails = {};
        configDetails.timeZone = this.timeZoneAbbreviated();
        configDetails.schedulingGroup = this.trackSchedulingGroup;
        configDetails.selectedDate = this.scheduleDate;
        if (this.startTime != undefined) {
            this.startTime = this.convertTimeto24hrs(this.startTime);
        }
        if (this.endTime != undefined) {
            this.endTime = this.convertTimeto24hrs(this.endTime);
        }
        var defaultDate = new Date().toISOString().substring(0, 10);
        var basicStartTimeConcat = (defaultDate + " " + this.startTime + ":00");
        var basicStartTimeFormatted = basicStartTimeConcat.replace(/\s+/g, 'T') + 'Z';
        var start_time = basicStartTimeFormatted.split(/[^0-9]/);
        var basicEndTimeConcat = (defaultDate + " " + this.endTime + ":00");
        var basicEndTimeFormatted = basicEndTimeConcat.replace(/\s+/g, 'T') + 'Z';
        var end_time = basicEndTimeFormatted.split(/[^0-9]/);
        configDetails.year = start_time[0];
        configDetails.month = start_time[1];
        configDetails.date = start_time[2];
        configDetails.startHours = start_time[3];
        configDetails.startMinutes = start_time[4];
        configDetails.startSeconds = start_time[5];
        configDetails.endHours = end_time[3];
        configDetails.endMinutes = end_time[4];
        configDetails.endSeconds = end_time[5];
        this.handleGetTimeslotsbyTimeZone(configDetails);

    }


    timeZoneAbbreviated() {
        const { 1: tz } = new Date().toString().match(/\((.+)\)/);

        if (tz.includes(" ")) {
            return tz
                .split(" ")
                .map(([first]) => first)
                .join("");
        }
        else {
            return tz;
        }
    };

    handleGetTimeslotsbyTimeZone(configDetails) {
        //console.log('configDetails-->' + JSON.stringify(configDetails));
        var defaultDate = new Date().toISOString().substring(0, 10);
        var isCurrDate = (defaultDate == this.scheduleDate) ? true : false;
        //console.log('isCurrDate-->' + isCurrDate);
        generateTimeSlots({ scheduleDetails: configDetails })
            .then(tzSlots => {
                if (tzSlots != undefined) {
                    //console.log('tzslots-->' + JSON.stringify(tzSlots));
                    // this.timeslots = JSON.parse(JSON.stringify(tzSlots));
                    // this.timeslots = this.removeDuplicates(tzSlots);
                    this.timeslots = tzSlots.filter((thing, index, self) =>
                        index === self.findIndex((t) => (
                            t.label === thing.label
                        )))
                    this.timeslots.forEach(ele => {
                        var tempdate = new Date(defaultDate + " " + ele.label);
                        if (tempdate.getHours() < 12) {
                            if (this.morningSlots.indexOf(ele) == -1) { this.morningSlots.push(ele); }
                        }
                        else if (tempdate.getHours() < 18 && tempdate.getHours() >= 12) {
                            if (this.afternoonSlots.indexOf(ele) == -1) { this.afternoonSlots.push(ele); }
                        }
                        else if (tempdate.getHours() >= 18) {
                            if (this.evengSlots.indexOf(ele) == -1) { this.evengSlots.push(ele); }
                        }

                        if (isCurrDate) {
                            if (tempdate.getTime() < new Date().getTime()) {
                                ele.timeSlotAvialable = false;
                            }
                        }

                    });
                    //console.log('morningSlots->' + JSON.stringify(this.morningSlots));
                    this.morningSlots.forEach(mrngSlots => {
                        if (mrngSlots.timeSlotAvialable) {
                            this.showMorningSlots = true;
                        }
                    });
                    this.afternoonSlots.forEach(anSlots => {
                        if (anSlots.timeSlotAvialable) {
                            this.showAfterNoonSlots = true;
                        }
                    });
                    this.evengSlots.forEach(eveSlots => {
                        if (eveSlots.timeSlotAvialable) {
                            this.showEveningSlots = true;
                        }
                    });

                }
                this.showSpinner = false;

            }).catch(error => {
                console.log('err->' + JSON.stringify(error));
                this.showSpinner = false;
            });
    }


    removeDuplicates(arr) {
        arr.filter((obj, pos, arr) => {
            return arr.map(mapObj =>
                mapObj.label).indexOf(obj.label) == pos;
        });
    }

    handleTab(event) {
        var currTab = event.target.dataset.value;

        Array.from(this.template.querySelectorAll(".slds-tabs_default__item")).forEach(row => {
            //console.log(row.title);
            if (row.title == currTab) {
                row.className = ACTIVE_TAB_CLASS;
            }
            else {
                row.className = INACTIVE_TAB_CLASS;
            }
        });


        switch (currTab) {
            case 'Morning':
                this.isMorningTabActive = true;
                this.isAfternoonTabActive = false;
                this.isEveningTabActive = false;
                break;
            case 'Afternoon':
                this.isMorningTabActive = false;
                this.isAfternoonTabActive = true;
                this.isEveningTabActive = false;
                break;
            case 'Evening':
                this.isMorningTabActive = false;
                this.isAfternoonTabActive = false;
                this.isEveningTabActive = true;
                break;
        }
    }

    setDefaultTab(){

        let period = (this.showMorningSlots) ? 'Morning' : (this.showAfterNoonSlots) ? 'Afternoon' : 'Evening';

        setTimeout(() => {
            Array.from(this.template.querySelectorAll(".slds-tabs_default__item")).forEach(row => {
            if (row.title == period) {
                row.className = ACTIVE_TAB_CLASS;
            }else{
                row.className = INACTIVE_TAB_CLASS;
            }
        });
        }, 200);

        switch (period) {
            case 'Morning':
                this.isMorningTabActive = true;
                this.isAfternoonTabActive = false;
                this.isEveningTabActive = false;
                break;
            case 'Afternoon':
                this.isMorningTabActive = false;
                this.isAfternoonTabActive = true;
                this.isEveningTabActive = false;
                break;
            case 'Evening':
                this.isMorningTabActive = false;
                this.isAfternoonTabActive = false;
                this.isEveningTabActive = true;
                break;
        }
    }

}