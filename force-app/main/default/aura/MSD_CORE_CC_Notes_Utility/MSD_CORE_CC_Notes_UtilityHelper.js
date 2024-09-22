({
	doInit : function(component, event, helper) {
        try{
            var recId = component.get("v.recordId");
            if(recId.startsWith('500')){
                component.set("v.isCaseRecord", true);
                var action = component.get("c.getCaseInfo");
                action.setParams({ "caseId" : component.get('v.recordId')});
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var res = response.getReturnValue();
                        component.set("v.lstNotes", res.lstNotes);
                        component.set('v.userProfile', res.userProfile);
                        component.set("v.restrictNew", res.restrictNew);
                    }
                });
                $A.enqueueAction(action);
            }
            else{
                component.set("v.isCaseRecord", false);
            }
        }
        catch(e){}
	},
    
    
})