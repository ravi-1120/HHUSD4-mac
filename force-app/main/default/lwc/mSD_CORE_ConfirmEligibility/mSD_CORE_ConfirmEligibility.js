import { LightningElement,track,wire,api } from 'lwc';
import getEligibilityDetails from '@salesforce/apex/MSD_CORE_SettingsController.getEligibilityDetails';
import getPicklistValue from '@salesforce/apex/MSD_CORE_RegistrationController.getPicklistValue';
import getOrganizations from '@salesforce/apex/MSD_CORE_RegistrationController.getOrganizations';
import submitEligibility from '@salesforce/apex/MSD_CORE_SettingsController.submitEligibility';
import successicon from '@salesforce/resourceUrl/successicon';
// import getActiveOrgs from '@salesforce/apex/MSD_CORE_SettingsController.getActiveOrgs';
import plus from '@salesforce/resourceUrl/plusicon';
import USER_ID from "@salesforce/user/Id";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import {refreshApex} from '@salesforce/apex';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import settingscss from '@salesforce/resourceUrl/settingscss';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import CloseIconImage from '@salesforce/resourceUrl/cancelicon';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';
import { NavigationMixin } from 'lightning/navigation';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

export default class MSD_CORE_ConfirmEligibility extends NavigationMixin(LightningElement) {
    CloseIcon = CloseIconImage;
    @track orgTypeinput = '';
    @track orginput ='';
    @track orgIdinput ='';
    @track roleinput = 'Select'; //'Consultant';
    @track stateinput = 'PA';
    @track ptProcessVal = false;
    @track workstreetAddrVal = '';
    @track unitsuitVal = '';
    @track cityVal = '';
    @track stateVal = '';
    @track zipVal = '';
    @track workPhoneVal = '';
    @track extVal = '';
    @track healthdecisionmaker  = false;    
    @track infocorrect = false;
    @track selectedNext = false;
    @track allvalid = false;
    @track otherRole='';
    @track siteName = '';
    @track siteApiName = '';
    @track roleinputValidtion=true;
    @track eligibilityRecord = {};
    @track settingurl;
    @track settingapi;
    @track disableOrgCross = false;
    successicon = successicon;
    plusicon = plus;
    label = {jobcode};
    validRegex = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;
    @api listdata;
    @track relatedId;
    loadEligibility(){
        refreshApex(this.eligibilityRecord);
    }
    @wire(getRecord, { recordId: USER_ID })
    user;
    get acknowledged(){
        return this.selectedNext? (this.healthdecisionmaker && this.infocorrect )?true:false : true;
    }
    get orgTypeinputValid(){
        return this.selectedNext?this.orgTypeinput?true:false: true;
    }
    get orginputValid(){
        return this.selectedNext?this.orginput?true:false: true;
    }
    get roleinputValid(){
        return this.selectedNext?this.roleinput?true:false: true;
    }
    get ptProcessValValid(){
        return this.selectedNext?this.ptProcessVal?true:false: true;
    }
    get workstreetAddrValValid(){
        return this.selectedNext?this.workstreetAddrVal?true:false: true;
    }
    get cityValValid(){
        return this.selectedNext?this.cityVal?true:false: true;
    }
    get stateValValid(){
        return this.selectedNext?this.stateinput?true:false: true;
    }
    get zipValValid(){
        return this.selectedNext?this.zipVal?true:false: true;
    }
    /*get workPhoneValValid(){
    return this.selectedNext?this.workPhoneVal?true:false: true;
    } */
    get otherroleValid(){
        return this.selectedNext?this.showOther?this.otherRole?true:false:true:true;
    }

    get formatPhoneNumber() {
        this.workPhoneVal = this.workPhoneVal.replace(/\D/g,'').substring(0,10); //Strip everything but 1st 10 digits
        var size = this.workPhoneVal.length;
        if (size>0) {this.workPhoneVal="("+this.workPhoneVal}
        if (size>3) {this.workPhoneVal=this.workPhoneVal.slice(0,4)+") "+this.workPhoneVal.slice(4)}
        if (size>6) {this.workPhoneVal=this.workPhoneVal.slice(0,9)+"-" +this.workPhoneVal.slice(9)}
        var cleaned = ('' + this.workPhoneVal).replace(/\D/g, '');
        var match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
        if (match || !this.selectedNext) {
            this.workPhoneValValid = true;
        }else{
            this.workPhoneValValid = false;
        }
        return this.workPhoneVal;
    }

    @track accrecordId = '';
    @track isSuccesspop = false;
    @track contactrole = '';
    @track skey='';
    // pageName = 'Eligibility';
    @track  rolelist = [];
    @track orgtypelist = [];
    @track statelist = [];
    @track orglist = [];
    @track consultant = false;
    @track ptProcess = false; 
    @track showOther = false;
    @track orgTypeValues = ['Clinician / Physician','Contracting manager / Director','Government Relations Representative','Health Economist','Provider Relations Director','Quality Director','Trade / Industry Relations Director','Executive Administrator (VP , Chief of Pharmacy)','Medical Director','Pharmacy Director','Pharmacist (Clinical, Drug Information)','Student in Rotation'];    
    searchKeyDebounced;

    doneTypingInterval = 300;
    typingTimer;
    @track consultantlist = [];
    count=1;
    connectedCallback() {
        getOrganizations({ searchKey: null }).then((result) => {
            this.orglist = [];
            this.orglist = result;
        })
    }

    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.accrecordId = currentPageReference.state.recordId;
        }
    }

    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        console.log({ value });
        const { data, error } = value;
        if (data) {
            console.log({ data });
            this.contactrole = data;
        }
        if (error) {
            console.log({ error });
        }
    }

    handleDefaults(event){
        let dropdownitems = this.template.querySelectorAll('.slds-dropdown-trigger');
        dropdownitems.forEach((el) => {
            el.classList.remove('slds-is-open');
        });
    }

    handleSearch(event){
        if(!this.orginput){
            getOrganizations({ searchKey: null }).then((result) => {
                this.orglist = [];
                this.orglist = result;
            }) 
        }
    }

    removeOrg(event){
        let value = event.currentTarget.dataset.id;
        let updatedlist = [];
        console.log('value',value);
        var activecount = 0;
        for(let i=0; i< this.consultantlist.length;i++){
            if(this.consultantlist[i].id == value){
                this.consultantlist[i].isactive = false;
                // this.relatedOrgId = this.consultantlist[i].relatedOrgId;
            }
            if(this.consultantlist[i].isactive){
                activecount = activecount+1;
            }
        }
        // updatedlist = this.consultantlist.filter(function(con) {
        //     return con.id != value;
        // } );
        console.log('updatedlist>>',updatedlist);
        console.log('updatedlistlength>>',updatedlist.length);
        console.log('consultantlistlength>>>',this.consultantlist.length);
            if(activecount == 1){
                this.disableOrgCross = true;
            }else{
                this.disableOrgCross = false;
            }
    }

    handleRadio(event){
        const evt = event.currentTarget;
        let val = event.currentTarget.dataset.id;
        let value = event.currentTarget.value;
                evt.checked= true;
        for(let i=0; i< this.consultantlist.length;i++){
            if( this.consultantlist[i].id == val ){
                if(value == 'diffemail'){
                    this.consultantlist[i].myemail = false;
                    this.consultantlist[i].diffemail = true;
                    this.consultantlist[i].disableEmail = false;
                    this.consultantlist[i].diffemailAddress = '';
                    if(!this.consultantlist[i]?.diffemailAddress){
                        this.consultantlist[i].diffemailAddressValid = false;
                    }else{
                        if (this.consultantlist[i].diffemailAddress.match(this.validRegex)) {
                            this.consultantlist[i].diffemailAddressValid = true;
                        }else{
                            this.consultantlist[i].diffemailAddressValid = false;
                        }
                    }
                }else{
                    this.consultantlist[i].myemail =true;
                        this.consultantlist[i].diffemail =false;
                        this.consultantlist[i].disableEmail = true;
                        this.consultantlist[i].diffemailAddressValid = true;
                }
                this.consultantlist[i].emailchoiceValid =true;
            }
        }
    }

 

    handleOrgConsultant(event) {
        let value = event.currentTarget.dataset.id;
        let orgval  = event.currentTarget.attributes.value.value;
        let orgid  = event.currentTarget.dataset.orgid;
        for(let i=0; i< this.consultantlist.length;i++){
            if( this.consultantlist[i].id == value ){
                this.consultantlist[i].orgname = orgval;
                this.consultantlist[i].orgId = orgid;
                this.consultantlist[i].orgIdValid = orgval?true:false;
            }
        }
    }

    handleEmailConsultant(event){
        let value = event.currentTarget.dataset.id;
        let email  = event.currentTarget.value;
        for(let i=0; i< this.consultantlist.length;i++){
            if( this.consultantlist[i].id == value ){
                this.consultantlist[i].diffemailAddress = email;
                if (email.match(this.validRegex)) {
                    this.consultantlist[i].diffemailAddressValid = true;
                }else{
                    this.consultantlist[i].diffemailAddressValid = false;
                }
                if(this.selectedNext && !this.consultantlist[i].diffemailAddress){
                    this.consultantlist[i].diffemailAddressValid = false;
                }   
            }
        }
    }

    handleInput(event){
        let name = event.currentTarget.attributes.name.value;

        if(name == 'otherrole'){
            this.otherRole = event.currentTarget.value;
        }
        if(name == 'workstreetAddr'){
            this.workstreetAddrVal = event.currentTarget.value;
           
        }
        if(name == 'unitsuit'){
            this.unitsuitVal = event.currentTarget.value;
           
        }
        if(name == 'city'){
            this.cityVal = event.currentTarget.value;
            
        }
        if(name == 'zip'){
            this.zipVal = event.currentTarget.value;
            
        }
        if(name == 'workphone'){
            this.workPhoneVal = event.currentTarget.value;
            
        }
        if(name == 'ext'){
            this.extVal = event.currentTarget.value;
            
        }
    }

    handlegaevent(event){
        let name = event.currentTarget.attributes.name.value;

        if(name == 'workstreetAddr'){
            
            this.fireDataClickEvent("label", '', 'street address', '', 'settings__c', '/settings');
        }
        if(name == 'unitsuit'){
            
            this.fireDataClickEvent("label", '', 'unit(optional)', '', 'settings__c', '/settings');
        }
        if(name == 'city'){
            
            this.fireDataClickEvent("label", '', 'city', '', 'settings__c', '/settings');
        }
        if(name == 'zip'){
            
            this.fireDataClickEvent("label", '', 'zip', '', 'settings__c', '/settings');
        }
        if(name == 'workphone'){
            
            this.fireDataClickEvent("label", '', 'work phone', '', 'settings__c', '/settings');
        }
        if(name == 'ext'){
            
            this.fireDataClickEvent("label", '', 'extension(optional)', '', 'settings__c', '/settings');
        }
    }
 
    

    handlePT(event){
        this.ptProcessVal = event.currentTarget.checked;
    }

    handleOrgTypeConsultant(event){
        let value = event.currentTarget.dataset.id;
        let orgtypeval = event.currentTarget.attributes.value.value;
        for(let i=0; i< this.consultantlist.length;i++){
            if( this.consultantlist[i].id == value ){
                this.consultantlist[i].orgtype = orgtypeval;
                this.consultantlist[i].orgtypeValid = orgtypeval?true:false;
            }
        }
    }

    addOrganization(event){
        let cons = {
            'id': ++ this.count,
            'myemailId' : this.count+'myemailId',
            'diffemailId' : this.count+'diffemail',
            'myemail' : true,
            'diffemail' : false,
            'diffemailAddress' : null,
            'orgname' : null,
            'orgId' : null,
            'orgtype' : null,
            'orgIdValid' : false,
            'orgtypeValid' : false,
            'diffemailAddressValid':true,
            'emailchoiceValid':true,
            'disableEmail':true,
            'relatedOrgId': null,
            'isactive':true
        };

        if ( this.consultantlist ) {
            this.consultantlist = [...this.consultantlist, cons ];
        } else {
            this.consultantlist = [ cons ];
        }
        if(this.consultantlist.length == 1){
            this.disableOrgCross = true;
        }else{
            this.disableOrgCross = false;
        }
        console.log(JSON.stringify(this.consultantlist));
    }

    renderedCallback(){
        if(this.roleinput == 'Consultant'){
            this.consultant = true;
        }else{
            this.consultant = false
        }

        if(this.consultantlist.length == 0){
            this.consultantlist = [ {
                'id': this.count,
                'myemailId' : this.count+'myemailId',
                'diffemailId' : this.count+'diffemail',
                'myemail' : true,
                'diffemail' : false,
                'diffemailAddress' : null,
                'orgname' : null,
                'orgId' : null,
                'orgtype' : null,
                'orgIdValid' : false,
                'orgtypeValid' : false,
                'diffemailAddressValid':true,
                'emailchoiceValid':true,
                'disableEmail':true,
                'relatedOrgId': null,
                
            } ];
            
            if(this.roleinput == ''){
                this.roleinput = 'Select';
            }
            if(this.orgTypeValues.includes(this.roleinput)){
                this.ptProcess = true;
            }
        }
        
        Promise.all([
            loadStyle(this, settingscss)
        ]).then(() => {
        }).catch(error => {
            console.log(error.body.message);
        });
    }
    handleSeachKeyChangeDebounced(event){
        clearTimeout(this.typingTimer);
        let value = event.target.value;
        let conid = event.target.dataset.id;
        if(!conid){
            this.orginput = value;
        }else{
            for(let i=0; i< this.consultantlist.length;i++){
                if( this.consultantlist[i].id == conid ){
                    this.consultantlist[i].orgname = value;
                    this.consultantlist[i].orgId = null;
                    this.consultantlist[i].orgIdValid = value?true:false;
                }
            }
        }
            
        this.handleSearch();
        this.typingTimer = setTimeout(() => {
            if(value){
                getOrganizations({ searchKey: value }).then((result) => {
                    this.orglist = [];
                    this.orglist = result;
                })
            }
        }, this.doneTypingInterval);
    }

    @wire(getEligibilityDetails,{ userId: USER_ID })
    getEligibility(result){
        this.eligibilityRecord = result;
        console.log(this.eligibilityRecord,'eligibility-->');
        let data = result.data;
         console.log(this.data,'data--->');
         console.log(this.listdata,'listdata==>');
        let error = result.error;
         console.log(this.error,'error-->');
        this.consultantlist = [];    
        if(data && data.Id){
            console.log('Eligibiligy'+JSON.stringify(data));
            this.orgTypeinput = data.MSD_CORE_Organization_Type__c?data.MSD_CORE_Organization_Type__c:'';
            this.orginput = data.MSD_CORE_Organization__r?.Name?data.MSD_CORE_Organization__r?.Name:'';
            this.orgIdinput = data.MSD_CORE_Organization__c? data.MSD_CORE_Organization__c:'';
            this.roleinput = data.MSD_CORE_Role__c?data.MSD_CORE_Role__c:'';
            this.stateinput = data.MS_CORE_Organization_State_Code__c?data.MS_CORE_Organization_State_Code__c:'';
            this.ptProcessVal = data.MSD_CORE_P_T_Process__c?data.MSD_CORE_P_T_Process__c:'';
            this.workstreetAddrVal = data.MSD_CORE_Organization_Street_1__c?data.MSD_CORE_Organization_Street_1__c:'';
            this.unitsuitVal = data.MSD_CORE_Organization_Street_2__c?data.MSD_CORE_Organization_Street_2__c:'';
            this.cityVal = data.MSD_CORE_Organization_City__c?data.MSD_CORE_Organization_City__c:'';
            this.stateVal = data.MS_CORE_Organization_State_Code__c?data.MS_CORE_Organization_State_Code__c:'';
            this.zipVal = data.MSD_CORE_Organization_ZIP__c?data.MSD_CORE_Organization_ZIP__c:'';
            this.workPhoneVal = data.MSD_CORE_Organization_Phone__c?data.MSD_CORE_Organization_Phone__c:'';
            this.extVal = data.MSD_CORE_Organization_Extension__c?data.MSD_CORE_Organization_Extension__c:'';
            // if(data.MSD_CORE_Healthcare_Professional__c){
            //     this.healthdecisionmaker = data.MSD_CORE_Healthcare_Professional__c;
            // } 
            this.infocorrect = false;
            this.selectedNext = false;
            this.allvalid = false;
            this.otherRole=data.MSD_CORE_Other_Role__c?data.MSD_CORE_Other_Role__c:'';
            if(data.Related_Organizations__r){
                for(let i=0; i < data.Related_Organizations__r.length; i++){
                    let eli = {};
                    eli.orgIdValid = true;
                    eli.orgtypeValid = true;
                    eli.diffemailAddress = '';
                    eli.diffemailAddressValid = true;
                    eli.diffemail = false;
                    eli.myemail = false;
                    eli.myemailId = i+'myemailId';
                    eli.diffemailId = i+'diffemail';
                    eli.emailchoiceValid = true;
                    eli.disableEmail = false;
                    eli.id =i;
                    eli.orgname = data.Related_Organizations__r[i].MSD_CORE_Organization__r?.Name?data.Related_Organizations__r[i].MSD_CORE_Organization__r?.Name:'';
                    eli.isactive = data.Related_Organizations__r[i].MSD_CORE_Is_Active__c;
                    eli.orgId = data.Related_Organizations__r[i]?.MSD_CORE_Organization__c?data.Related_Organizations__r[i]?.MSD_CORE_Organization__c:'';
                    eli.orgtype = data.Related_Organizations__r[i]?.MSD_CORE_Organization_Type__c?data.Related_Organizations__r[i]?.MSD_CORE_Organization_Type__c:'';
                    if(data.MSD_CORE_Account__r?.PersonEmail == data.Related_Organizations__r[i]?.MSD_CORE_Email__c && data.Related_Organizations__r[i]?.MSD_CORE_Email__c){
                        eli.myemail = true;
                        eli.disableEmail = true;
                        eli.emailchoiceValid = true;
                    }else{
                        if(data.Related_Organizations__r[i]?.MSD_CORE_Email__c){
                            eli.diffemailAddress = data.Related_Organizations__r[i]?.MSD_CORE_Email__c?data.Related_Organizations__r[i]?.MSD_CORE_Email__c:'';
                            eli.diffemail = true;
                            if(eli.diffemailAddress ){
                                eli.emailchoiceValid = true;
                                
                            }else{
                                eli.emailchoiceValid = false;    
                            }
                        }
                    }
                    eli.relatedOrgId = data.Related_Organizations__r[i]?.Id?data.Related_Organizations__r[i]?.Id:'';
                    this.consultantlist.push(eli);
                }
                console.log(this.orginput,'orginput');
                console.log('Eligibiligy'+JSON.stringify(data));
            }
        
            if(this.consultantlist.length == 0){
                this.consultantlist = [ {
                    'id': this.count,
                    'myemailId' : this.count+'myemailId',
                    'diffemailId' : this.count+'diffemail',
                    'myemail' : true,
                    'diffemail' : false,
                    'diffemailAddress' : null,
                    'orgname' : null,
                    'orgId' : null,
                    'orgtype' : null,
                    'orgIdValid' : false,
                    'orgtypeValid' : false,
                    'diffemailAddressValid':true,
                    'emailchoiceValid':true,
                    'disableEmail':true,
                    'relatedOrgId': null,
                    'isactive':true
                } ];
                if(this.roleinput == ''){
                    this.roleinput = 'Select';
                }
            }

            if(this.consultantlist.length == 1){
                this.disableOrgCross = true;
            }else{
                this.disableOrgCross = false;
            }

            if(this.orgTypeValues.includes(this.roleinput)){
                this.ptProcess = true;
            }
            if(this.roleinput == 'Other'){
                this.showOther = true;
            }
        }else if(error){
            console.log(JSON.stringify(error));
        }
        
    }; 
    
    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log('login mheee--->', { data });
        console.log('settingurl>>>', data.siteAPINamesdebuglog.setting);
        console.log('settingApi>>>', data.siteNames.setting);
        this.settingurl = data.siteAPINamesdebuglog.setting;
        this.settingapi = data.siteNames.setting;

        console.log({ error });
        if (data) {
            this.siteName = data.siteAPINamesdebuglog;
            this.siteApiName = data.siteNames;
        }
        if (error) {
            console.log({ error });
        }
    }

    handleBacksetng(event){ 
        console.log('entered event');
        // this.isSuccesspop = false;
        if (this.settingapi != undefined && this.settingurl != undefined){
            console.log('enterif');
            location.href = this.settingurl + '?tab=2';
//             this[NavigationMixin.Navigate]({
//                     type: 'standard__webPage',
//                     attributes: {
//                         name:   this.settingapi,
//                         url:   this.settingurl + '?tab=2' 
//                     }
//                 });
        }
        this.fireDataClickEvent("button", '', 'back to settings', 'modal', 'settings__c', '/settings');
      }


    @wire(getPicklistValue, { objectType: 'MSD_CORE_Eligibility__c', selectedField: 'MSD_CORE_Organization_Type__c' })
    getorgtype({error,data}){
        if(data){
            console.log(JSON.stringify(data));
            this.orgtypelist = data;
        }else if(error){
            console.log(JSON.stringify(error));
        }
    };

    @wire(getPicklistValue, { objectType: 'MSD_CORE_Eligibility__c', selectedField: 'MSD_CORE_Role__c' })
    getroles({error,data}){
        if(data){
            console.log(JSON.stringify(data));
            this.rolelist = data;
        }else if(error){
            console.log(JSON.stringify(error));
        }
    };

    @wire(getPicklistValue, { objectType: 'MSD_CORE_Eligibility__c', selectedField: 'MS_CORE_Organization_State_Code__c' })
    getstates({error,data}){
        if(data){
            console.log(JSON.stringify(data));
            this.statelist = data;
        }else if(error){
            console.log(JSON.stringify(error));
        }
    };
		
    handleDropdown(event){
				console.log('handleDropdown');
        const evt = event.currentTarget;
        evt.classList.toggle('slds-is-open');
         let labelname = event.currentTarget.dataset.labelname;
        // let input = event.currentTarget.dataset.input;
        if(labelname == 'Organization name'){
            this.fireDataClickEvent("label", '', 'organization name', '', 'settings__c', '/settings');
        }else if (labelname == 'Organization type') {
            this.fireDataClickEvent("dropdown", '', 'organization type', '', 'settings__c', '/settings');
        }
        else if (labelname == 'role') {
            this.fireDataClickEvent("dropdown", '', 'role', '', 'settings__c', '/settings');
        }
        else if (labelname == 'state') {
            this.fireDataClickEvent("dropdown", '', 'state', '', 'settings__c', '/settings');
        }
        // else if (labelname == 'Organization type') {
        //     this.fireDataClickEvent("label", '', 'organization name', '', 'settings__c', '/settings');
        // }
        // else if (labelname == 'Organization type') {
        //     this.fireDataClickEvent("label", '', 'organization name', '', 'settings__c', '/settings');
        // }
     
    }

    handleOrgType(event) {
        this.orgTypeinput = event.currentTarget.attributes.value.value;
    }

    handleOrg(event) {
        this.orginput = event.currentTarget.attributes.value.value;
        this.orgIdinput = event.currentTarget.dataset.id;
        console.log('individual event');
    }

    handleRole(event) {
        this.roleinput = event.currentTarget.attributes.value.value;
        if(this.roleinput == 'Consultant'){
            this.consultant = true;
        }else{
            this.consultant = false
        }
        if(this.orgTypeValues.includes(this.roleinput)){
            this.ptProcess = true;
        }else{
            this.ptProcess = false;
        }
        if(this.roleinput == 'Other'){
            this.showOther = true;
        }else{
            this.showOther = false;
        }
        this.fireDataClickEvent("dropdown_selection", '', this.roleinput, '', 'settings__c', '/settings');
    }

    handleState(event) {
        this.stateinput = event.currentTarget.attributes.value.value;
    }
 
    handlebackclk() {
        const clickpreviouspage = new CustomEvent("showpasswordpage", {
            detail: false
        });
        this.dispatchEvent(clickpreviouspage);
    }

    handleAcknowledge(){
        const evt = event.currentTarget;
        let name = event.currentTarget.name;
        if(name == 'healthdecisionmaker'){
            this.healthdecisionmaker = evt.checked;
            this.fireDataClickEvent("checkbox", '', 'yes', '', 'settings__c', '/settings');
        }
        if(name == 'infocorrect'){
            this.infocorrect = evt.checked ;
            this.fireDataClickEvent("checkbox", '', 'I acknowledge', '', 'settings__c', '/settings');
        }
    }

    handleCancel(event){
        console.log('handleCancel');
        const cancelEvent = new CustomEvent('cancelediteligibility', {});
        this.dispatchEvent(cancelEvent);
        let btnName = event.currentTarget.dataset.name;
        if(btnName == 'cacelbtn'){
            this.fireDataClickEvent("button", '', 'cancel', '', 'settings__c', '/settings');
        }else if (btnName == 'crossbtn') {
            this.fireDataClickEvent("button", '', 'back to screen_X', 'modal', 'settings__c', '/settings');
        }else if (btnName == 'contactlink') {
            this.fireDataClickEvent("link", '', 'contact', 'modal', 'settings__c', '/settings');
        }
        
    }

    

    handleSubmit() {
        this.selectedNext = true;
        if(this.roleinput == 'Select'){
            this.roleinputValidtion = false;
        }else{
            this.roleinputValidtion = true;
        }

        this.typingTimer = setTimeout(() => {
            let dropdownitems = this.template.querySelectorAll('.elig-validation');
            if(dropdownitems.length == 0){
                try {
                    let inputFields = this.template.querySelectorAll('.inputcls');
                    inputFields.forEach(infield => {
                        if(infield.name == 'workstreetAddr'){
                            this.workstreetAddrVal = infield.value;
                        }
                        if(infield.name == 'unitsuit'){
                            this.unitsuitVal = infield.value;
                        }
                        if(infield.name == 'city'){
                            this.cityVal = infield.value;
                        }
                        if(infield.name == 'zip'){
                            this.zipVal = infield.value;
                        }
                        if(infield.name == 'workphone'){
                            this.workPhoneVal = infield.value;
                        }
                        if(infield.name == 'ext'){
                            this.extVal = infield.value;
                        }
                        console.log(JSON.stringify(infield));
                    });
                    this.eligibilityWrap = {};
                    this.eligibilityWrap.orgId = this.orgIdinput;
                    this.eligibilityWrap.orgname = this.orginput;
                    this.eligibilityWrap.orgtype = this.orgTypeinput;
                    this.eligibilityWrap.role = this.roleinput;
                    this.eligibilityWrap.workstreetAddrVal = this.workstreetAddrVal;
                    this.eligibilityWrap.unitsuitVal = this.unitsuitVal;
                    this.eligibilityWrap.cityVal = this.cityVal;
                    this.eligibilityWrap.zipVal = this.zipVal;
                    this.eligibilityWrap.workPhoneVal = this.workPhoneVal;
                    this.eligibilityWrap.extVal = this.extVal;
                    this.eligibilityWrap.state = this.stateinput;
                    this.eligibilityWrap.pt = this.ptProcessVal;
                    this.eligibilityWrap.relatedOrg = this.consultantlist;
                    this.eligibilityWrap.otherRole = this.otherRole;
                    this.eligibilityWrap.healthdecisionmaker = this.healthdecisionmaker;
                    this.submitEligibilityMethod();
                    console.log(this.eligibilityWrap,'this.eligibilityWrap-->');
                    console.log(JSON.stringify(this.eligibilityWrap),'eligibilitywrapper');

                } catch (error) {
                    console.log('Error in Handle Finish-->',{error});
                }
            }
        }, 100); 
        this.fireDataClickEvent("button", '', 'submit', '', 'settings__c', '/settings');
    }

    submitEligibilityMethod() {
        submitEligibility({userId: USER_ID,wrapData:JSON.stringify(this.eligibilityWrap) })
            .then((result) => {
                console.log('Result of submitEligibility--->',{result});
                if(result == "Success") {
                    console.log('Raviteja 628');
                    this.isSuccesspop = true;
                       //alert('Updated Successfully');
                }else {
                    const toastEvent = new ShowToastEvent({
                    title: "warning",
                    message: "NOt updataed",
                    variant: "warning"
                    });
                    this.dispatchEvent(toastEvent);
                }

            })
            .catch((error) => {
                console.log('Error of submitEligibility--->',{error});
                const toastEvent = new ShowToastEvent({
                    title: "warning",
                    message: "NOt updataed catch block",
                    variant: "warning"
                    });
                    this.dispatchEvent(toastEvent);
            })
    }

//Google Analytics
    fireDataClickEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'account management',
                page_purpose: 'account management',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: linkedtext,
                link_url: linkedurl,
                content_count: '',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'settings',

            },
            bubbles: true,
            composed: true
        }));
    }
}