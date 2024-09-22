({
	doInit : function(component, event, helper) {
        helper.doInit(component, event, helper);
	},
    openSearchModal : function(component, event, helper) {
        var modal = component.find('searchAccountModal');
        $A.util.toggleClass(modal, 'slds-hide');
	},
	closeModal : function(component, event, helper) {
        var modal = component.find('searchAccountModal');
        $A.util.toggleClass(modal, 'slds-hide');
        
	},
    
    closeNewModal : function(component, event, helper){
        component.set("v.showModal", false);
        var type = component.get("v.infoType");        
    },
    
    recordUpdated : function(component, event, helper) {
        //helper.doInit(component, event, helper);
        /*var changeType = event.getParams().changeType;
        if (changeType === "CHANGED") { 
      		component.find("forceRecord").reloadRecord();
        }*/
    },
    
    refreshCmp : function(component, event, helper) {
        //setTimeout(function(){
        helper.doInit(component, event, helper);
        //}, 5000);   
        //$A.get('e.force:refreshView').fire();
	},
    
    refreshCmpCTI : function(component, event, helper) {
        console.log('refresh CTI cmp');
        setTimeout(function(){
            console.log('befor timeout init');
        	helper.doInit(component, event, helper);
            console.log('after timeout init');
        }, 5000);
        
        //$A.get('e.force:refreshView').fire();
	},
	
    editInfo :  function(component, event, helper){
        var container = component.find("accSearchContainer");
        $A.createComponent("c:MSD_CORE_Account_Search_MVN",
                           {"recordId": component.get('v.recordId'), "editInfo":true},
                           function(cmp) {
                               container.set("v.body", [cmp]);
                           });
    },
    
    removeCustomer : function(component, event, helper){
        var action = component.get('c.removeSelectedCustomer');
        action.setParams({
            caseId: component.get('v.recordId')
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                helper.doInit(component, event, helper);
                $A.get("e.c:MSD_CORE_CC_RefreshCustInfoCTI").fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
   
    removeReferredBy : function(component, event, helper){
        var action = component.get('c.removeSelectedReferredBy');
        action.setParams({
            caseId: component.get('v.recordId')
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                helper.doInit(component, event, helper);
                 $A.get("e.c:MSD_CORE_CC_RefreshCustInfoCTI").fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    removeBusiness : function(component, event, helper){
        var action = component.get('c.removeSelectedBusiness');
        action.setParams({
            caseId: component.get('v.recordId')
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                helper.doInit(component, event, helper);
                $A.get("e.c:MSD_CORE_CC_RefreshCustInfoCTI").fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    navigateToCust : function(component, event, helper, recId){
    	helper.navigateToRec(component, event, helper, component.get("v.caseRecord").AccountId);
	},
    
    navigateToRef : function(component, event, helper, recId){
    	helper.navigateToRec(component, event, helper, component.get("v.caseRecord").Referred_By_MVN__c);
	},
    
    navigateToBuss : function(component, event, helper, recId){
    	helper.navigateToRec(component, event, helper, component.get("v.caseRecord").MSD_CORE_Business__c);
	},
    
    toggleSection : function(component, event, helper) {
        // dynamically get aura:id name from 'data-auraId' attribute
        //var sectionAuraId = event.target.getAttribute("data-auraId");
        // get section Div element using aura:id
        var sectionDiv = component.find('reqSection').getElement();
        /* The search() method searches for 'slds-is-open' class, and returns the position of the match.
         * This method returns -1 if no match is found.
        */
        var sectionState = sectionDiv.getAttribute('class').search('slds-is-open'); 
        
        // -1 if 'slds-is-open' class is missing...then set 'slds-is-open' class else set slds-is-close class to element
        if(sectionState == -1){
            sectionDiv.setAttribute('class' , 'slds-section slds-is-open');
        }else{
            sectionDiv.setAttribute('class' , 'slds-section slds-is-close');
        }
    },
    
    addressChange : function (component, event, helper) {
        var addId = component.find('address').get('v.value');
        if(addId != 'New'){
            helper.addressChange(component, event, helper, addId);
        }
        else{
            var caseAccID = component.get("v.casAccountId");
            component.set("v.infoType", 'Address');
            component.set("v.showModal", true);
        }
    },
    
    phoneChange : function (component, event, helper) {
        var phoneVal = component.find('phone').get('v.value');
        if(phoneVal != 'Change'){
        	helper.phoneChange(component, event, helper);
        }
        else{
            component.set("v.infoType", 'Phone');
            component.set("v.showModal", true);
        }
    },
    
    emailChange : function (component, event, helper) {
        var emailVal = component.find('email').get('v.value');
        if(emailVal != 'Change'){
        	helper.emailChange(component, event, helper);
        }
        else{
            component.set("v.infoType", 'Email');
            component.set("v.showModal", true);
        }
    },
    
    faxChange : function (component, event, helper) {
        var faxVal = component.find('fax').get('v.value');
        if(faxVal != 'Change'){
        	helper.faxChange(component, event, helper);
        }
        else{
            component.set("v.infoType", 'Fax');
            component.set("v.showModal", true);
        }
    },
    
    handleSave :  function(component, event, helper){
        var type = component.get("v.infoType");
        var allValid = false;
        if(type != 'Address'){
            var inputCmp = component.find(type);
            inputCmp.showHelpMessageIfInvalid();
            allValid = inputCmp.get('v.validity').valid;
        }
        else{
            let failedFields = [];
            var fields = component.find("field");
        	/*for(let i in fields){
                if(!helper.isNotBlank(fields[i].get("v.value"))){
                    failedFields.push(fields[i].get("v.fieldName"));
                }
            }*/
            if(!helper.isNotBlank(failedFields)){
                allValid = true;
            }
       		
            /*allValid = component.find('field').reduce(function (validSoFar, inputCmp) {
                inputCmp.showHelpMessageIfInvalid();
                return validSoFar && inputCmp.get('v.validity').valid;
            }, true);*/
        }

        if (allValid) {
            if(type == 'Email'){
                helper.newEmail(component, event, helper);
            }
            if(type == 'Phone'){
                helper.newPhone(component, event, helper);
            }
            if(type == 'Fax'){
                helper.newFax(component, event, helper);
            }
            if(type == 'Address'){
                component.set('v.showSpinner',true);
                component.find("newAddressForm").submit();
            }
        } else {
            helper.showToast(component, event, helper, 'Error!', 'Please enter valid '+type ,'error');
        }
    },
    handleSubmit : function(component, event, helper){
    },
    handleSuccess : function(component, event, helper){
        component.set('v.showSpinner', false);
        component.set("v.showModal", false);
        var params = event.getParams();
        var newAddId = params.response.id;
        helper.addressChange(component, event, helper, newAddId);
        
        //helper.doInit(component, event, helper);
        $A.get('e.force:refreshView').fire();
        
    },
    hideAlertPopup : function(component, event, helper){
        component.set("v.showAlert", false);
    },
     handleError: function(component, event, helper) {
        // errors are handled by lightning:inputField and lightning:messages
        // so this just hides the spinner
        component.set('v.showSpinner', false);
    },
    queryZip : function(component, event, helper) {
        var zip = component.find('Zip_vod__c').get('v.value');
        
        if(zip.length >= 5){
            var action = component.get("c.queryZipCodes"); 
            action.setParams({
                'zip' : zip
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {                
                    component.set('v.zipcodeList', response.getReturnValue());
                    
                    if(response.getReturnValue().length > 1)
                        component.set('v.showAlert', true);
                    else if(response.getReturnValue().length == 1)
                    {
                        component.find('City_vod__c').set('v.value', response.getReturnValue()[0].pw_ccpro__City__c);
                        component.find('State_vod__c').set('v.value', response.getReturnValue()[0].pw_ccpro__State__r.Name);
                        component.find('Country_vod__c').set('v.value', response.getReturnValue()[0].pw_ccpro__State__r.pw_ccpro__Country__r.pw_ccpro__IsoCode_2__c);
                        component.set('v.showAlert', false);
                    }
                } else {
                    console.log('An exception');
                }
            });
            $A.enqueueAction(action);        
        }
    },
    fillAddressFields : function(component, event, helper) {
        var zip = event.currentTarget.id;
        var zipcodeList = component.get('v.zipcodeList');
        
        for(var i=0; i < zipcodeList.length; i++){
            if(zipcodeList[i].Id == zip){
                console.log(zipcodeList[i].pw_ccpro__State__r.pw_ccpro__Country__r.Name);
                component.find('City_vod__c').set('v.value', zipcodeList[i].pw_ccpro__City__c);
                component.find('State_vod__c').set('v.value', zipcodeList[i].pw_ccpro__State__r.Name);
                component.find('Country_vod__c').set('v.value', zipcodeList[i].pw_ccpro__State__r.pw_ccpro__Country__r.pw_ccpro__IsoCode_2__c);
                component.set('v.showAlert', false);
            }
        }  
    }
})