({
	searchCaseContacts : function(component, event, helper) {
        var modal = component.find('addlCaseConsSection');
        $A.util.toggleClass(modal, 'slds-hide');
        
        var container = component.find("addlCaseContactsSearchModal");
        $A.createComponent("c:MSD_CORE_AdditionalCaseContactsSearch",
                           {"recordId":component.get('v.recordId')},
                           function(cmp) {
                               container.set("v.body", [cmp]);
                           });
	},
    
    closeModal : function(component, event, helper) {
        var modal = component.find('addlCaseConsSection');
        $A.util.toggleClass(modal, 'slds-hide');
	},
})