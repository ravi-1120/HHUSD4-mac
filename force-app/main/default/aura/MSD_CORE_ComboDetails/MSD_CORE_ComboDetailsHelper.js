({
	helperInit : function(component, event, helper) {
        try{
            var action = component.get("c.queryCaseFields"); 
            action.setParams({
                'csId' : component.get("v.recordId")                
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var data = response.getReturnValue();
                    component.set('v.fielddata', data);
                    if(data.length > 0){
                        component.set('v.sectionName', data[0].sectionName);
                        component.set('v.recordTypeId', data[0].cs.RecordTypeId);
                        component.set('v.casestatus', data[0].cs.Status);
                        component.set('v.userProfileName', data[0].user.Profile.Name);
                       console.log('User Profile'+data[0].user.Profile.Name);
                        component.set('v.reloadForm', true);
                        if(data[0].cs.RecordType.Name.indexOf('Product Complaint') != -1)
                            component.set('v.selTabId', 'PQC Details');
                    }
                } else {
                    console.log('An exception');
                }
            });
            $A.enqueueAction(action);
        }
        catch(e){}
	},
    refreshFocusedTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.refreshTab({
                      tabId: focusedTabId,
                      includeAllSubtabs: true
             });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    setTabClosable : function(component, event, helper, closable) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.disableTabClose({
                tabId: focusedTabId,
                disabled: true,
                closeable:closable
                
            })
            .then(function(tabInfo) {
                console.log(tabInfo);
            })
            .catch(function(error) {
                console.log(error);
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
})