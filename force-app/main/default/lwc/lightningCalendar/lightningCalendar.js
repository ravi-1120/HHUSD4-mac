import { LightningElement, track, api } from 'lwc';
import callogo from '@salesforce/resourceUrl/cal';
import UserPreferencesHideLightningMigrationModal from '@salesforce/schema/User.UserPreferencesHideLightningMigrationModal';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import lightningcss from '@salesforce/resourceUrl/lightningCalendarCSS';

const monthNames = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
];
const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

export default class LightningCalendar extends LightningElement {
    isShow;
    sourceTextBox;
    displayMonth;
    currentMonth = 0;
    currentYear;
    disablePrevCalender = false;
    calendarRows = [];
    calicon = callogo;
    calDay;
    calMonth;
    calYear;
    apiCSS;
    calendarCss;
    styleCSS = '';
    pageName;

    connectedCallback(){
        Promise.all([
            loadStyle(this, lightningcss),
        ]).then(() => {
            console.log('Files loaded');
        })
            .catch(error => {
                console.log(error.body.message);
            });
    }

    displayCurrentMonth() {
        const _today = new Date(this.calYear, this.calMonth, this.calDay, 10, 33, 30, 0);
        this.currentMonth = this.calMonth;
        this.currentYear = this.calYear;
        this.displayMonth = monthNames[_today.getMonth()] + ' ' + _today.getFullYear();
    }
    handleNextMonth(event) {
        if (this.currentMonth == 11) {
            this.currentMonth = 0;
            this.currentYear = this.currentYear + 1;
        } else {
            this.currentMonth = this.currentMonth + 1;
        }
        this.displayMonth = monthNames[this.currentMonth] + ' ' + this.currentYear;
        this.createCalendar(this.currentMonth, this.currentYear);
    }
    handlePreviousMonth(event) {
        if (this.currentMonth == 0) {
            this.currentMonth = 11;
            this.currentYear = this.currentYear - 1;
        } else {
            this.currentMonth = this.currentMonth - 1;
        }

        this.displayMonth = monthNames[this.currentMonth] + ' ' + this.currentYear;
        this.createCalendar(this.currentMonth, this.currentYear);
    }
    createCalendar(month, year) {
        this.calendarRows = [];
        this.disablePrevCalender = false;
        let today = new Date();
        let isPassedMonth =false;//used for passed input date as disbaled calendar
        let firstDay = (new Date(year, month)).getDay();
        let daysInMonth = 32 - new Date(year, month, 32).getDate();

        if(month < today.getMonth() && year<=today.getFullYear() ){//used for passed input date as disbaled calendar
            isPassedMonth = true;
        }

        let date = 1;

        for (let i = 0; i < 6; i++) {

            let calendars = [];
            for (let j = 0; j < 7; j++) {
                if (isPassedMonth ||( date === today.getDate() && year === today.getFullYear() && month === today.getMonth())) {//used for passed input date as disbaled calendar
                    this.disablePrevCalender = true;
                }

                if (i === 0 && j < firstDay) {
                    calendars.push({ id: i + j, isDisabled: true, isSelected: false, day: '', class: 'td-blank', clickDisabled: true });
                }
                else if (date > daysInMonth) {
                    break;
                }
                else {

                    if (date === this.calDay && year === this.calYear && month === this.calMonth) {
                        calendars.push({ id: i + j, isDisabled: false, isSelected: true, day: date, class: 'selected', clickDisabled: false });
                    } // color today's date
                    else {
                        if (isPassedMonth || (date < today.getDate() && year === today.getFullYear() && month === today.getMonth())) {//used for passed input date as disbaled calendar
                            calendars.push({ id: i + j, isDisabled: false, isSelected: false, day: date, class: 'td-disabled', clickDisabled: true });
                        } else {
                            calendars.push({ id: i + j, isDisabled: false, isSelected: false, day: date,class: 'td-enabled' });
                        }

                    }
                    date++;
                }


            }
            this.calendarRows.push({ id: 'Row' + i, rowCalendar: calendars })
        }
        console.log(' calendarRows ', this.calendarRows);

    }
    showCalendar(event) {
        this.sourceTextBox = event.currentTarget.dataset.id;
        this.isShow = this.isShow ? false : true;
    }
    setDate(event) {
        const selectedDate = event.target.outerText;
        const ID = this.sourceTextBox;
        let selectdtvar = months[this.currentMonth] + ' ' + selectedDate + ', ' + this.currentYear;
        this.isShow = false;
        this.handleDispatch(selectdtvar, ID);
    }

    handleDispatch(selectedDate, sourceControl) {
        this.dispatchEvent(new CustomEvent('selecteddate', {
            detail: { selectedDate: selectedDate, sourceControl: sourceControl }
        }));
    }

    @api
    passcalenderparameter(objparameter) {
        console.log({ objparameter });
        this.isShow = objparameter.isShow;
        this.sourceTextBox = objparameter.sourceTextBox;
        this.calDay = objparameter.calday;
        this.calMonth = objparameter.calmonth;
        this.calYear = objparameter.calyear;
        this.apiCSS = objparameter.apicss;
        this.pageName = objparameter.pagename;

        let page = objparameter.pagename;
        console.log({ page });
        if (page == 'schedule') {
            this.calendarCss = 'slds-datepicker slds-dropdown slds-dropdown_left';
        } else {
            this.calendarCss = 'slds-datepicker slds-dropdown slds-dropdown_left calendar' + this.apiCSS;
        }
        if (objparameter.isShow) {
            this.displayCurrentMonth();
            this.displayCalender();
        }

        let top = this.getTopMagnitude(this.apiCSS);
        console.log('Top ' + top);
        this.styleCSS = 'top:' + top + 'px';

        return false;
    }
    getTopMagnitude(index) {
        let top = 64;
        if (this.pageName == 'mhe') {
            top=70;
            if (index == 1) {
                top -= 24;
            } else if (index == 2) {
                top -= 20 * 2;
            }
        } else {
            if (index == 1) {
                top += 103;
            } else if (index == 2) {
                top += 103 * 2;
            }
        }
        return top;
    }

    displayCalender() {
        let currentMonth = this.calMonth;
        let currentYear = this.calYear;
        console.log('currentMonth ' + currentMonth);
        console.log('currentMonth ' + currentYear);
        this.createCalendar(currentMonth, currentYear);
    }
    @api doCloseCalendar(passParameterObj) {
        this.isShow = passParameterObj.isShow;
    }
}