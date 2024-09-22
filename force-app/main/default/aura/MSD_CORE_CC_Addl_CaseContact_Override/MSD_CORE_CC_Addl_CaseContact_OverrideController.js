({
	doInit : function(component, event, helper) {
        var currentURL = window.location.href;
        alert(currentURL);
        var fromIndex = currentURL.lastIndexOf('/Case/');
        var toIndex = currentURL.lastIndexOf('/view');
        /*
		var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": 'MSD_CORE_AE_Contact__c ',
            "defaultFieldValues": {
                'MSD_CORE_Adverse_Event__c' : '415-240-6590'
            },
            "recordTypeId" : response.getReturnValue()
        });
        createRecordEvent.fire();*/
	}
})