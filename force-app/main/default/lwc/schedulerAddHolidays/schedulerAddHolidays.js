import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import saveHolidays from '@salesforce/apex/BusinessRulesController.saveHolidays';
import getHolidays from '@salesforce/apex/BusinessRulesController.getHolidays';
const HOLIDAY_DUPLICATE_MSG = 'This date is already taken please choose another date';
import { getRecord, RecordFieldDataType } from 'lightning/uiRecordApi';
import JSON_PAYLOAD_FIELD from '@salesforce/schema/Scheduler_Configuration__c.JSON_Payload__c';
import ID_FIELD from '@salesforce/schema/Scheduler_Configuration__c.Id';
import { updateRecord } from 'lightning/uiRecordApi';
const FIELDS = [JSON_PAYLOAD_FIELD, ID_FIELD];


export default class SchedulerAddHolidays extends LightningElement {
    @api holidaysList;
    @api groupId;
    @track showModal = false;
    showAddHolidaySection = false;
    holidayName = '';
    holidayDate = '';
    isloading = false;
    refreshTable;
    @track isSaveDisabled = true;
    @api recordId;
    schedulerPayload;
    currrecordDetails;

    @wire(getHolidays, { groupId: '$groupId' })
    wiredData(result) {
        this.refreshTable = result;
        console.log('group Id => ' + this.groupId);
        if (result.data) {
            this.holidaysList = result.data;
            console.log('Refresh Holidays List ', JSON.parse(JSON.stringify(result.data)));
        } else if (result.error) {
            console.log('Errro List ', JSON.parse(JSON.stringify(result.error)));
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(response) {
        this.currrecordDetails = response;
        console.log("recordId holiday component " + this.recordId);
        if(response){
            if (response.data) {
                this.schedulerPayload = JSON.parse(response.data.fields.JSON_Payload__c.value);
                console.log('payload-->' + JSON.stringify(this.schedulerPayload));
            }
            else if (response.error) {
                console.log("Error Data-->" + JSON.stringify(response.error));
            }
        }
    }

    connectedCallback() {
        this.openModal();
        //this.refreshHolidaysList();
        refreshApex(this.currrecordDetails);
    }
    
    getHolidayName(event) {
        this.holidayName = event.target.value;
        this.isSaveDisabled = (this.holidayName != '' && this.holidayDate != '') ? false : true;
    }
    
    getHolidayDate(event) {
        var today = new Date();
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
        var yyyy = today.getFullYear();today = yyyy+ '-' + mm + '-' + dd;
        let dateCmp = this.template.querySelector(".dateCmp");
        console.log('event.target.value'+event.target.value);
        console.log('Today Value'+today);
         if (event.target.value<today) {
            dateCmp.setCustomValidity("Please enter date today or > today");
            this.isSaveDisabled =true;
        } else {
            dateCmp.setCustomValidity("");
            this.holidayDate = event.target.value;
            this.isSaveDisabled = (this.holidayName != '' && this.holidayDate != '') ? false : true;
            
        }
        dateCmp.reportValidity();
        
    }
  
    saveHoliday(event) {
        console.log('HolidayName ', JSON.parse(JSON.stringify(this.holidayName)));
        console.log('HolidayDate ', JSON.parse(JSON.stringify(this.holidayDate)));
        console.log('Group ID ', JSON.parse(JSON.stringify(this.groupId)));
        const allValid = [
            ...this.template.querySelectorAll("lightning-input")
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
            this.isloading = true;
            var isDuplidateHoliday = this.holidaysList.filter(i => this.holidayDate.indexOf(i.Holiday__r.Date__c) >= 0).length > 0 ? true : false;
            console.log('isDuplidateHoliday-->' + isDuplidateHoliday);
            if (isDuplidateHoliday) {
                this.isloading = false;
                this.showToast("ERROR", HOLIDAY_DUPLICATE_MSG, "error");
            }
            else {
                this.updateSchedulerPayload(this.holidayDate, this.groupId);

            }
        }
    }

    refreshHolidaysList() {
        return refreshApex(this.refreshTable);
    }

    openModal() {
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        const closeChangeEvent = new CustomEvent('close', {
            detail: { checkModal: false }
        });
        this.dispatchEvent(closeChangeEvent);
    }

    addHoliday() {
        this.showAddHolidaySection = true;
    }

    showToast(title, message, type) {
        console.log('title : ', title);
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: type,
        });
        this.dispatchEvent(evt);
    }

    updateSchedulerPayload(holiday, groupId) {
        var tempPayload = this.schedulerPayload;
        if (tempPayload.holidaysByGroup != undefined && tempPayload.holidaysByGroup.length > 0) {
            console.log('holidaysByGroup-->' + JSON.stringify(tempPayload.holidaysByGroup));
            tempPayload.holidaysByGroup.forEach(ele => {
                if (ele.groupId == groupId) {
                    console.log('groupName-->' + ele.groupName);
                    if (ele.holidays.indexOf(holiday) == -1) {
                        ele.holidays.push(holiday);
                        console.log('holiday-->' + holiday);
                    }
                }
            });
            console.log('tempPayload-->' + JSON.stringify(tempPayload));
            this.schedulerPayload = tempPayload;
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.recordId;
            fields[JSON_PAYLOAD_FIELD.fieldApiName] = JSON.stringify(tempPayload);
            const recordInput = { fields };
            updateRecord(recordInput)
                .then((updateResult) => {
                    console.log('record updated-->' + updateResult);
                    saveHolidays({ holidayName: this.holidayName, holidayDate: this.holidayDate, groupId: this.groupId })
                        .then((result) => {
                            console.log('result', result);
                            if (result === 'SUCCESS') {
                                this.showToast("SUCCESS", 'Holiday Created Successfully', "success");
                                this.refreshHolidaysList();
                                this.holidayDate = '';
                                this.holidayName = '';
                                this.isSaveDisabled = true;
                                this.isloading = false;
                                //this.closeModal();
                            }
                            else if (result === 'ERROR') {
                                this.isloading = false;
                                this.showToast("ERROR", 'Error in Holiday Creation', "error");
                            }
                        })
                        .catch((error) => {
                            this.isloading = false;
                            console.log('Error=>' + JSON.stringify(error.message));
                        });
                })
                .catch(error => {
                    this.isloading = false;
                    console.log('error-->' + JSON.stringify(error));
                });
        }
    }
}