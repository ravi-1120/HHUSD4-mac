({
    doInit :  function(component, event, helper){
    	helper.doInit(component, event, helper);
    },
    
    handleUploadFinished : function(component, event, helper) {
        helper.showToast(component, event, helper, 'Success!', 'Upload Successful' ,'success');	
        helper.doInit(component, event, helper);
	
    },
    
    handleRedirect : function(component, event, helper){
        var recIds = [];
        var selectedItem = event.currentTarget;
        var recId= selectedItem.dataset.recordid;        
        recIds.push(recId);
        $A.get('e.lightning:openFiles').fire({
		    recordIds: recIds
		});
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
    }
})