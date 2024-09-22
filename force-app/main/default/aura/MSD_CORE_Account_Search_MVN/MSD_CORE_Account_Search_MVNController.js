({
    openSearchModal : function(component, event, helper) {
        component.set("v.showSearch", true);
        /*var modal = component.find('searchAccountModal');
        $A.util.removeClass(modal, 'slds-hide ');
        $A.util.addClass(modal, 'slds-show ');*/
	},
    
	closeModal : function(component, event, helper) {
        helper.checkAccAffiliation(component, event, helper);
    },
    
    cancelAffiliation: function(component, event, helper) {
         component.set("v.showAffiliationModal", false);
    },
    
    handleSubmit : function(component, event, helper) {
        event.preventDefault(); // stop form submission        
        var aff = component.get("v.affiliation");
        var eventFields = event.getParam("fields");
        eventFields["Child_Account_vod__c"] = aff.Child_Account_vod__c;
        eventFields["Parent_Account_vod__c"] = aff.Parent_Account_vod__c;
        eventFields["RecordTypeId"] = aff.RecordTypeId;
        component.find('affiliation').submit(eventFields);
    },
    
    handleSuccess : function(component, event, helper) {
        component.set("v.showAffiliationModal", false);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":"success",
            "title": "Success!",
            "message": "Affiliation added."
        });
        toastEvent.fire();
        
        if(component.get("v.destroyEdit")){
            component.destroy();
        }
    },
    handleError: function(component, event, helper) {
        
    },
    
})