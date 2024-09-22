({
	doInit : function(component, event, helper) {
        component.set("v.fieldList",helper.getFields(component, event, helper));
		var action = component.get("c.getRelatedListRecords");
        action.setParams({
            "caseId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.relatedRecords", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	},
    
    handleRedirect : function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var recId= selectedItem.dataset.recordid;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId
        });
        navEvt.fire();
    },
    
    menuAction : function(component, event, helper) {
    	var selectedMenuItemValue = event.getParam("value");
		if(selectedMenuItemValue == 'New'){
            var modal = component.find('newCaseContactSection');
        	$A.util.toggleClass(modal, 'slds-hide');
		}
        if(selectedMenuItemValue == 'Search'){
            var modal = component.find('addlCaseConsSection');
        	$A.util.toggleClass(modal, 'slds-hide');
		}
	},
    
    hideNew  : function(component, event, helper) {
    	var modal = component.find('newCaseContactSection');
        $A.util.toggleClass(modal, 'slds-hide');
    },
})