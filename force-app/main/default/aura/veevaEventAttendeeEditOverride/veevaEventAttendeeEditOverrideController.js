/* eslint-disable */
({
    doInit: function(component, event, helper) {
        var action = component.get("c.getTargetRecordForEventAttendee");
        action.setParams({
            "eventAttendeeId": component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.setNewPageProperties(component, response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    onPageReferenceChange: function(component, event, helper) {
        if (Number.parseInt(component.get("v.pageReference").state.count) > 1) {
            $A.get("e.force:refreshView").fire();
        }
        const pageRef = component.get('v.pageReference');
        const navService = component.find("navService");
        navService.navigate(pageRef);
    },
})