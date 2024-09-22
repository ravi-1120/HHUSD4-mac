({
	doInit : function(component, event, helper) {
        var action = component.get("c.getCaseStatusPage");
        action.setParams({ "csId" : component.get('v.recordId')});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.cs", response.getReturnValue().objCase);
                component.set("v.isReadOnlyUser", response.getReturnValue().isReadOnlyUser);
            }
        });
        $A.enqueueAction(action);
	},
    
    updateCaseStatus : function(component, event, helper) {
        if(!component.get("v.isReadOnlyUser")){
            var status = event.target.id;
            var action = component.get("c.updateCaseStatus"); 
            action.setParams({
                'csId' : component.get("v.recordId"),
                'status' : status
            });
            action.setCallback(this, function(response) {
                var state = response.getReturnValue();
                if (state === "Success") {
                    $A.get('e.force:refreshView').fire(); 
                } 
                else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        message: state,
                        type : 'error'
                    });
                    toastEvent.fire();
                }
            });
            $A.enqueueAction(action);
        }
        else{
           	var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                message: 'You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.',
                type : 'error'
            });
            toastEvent.fire();
        }
             
	}
})