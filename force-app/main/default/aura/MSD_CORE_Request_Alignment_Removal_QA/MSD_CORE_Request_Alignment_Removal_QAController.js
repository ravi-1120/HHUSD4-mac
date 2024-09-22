({
	doInit : function(component, event, helper) {
        
    },
    close : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	},
    processRemoval : function(component, event, helper) {
              
        var action = component.get("c.processAlignmentRemoval"); 
        action.setParams({
            'accountId'    : component.get("v.recordId"),
            'removalReason': component.get("v.removalReason")
        });
                
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //var retValue =  response.getReturnValue();
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "Alignment removal request has been submitted."
                });
                toastEvent.fire();
                
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
                
            } else if (state === "ERROR") {
        		
                let errors = response.getError();
                let message = 'Unknown error'; // Default error message
				
                // Retrieve the error message sent by the server
				if (errors && Array.isArray(errors) && errors.length > 0) {
    				message = errors[0].message;
				}
				// Display the message - Note using the .error function for the console!
                console.error(message);
                
                //Pass the Errors to the Helper Method to display on the UI to the User.
                helper.handleErrors(errors);
                $A.get("e.force:closeQuickAction").fire();
            }else if (state === "INCOMPLETE"){
                console.error('No response from server or client is offline.');
            }
    		else {
        		// Handle other reponse states
        		console.error('unexpected error.');
    		}
        });
        $A.enqueueAction(action);            
	}
})