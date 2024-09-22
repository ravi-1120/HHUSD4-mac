({
    doInit : function(component, event, helper) {
        console.log(component.get("v.recordId"));
        component.set('v.userProfile', 'MSD_CORE Contact Center - PCC Agent');
        var action = component.get('c.getCaseInformation');
        action.setParams({
            csId: component.get('v.recordId')
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                var res = actionResult.getReturnValue();
                console.log('response -->'+JSON.stringify(actionResult.getReturnValue()));
                component.set('v.customer', res.objCase.AccountId);
                component.set('v.desc', res.objCase.MSD_CORE_AE_Description__c);
                component.set('v.userProfile', res.userProfile);
            }
        });
        $A.enqueueAction(action);
	},
    
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
            var interactionVal = component.get("v.simpleNewCase.Interaction_Notes_MVN__c");
            if(interactionVal){
                component.set("v.interactionLogVal",interactionVal);
                var len = interactionVal.length;
                component.set("v.remainingChars",(50 - len));
            }
        }
        else if (eventParams.changeType === "CHANGED") { 
          /* handle record change; reloadRecord will cause you to lose your current record, including any changes you’ve made */ 
          component.find("caseRecordCreator").reloadRecord();
        }
    },
    
    remainingChars : function(component, event, helper) {
        try{
            var len = component.get("v.interactionLogVal").length;
        	component.set("v.remainingChars",(50 - len));
            component.set("v.message",'Unsaved Data');
            component.set("v.needSaving",true);
        }
        catch(e){
            console.log(e);
        }
	},
    
    saveInteration : function(component, event, helper){
        var len = component.get("v.interactionLogVal").length;
        if(len > 0 && component.get("v.needSaving")){
            component.set("v.message",'Saving...');
            var objCase = component.get("v.simpleNewCase");
            console.log('objCase -->'+JSON.stringify(objCase));
            component.set("v.simpleNewCase.Interaction_Notes_MVN__c", component.get("v.interactionLogVal"));
                        
            //objCase.Interaction_Notes_MVN__c = component.get("v.interactionLogVal");
            component.find("caseRecordCreator").saveRecord(function(saveResult) {
                if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                    // record is saved successfully
                    component.set("v.message",'Saved');
                    component.set("v.needSaving",false);
                    var timezone = $A.get("$Locale.timezone");
                    console.log('Time Zone Preference in Salesforce ORG :'+timezone);
                    var mydate = new Date().toLocaleString("en-US", {timeZone: timezone})
                    console.log('Date Instance with Salesforce Locale timezone : '+mydate);
                    component.set("v.timeStamp",mydate);
                } else if (saveResult.state === "INCOMPLETE") {
                    // handle the incomplete state
                    console.log("User is offline, device doesn't support drafts.");
                } else if (saveResult.state === "ERROR") {
                    // handle the error state
                    console.log('Problem saving contact, error: ' + 
                                JSON.stringify(saveResult.error));
                } else {
                    console.log('Unknown problem, state: ' + saveResult.state +
                                ', error: ' + JSON.stringify(saveResult.error));
                }
            });
        }
    },
    
    handleClick : function(component, event, helper){
        console.log('Customer -->'+ component.get("v.customer"));
        var cust = component.get("v.customer");
        //if(cust){
            $A.util.removeClass(component.find("spinner"),"slds-hide");
            $A.util.addClass(component.find("spinner"),"slds-show");
            var reqType = event.currentTarget.getAttribute("data-attriVal");
            console.log(reqType);
            var objCase = component.get("v.simpleNewCase");
            console.log('objCase -->'+JSON.stringify(objCase));
            var action = component.get("c.createChildCaseFromInteractionLog");
            action.setParams({ "objCase" : objCase,
                              "requestType" : reqType,
                              "custId" : cust
                             });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    $A.get('e.force:refreshView').fire();
                    var caseId = response.getReturnValue();
                    console.log('Record Id created -- >'+caseId);
                    var focusedTabId ='';
                    var workspaceAPI = component.find("workspace");
                        workspaceAPI.getFocusedTabInfo().then(function(response) {
                        focusedTabId = response.tabId;
                    });
                    $A.util.removeClass(component.find("spinner"),"slds-show");
                    $A.util.addClass(component.find("spinner"),"slds-hide");
                    workspaceAPI.openSubtab({
                        parentTabId: focusedTabId,
                        recordId: caseId,
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
     	/*}
        else{
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "type": "error",
                "message": "Please select a Customer inorder to create a Child Case."
            });
            toastEvent.fire();
        }*/
    }                                                 
})