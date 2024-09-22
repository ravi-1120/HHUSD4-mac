({
	handleEdit : function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
    	urlEvent.setParams({
            "url": '/apex/MSD_Core_NewAddrWiz_VF?accId='+component.get("v.recordId")+'&accRecTypeId='+component.get("v.simpleRecord.RecordTypeId")
    });
    	urlEvent.fire();
	},
    addAddress : function(component, event, helper) {
        var action = component.get("c.addFields");
        console.log('calling.....'+ component.get('v.simpleRecord.RecordType.Name'));
            action.setParams({ "RTName" : component.get('v.simpleRecord.RecordType.Name')});
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log(response.getState());
                if (state === "SUCCESS") {
                    console.log(response.getReturnValue());
                    component.set("v.addFields", response.getReturnValue());

               }
            });
            $A.enqueueAction(action);
        var action1 = component.get("c.NAWAddFMap");
           action1.setParams({ "RTName" : component.get('v.simpleRecord.RecordType.Name')});
            action1.setCallback(this, function(response) {
                var state = response.getState();
                console.log(response.getState());
                if (state === "SUCCESS") {
                    console.log(response.getReturnValue());
                    component.set("v.NAWAddFMap", response.getReturnValue());

               }
            });
            $A.enqueueAction(action1);
        var action2 = component.get("c.Accdetails");
           action2.setParams({ "AccId" : component.get('v.recordId')});
            action2.setCallback(this, function(response) {
                var state = response.getState();
                console.log(response.getState());
                if (state === "SUCCESS") {
                    console.log(response.getReturnValue());
                    component.set("v.AccDetails", response.getReturnValue());

               }
            });
            $A.enqueueAction(action2);
                    component.set('v.showSpinner', false);
        var modal = component.find('addAddress');
        $A.util.toggleClass(modal, 'slds-hide');
	},
    
    closeModal : function(component, event, helper) {
        var modal = component.find('addAddress');
        $A.util.toggleClass(modal, 'slds-hide');
	},
    
    handleCloseEvent : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        var modal = component.find('addAddress');
        $A.util.toggleClass(modal, 'slds-hide');
	}
})