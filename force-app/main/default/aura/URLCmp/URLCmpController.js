({
    init: function(component, event, helper) {
        var myPageRef = component.get("v.pageReference");
        var caseId = myPageRef.state.c__caseId;
        component.set("v.caseId", caseId);
        component.find('recordEditor').reloadRecord(true);
        console.log('before helper call');
        
        setTimeout(function(){ helper.closeCase(component, event, helper); }, 1000);
        
        /*
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            console.log('Tab Id -->'+response.tabId);
            console.log('Parent Tab Id -->'+response.parentTabId);
        })
        .catch(function(error) {
            console.log(error);
        });*/        
    },
    
    closeFocusedTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            console.log('Tab Id -->'+response.tabId);
            console.log('Parent Tab Id -->'+response.parentTabId);
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    handleSaveContact : function(component, event, helper) {
        component.set("v.simpleRecord.Patient_First_Name_MVN__c", 'fName3');
        component.find("recordEditor").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                alert("Save completed successfully.");
            } else if (saveResult.state === "INCOMPLETE") {
                alert("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                alert('Problem saving record, error: ' + 
                      JSON.stringify(saveResult.error));
            } else {
                alert('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
    },
    
     
})