({
    doInit :  function(component, event, helper){        
        var action = component.get('c.getPublishstatus');
        action.setParams({"kId":component.get('v.recordId')});
        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS"){
                console.log("Publish status---->" + response.getReturnValue());
                var kRecord = response.getReturnValue();
                component.set("v.publishStatus",kRecord.PublishStatus);
                component.set("v.approvalStatus",kRecord.MSD_CORE_ApprStatus__c);
            }
        });
        $A.enqueueAction(action);
    },
    
    doSave: function(component, event, helper) {
        if (component.find("fileId").get("v.files").length > 0) {
            helper.uploadHelper(component, event);
        } else {
            alert('Please Select a Valid File');
        }
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    },
    
    gotoRelatedList : function(component, event, helper){
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            url: '/lightning/r/Case/'+component.get("v.recordId")+'/view',
            focus: true
        }).then(function(response) {
            workspaceAPI.openSubtab({
                parentTabId: response,
                url: '/lightning/r/'+component.get("v.recordId")+'/related/CombinedAttachments/view',
                focus: true
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    doAction : function(component, event, helper){
        component.set("v.attIdList", []);
        component.set("v.attachments", []);
    }, 
    
    doCancel: function(component, event, helper){
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
        var url = '/lightning/r/Knowledge__kav/'+component.get("v.recordId")+'/view';
        window.location.href = url ;
            }
    //CommentedLines
    
})