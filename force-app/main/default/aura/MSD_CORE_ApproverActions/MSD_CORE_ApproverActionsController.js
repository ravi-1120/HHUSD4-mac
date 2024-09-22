({
	doInit : function(component, event, helper) {
        
    },
    close : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	},
    approve : function(component, event, helper) {
        var action = component.get("c.approveKnowledgeWithChanges"); 
        action.setParams({
            'targetObjectId' : component.get("v.recordId"),          
            'comments' : component.find('chkArchive').get("v.value"),
            'status' : 'Approved with Changes'
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