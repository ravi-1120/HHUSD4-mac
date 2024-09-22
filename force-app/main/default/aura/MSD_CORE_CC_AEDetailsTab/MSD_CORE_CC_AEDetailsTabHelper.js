({
	helperInit : function(component, event, helper) {
		var action = component.get("c.queryCaseFields"); 
        action.setParams({
            'csId' : component.get("v.recordId")                
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                component.set('v.fielddata', data);
                
                if(data.length > 0){
                    component.set('v.sectionName', data[0].sectionName);
                    component.set('v.recordTypeId', data[0].cs.RecordTypeId);
                }
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
	}
})