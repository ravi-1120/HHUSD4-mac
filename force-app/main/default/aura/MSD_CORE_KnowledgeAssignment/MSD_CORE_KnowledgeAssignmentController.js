({
	doInit : function(component, event, helper) {
        var action = component.get("c.articleActions");
        action.setParams({
            articleId : component.get('v.recordId'), 
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                var data = actionResult.getReturnValue();
                if(data)
                	$A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    }
})