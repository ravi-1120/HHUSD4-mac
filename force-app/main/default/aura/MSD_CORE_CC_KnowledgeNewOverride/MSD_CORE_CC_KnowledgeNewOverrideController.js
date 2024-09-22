({
    doInit : function(component, event, helper) {        
        var action = component.get("c.fetchRecordTypeValues");
        action.setParams({'sObjectType' : 'Knowledge__kav'});
        action.setCallback(this, function(response) {
            var rts = [];
            var resp = response.getReturnValue();
            for(var key in resp){
                rts.push({label:resp[key], value:key});
            }
            component.set("v.lstRecordTypes", rts);
            var cmpTarget = component.find('recTypeSelector');
            $A.util.toggleClass(cmpTarget, 'slds-hide');
        });
        $A.enqueueAction(action);
        
        var pname = component.get('c.getProfileName');
        pname.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                var res = actionResult.getReturnValue();
                component.set('v.userProfileName', res);
            }
        });
        $A.enqueueAction(pname);        
    },
    
    closeModal : function(component, event, helper) { 
    	var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});            
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    createRecord : function(component, event, helper) { 
        var action = component.get("c.getTemplateValues");
        action.setParams({'rtId': component.get("v.selectedRTId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var cmpTarget = component.find('recTypeSelector');
        		$A.util.toggleClass(cmpTarget, 'slds-hide');
                var rec = response.getReturnValue();                
                
                var createRecordEvent = $A.get("e.force:createRecord");
                if(rec){  
                    rec.Id = null;
                    rec.RecordTypeId = component.get("v.selectedRTId");
                    createRecordEvent.setParams({
                        "entityApiName": "Knowledge__kav",
                        "defaultFieldValues": rec,
                        "recordTypeId" : component.get("v.selectedRTId")
                    });
                }
                else{
                    createRecordEvent.setParams({
                        "entityApiName": "Knowledge__kav",
                        "recordTypeId" : component.get("v.selectedRTId")
                    });
                }
                
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    setTimeout(function(){ 
                        workspaceAPI.closeTab({tabId: focusedTabId});
                    }, 100);                    
                   
                })
                .catch(function(error) {
                    console.log(error);
                });
                createRecordEvent.fire(); 
            }
        });
        $A.enqueueAction(action);
    },
    handlePicklistChange : function(component, event, helper) { 
        if(component.get("v.selectedRTId") != '')
        {
            component.set("v.disableNext", false); 
        }
        else{
            component.set("v.disableNext", true); 
        }
    }
})