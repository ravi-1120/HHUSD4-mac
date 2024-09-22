({
    doInit: function(component, event, helper) {
    },
	openModal : function(component, event, helper) {
        var object = component.get("v.objCase");
        var campaign = object['MSD_CORE_Campaign__c'];
        var product  = object['Product_MVN__c'];
        var workspaceAPI = component.find("workspace");
        var recordId = component.get("v.recordId");
        var tabs = workspaceAPI.getFocusedTabInfo();
        console.log(tabs);
        workspaceAPI.openTab({
            url: '/flow/MSD_CORE_PCC_Fulfillment?varCaseRecordID='+recordId+'&retURL='+recordId,
            focus: true
        });
        //component.set("v.showPopup", true);
},
    closeModal : function(component, event, helper) {
        component.set("v.showPopup", false);
    }
})