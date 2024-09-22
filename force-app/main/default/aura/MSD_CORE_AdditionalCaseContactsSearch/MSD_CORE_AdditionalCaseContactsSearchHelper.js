({
	
    getFields : function(component, event, helper){
        return {
            Fields: [
                {placeholder:'First Name',fieldName:"First Name",value:''},
                {placeholder:'Last Name',fieldName:"Last Name",value:''}
                
             ],
            Address : [
                {placeholder:'Phone',fieldName:"Phone",value:''},
                {placeholder:'City',fieldName:"City",value:''},
                {placeholder:'Zip',fieldName:"Zip",value:''}
            ],
            RadioOptions : [
                {'label': 'All', 'value': 'All'},
                {'label': 'CONSUMER', 'value': 'CONSUMER'},
                {'label': 'EMPLOYEE', 'value': 'EMPLOYEE'},
                {'label': 'HEALTHCARE BUSINESS PROF', 'value': 'HEALTHCARE BUSINESS PROF'},
                {'label': 'INDIV HEALTHCARE PROF', 'value': 'INDIV HEALTHCARE PROF'}
            ]
         }
    },
    
    searchCaseContacts : function(component, event, helper){
        var fieldsToSearch = helper.getFieldsToSearch(component, event, helper);
        
        var action;
        if($A.util.isEmpty(fieldsToSearch)){
            helper.showToast(component, event, helper, 'Error', $A.get("$Label.c.MSD_CORE_AE_Contact_Search_Enter_Search_Criteria"), 'error');            
        }
        else{
        	if(fieldsToSearch.hasOwnProperty('Zip') || fieldsToSearch.hasOwnProperty('City')){
               action = component.get("c.runQueryOnAddressLtg");
            }
            else{
                console.log("KRB: Here 4");
                action = component.get("c.runQueryOnAccountLtg");
            }
            console.log("KRB: Here");
            
            if(action){
                console.log("KRB: Here 2");
                action.setParams({ JSONFields : JSON.stringify(fieldsToSearch),
                                  contType : component.get("v.selectedRadioOption")
                                });
                action.setCallback(this, function(response) {
                    const state = response.getState();
                    console.log('state -->'+state);
                    if (state === "SUCCESS") {
                        let resp = response.getReturnValue();
                        console.log('resp -->'+resp);
                        if(resp.length>0){
                            component.set("v.caseContacts",resp);
                        }
                        else{
                            helper.showToast(component,event,helper,'Error',$A.get("$Label.c.MSD_CORE_AE_Contact_Search_No_Records_Found"), 'error');
                            component.set("v.caseContacts",[]);
                        }
                    }
                });
                $A.enqueueAction(action);  
            }
        }
    },
    
    saveSelected : function(component, event, helper){
        var caseContacts = component.get("v.caseContacts");
        var caseConsToInsert = [];
        for(var i in caseContacts){
            if(caseContacts[i].include){
                caseConsToInsert.push(caseContacts[i]);
            }
        }
        if(caseConsToInsert.length > 0){
            const action = component.get("c.createCaseContacts");
            action.setParams({ selectedConsJSON : JSON.stringify(caseConsToInsert),
                              caseId : component.get("v.recordId")
            });
            action.setCallback(this, function(response) {
                const state = response.getState();
                if (state === "SUCCESS") {
                    let resp = response.getReturnValue();
                    if(resp == 'SUCCESS'){
                        $A.get('e.force:refreshView').fire();
                        component.set("v.caseContacts",[]);
                        component.set("v.fieldList",helper.getFields(component, event, helper));
                        helper.showToast(component, event, helper, 'Success', 'Records added successfully', 'success');
                    }
                    else if (resp.indexOf('EXCEPTION') > -1){
                        helper.showToast(component, event, helper, 'Error', resp.split('_')[1], 'error');
                    }
                }
            });
            $A.enqueueAction(action); 
        }
        else{
            helper.showToast(component, event, helper, 'Error', $A.get("$Label.c.MSD_CORE_AE_Contact_Search_Search_And_Select"), 'error');
        }
    },
    
    createNew : function(component, event, helper){
        var fieldsToSearch = helper.getFieldsToSearch(component, event, helper);
        if(fieldsToSearch.hasOwnProperty('Last Name')){
            const action = component.get("c.createNewLtg");
            action.setParams({ JSONFields : JSON.stringify(fieldsToSearch),
                              caseId : component.get("v.recordId")
            });
            action.setCallback(this, function(response) {
                const state = response.getState();
                if (state === "SUCCESS") {
                    let resp = response.getReturnValue();
                    if(resp != 'EXCEPTION'){
                        $A.get('e.force:refreshView').fire();
                        helper.showToast(component, event, helper, 'Success', 'Records created successfully', 'success');
                        /*var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                          "recordId": resp,
                          "slideDevName": "detail"
                        });
                        navEvt.fire();*/
                        component.getEvent("MSD_CORE_CC_CloseEvent").fire();

                    }
                    else{
                        helper.showToast(component, event, helper, 'Error', 'An exception has occured.', 'error');                    }
                }
            });
            $A.enqueueAction(action);
        }
        else{
            helper.showToast(component, event, helper, 'Error', $A.get("$Label.c.MSD_CORE_AE_Contact_Search_Required_Flds"), 'error');
        }
    },
    
    getFieldsToSearch : function(component, event, helper){
        var accSearchFields = component.get("v.fieldList").Fields;
        var addressSearchFields = component.get("v.fieldList").Address;
        var fieldsToSearch = {};
        for(var i in accSearchFields){
            if(helper.isNotBlank(accSearchFields[i].value)){
                fieldsToSearch[accSearchFields[i].fieldName] = accSearchFields[i].value;                
            }
        }
        
        for(var i in addressSearchFields){
            if(helper.isNotBlank(addressSearchFields[i].value)){
                fieldsToSearch[addressSearchFields[i].fieldName] = addressSearchFields[i].value;                
            }
        }
        return fieldsToSearch;
    }
})