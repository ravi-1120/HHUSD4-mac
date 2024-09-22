import { LightningElement, wire, api, track } from 'lwc';
import getOrganizations from '@salesforce/apex/MSD_CORE_RegistrationController.getOrganizations';
import saveEligibility from '@salesforce/apex/MSD_CORE_RegistrationController.saveEligibility';
import {refreshApex} from '@salesforce/apex';
import { CurrentPageReference } from 'lightning/navigation';
import getEligibilityDetails from '@salesforce/apex/MSD_CORE_RegistrationController.getEligibilityDetails';
import getPicklistValue from '@salesforce/apex/MSD_CORE_RegistrationController.getPicklistValue';
export default class msd_CORE_Eligilibility extends LightningElement {

    @track orgTypeinput = '';
    @track orginput ='';
    @track orgIdinput ='';
    @track roleinput = 'Select'; //'Consultant';
    @track stateinput = '';  // INC2747380 - fix added by Sabari to Make the default value null
    @track ptProcessVal = false;
    @track workstreetAddrVal = '';
    @track unitsuitVal = '';
    @track cityVal = '';
    @track searchterm = ''; //INC2747384
    @track stateVal = '';
    @track zipVal = '';
    @track workPhoneVal = '';
    @track extVal = '';
    @track healthdecisionmaker  = false;    
    @track infocorrect = false;
    @track selectedNext = false;

    @track selectedOrgName = false;
    @track selectedOrgType = false;
    @track selectedRole = false;
    @track selectedWorkAdd = false;

    @track selectedCity = false;
    @track selectedState = false;
    @track selectedZip = false;
    @track selectedWork = false;

    @track allvalid = false;
    @track otherRole='';
    @track roleinputValidtion=true;
    @track eligibilityRecord = {};
    validRegex = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;

    @api mobilescreen;
    @track disablebtn = true;
    @track btndisablecls = 'slds-button elig-button btn-fill btndisable';

    loadEligibility(){
        refreshApex(this.eligibilityRecord);
    }

    get acknowledged(){
        return this.selectedNext? (this.healthdecisionmaker && this.infocorrect )?true:false : true;
    }
    get orgTypeinputValid(){
        return this.selectedOrgType?this.orgTypeinput?true:false: true;
    }
    get orginputValid(){
        return this.selectedOrgName?this.orginput?true:false: true;
    }
    get roleinputValid(){
        return this.selectedRole?this.roleinput?true:false: true;
    }
    get ptProcessValValid(){
        return this.selectedNext?this.ptProcessVal?true:false: true;
    }
    get workstreetAddrValValid(){
        return this.selectedWorkAdd?this.workstreetAddrVal?true:false: true;
    }
    get cityValValid(){
        return this.selectedCity?this.cityVal?true:false: true;
    }
    get stateValValid(){
        return this.selectedState?this.stateinput?true:false: true;
    }
    get zipValValid(){
        return this.selectedZip?this.zipVal?true:false: true;
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
        if (match || !this.selectedWork) {
            this.workPhoneValValid = true;
        }else{
            this.workPhoneValValid = false;
        }
        return this.workPhoneVal;
    }

    @track oldInput = '';
    @track accrecordId = '';
    @track skey='';
    pageName = 'Eligibility';
    @track  rolelist = [];
    @track orgtypelist = [];
    @track statelist = [];
    @track stateexist = []; //INC2747384
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
        this.disablebtn = true;
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

    handleChange(event){
        console.log('handleChange');
        console.log(event);
        console.log(event.currentTarget.dataset.inputno);

        if (parseInt(event.currentTarget.dataset.inputno) == 1) {
            this.selectedOrgName = true;
        } else if (parseInt(event.currentTarget.dataset.inputno) == 2) {
            this.selectedOrgType = true;
        } else if (parseInt(event.currentTarget.dataset.inputno) == 3) {
            if (this.roleinput == 'Select') {
                this.roleinputValidtion = false;
            } else {
                this.roleinputValidtion = true;
            }
        } else if (parseInt(event.currentTarget.dataset.inputno) == 4) {
            this.selectedWorkAdd = true;
        } else if (parseInt(event.currentTarget.dataset.inputno) == 5) {
            this.selectedCity = true;
        } else if (parseInt(event.currentTarget.dataset.inputno) == 6) {
            this.selectedState = true;
        } else if (parseInt(event.currentTarget.dataset.inputno) == 7) {
            this.selectedZip = true;
        } else if (parseInt(event.currentTarget.dataset.inputno) == 8) {
            this.selectedWork = true;
        }
        

        if(this.oldInput == ''){
            this.oldInput = event.currentTarget.dataset.inputno;
        }else{
            if (parseInt(this.oldInput) != parseInt(event.currentTarget.dataset.inputno)) {
                var inputList = [parseInt(this.oldInput), parseInt(event.currentTarget.dataset.inputno)];
                console.log('inputList', inputList);
                inputList = inputList.sort();
                console.log('inputList', inputList);

                for (var i = inputList[0]; i < inputList[1]; i++) {
                    if (i == 1) {
                        this.selectedOrgName = true;
                    } else if (i == 2) {
                        this.selectedOrgType = true;
                    } else if (i == 3) {
                        if (this.roleinput == 'Select') {
                            this.roleinputValidtion = false;
                        } else {
                            this.roleinputValidtion = true;
                        }
                    } else if (i == 4) {
                        this.selectedWorkAdd = true;
                    } else if (i == 5) {
                        this.selectedCity = true;
                    } else if (i == 6) {
                        this.selectedState = true;
                    } else if (i == 7) {
                        this.selectedZip = true;
                    } else if (i == 8) {
                        this.selectedWork = true;
                    }
                }
            }


            this.oldInput = event.currentTarget.dataset.inputno;
        }

        if (this.infocorrect && this.healthdecisionmaker && this.isInputValid()) {
            this.disablebtn = false;
            this.btndisablecls = 'slds-button elig-button btn-fill btnenablecls';
        } else {
            this.disablebtn = true;
            this.btndisablecls = 'slds-button elig-button btn-fill btndisable';
        }

    }

    removeOrg(event){
        let value = event.target.dataset.id;
        this.consultantlist = this.consultantlist.filter(function(con) {
            return con.id != value;
        } );
    }

    handleRadio(event){
        const evt = event.currentTarget;
        let val = event.currentTarget.dataset.id;
        let value = event.currentTarget.value;
                evt.checked= true;
        for(let i=0; i< this.consultantlist.length;i++){
            if( this.consultantlist[i].id == val ){
                if(value == 'diffemail'){
                    this.consultantlist[i].myemail =false;
                        this.consultantlist[i].diffemail =true;
                        this.consultantlist[i].disableEmail = false;
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
        if(value == 'myemail'){
          this.fireDataLayerEvent("radio", "step_2_consultant", "indicate email", 'registration_flow', 'Register', '/SelfRegister');
          this.fireDataLayerEvent("radio_selection", "step_2_consultant", "Use my default email address", 'registration_flow', 'Register', '/SelfRegister'); 
        }else{
          this.fireDataLayerEvent("radio", "step_2_consultant", "indicate email", 'registration_flow', 'Register', '/SelfRegister');
          this.fireDataLayerEvent("radio_selection", "step_2_consultant", "Use different email address", 'registration_flow', 'Register', '/SelfRegister'); 
        }
    }

    handleEmail(){
        this.fireDataLayerEvent("label", "step_2_consultant", "email", 'registration_flow', 'Register', '/SelfRegister');
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
        this.fireDataLayerEvent("dropdown", "step_2_consultant", "organization name", 'registration_flow', 'Register', '/SelfRegister');
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
       let labelname = event.currentTarget.dataset.labelname;
       if(labelname == 'Work street address'){
          this.fireDataLayerEvent('label', 'step_2', 'street address', 'registration_flow', 'Register', '/SelfRegister');
       }
       if(labelname == 'Unit'){
          this.fireDataLayerEvent('label', 'step_2', 'unit (optional)', 'registration_flow', 'Register', '/SelfRegister');
       }
       if(labelname == 'City'){
          this.fireDataLayerEvent('label', 'step_2', "city", 'registration_flow', 'Register', '/SelfRegister');
       }
       if(labelname == 'Zip'){
          this.fireDataLayerEvent('label', 'step_2', 'zip', 'registration_flow', 'Register', '/SelfRegister');
       }
       if(labelname == 'Work phone'){
          this.fireDataLayerEvent('label', 'step_2', 'work phone', 'registration_flow', 'Register', '/SelfRegister');
       }
       if(labelname == 'Extension'){
          this.fireDataLayerEvent('label', 'step_2', 'extension (optional)', 'registration_flow', 'Register', '/SelfRegister');
       }
       if(labelname == 'specify'){
          this.fireDataLayerEvent('label', "step_2_other", "please specify", 'registration_flow', 'Register', '/SelfRegister');
       }
    }

    handlePT(event){
        this.ptProcessVal = event.currentTarget.checked;
            if(this.ptProcessVal == true){
                this.fireDataLayerEvent("checkbox", "step_2_pt", "yes_pt", 'registration_flow', 'Register', '/SelfRegister');
            }
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
        this.fireDataLayerEvent("dropdown", "step_2_consultant", "organization type", 'registration_flow', 'Register', '/SelfRegister');
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
            };

        if ( this.consultantlist ) {
            this.consultantlist = [...this.consultantlist, cons ];

        } else {
            this.consultantlist = [ cons ];
        }
        console.log(JSON.stringify(this.consultantlist));
        this.fireDataLayerEvent("button", "step_2_consultant","add organization", 'registration_flow', 'Register', '/SelfRegister');
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
            //RT
            if(this.roleinput == ''){
                this.roleinput = 'Select'; //Consultant
            }
            if(this.orgTypeValues.includes(this.roleinput)){
                this.ptProcess = true;
            }
        }
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

    @wire(getEligibilityDetails,{accountid: '$accrecordId'})
    getEligibility(result){
        this.eligibilityRecord = result;
        let data = result.data;
        let error = result.error;
        this.consultantlist = [];    
        if(data && data.Id){
            console.log('Eligibiligy'+JSON.stringify(data));
            this.orgTypeinput = data.MSD_CORE_Organization_Type__c?data.MSD_CORE_Organization_Type__c:'';
            this.orginput = data.MSD_CORE_Organization__r?.Name?data.MSD_CORE_Organization__r?.Name:'';
            this.orgIdinput = data.MSD_CORE_Organization__c? data.MSD_CORE_Organization__c:'';
            this.roleinput = data.MSD_CORE_Role__c?data.MSD_CORE_Role__c:'';
            this.stateinput = data.MS_CORE_Organization_State_Code__c?data.MS_CORE_Organization_State_Code__c:'';
            if(this.stateinput)
            {
                this.searchterm = this.stateinput;  //INC2747384
            }
            this.ptProcessVal = data.MSD_CORE_P_T_Process__c?data.MSD_CORE_P_T_Process__c:'';
            this.workstreetAddrVal = data.MSD_CORE_Organization_Street_1__c?data.MSD_CORE_Organization_Street_1__c:'';
            this.unitsuitVal = data.MSD_CORE_Organization_Street_2__c?data.MSD_CORE_Organization_Street_2__c:'';
            this.cityVal = data.MSD_CORE_Organization_City__c?data.MSD_CORE_Organization_City__c:'';
            this.stateVal = data.MS_CORE_Organization_State_Code__c?data.MS_CORE_Organization_State_Code__c:'';
            this.zipVal = data.MSD_CORE_Organization_ZIP__c?data.MSD_CORE_Organization_ZIP__c:'';
            this.workPhoneVal = data.MSD_CORE_Organization_Phone__c?data.MSD_CORE_Organization_Phone__c:'';
            this.extVal = data.MSD_CORE_Organization_Extension__c?data.MSD_CORE_Organization_Extension__c:'';
            if(data.MSD_CORE_Healthcare_Professional__c){
                this.healthdecisionmaker = data.MSD_CORE_Healthcare_Professional__c;
            } 
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
                    eli.orgId = data.Related_Organizations__r[i]?.MSD_CORE_Organization__c?data.Related_Organizations__r[i]?.MSD_CORE_Organization__c:'';
                    eli.orgtype = data.Related_Organizations__r[i]?.MSD_CORE_Organization_Type__c?data.Related_Organizations__r[i]?.MSD_CORE_Organization_Type__c:'';
                    if(data.MSD_CORE_Account__r?.PersonEmail == data.Related_Organizations__r[i]?.MSD_CORE_Email__c && data.Related_Organizations__r[i]?.MSD_CORE_Email__c ){
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
                //RT
                if(this.roleinput == ''){
                    this.roleinput = 'Select'; //Consultant
                }
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
    /*
        @wire(getOrganizations,{searchKey: ''})
    getOrgList({error,data}){
        if(data){
            console.log(JSON.stringify(data));
            this.orglist = data;
        }else if(error){
            console.log(JSON.stringify(error));
        }
        }; */

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
            this.stateexist = this.statelist; //INC2747384
        }else if(error){
            console.log(JSON.stringify(error));
        }
    };

    handleDropdown(event){
        const evt = event.currentTarget;
        evt.classList.toggle('slds-is-open');
        let labelname = event.currentTarget.dataset.labelname;
        let input = event.currentTarget.dataset.input;
        if(labelname == 'role' && input == 'Select'){
            this.fireDataLayerEvent('dropdown', 'step_2', 'role', 'registration_flow', 'Register', '/SelfRegister');
        }
        if(labelname == 'Organization type'){
            console.log('entered dropdown');
            this.fireDataLayerEvent('dropdown', 'step_2', 'organization type', 'registration_flow', 'Register', '/SelfRegister');
        }
    }

    merckPrivacy(event){
        this.fireDataLayerEvent('link', 'step_2', 'view privacy', 'registration_flow', 'Register', '/SelfRegister');
    }

    handleOrgType(event) {
        this.orgTypeinput = event.currentTarget.attributes.value.value;
    }

    handleOrg(event) {
        this.orginput = event.currentTarget.attributes.value.value;
        this.orgIdinput = event.currentTarget.dataset.id;
        console.log('individual event');
        this.fireDataLayerEvent('dropdown', 'step_2', 'organization name', 'registration_flow', 'Register', '/SelfRegister');
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
        this.fireDataLayerEvent('dropdown_selection', 'step_2', this.roleinput, 'registration_flow', 'Register', '/SelfRegister');
    }

    handleState(event) {
        this.stateinput = event.currentTarget.attributes.value.value;
        this.searchterm = this.stateinput;
        this.stateexist = this.statelist; //INC2747384
        this.fireDataLayerEvent('dropdown', 'step_2', 'state', 'registration_flow', 'Register', '/SelfRegister');
    }

    handleStatesearch(event){ // Added by Sabari - INC2747384
        this.searchterm = event.target.value;
        const statedropdown =  this.template.querySelector('.statedropdown');
        if(!statedropdown.classList.contains("slds-is-open"))
        {
            statedropdown.classList.add("slds-is-open");
        }else{
            this.stateinput = '';
        }
        if(!this.searchterm){
            this.stateexist = this.statelist;
        } else{
        this.stateexist = this.statelist.filter(item=>item.toLowerCase().includes(this.searchterm.toLowerCase()));
        if(this.stateexist.length>0){
            console.log('Value Exists1-'+this.stateexist);
        }else{
            this.stateexist = this.statelist;
            console.log('No value exists1');
        }
        }
    }

    handleInfoClick(event){
      this.fireDataLayerEvent('label', 'step_2', 'view information', 'registration_flow', 'Register', '/SelfRegister');
    }    
        

    handlebackclk() {
         const clickpreviouspage = new CustomEvent("showpasswordpage", {
             detail: false,

         });
         this.dispatchEvent(clickpreviouspage);
        this.fireDataLayerEvent("button", 'step_2', "back", 'registration_flow', 'Register', '/SelfRegister');
    }


    isInputValid(){

        let isValid = true;
        // if(!this.orgTypeinputValid && !this.orginputValid && !this.roleinputValid && !this.workstreetAddrValValid && !this.cityValValid && !this.stateValValid && !this.zipValValid && !this.workPhoneValValid){
        console.log('---isInputValid->'+!this.orgTypeinput+'---'+!this.orginput+'---'+!this.roleinput+'---'+!this.workstreetAddrVal+'---'+!this.cityVal+'---'+!this.stateinput+'---'+!this.zipVal+'---'+!this.workPhoneVal);
        if(!this.orgTypeinput || !this.orginput || !this.roleinput || !this.workstreetAddrVal || !this.cityVal || !this.stateinput || !this.zipVal || !this.workPhoneVal){
            isValid = false;
        }
        console.log('isValid->'+isValid);
        return isValid;

    }

    handleAcknowledge(){
        const evt = event.currentTarget;
        let name = event.currentTarget.name;
        if(name == 'healthdecisionmaker'){
            this.healthdecisionmaker = evt.checked;
                if(this.healthdecisionmaker == true){
                        this.fireDataLayerEvent("checkbox", 'step_2', "yes" , 'registration_flow', 'Register', '/SelfRegister');
                }
        }
        if(name == 'infocorrect'){
            this.infocorrect = evt.checked ;
                if(this.infocorrect == true){
                        this.fireDataLayerEvent("checkbox", 'step_2', "I acknowledge" , 'registration_flow', 'Register', '/SelfRegister');
                }
        }
        if (this.infocorrect && this.healthdecisionmaker && this.isInputValid()) {
            this.disablebtn = false;
            this.btndisablecls = 'slds-button elig-button btn-fill btnenablecls';
        } else {
            this.disablebtn = true;
            this.btndisablecls = 'slds-button elig-button btn-fill btndisable';
        }
    }

    /*
    handleSaveEligibility() {
        SaveEligibility({ recordId: this.accrecordId, jsonInput: eligibility})
            .then((result) => {
                console.log('<-----Result of Eligibility----->',{result});
            })
            .catch((error) => {
                console.log('<-----Error in Eligibility----->',{error});
            })
    }  */

    handlenextclk() {
        this.selectedNext = true;
        this.selectedCity = true;
        this.selectedState = true;
        this.selectedZip = true;
        this.selectedWork = true;
        this.selectedOrgName = true;
        this.selectedOrgType = true;
        this.selectedRole = true;
        this.selectedWorkAdd = true;
        //RT 
        if(this.roleinput == 'Select'){
            this.roleinputValidtion = false;
        }else{
            this.roleinputValidtion = true;
        }
        this.fireDataLayerEvent("button", 'step_3', "next" , 'registration_flow', 'Register', '/SelfRegister');

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

                    /*
                    let isValidField = true;
                    let isValidCombo = true;

                    let inputFields = this.template.querySelectorAll('.inputcsscls');
                    inputFields.forEach(infield => {
                        if (!infield.checkValidity()) {
                            console.log('IFFF');
                            infield.reportValidity();
                            isValidField = false;
                        }
                    });

                    let comboboxFields = this.template.querySelectorAll('.inputboxcls');
                    comboboxFields.forEach(infield => {
                        if (!infield.checkValidity()) {
                            infield.reportValidity();
                            isValidCombo = false;
                        }
                    });

                    if(!this.salutation) {
                        this.salutation = this.template.querySelector('[data-name="salutation"').value;
                    } 
                    if (!this.firstname) {
                        this.firstname = this.template.querySelector('[data-name="firstname"').value;
                    }
                    if (!this.lastname) {
                        this.lastname = this.template.querySelector('[data-name="lastname"').value;
                    }
                    if (!this.suffix) {
                        this.suffix = this.template.querySelector('[data-name="suffix"').value;
                    }
                    if (!this.designation) {
                        this.designation = this.template.querySelector('[data-name="designation"').value;
                    }
                    if (!this.speciality) {
                        this.speciality = this.template.querySelector('[data-name="speciality"').value;
                    }
                    */
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
                    console.log('this.eligibilityWrap-->',this.eligibilityWrap);
                    console.log(JSON.stringify(this.eligibilityWrap),'eligibilityWrap-->');
                    this.submitEligibilityMethod();

                } catch (error) {
                    console.log('Error in Handle Finish-->',{error});
                }
            }
        }, 300); 
    }

    submitEligibilityMethod() {
        saveEligibility({accountid: this.accrecordId,wrapData:JSON.stringify(this.eligibilityWrap) })
            .then((result) => {
                console.log('Result of submitEligibility--->',{result});
                if(result == 'Success') {
                    refreshApex(this.eligibilityRecord);
                    const clicknextpage = new CustomEvent("hideeligibilitypage", {
                        detail: false
                    });
                    this.dispatchEvent(clicknextpage); 
                }
            })
            .catch((error) => {
                console.log('Error of submitEligibility--->',{error});
            })
    }

    // Google analytics
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'account management',
                page_purpose: 'registration',
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
                sfmc_id: '',
                sfmc_audience: '',
                page_url: location.href,
                page_title: 'Self Registration',

            },
            bubbles: true,
            composed: true
        }));
    }
}