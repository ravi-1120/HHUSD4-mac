({
	doInit: function(component, event, helper) {
        component.find("caseRecordCreator").getNewRecord(
            "Case", // objectApiName
            null, // recordTypeId
            false, // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newCase");
                var error = component.get("v.newCaseError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                }
                else {
                    console.log("Record template initialized: " + rec.apiName);
                    helper.handleSaveCase(component, event, helper);
                }
            })
        );
    },

    
})