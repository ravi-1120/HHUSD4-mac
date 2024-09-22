({
	doInit : function(component, event, helper) {
        var action = component.get("c.getProdInfo");
        action.setParams({ "prodId" : component.get('v.recordId')});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.parentRT", response.getReturnValue().MSD_CORE_Adverse_Event__r.RecordType.Name);
                var fieldValue = response.getReturnValue().MSD_CORE_Related_to__c;
                if(helper.isNotBlank(fieldValue)){
                    if(fieldValue == 'AE'){
                        component.set("v.checkboxVal","AE");
                    }
                    if(fieldValue == 'PQC'){
                        component.set("v.checkboxVal","PQC");
                    }
                    if(fieldValue == 'AE and PQC'){
                        var chekedList = [];
                        chekedList.push('AE');
                        chekedList.push('PQC');
                        component.set("v.checkboxVal",chekedList);
                    }
                }
                component.set("v.showForm",true);
            }
        });
        $A.enqueueAction(action);
    },
    
    handleRecordUpdated : function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
            component.set("v.showForm", false);
            component.set("v.showForm", true);
        }
		/*
        if(eventParams.changeType === "LOADED") {
       		var fieldValue = component.get("v.simpleRecord.MSD_CORE_Related_to__c");
            if(helper.isNotBlank(fieldValue)){
                if(fieldValue == 'AE'){
                    component.set("v.checkboxVal","AE");
                    
                }
                if(fieldValue == 'PQC'){
                    component.set("v.checkboxVal","PQC");
                }
                if(fieldValue == 'AE and PQC'){
                    var chekedList = [];
                    chekedList.push('AE');
                    chekedList.push('PQC');
                    component.set("v.checkboxVal",chekedList);
                }
            }
            component.set("v.showForm",true);
        }*/        
	}
})