({
	doInit : function(component, event, helper) {
		 component.set("v.fieldList",helper.getFields(component, event, helper));
	},
    
    searchCaseContacts : function(component, event, helper) {
        var modal = component.find('addlCaseConsSection');
        $A.util.toggleClass(modal, 'slds-hide');
        var container = component.find("addlCaseContactsSearchModal");
        $A.createComponent("c:MSD_CORE_AdditionalCaseContactsSearch",
                           {"fieldList": component.get('v.fieldList'),"recordId":component.get('v.recordId')},
                           function(cmp) {
                               container.set("v.body", [cmp]);
                           });
	},
    
    closeModal : function(component, event, helper) {
        var modal = component.find('addlCaseConsSection');
        $A.util.toggleClass(modal, 'slds-hide');
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
                    if(resp == 'SUCCESS'){
                        helper.showToast(component, event, helper, 'Success', 'Records created successfully', 'success');
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                          "recordId": resp,
                          "slideDevName": "detail"
                        });
                        navEvt.fire();
                    }
                    else if (resp.indexOf('EXCEPTION') > -1){
                        helper.showToast(component, event, helper, 'Error', resp.split('_')[1], 'error');
                    }
                }
            });
            $A.enqueueAction(action);
        }
        else{
            helper.showToast(component, event, helper, 'Error', $A.get("$Label.c.MSD_CORE_AE_Contact_Search_Required_Flds"), 'error');
        }
    },
})