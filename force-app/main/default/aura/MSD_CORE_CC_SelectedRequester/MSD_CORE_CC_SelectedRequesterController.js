({
	doInit : function(component, event, helper) {
		helper.getPicklistValues(component, event, helper);
		component.set("v.fieldList",helper.getFields(component, event, helper));
	},
    
    openSearchModal : function(component, event, helper) {
        component.set("v.searchCriteria",component.get('v.fieldList'));
       console.log('criteria -->'+JSON.stringify(component.get('v.fieldList')));
        var modal = component.find('searchAccountModal');
        $A.util.toggleClass(modal, 'slds-hide');
	},
    
    closeModal : function(component, event, helper) {
        var modal = component.find('searchAccountModal');
        $A.util.toggleClass(modal, 'slds-hide');
	},
        
    clearSearch : function(component, event, helper) {
		 component.set("v.fieldList",helper.getFields(component, event, helper));
	},
    
    
})