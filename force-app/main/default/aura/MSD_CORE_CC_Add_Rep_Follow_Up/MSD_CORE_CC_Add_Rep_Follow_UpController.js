({
	myAction : function(component, event, helper) {
	},
    
    handleQuickActionMenuSelect: function (component, event, helper) {
       var recId = component.get("v.recordId");
       if(recId){ 
             var action = component.get("c.createRepFollowUpTask");
             action.setParams({ "caseId" : recId});
             action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                   var taskId = response.getReturnValue();
                    if(taskId == 'Exception'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                           "title": "Error!",
                           "type": "error",
                           "message": "An exception has occured creating the Task Record."
                         });
                         toastEvent.fire();
                    } 
                    
                   var focusedTabId ='';
                   var workspaceAPI = component.find("workspace");
                   workspaceAPI.getFocusedTabInfo().then(function(response) {
                      focusedTabId = response.tabId;
                   });
                    
                   workspaceAPI.openSubtab({
                      parentTabId: focusedTabId,
                      recordId: taskId,
                      focus: true
                   });
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": "An exception has occured."
                    });
                    toastEvent.fire();
                }
            });
         $A.enqueueAction(action);
         }     
    },   
})