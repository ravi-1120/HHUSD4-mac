({
	openTabWithSubtab : function(component, event, helper) {
        var focusedTabId ='';
        var workspaceAPI = component.find("workspace");
        	workspaceAPI.getFocusedTabInfo().then(function(response) {
            focusedTabId = response.tabId;
       });
            workspaceAPI.openSubtab({
                parentTabId: focusedTabId,
                recordId: '5000m000004hHiWAAU',
                focus: true
            });
	}
})