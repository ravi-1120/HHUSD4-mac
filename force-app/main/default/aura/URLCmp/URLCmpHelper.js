({
    closeCase : function(component, event, helper) {
        console.log('in helper');
		
        component.set("v.simpleRecord.Patient_First_Name_MVN__c", 'First Name frm URL btn');
        component.find("recordEditor").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                helper.showToast(component, event, helper, 'Success', 'Save completed successfully', 'success');
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });
            } else if (saveResult.state === "INCOMPLETE") {
                alert("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                alert('Problem saving record, error: ' + 
                      JSON.stringify(saveResult.error));
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });
            } else {
                alert('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
	}
})