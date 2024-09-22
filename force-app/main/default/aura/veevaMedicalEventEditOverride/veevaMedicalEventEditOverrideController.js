/* eslint-disable */
({
    doInit: function(component, event, helper) {
        console.log(component);
        console.log(event);
        var action = component.get("c.getTargetRecordForMedicalEvent");
        action.setParams({
            "medicalEventId": component.get("v.recordId")
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