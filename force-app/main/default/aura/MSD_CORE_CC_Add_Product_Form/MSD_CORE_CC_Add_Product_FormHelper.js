({
	isFormValid: function(component, event, helper){
        let failedFields = [];
        let fields = component.find("required");
        for(let i in fields){
            if(helper.isNotBlank(fields[i]) && typeof fields[i] === "object"){
                if(!helper.isNotBlank(fields[i].get("v.value"))){
                    failedFields.push(" "+fields[i]["fieldLabel"]);
                }
            }
        }
        return helper.isNotBlank(failedFields);
    },
    
    closeEditTab : function(component, event, helper){
        var workspaceAPI = component.find("workspace1");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        });
    }
})