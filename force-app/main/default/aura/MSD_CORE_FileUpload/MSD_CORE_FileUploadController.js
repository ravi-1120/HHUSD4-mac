({
    doInit :  function(component, event, helper){
        try{
            component.set('v.hosturl', window.location.hostname);
            var action = component.get('c.getCaseInfo');
            action.setCallback(this, function(actionResult) {
                if(actionResult.getState() === "SUCCESS"){
                    var res = actionResult.getReturnValue();
                    console.log('response for profile-->'+JSON.stringify(res));
                    component.set('v.userProfile', res.userProfile);
                }
            });
            $A.enqueueAction(action);
        }
        catch(e){
            console.log('exception-->' , e)
        }
        if(!component.get("v.vfHosturl"))
        	helper.getVfHostUrl(component);
        var showAsTable = component.get("v.showAsTable");
        
        window.addEventListener("message", $A.getCallback(function(event) {
            //Ramesh: 06/15/2020 - Updated this message handler to receive messages only from VF host
            var vfOrigin =  component.get("v.vfHosturl");
            if(event.data.name =="com.merck.fileupload")
            {
            	helper.doInit(component, event, helper);
            }
            //if(event.origin !== vfOrigin ){return;}
            //if(event.data.name =="com.merck.fileupload")
            //	$A.get('e.force:refreshView').fire(); //Commented this line as it is causing performance issues.
            //	helper.doInit(component, event, helper); //added this line to refresh the attachment list.
        }), false);
        
        if(showAsTable == false)
            helper.doInit(component, event, helper);
    },
    
    doSave: function(component, event, helper) {
        if (component.find("fileId").get("v.files").length > 0) {
            helper.uploadHelper(component, event);
        } else {
            alert('Please Select a Valid File');
        }
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
    deleteAttachment : function(component, event, helper){
        var id = event.currentTarget.dataset.id;
        if(confirm('Are you sure to delete this attachment?')){
            var action = component.get('c.deleteAttachmentAura');
            action.setParams({
                attachmentId: id
            });
            action.setCallback(this, function(actionResult) {
                if(actionResult.getState() === "SUCCESS"){
                    helper.doInit(component, event, helper);
                    $A.get('e.force:refreshView').fire();
                } else if (actionResult.getState() === "ERROR") {
                    var errors = actionResult.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type": "error",
                                "message": errors[0].message
                            });
                            toastEvent.fire();
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
        }
    }
})