({
	doInit : function(component, event, helper) {
	},
    submitApproval: function(component,event,helper){
         var modal = component.find('submitApproval');
        $A.util.toggleClass(modal, 'slds-hide');
    },
     closeModal : function(component, event, helper) {
        var modal = component.find('submitApproval');
        $A.util.toggleClass(modal, 'slds-hide');
	},
    
    handleCloseEvent : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        var modal = component.find('submitApproval');
        $A.util.toggleClass(modal, 'slds-hide');
	}
})