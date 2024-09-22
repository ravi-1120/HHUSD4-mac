({
	closeModal : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        });
        //var cmpTarget = component.find('addCaseCon');
        //$A.util.toggleClass(cmpTarget, 'slds-hide');
	}
})