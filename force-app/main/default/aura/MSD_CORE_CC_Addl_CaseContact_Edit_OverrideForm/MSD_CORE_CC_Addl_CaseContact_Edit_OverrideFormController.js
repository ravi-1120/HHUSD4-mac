({
	handleLoad: function(component, event, helper) {
    },
    
    handleSave: function(component, event, helper) {
        component.set("v.showSpinner", true);
        component.set("v.buttonClicked",'Save');
    },
    
    handleSaveNew: function(component, event, helper) {
        component.set("v.showSpinner", true);
        component.set("v.buttonClicked",'SaveNew');
    },
    
    handleSubmit: function(component, event, helper) {
       
    },
    
    handleError: function(component, event, helper) {
    },
    
    
    handleSuccess: function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            if(component.get("v.buttonClicked") == 'SaveNew'){
                /*setTimeout(function(){ 
                    var workspaceAPI = component.find("workspace");
                    workspaceAPI.closeTab({tabId: focusedTabId});
                }, 2000);*/
                
                var parentId = component.get('v.parentId');
                var action = component.get('c.getRecordType');
                action.setParams({
                    csId: parentId
                });
                action.setCallback(this, function(actionResult) {
                    if(actionResult.getState() === "SUCCESS"){
                        var recTypeId = actionResult.getReturnValue();
                        component.set("v.recTypeId",recTypeId);
                        component.set("v.recordId","");
                        component.set("v.showSpinner", false);
                        component.set("v.reloadForm",false);
                        component.set("v.reloadForm",true);
                    }
                });
                $A.enqueueAction(action);
            }
            else{
                component.set("v.showSpinner", false);
                workspaceAPI.closeTab({tabId: focusedTabId});
                //alert('close');
            }            
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    closeFocusedTab: function(component, event, helper) {
        
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    handleKeyPress : function(component, event, helper){
        if (event.keyCode == 13){
            component.set("v.showSpinner", true);
            component.set("v.buttonClicked",'Save');
        }
    },
   
    handlePicklistChange: function(component, event, helper) {
        const selectedValue = component.get("v.selectedValue");
        component.set("v.showTextField", selectedValue === "Employee");
    }
})