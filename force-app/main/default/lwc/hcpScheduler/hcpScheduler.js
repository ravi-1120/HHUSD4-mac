import getAppointmentDates from '@salesforce/apex/AppointmentSchedulerController.getAppointmentDates';
import saveAppointmentScheduleDetails from '@salesforce/apex/AppointmentSchedulerController.saveAppointmentScheduleDetails';
import getAgentAvilability from '@salesforce/apex/NiceInContactController.getAgentAvilability';
import appointmentTemplateLabel from '@salesforce/label/c.AMO_Appointment_Template_Label';
import communicationModeLabel from '@salesforce/label/c.AMO_Communication_Mode_Label';
import GAFiledsToTag from '@salesforce/label/c.AMO_GA_Fields_To_Tag';
import header from '@salesforce/label/c.AMO_Header';
import headerMessage from '@salesforce/label/c.AMO_Header_Message';
import headerMessageUS from '@salesforce/label/c.AMO_Header_Message_US';
import headerTherapeutic from '@salesforce/label/c.AMO_Header_Therapeutic';
import productEnquiryLabel from '@salesforce/label/c.AMO_Product_Enquiry_Label';
import professionalDesignationLabel from '@salesforce/label/c.AMO_Professional_Designation';
import tumorLabel from '@salesforce/label/c.AMO_Tumor_Label';
import AEMessageHeader from '@salesforce/label/c.HCP_Scheduler_Footer_Message_Header';
import merckLogo from '@salesforce/label/c.Merck_Logo';
import setHours from '@salesforce/label/c.setHours';
import { LightningElement, track, wire } from 'lwc';
// import medicalInquiryButtonLabel from '@salesforce/label/c.Medical_Inquiry_Button_Label';
import getHCPData from '@salesforce/apex/AppointmentSchedulerController.getHCPData';
import scheduleCallbackLabel from '@salesforce/label/c.AMO_Schedule_Callback_Label';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';


const SCHEDULER_CSS = ' ';
export default class HcpScheduler extends NavigationMixin(LightningElement) {
    label = {
        merckLogo,
        headerTherapeutic,
        header,
        headerMessage,
        professionalDesignationLabel,
        appointmentTemplateLabel,
        tumorLabel,
        communicationModeLabel,
        AEMessageHeader,
        headerMessageUS,
        setHours,
        GAFiledsToTag,
        productEnquiryLabel,
        scheduleCallbackLabel
        // medicalInquiryButtonLabel
    };

    schedulerCSS = SCHEDULER_CSS;
    // @track isDisabled = false;
    @track disableBtn = false;
    ischecked = true;
    @track radioButtonDisabled = false;
    @track dt;
    @track appointmentTemplates;

    @track showCommunicationModes;
    @track showScheduleCallbackCmp;
    @track showUserForm;
    @track showMessage = false;
    @track selectedDateTime;
    @track isSchedulable = false;
    @track selectedTemplate;
    @track showSchedular = false;

    @track dtList = [];
    @track scheduleDetails = {};
    @track communicationoptions;
    @track showTumor = false;
    @track schdulerDataStructure;
    @track designationOptions;

    @track holidaysList;
    @track agentAvailability;
    @track showSpinner = false;
    @track currSchedulingGroup;
    @track calloutResponse;
    isRendered = false;
    gaFileds = {}; //= JSON.parse(this.label.GAFiledsToTag);
    scheduledEvent;
    showFeedback = false;
    @track products;
    @track showBlackBoxMsg = false;
    @track blackBoxMsg;
    @track selectedProduct;
    @track businessHours;
    @track callMeNowMessage;
    @track callMeNowClosed;
    //@track callMeNowHoliday; //POC - Disable call me now Message
    @track isTodayHoliday;
    @track meicalInfoTrack;
    @track currLocation = '';
    @track targetId;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('currentPageReference1-->' + JSON.stringify(currentPageReference));
        if (currentPageReference.state != undefined) {
            console.log('currentPageReference-->' + JSON.stringify(currentPageReference.state));
            this.currLocation = currentPageReference.state.schedulerId;
        }
    }


    /*@wire(getHCPData, { href: this.currLocation, currDate: new Date() })
    getHCPData({ error, data }) {
        console.log('getHCPData-->' + this.currLocation);
        if (data) {
            console.log('getHCPData');
            this.configureScheduler(data);
        } else if (error) {
            console.log('err->' + JSON.stringify(error));
        }
    } */

    connectedCallback() {
        getHCPData({ href: this.currLocation, currDate: new Date() }).then(result => {
            this.configureScheduler(result);
        }).catch(error => {
            console.log('err-->' + JSON.stringify(error));
        });
    }


    configureScheduler(hcpDSResultwire) {
        this.dt = new Date();
        let hcpDSResult = JSON.parse(JSON.stringify(hcpDSResultwire));
        var estTime = this.convertTZ(new Date(), "America/New_York");
        console.log(estTime);
        var currESTTime = new Date(estTime);
        console.log('getHCPDataStructurebyId-->' + JSON.stringify(hcpDSResult));
        this.schedulerCSS = (hcpDSResult.uiCss.bgColor != undefined) ? this.schedulerCSS + 'background-color:' + hcpDSResult.uiCss.bgColor : this.schedulerCSS;
        // this.appointmentTemplates = hcpDSResult.templates.sort((a, b) => parseInt(a.order) - parseInt(b.order));

        this.designationOptions = hcpDSResult.professionalDesignation.sort((a, b) => parseInt(a.order) - parseInt(b.order));
        this.products = (hcpDSResult.products != undefined) ? hcpDSResult.products.sort((a, b) => parseInt(a.order) - parseInt(b.order)) : '';
        this.dtList = hcpDSResult.scheduleDates;
        this.communicationoptions = hcpDSResult.communicationModes;
        this.schdulerDataStructure = hcpDSResult;
        this.scheduleDetails.schedulerOwner = hcpDSResult.schedulerOwner;
        this.scheduleDetails.schedulerId = hcpDSResult.id;
        this.showSchedular = true;
        var tempGAFields = JSON.parse(GAFiledsToTag);
        this.gaFileds = JSON.parse(JSON.stringify(tempGAFields));
    }

    /* // commeting as feedback is out of scope for R2
    configureFeedbackForm() {
        if (window.location.href.indexOf('schedulerId=') != -1) {
            var tempSchedulerId = window.location.href.split('schedulerId=')[1];
            getHCPDataStructurebyId({ schedulerId: tempSchedulerId, currDate: this.dt })
                .then(hcpDSResult => {
                    if (hcpDSResult != undefined) {
                        this.schdulerDataStructure = hcpDSResult;
                        this.showFeedback = true;
                        this.showSpinner = false;
                        this.showCommunicationModes = false;
                        this.showSchedular = false;
                        this.showMessage = false;
                        this.scheduledEvent = window.location.href.split('eventId=')[1];
                        this.scheduledEvent = this.scheduledEvent.substr(0, this.scheduledEvent.indexOf('&'));
                    }

                })
                .catch(error => {
                    console.log('err->' + JSON.stringify(error));
                });
        }
    }
    */



    showForm(event) {
        let targetId = parseInt(event.target.dataset.targetId);
        this.showUserForm = true;
    }

    handleSelectedTimeslot(event) {
        if (event.detail != undefined) {
            console.log('handleSelectedTimeslot->' + JSON.stringify(event.detail));
            this.selectedDateTime = event.detail;
            this.scheduleDetails = Object.assign(this.scheduleDetails, event.detail);
            this.showUserForm = true;
            var tempDateTime = event.detail.dateLabel + ', ' + event.detail.timeSlotLabel
            this.handleDataLayerEvent('selected time', tempDateTime);
            this.gaFileds['selected time'] = tempDateTime;
        }
    }

    handleNextorPreviousWeek(event) {
        if (event.detail != undefined) {
            this.dtList = [];
            (event.detail == 'Previous Week') ? this.dt.setDate(this.dt.getDate() - 7) : this.dt.setDate(this.dt.getDate() + 7);
            getAppointmentDates({ currentDate: this.dt }).then(result => {
                this.dtList = result;
            });
        }
    }

    handleUserFormDetails(event) {
        if (event.detail != undefined) {
            console.log('user form details-->' + JSON.stringify(event.detail));
            this.scheduleDetails = Object.assign(this.scheduleDetails, event.detail);
            this.updateSchedularDetails();
        }
    }


    handleTemplatesChange(templateValue) {
        this.scheduleDetails.templateId = templateValue;
        this.handleScheduleCallBackandGroup(templateValue);
    }

    handleCommunicationChange(event) {

        if (event.target !== undefined) {
            this.scheduleDetails.communicationMode = event.target.dataset.value;
            this.handleDataLayerEvent(communicationModeLabel, event.target.dataset.value);
            if (event.target.dataset.value === 'Schedule a callback') {
                this.showScheduleCallbackCmp = true;
                this.scheduleDetails.isCallMeNow = false;
                this.showUserForm = false;
            }
            else if (event.target.dataset.value === 'Call me now') {
                if (this.scheduleDetails.isAgentAvialable !== undefined && this.scheduleDetails.isAgentAvialable === true) {
                    this.showScheduleCallbackCmp = false;
                    this.showUserForm = true;
                    this.scheduleDetails.isCallMeNow = true;
                }
            }
            this.gaFileds[communicationModeLabel] = event.target.dataset.value;

            if (event.target.dataset.readOnly === "true") {
                console.log('Radio button is disabled.');
            }
        }

        
    }

    updateSchedularDetails() {
        this.showSpinner = true;
        if (this.scheduleDetails.isCallMeNow === false) {
            var estDateTime = this.scheduleDetails.dateValue + 'T' + this.scheduleDetails.timeSlotValue + 'Z';
            console.log(estDateTime);
            var utcDt = new Date(estDateTime);//GMT Date (9AM)
            //var localDate = new Date(new Date(utcDt).setHours(utcDt.getHours() + 4));//to consider est dates from UI 1PM
            var localDate = new Date(new Date(utcDt).setHours(utcDt.getHours() + parseInt(this.label.setHours)));//to consider est dates from UI 1PM
            console.log('-------' + localDate.getHours() + '-------' + localDate.getMinutes());
            this.scheduleDetails.localDateValue = localDate.toString();
            this.scheduleDetails.localHour = localDate.getHours();
            this.scheduleDetails.localMinute = localDate.getMinutes();
        }
        else {
            var estTime = this.convertTZ(new Date(), "America/New_York");
            console.log(estTime);
            var currESTDate = estTime.getFullYear() + '-' + String(estTime.getMonth() + 1).padStart(2, '0') + '-' + String(estTime.getDate()).padStart(2, '0');
            this.scheduleDetails.currESTDate = currESTDate;
            var currESTTime = String(estTime.getHours()).padStart(2, '0') + ':' + String(estTime.getMinutes()).padStart(2, '0') + ':' + '00';
            this.scheduleDetails.currESTTime = currESTTime;
        }
        console.log('schedularDetails-->' + JSON.stringify(this.scheduleDetails));
        saveAppointmentScheduleDetails({ scheduleDetails: this.scheduleDetails }).then(result => {
            console.log('saveAppointmentScheduleDetails-->' + JSON.stringify(result));
            this.scheduledEvent = result;
            this.agentAvailability = (result.agentAvilability != undefined) ? result.agentAvilability : '';
            this.calloutResponse = (result.calloutResponse != undefined) ? result.calloutResponse : '';
            this.showSpinner = false;
            this.showCommunicationModes = false;
            this.showSchedular = false;
            this.showMessage = true;
            var evtAction = this.gaFileds;
            evtAction = JSON.stringify(evtAction);
            this.handleDataLayerEvent('submit button sucessfull', evtAction);
        })
            .catch(error => {
                console.log('er->' + JSON.stringify(error));
                this.showSpinner = false;
            });
    }

    handleDesignationChange(profDesignatioValue) {
        if (profDesignatioValue !== undefined) {
            this.scheduleDetails.professionalDesignation = profDesignatioValue;
            if (this.scheduleDetails.templateId !== undefined) {
                this.handleScheduleCallBackandGroup(this.scheduleDetails.templateId);
            }
        }
    }

    handleScheduleCallBackandGroup(selectedTemplateId) {
        if (this.scheduleDetails.professionalDesignation !== undefined && this.scheduleDetails.productEnquiry != undefined) {
            this.appointmentTemplates.forEach(ele => {
                if (ele.value === selectedTemplateId) {
                    this.selectedTemplate = ele;
                    this.scheduleDetails.templateId = ele.value;
                    this.scheduleDetails.templateLabel = ele.label;
                    this.showTumor = (ele.conveyTumor && this.scheduleDetails.productEnquiry != 'WELIREG™ (belzutifan)' && this.scheduleDetails.productEnquiry != 'VERQUVO® (vericiguat)') ? true : false;
                    console.log('showTumor-->' + this.showTumor + ' ele.conveyTumr-->' + ele.conveyTumor);
                    if (!this.showTumor) { this.scheduleDetails.tumorIndication = ''; }
                    if (ele.isSchedulable === true) {
                        this.showCommunicationModes = true;
                        this.isSchedulable = true;
                        this.showMessage = false;
                    }
                    else {
                        this.showCommunicationModes = false;
                        this.scheduleDetails.isCallMeNow = false
                        this.showMessage = true;
                        this.isSchedulable = false;
                        this.showSchedular = false;
                        this.handleDataLayerEvent('Product Access Inquiries', 'Page Visit');
                    }
                }
            });
            console.log('templatelabel->' + this.scheduleDetails.templateLabel + '-->' + this.scheduleDetails.professionalDesignation +
                ' product enquiry->' + this.scheduleDetails.productEnquiry);
            if (this.schdulerDataStructure.assignmentGroups != undefined && this.isSchedulable == true) {
                this.schdulerDataStructure.assignmentGroups.forEach(schedulerDS => {
                    schedulerDS.routingGroup.forEach(element => {
                        if (element.appointmentTemplate === this.scheduleDetails.templateLabel
                            && element.professionalDesignation.indexOf(this.scheduleDetails.professionalDesignation) !== -1
                            && element.product.indexOf(this.scheduleDetails.productEnquiry) !== -1) {
                            this.scheduleDetails.schedulingGroup = schedulerDS.groupName;
                            this.scheduleDetails.schedulingGroupId = schedulerDS.groupId;
                        }
                    });
                });
                console.log('scheduling group-->' + this.scheduleDetails.schedulingGroup);
                if (this.schdulerDataStructure.holidaysByGroup != undefined && this.isSchedulable == true) {
                    this.schdulerDataStructure.holidaysByGroup.forEach(hDayList => {
                        if (hDayList.groupId == this.scheduleDetails.schedulingGroupId) {
                            this.holidaysList = hDayList.holidays;
                        }
                    });
                }
                if (this.schdulerDataStructure.businessHours != undefined && this.isSchedulable == true) {
                    this.schdulerDataStructure.businessHours.forEach(bHoursList => {
                        if (bHoursList.groupId == this.scheduleDetails.schedulingGroupId) {
                            this.businessHours = bHoursList.operatingHours;
                            this.callMeNowMessage = bHoursList.operatingHoursMessage;
                            this.callMeNowClosed = bHoursList.OutsideOperatingHoursMessage;
                            //this.callMeNowHoliday = bHoursList.holidayMessage;//POC - Disable call me now Message
                        }
                    });
                }
                if (this.currSchedulingGroup != this.scheduleDetails.schedulingGroup) {
                    this.showUserForm = false; //Fix - Hiding the form when group changes 23R2.0
                    this.showSpinner = true;
                    var tempDateList = this.dtList;
                    this.dtList = [];
                    let appointmentDetails = { 'schedulingGroup': this.scheduleDetails.schedulingGroup, 'communicationMode': 'Call Me Now' };
                    //var isAgentAvialable;
                    var estTime = this.convertTZ(new Date(), "America/New_York");
                    console.log(estTime);
                    var currESTTime = new Date(estTime);
                    
                    //for disabling call me now during holidays
                    this.isTodayHoliday = this.holidaysList?.includes(currESTTime.toLocaleDateString('en-CA')) || false;
                    console.log('If today is holiday? Disable CallmeNow: '+this.isTodayHoliday);
                    console.log('Holiday List: '+this.holidaysList);

                    let dayOfWeek = currESTTime.toLocaleDateString('en-US', { weekday: 'long' });
                    var weekEnd = (dayOfWeek == 'Sunday' || dayOfWeek == 'Saturday') ? true : false;
                    var startTime;
                    var endTime;
                    if (this.businessHours != undefined) {
                        this.businessHours.forEach(bh => {
                            if (bh.weekName == dayOfWeek) {
                                startTime = parseInt(bh.startTime.substr(0, bh.startTime.indexOf(':')));
                                endTime = parseInt(bh.endTime.substr(0, bh.endTime.indexOf(':')));
                            }
                        });
                        endTime = parseInt(endTime) + 12;
                    }
                    if (currESTTime.getHours() >= startTime && currESTTime.getHours() < endTime && weekEnd != true && !this.isTodayHoliday) {
                        console.log('log-------->');
                        console.log(`Condition will pass: ${(currESTTime.getHours() >= startTime && currESTTime.getHours() < endTime && weekEnd != true && !this.isTodayHoliday)}`);
                        getAgentAvilability({ scheduleDetails: appointmentDetails })
                            .then(agentAvailability => {
                                console.log('agent---->');
                                console.log('agentAvailability res->' + JSON.stringify(agentAvailability));
                                if (agentAvailability != undefined) {
                                    console.log('agentAvailability res->' + JSON.stringify(agentAvailability));
                                    agentAvailability.skillActivity.forEach(ele => {
                                        console.log('ele-------->'+JSON.stringify(ele));
                                        if (ele.agentsLoggedIn > 0) {
                                            this.scheduleDetails.isAgentAvialable = true;
                                        }
                                        else {
                                            this.scheduleDetails.isAgentAvialable = false;
                                        }
                                    });
                                    console.log('isAgentAvialable-->' + this.scheduleDetails.isAgentAvialable);
                                    this.configureImmediateCallback(this.scheduleDetails.isAgentAvialable);
                                    this.showSpinner = false;
                                    this.dtList = tempDateList;
                                }
                                else {
                                    this.showSpinner = false;
                                    this.dtList = tempDateList;
                                    this.scheduleDetails.isAgentAvialable = false;
                                    this.configureImmediateCallback(this.scheduleDetails.isAgentAvialable);
                                }
                            })
                            .catch(error => {
                                console.log('err->' + JSON.stringify(error));
                                this.dtList = tempDateList;
                                this.showSpinner = false;
                            });
                    } else {
                        this.showSpinner = false;
                        this.dtList = tempDateList;
                        this.scheduleDetails.isAgentAvialable = false;
                        this.configureImmediateCallback(this.scheduleDetails.isAgentAvialable);
                    }
                    this.currSchedulingGroup = this.scheduleDetails.schedulingGroup;
                }
            }
        }
    }

    handleTumorChange(event) {
        let currentLabel = event.target.dataset.value;
        this.scheduleDetails[currentLabel] = event['currentTarget'].value;
    }

    handleTumorClick() {
        this.handleDataLayerEvent(tumorLabel, 'click');
        this.gaFileds[tumorLabel] = 'click';
    }

    handleBack(event) {
        this.showSchedular = true;
        this.showMessage = false;
        this.showCommunicationModes = false;
        this.isSchedulable = false;
        this.scheduleDetails = {};
        this.showScheduleCallbackCmp = false;
        this.showUserForm = false;
        this.blackBoxMsg = '';
        this.appointmentTemplates = '';
    }

    convertTZ(date, tzString) {
        return new Date((typeof date === "string" ? new Date(date) : date).toLocaleString("en-US", { timeZone: tzString }));
    }

    configureImmediateCallback(isAgentAvialable) {
        var estTime = this.convertTZ(new Date(), "America/New_York");
        console.log(estTime);
        var currESTTime = new Date(estTime);
        let dayOfWeek = currESTTime.toLocaleDateString('en-US', { weekday: 'long' });
        var weekEnd = (dayOfWeek == 'Sunday' || dayOfWeek == 'Saturday') ? true : false;
        var startTime;
        var endTime;
        if (this.businessHours != undefined) {
            this.businessHours.forEach(bh => {
                if (bh.weekName == dayOfWeek) {
                    startTime = parseInt(bh.startTime.substr(0, bh.startTime.indexOf(':')));
                    endTime = parseInt(bh.endTime.substr(0, bh.endTime.indexOf(':')));
                }
            });
            endTime = parseInt(endTime) + 12;
        }
        this.communicationoptions.forEach(ele => {
            if (ele.label == 'Call me now') {
                if (currESTTime.getHours() >= startTime && currESTTime.getHours() < endTime && weekEnd != true /*&& !(this.isTodayHoliday)*/) {//POC - Disable call me now Message
                    ele.readOnly = (isAgentAvialable == true) ? false : true;
                    ele.message = this.callMeNowMessage;
                }/*else if(this.isTodayHoliday){ //POC - Disable call me now Message
                    ele.readOnly = true;
                    ele.message = this.callMeNowHoliday;
                }*/else {
                    ele.readOnly = true;
                    ele.message = this.callMeNowClosed;
                }
            }
        });
    }

    handleDropDownChange(event) {
        if (event.detail !== undefined) {
            console.log('dropdown-->' + JSON.stringify(event.detail));
            if (event.detail.title === 'professionalDesignation') {
                this.handleDataLayerEvent(professionalDesignationLabel, event.detail.label);
                this.handleDesignationChange(event.detail.value);
                this.gaFileds[professionalDesignationLabel] = event.detail.label;
            }
            else if (event.detail.title === 'appointmentTemplate') {
                this.handleDataLayerEvent(appointmentTemplateLabel, event.detail.label);
                this.handleTemplatesChange(event.detail.value);
                this.gaFileds[appointmentTemplateLabel] = event.detail.label;
            }
            else if (event.detail.title === 'productEnquiry') {
                this.appointmentTemplates = [];
                this.handleDataLayerEvent(productEnquiryLabel, event.detail.label);
                this.handleProductEnquiryChange(event.detail);
                this.gaFileds[productEnquiryLabel] = event.detail.label;
            }
        }
    }

    handleDataLayerEvent(evtCategory, evtAction) {
        let tempEventDetails = { event_category: evtCategory, event_action: evtAction, event_label: "askmerck.com" };
        const formSubmitEvt = new CustomEvent("datalayerevent", {
            detail: tempEventDetails,
            bubbles: true,
            composed: true,
        });
        this.dispatchEvent(formSubmitEvt);
    }


    handleUserdetailsChange(event) {
        if (event.detail != undefined) {
            this.handleDataLayerEvent(event.detail.label, event.detail.value);
            this.gaFileds[event.detail.label] = event.detail.value;
        }
    }

    handleDownloadICS(event) {
        if (event.detail != undefined) {
            this.handleDataLayerEvent(event.detail.event_category, event.detail.event_action);
        }
    }

    handleMerckAcessWeblink(event) {
        if (event.detail != undefined) {
            this.handleDataLayerEvent(event.detail.event_category, event.detail.event_action);
        }
    }

    handleProductEnquiryChange(productValue) {
        if (productValue != undefined) {
            this.products.forEach(ele => {
                if (ele.label == productValue.label) {
                    console.log('product-->' + JSON.stringify(ele));
                    this.selectedProduct = ele;
                    this.scheduleDetails.productEnquiry = ele.label;
                    this.scheduleDetails.productEnquiryValue = ele.value;
                    this.scheduleDetails.productParent = ele.parentID; //product_vod (veeva product) ID
                    if (ele.isBlackBox == true) {
                        this.showBlackBoxMsg = true;
                        this.blackBoxMsg = ele.additionalInformation;
                    }
                    else {
                        this.showBlackBoxMsg = false;
                    }
                }
            });
            var tempAppointmentTemplates = this.schdulerDataStructure.templates.sort((a, b) => parseInt(a.order) - parseInt(b.order));
            var tempSelectedProduct = this.selectedProduct;
            if ((tempSelectedProduct.inquiryTypes).length > 0) {
                var filteredTemplates = tempAppointmentTemplates.filter(function (item) {
                    return tempSelectedProduct.inquiryTypes.indexOf(item.label) !== -1;
                });
                this.appointmentTemplates = filteredTemplates;
                console.log('-->' + this.appointmentTemplates.indexOf(this.scheduleDetails.templateId));
                this.scheduleDetails.templateId=null
                if (this.scheduleDetails.templateId && this.appointmentTemplates.indexOf(this.scheduleDetails.templateId) !== -1) {
                    if (this.scheduleDetails.templateId != undefined) {
                        this.handleScheduleCallBackandGroup(this.scheduleDetails.templateId);
                    }
                }
                else {
                    this.refreshTemplates();
                }
            }

        }
    }

    refreshTemplates() {
        if (this.template.querySelector('.appointmentTemplate') != undefined && this.template.querySelector('.appointmentTemplate') != null) {
            this.template.querySelector('.appointmentTemplate').refreshLabel();
        }
        this.showTumor = false;
        this.showCommunicationModes = false;
        this.showScheduleCallbackCmp = false;
        this.showUserForm = false;
        this.scheduleDetails.communicationMode = '';
    }

    handleChange(event){
        const radioButton = event.target;
            console.log('radioButton--->'+radioButton);
            // if (!radioButton.disabled) {
            // radioButton.style.display = 'none';
            // }
            if (!radioButton.disabled && radioButton.style.display !== 'none') {
                radioButton.disabled = true;
                // radioButton.style.cursor= 'not-allowed';
                // radioButton.style.display = 'none';
                // radioButton.classList.add('blocked-radio');
                event.preventDefault();

            }
    }

   
    
}