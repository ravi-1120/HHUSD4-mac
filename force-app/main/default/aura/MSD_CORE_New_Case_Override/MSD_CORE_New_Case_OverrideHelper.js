({
	handleSaveCase: function(component, event, helper) {
    	component.set("v.simpleNewCase.Origin", 'Phone');
        component.set("v.simpleNewCase.Status", 'Open');
        component.find("caseRecordCreator").saveRecord(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                    if(saveResult.recordId){
                        setTimeout(function(){ 
                             workspaceAPI.openTab({
                                    recordId: saveResult.recordId,
                                    focus: true
                                });
                        }, 1);
                    }
                })
                .catch(function(error) {
                    console.log(error);
                });
                /*
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": ,
                    "slideDevName": "detail"
                });
                navEvt.fire(); */
            }
        });
    },
})