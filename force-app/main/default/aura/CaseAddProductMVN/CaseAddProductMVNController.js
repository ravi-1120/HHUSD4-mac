({
	handleLoad : function(component, event, helper) {
	component.set("v.showSpinner", false);
	},
    handleSubmit : function(component, event, helper) {
       //We don't need to put basic validation here as that are handle by lightning:inputfield and recordEditForm
       //event.preventDefault(); use this to stop default flow
    },
    handleSuccess : function(component, event, helper) {
	    
	//Redirect to detail page on success
	var payload = event.getParams().response;
        component.set("v.recId", payload.id);
        component.set("v.fileImport", true);
        component.set("v.disableField", true);
        
         var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "product has been created successfully."
        });
        toastEvent.fire();
         var url = window.location.href; 
            var value = url.substr(0,url.lastIndexOf('/') + 1);
            window.history.back();
            return false;
    }
})