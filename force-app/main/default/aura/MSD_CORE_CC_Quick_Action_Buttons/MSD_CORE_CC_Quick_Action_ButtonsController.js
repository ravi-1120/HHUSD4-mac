//MSD_CORE_CC_Quick_Action_ButtonsController.js
//Created By: Kevin Brace
//Created Date: 7/29/2019
//Description: Controller JavaScript for the MSD_CORE_Quick_Action_Buttons.cmp Aura Lightning Component. 
//Change Log: 
//             KRB REL 19R4.0 7/29/2019 - Initial Version
    

({ 
    doInit : function(component, event, helper) {
        console.log(component.get("v.recordId"));
        var action = component.get('c.getCaseInfo');
        action.setParams({
            csId: component.get('v.recordId')
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                var res = actionResult.getReturnValue();
                //console.log('response for profile-->'+JSON.stringify(actionResult.getReturnValue()));
                component.set('v.userProfile', res.userProfile);
            }
        });
        $A.enqueueAction(action);
	},

    handleQuickActionMenuSelect: function (component, event, helper) {
       var selectedMenuItemValue = event.getParam("value");
       var recId = component.get("v.recordId");
       if(recId){ 
        
          if(selectedMenuItemValue == 'Rep_Follow_Up_Request'){
            
             var action = component.get("c.createRepFollowUpTask");
             action.setParams({ "caseId" : recId});
             action.setCallback(this, function(response) {
                
                var state = response.getState();
                
                if (state === "SUCCESS") {
                   var taskId = response.getReturnValue();
                    
                    if(taskId == 'Exception'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                           "title": "Error!",
                           "type": "error",
                           "message": "An exception has occured creating the Task Record."
                         });
                         toastEvent.fire();
                    } 
                    
                   var focusedTabId ='';
                   var workspaceAPI = component.find("workspace");
                   
                   workspaceAPI.getFocusedTabInfo().then(function(response) {
                      focusedTabId = response.tabId;
                   });
                    
                   workspaceAPI.openSubtab({
                      parentTabId: focusedTabId,
                      recordId: taskId,
                      focus: true
                   });
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": "An exception has occured."
                    });
                    toastEvent.fire();
                }

            });
           
            $A.enqueueAction(action);
         }
           
      }
      else{
             var toastEvent = $A.get("e.force:showToast");
             toastEvent.setParams({
                "title": "Error!",
                "type": "error",
                "message": "Select a Case Record First, then Request a Follow Up Task."
              });
              
              toastEvent.fire();
      }      
        
    },    
    
});