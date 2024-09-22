({
	doInit : function(component, event, helper) {
        alert('in override cmp');
        /*
        var action = component.get("c.getParentCaseId");
        action.setParams({ "caseId" : component.get('v.recordId')});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var parentCaseId = response.getReturnValue();
                var workspaceAPI = component.find("workspace");
                if(parentCaseId){
                    workspaceAPI.openTab({
                        recordId: parentCaseId,
                        focus: true
                    }).then(function(response) {
                        workspaceAPI.openSubtab({
                            parentTabId: response,
                            recordId: component.get("v.recordId"),
                            focus: true
                        });
                    })
                    .catch(function(error) {
                        console.log(error);
                    });
                }
                else{
                    workspaceAPI.openTab({
                        recordId: component.get("v.recordId"),
                        focus: true
                    })
                    .catch(function(error) {
                        console.log(error);
                    });
                }
            }
        });
        $A.enqueueAction(action);*/
	}
})