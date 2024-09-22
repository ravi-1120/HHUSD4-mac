({
	getCaseData : function(component, event, helper) {
		 var recordtypeId = component.get("v.recordId"); 
         var action = component.get("c.getCaseRecord");
        action.setParams({recordId : recordtypeId});
        action.setCallback(this,function(response){
            var state = response.getState();
             var stringItems1 = response.getReturnValue();
            if (state === "SUCCESS") {
                var stringItems = response.getReturnValue();
                console.log('DataFromApex'+JSON.stringify(stringItems));
            component.set("v.simpleNewCase", JSON.stringify(stringItems)); 
			/*component.set("v.simpleNewCase.MSD_CORE_Source_Code__c", JSON.stringify(stringItems).MSD_CORE_Source_Code__c);  
            component.set("v.simpleNewCase.MSD_CORE_Preferred_Language__c", JSON.stringify(stringItems).MSD_CORE_Preferred_Language__c);
            component.set("v.simpleNewCase.MSD_CORE_Campaign__c", JSON.stringify(stringItems).MSD_CORE_Campaign__c); 
            component.set("v.simpleNewCase.MSD_CORE_Source__c", JSON.stringify(stringItems).MSD_CORE_Source__c); 
            component.set("v.simpleNewCase.MSD_CORE_Source__c", JSON.stringify(stringItems).MSD_CORE_Source__c);  */  
           component.set("v.simpleNewCase.Interaction_Notes_MVN__c", component.get("v.descriptionVal"));
            component.set("v.simpleNewCase.MSD_CORE_AE_Description__c", component.get("v.descriptionVal"));
            component.set("v.simpleNewCase.MSD_CORE_Request_Description__c", component.get("v.descriptionVal"));
            component.set("v.simpleNewCase.Details_MVN__c", component.get("v.descriptionVal"));
            component.set("v.isReadOnlyUser", response.getReturnValue().isReadOnlyUser);
            }
            component.find("caseRecordCreator").saveRecord(function(saveResult) {
                if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                   console.log('saveResult -->'+JSON.stringify(saveResult)); 
                    // record is saved successfully
                    component.set("v.message",'Saved');
                    component.set("v.needSaving",false);
                    var timezone = $A.get("$Locale.timezone");
                    console.log('Time Zone Preference in Salesforce ORG :'+timezone);
                    var mydate = new Date().toLocaleString("en-US", {timeZone: timezone})
                    console.log('Date Instance with Salesforce Locale timezone : '+mydate);
                    component.set("v.timeStamp",mydate);
                }
                 });
        });
        $A.enqueueAction(action);
        	},
   /* loadData: function(component, event, helper) {
    }  */  
         updateCaseDescription : function(component, event, helper){
        var action = component.get('c.updateCaseDesc');
        action.setParams({
            "caseId": component.get("v.recordId"),
            "descVal": component.get("v.descriptionVal")
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state === "SUCCESS"){
                console.log('success all');
            }
        });
        $A.enqueueAction(action);
    }
})