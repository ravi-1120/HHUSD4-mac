({
    removeItem: function(component, event, helper) {
        if(confirm("Are you sure you want to cancel case?")){    
			var action = component.get('c.updateStatus');
        	helper.updateCaseStatus(component, event, helper);
        }
    },
	updateStatus : function(component, event, helper) {
       helper.updateCaseStatus(component, event, helper);
             
	},
    doInit : function(component, event, helper) {
        helper.doInit(component, event, helper);
	}
})