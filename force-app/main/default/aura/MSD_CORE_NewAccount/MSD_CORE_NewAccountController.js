({
    doInit: function(component, event, helper) {
        helper.helperInit(component, event, helper);
    },
    handleTradeChange : function(component, event, helper) {
        var classOfTrade = component.get("v.classOfTrade");
        if(classOfTrade == 'EMPLOYEE')
        {
            setTimeout(function(){
                //component.find('MSD_CORE_Employee_Company__c').set("v.value", "");
                //component.find('MSD_CORE_Employee_Alias__c').set("v.value", "");
                //component.find('MSD_CORE_Merck_Employee_ID__c').set("v.value", "");
            }, 1000);
        }
        component.set("v.showSearch", true);
	},
	openModal : function(component, event, helper) {
        component.set("v.showSearch", true);
	},
    hideAlertPopup : function(component, event, helper){
        component.set("v.showAlert", false);
    },
    formPress : function(component, event, helper) {
        console.log('Event code----->>'+event.keyCode);
        if (event.keyCode === 13){
            var saveRec = component.get('c.saveRecords');
        	$A.enqueueAction(saveRec);
        	//controller.saveRecords(component, event, helper);
        	//component.saveRecords(component, event, helper);
        }
            
    },
	closeModal : function(component, event, helper) {
        /*var fieldValue = component.get('v.classOfTrade');
        if(fieldValue.toLowerCase().indexOf(prescriberType.toLowerCase()) != -1)
        {
            if(component.find('IMS_Specialty_MRK__c') != undefined)
                component.find('IMS_Specialty_MRK__c').set("v.value", "");
            if(component.find('IMS_Sub_Specialty_MRK__c') != undefined)
                component.find('IMS_Sub_Specialty_MRK__c').set("v.value", "");
        }
        if(fieldValue.indexOf('INDIV HEALTHCARE PROF') != -1){
            if(component.find('License_vod__c') != undefined)
                component.find('License_vod__c').set("v.value", "");
            if(component.find('Credentials_vod__c') != undefined)
                component.find('Credentials_vod__c').set("v.value", "");
        }*/
        component.set("v.showSearch", false);
    },
    cltypeSelected : function(component, event, helper) {
        helper.helperTypeSelected(component, event, helper);
    },
    cltypeSelected2 : function(component, event, helper) {
        component.set("v.showSpinner", true); 
        helper.helperTypeSelected(component, event, helper);
    },
    callClosePopupEvent : function(component, event, helper) {
        var compEvent = component.getEvent("MSD_CORE_CloseModal");
        compEvent.fire();
    },
    saveRecords : function(component, event, helper) {   
        //var recordUi = event.getParam("recordUi");
        
        let failedValidationFields = helper.isFormValid(component, event, helper);
        
       	if(!failedValidationFields){
            
            component.set('v.showSpinner', true); 
            var isPersonSearch = component.get("v.isPersonSearch");
            if(isPersonSearch){
                component.find("First_Name_MRK__c").set("v.value", component.find("Preferred_First_Name_MRK__c").get("v.value"));
                component.find("Last_Name_MRK__c").set("v.value", component.find("Preferred_Last_Name_MRK__c").get("v.value"));
            }
            else{
                component.find("Name_MRK__c").set("v.value", component.find("Preferred_Full_Name_MRK__c").get("v.value"));
            }
            if(component.get("v.settings").MSD_CORE_Active_Person_Types__c.indexOf(component.find("classOfTrade").get("v.value")) != -1)
            	component.find("Status_MRK__c").set("v.value", component.get("v.settings").MSD_CORE_Account_Status_Active__c);    
            
            component.find('recordViewForm').submit();
        }
        else{
            event.preventDefault();
            /*var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Form Incomplete!",
                "type": "error",
                "message": "Please enter all required fields"
            });
            toastEvent.fire();*/
        }
    },
    handleSubmit: function(component, event, helper) {
        event.preventDefault();       // stop the form from submitting
        var fields = event.getParam('fields');
        console.log(fields);
        fields.Street = '32 Prince Street';
        //component.find('myRecordForm').submit(fields);
    },
    handleError: function(component, event, helper) {
        // errors are handled by lightning:inputField and lightning:messages
        // so this just hides the spinner
        component.set('v.showSpinner', false);
    },
    saveAddress : function(component, event, helper) {
        var account = event.getParams().response;
        component.find('Account_vod__c').set("v.value", account.id);
        if((component.find("Name") != undefined && component.find("Name").get("v.value") != null && component.find("Name").get("v.value").trim() != '' ) ||
           (component.find("Address_line_2_vod__c") != undefined && component.find("Address_line_2_vod__c").get("v.value") != null && component.find("Address_line_2_vod__c").get("v.value").trim() != '' ) ||
           (component.find("City_vod__c") != undefined && component.find("City_vod__c").get("v.value") != null && component.find("City_vod__c").get("v.value").trim() != '' ) ||
           (component.find("State_vod__c") != undefined && component.find("State_vod__c").get("v.value") != null && component.find("State_vod__c").get("v.value").trim() != '' ) ||
           (component.find("Zip_vod__c") != undefined && component.find("Zip_vod__c").get("v.value") != null && component.find("Zip_vod__c").get("v.value").trim() != '' ))
        {
            component.find('addressViewForm').submit();      
            
            var compEvent = component.getEvent("MSD_CORE_CloseModal");
            compEvent.fire();
            component.set('v.showSpinner', false);
        }
        else{
            
            var action = component.get("c.updateCaseWithAccount"); 
            action.setParams({
                'csId' : component.get('v.recordId'),
                'accountId' : component.find('Account_vod__c').get("v.value"),
                'adressId' : '',
                'type' : component.get('v.whichOne')
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {        
                    var compEvent = component.getEvent("MSD_CORE_CloseModal");
                    compEvent.fire();
                    component.set('v.showSpinner', false);
                } else {
                    console.log('An exception');
                }
            });
            $A.enqueueAction(action);
        }
    },
    successAddress : function(component, event, helper) {
        var adress = event.getParams().response;
        var action = component.get("c.updateCaseWithAccount"); 
        action.setParams({
            'csId' : component.get('v.recordId'),
            'accountId' : component.find('Account_vod__c').get("v.value"),
            'adressId' : adress.id,
            'type' : component.get('v.whichOne')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {        
                var compEvent = component.getEvent("MSD_CORE_CloseModal");
                compEvent.fire();
                component.set('v.showSpinner', false);
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
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