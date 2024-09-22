({
	doInit : function(component, event, helper) {
		var action = component.get("c.setDisclaimer"); 
        action.setParams({
            'csId' : component.get("v.recordId")                
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.disclaimer', response.getReturnValue());
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
	}
})