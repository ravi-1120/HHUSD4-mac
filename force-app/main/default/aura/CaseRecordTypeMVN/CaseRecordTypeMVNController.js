({
	doInit: function(component, event, helper) {
        var modal = component.find('searchFlashSection');
        $A.util.toggleClass(modal, 'slds-hide');
        setTimeout(function(){
    	    $A.util.toggleClass(component.find('searchChangeIt'), 'changeMe');
        }, 2000);
        
        helper.helperInit(component, event, helper);
         try{
         console.log(component.get("v.recordId"));
        var action = component.get('c.getCaseInfo');
        action.setParams({ "csId" : component.get('v.recordId')});
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
    },
    closeModal: function(component, event, helper) {
        var modal = component.find('searchFlashSection');
        $A.util.toggleClass(modal, 'slds-hide');
        $A.util.toggleClass(component.find('searchChangeIt'), 'changeMe');
    },
    showDisclaimer: function(component, event, helper) {
        var modal = component.find('recordTypeText');
        $A.util.toggleClass(modal, 'toggle');
    },
    aeChange: function(component, event, helper) {
        helper.aeChangeHelper(component, event, helper);
    },
    updateCase: function(component, event, helper) {
        helper.updateCaseHelper(component, event, helper);
    },
    handleSuccess: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    markRead: function(component, event, helper) {
        var action = component.get("c.markDisclaimerRead"); 
        action.setParams({
            'csId' : component.get("v.recordId")                
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var modal = component.find('searchFlashSection');
                $A.util.toggleClass(modal, 'slds-hide');
                $A.util.toggleClass(component.find('searchChangeIt'), 'changeMe');
                helper.helperInit(component, event, helper);
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
    },
    handleRefreshRecordTypeMVN: function(component, event, helper) {
        helper.helperInit(component, event, helper);
    }
})