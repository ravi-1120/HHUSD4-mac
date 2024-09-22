({
	doInit : function(component, event, helper) {
        var action = component.get("c.checkProcessInstance"); 
        
        action.setParams({
            'targetObjectId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if(result)
                    component.set("v.isApplicable", true);
                else
                    component.set("v.isApplicable", false);
                component.set("v.showComponent", true);
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
    },
    close : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	},
    approve : function(component, event, helper) {
        var action = component.get("c.approveKnowledgeWithChanges"); 
        action.setParams({
            'targetObjectId' : component.get("v.recordId"),          
            'comments' : component.find('chkArchive').get("v.value"),
            'status' : 'Approved'
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var csrId = response.getReturnValue();
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "Article Approved."
                });
                toastEvent.fire();
                
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
	}
})