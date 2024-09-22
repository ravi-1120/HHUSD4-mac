({
	doInit : function(component, event, helper) {
        try{
        component.set("v.showSpinner",true);   
        var action = component.get("c.getCustomerInfo");
        var picklist_fields = ["Address","Phone","Email","Fax"];
        var cmp_attributes = ["v.Address","v.Phone","v.Email","v.Fax"];	
        component.set('v.userProfileName', 'MSD_CORE Contact Center - Read Only User');
        action.setParams({ "csId" : component.get('v.recordId')});        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {     
                
                console.log('*** do init ***')
            	var res = response.getReturnValue();
                console.log('res.objCase -->'+JSON.stringify(res.objCase));
                component.set('v.caseRecord', res.objCase);
                console.log('options Map -- >'+JSON.stringify(res.optionsMap));
                var selectedAddId = res.objCase.Address_MVN__c;
                var selectedPhone = res.objCase.case_Account_Phone_MVN__c;
                var selectedEmail = res.objCase.case_Account_Email_MVN__c;
                var selectedFax = res.objCase.case_Account_Fax_MVN__c;
                component.set("v.casAccountId",res.objCase.AccountId);
                component.set("v.isReadOnlyUser",res.isReadOnlyUser);
                
                //var values = res.optionsMap();
                for(var k=0;k < picklist_fields.length;k++){	
                    var picklist_field_values = res.optionsMap[picklist_fields[k]];
                    var picklist_values=[];
                //    if(picklist_fields[k] != 'Address'){
                  //      picklist_values.push({value: '', label: 'Select'});
                   // }
                    picklist_values.push({value: '', label: 'Select'});
                    for(var key in picklist_field_values){
                        if((helper.isNotBlank(selectedAddId) && key == selectedAddId)||
                            (helper.isNotBlank(selectedPhone) && key == selectedPhone)||
                           (helper.isNotBlank(selectedEmail) && key == selectedEmail)||
                           (helper.isNotBlank(selectedFax) && key == selectedFax)
                          ){
                            console.log('picklist_fields[k] -->'+picklist_fields[k]);
                            if(picklist_fields[k] == 'Address'){
                                console.log('Address key -->'+key);
                                component.set("v.selectedAddressVal",key);
                            }
                            if(picklist_fields[k] == 'Phone'){
                                console.log('Phone key -->'+key);
                                component.set("v.selectedPhoneVal",key);
                            }
                            if(picklist_fields[k] == 'Fax'){
                                console.log('Fax key -->'+key);
                                component.set("v.selectedFaxVal",key);
                            }
                            if(picklist_fields[k] == 'Email'){
                                console.log('Email key -->'+key);
                                component.set("v.selectedEmailVal",key);
                            }
                            
                            picklist_values.push({value: key, label:picklist_field_values[key], selected:Boolean('TRUE')}); 
                        }
                        else{
                            picklist_values.push({value: key, label:picklist_field_values[key]}); 
                        }
                    	
                    }
                    if(picklist_fields[k] != 'Address'){
                        picklist_values.push({value: 'Change', label: 'Change'});
                    }
                    if(picklist_fields[k] == 'Address'){
                        picklist_values.push({value: 'New', label: 'New'});
                    }
                    component.set(cmp_attributes[k], picklist_values); 
                } 
                
            }
            else{
                component.set("v.showSpinner",false);
                //alert('ERROR');
            }
        });
        $A.enqueueAction(action);
        }
        catch(e){
            component.set("v.showSpinner",false);
        }
        
        try{
        action = component.get("c.queryCaseFields"); 
        action.setParams({
            'csId' : component.get("v.recordId")                
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                component.set("v.showSpinner",false);  
                var data = response.getReturnValue();
                if(data.length > 0){
                    component.set('v.casestatus', data[0].cs.Status);
                    component.set('v.userProfileName', data[0].user.Profile.Name);
                    
                }
            } else {
                console.log('An exception');
                component.set("v.showSpinner",false);
            }
        });
        $A.enqueueAction(action);
        }
        catch(e){
            component.set("v.showSpinner",false);
        }
	},
    
    navigateToRec : function(component, event, helper, recId){
    	var navigateToRec = $A.get("e.force:navigateToSObject");
        navigateToRec .setParams({
            "recordId": recId
            });
        navigateToRec.fire();
	},
    
    addressChange : function (component, evt, helper, addId) {
        //var addId = component.find('address').get('v.value');
        if(helper.isNotBlank(addId) && addId != 'New'){
            component.set("v.showSpinner",true); 
            var action = component.get('c.updateAddress');
            action.setParams({
                "caseId": component.get('v.recordId'),
                "addId": addId
            });
            action.setCallback(this, function(actionResult) {
                if(actionResult.getState() === "SUCCESS"){
                    helper.doInit(component, event, helper);
                    $A.get('e.force:refreshView').fire();
                    component.set("v.showSpinner",false); 
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    phoneChange : function (component, evt, helper) {
        var phoneVal = component.find('phone').get('v.value');
        if(helper.isNotBlank(phoneVal) && phoneVal != 'Change'){
            component.set("v.showSpinner",true); 
            var action = component.get('c.updatePhone');
            action.setParams({
                "caseId": component.get('v.recordId'),
                "accountPhoneText": phoneVal
            });
            action.setCallback(this, function(actionResult) {
                if(actionResult.getState() === "SUCCESS"){
                    $A.get('e.force:refreshView').fire();
                    component.set("v.showSpinner",false); 
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    emailChange : function (component, evt, helper) {
        var emailVal = component.find('email').get('v.value');
        if(helper.isNotBlank(emailVal) && emailVal != 'Change'){
            component.set("v.showSpinner",true); 
            var action = component.get('c.updateEmail');
            action.setParams({
                "caseId": component.get('v.recordId'),
                "emailText": emailVal
            });
            action.setCallback(this, function(actionResult) {
                if(actionResult.getState() === "SUCCESS"){
                    $A.get('e.force:refreshView').fire();
                    component.set("v.showSpinner",false); 
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    faxChange : function (component, evt, helper) {
        var faxVal = component.find('fax').get('v.value');
        if(helper.isNotBlank(faxVal) && faxVal != 'Change'){
            component.set("v.showSpinner",true); 
            var action = component.get('c.updateFax');
            action.setParams({
                "caseId": component.get('v.recordId'),
                "faxText": faxVal
            });
            action.setCallback(this, function(actionResult) {
                if(actionResult.getState() === "SUCCESS"){
                    $A.get('e.force:refreshView').fire();
                    component.set("v.showSpinner",false); 
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    newEmail : function (component, evt, helper) {
        var emailVal = component.get("v.newEmail");
        var action = component.get('c.createEmail');
        action.setParams({
            "caseId": component.get('v.recordId'),
            "email": emailVal
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state === "SUCCESS"){
                helper.doInit(component, event, helper);
                $A.get('e.force:refreshView').fire();
                component.set("v.showModal",false);
                //var emailLst = component.get("v.Email");
                //emailLst.push({value: emailVal, label:emailVal, selected:Boolean('TRUE')});
                //component.set("v.Email",emailLst);
                component.set("v.newEmail",'');
            }
            else if(state === "ERROR"){
                component.set("v.showModal",false);
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, event, helper, 'Error!', errors[0].message ,'error');
                    }
                }
            }
        });
        $A.enqueueAction(action);    
    },
    newPhone : function (component, evt, helper) {
        var phoneVal = component.get("v.newPhone");
        var action = component.get('c.createPhone');
        action.setParams({
            "caseId": component.get('v.recordId'),
            "phone": phoneVal
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state === "SUCCESS"){
                helper.doInit(component, event, helper);
                $A.get('e.force:refreshView').fire();
                component.set("v.showModal",false);
                //var phoneLst = component.get("v.Phone");
                //phoneLst.push({value: phoneVal, label:phoneVal, selected:Boolean('TRUE')});
                //component.set("v.Phone",phoneLst);
                component.get("v.newPhone");
            }
            else if(state === "ERROR"){
                component.set("v.showModal",false);
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, event, helper, 'Error!', errors[0].message ,'error');
                    }
                }
            }
        });
        $A.enqueueAction(action); 
    },
    newFax : function (component, evt, helper) {
        var faxVal = component.get("v.newFax");
        var action = component.get('c.createFax');
        action.setParams({
            "caseId": component.get('v.recordId'),
            "fax": faxVal
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state === "SUCCESS"){
                helper.doInit(component, event, helper);
                $A.get('e.force:refreshView').fire();
                component.set("v.showModal",false);
                //var faxLst = component.get("v.Fax");
                //faxLst.push({value: faxVal, label:faxVal, selected:Boolean('TRUE')});
                //component.set("v.Fax",faxLst);
                component.set("v.newFax",'');
            }
            else if(state === "ERROR"){
                component.set("v.showModal",false);
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, event, helper, 'Error!', errors[0].message ,'error');
                    }
                }
            }
        });
        $A.enqueueAction(action); 
    },
    
    newAddress : function (component, event, helper) {
        
    }

})