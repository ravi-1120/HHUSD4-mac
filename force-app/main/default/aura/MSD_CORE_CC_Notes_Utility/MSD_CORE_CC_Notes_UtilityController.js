({
    doInit : function(component, event, helper) {
        component.set('v.userProfile', 'MSD_CORE Contact Center - Read Only User');
        helper.doInit(component, event, helper);
    },
    
    onRecordIdChange : function(component, event, helper) {
        try{
            var recId = component.get("v.recordId");
            if(recId.startsWith('500')){
                component.set("v.isCaseRecord", true);
                 helper.doInit(component, event, helper);
                var action2 = component.get('c.getCaseRT');
                action2.setParams({
                    'csId' : recId               
                });
                action2.setCallback(this, function(actionResult) {
                    if(actionResult.getState() === "SUCCESS"){
                        var res = actionResult.getReturnValue();
                        if (res=='Interaction'||res =='Interaction - Closed')
                            component.set('v.Rtname', false);
                        else
                            component.set('v.Rtname', true);
                    }
                });
                $A.enqueueAction(action2);
                
            }
            else{
                component.set("v.isCaseRecord", false);
                var utilityAPI = component.find("utilitybar");
                utilityAPI.getAllUtilityInfo().then(function(response) {
                    for(var i=0 ; i < response.length ; i++){
                        if (response[i].utilityLabel.includes('Notes')) {
                            utilityAPI.setUtilityLabel({
                                label: "Notes (N/A)"
                            });
                        }
                    }
                })
            }
        }
        catch(e){}
    },
    
    newNote : function(component, event, helper) {
        var modalBody;
        $A.createComponent("c:MSD_CORE_CC_New_Note", {caseId : component.get("v.recordId")},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "New Note",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       cssClass: "mymodal",
                                       closeCallback: function() {
                                           helper.doInit(component, event, helper);
                                       }
                                   })
                               }                               
                           });
    },
    
    handleRedirect : function(component, event, helper) {
        var target = event.target;  
        var recId = target.getAttribute("data-recId");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId
        });
        navEvt.fire();
    },
    
    closeModal : function(component, event, helper){
        var modal = component.find('newNote');
        $A.util.toggleClass(modal, 'slds-hide');
    }
})