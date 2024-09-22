({
       doInit : function(component, event, helper) {
         console.log("entered")
    	var action = component.get("c.getDescInfo");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.isSearchDisabled",response.getReturnValue().isSearchDisabled);
                var storeResponse = response.getReturnValue().isReadOnly;
				component.set("v.hideDSCheckbox",response.getReturnValue().hideDSCheckbox);
                
                if(storeResponse){
                    component.set("v.descDisabled",true);
                    component.set("v.isReadOnlyUser",true);
            }
                else{
                    component.set("v.isReadOnlyUser",false);
                }
            }
        });
        $A.enqueueAction(action);
}, 
    handleRecordUpdatedread: function(component, event, helper){
        
    },
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED" ) {
            var caseStatus = component.get("v.simpleNewCase.Status");
            if(caseStatus == 'Submitted' || caseStatus == 'Closed'|| caseStatus == 'Cancelled')
            {
                component.set("v.descDisabled",true);
            }
            var rtName = component.get("v.simpleNewCase.RecordType.DeveloperName");
            if(rtName == 'Interaction_MVN'){
                component.set("v.descLabel",'Case Details');
                component.set("v.maxLength", 32768);
                var descriptionVal = component.get("v.simpleNewCase.Interaction_Notes_MVN__c");
                if(descriptionVal){
                    component.set("v.descriptionVal",descriptionVal);
                }
            }
            if(rtName == 'Request_MVN' || rtName == 'Request_Closed_MVN'){
                component.set("v.descLabel",'Details');
                component.set("v.maxLength", 32000);
                var descriptionVal = component.get("v.simpleNewCase.Details_MVN__c");
                if(descriptionVal){
                    component.set("v.descriptionVal",descriptionVal);
                }
            }
            if(rtName == 'Combo_Case_Preview' ||rtName == 'Combo_Case_MVN' || rtName == 'Combo_Case_Submitted'||rtName == 'Combo_Case_Closed' || rtName == 'Adverse_Event_MVN'|| rtName == 'Adverse_Event_Closed_MVN' || rtName == 'Adverse_Event_Submitted' || rtName == 'Product_Complaint_MVN'|| rtName == 'Product_Complaint_Closed_MVN'|| rtName == 'MSD_CORE_Product_Complaint_Submitted'){
                component.set("v.descLabel",'Description');
                component.set("v.maxLength", 2000);
                var descriptionVal = component.get("v.simpleNewCase.MSD_CORE_AE_Description__c");
                if(descriptionVal){
                    component.set("v.descriptionVal",descriptionVal);
                }
            }
            if(rtName == 'MSD_CORE_Temperature_Excursion' || rtName == 'MSD_CORE_Temperature_Excursion_Closed'){
                component.set("v.descLabel",'Details');
                component.set("v.maxLength", 32768);
                var descriptionVal = component.get("v.simpleNewCase.Details_MVN__c");
                if(descriptionVal){
                    component.set("v.descriptionVal",descriptionVal);
                }
            }
            if(rtName == 'MSD_CORE_Compensation_Request' || rtName =='MSD_CORE_Compensation_Request_Closed'){
                component.set("v.descLabel",'Details');
                component.set("v.maxLength", 32768);
                var descriptionVal = component.get("v.simpleNewCase.Details_MVN__c");
                if(descriptionVal){
                    component.set("v.descriptionVal",descriptionVal);
                }
            }
        }
        else if(eventParams.changeType === "CHANGED") {
           var readonly = component.get("v.isReadOnlyUser")
           if (readonly){
               console.log("readonly users");
               component.find("caseRecordCreatorread").reloadRecord(true);
            }
            else {
                 component.find("caseRecordCreator").reloadRecord(true);
           }
        }
    },
    
    //onDynamicSearchCheck: function(cmp,evt,helper){
    //    var checkCmp = cmp.find("checkDynamicSearch");
       // checkCmp.get("v.value")
   // }
    
    fireEvent : function(component, event, helper){
        
        if(!component.get("v.enableDynamicSearch")) return;
        
        var myEvent = $A.get("e.c:MSD_CORE_CC_AppEvent");
        myEvent.setParams({"desc": component.get("v.descriptionVal"), "recId" : component.get("v.recordId")});
        myEvent.fire();
    },
    
    byPassSearch : function(component, event, helper){
        var myEvent = $A.get("e.c:MSD_CORE_CC_AppEvent");
        myEvent.setParams({"desc": component.get("v.descriptionVal"), "bypassAutoSearch" :true, "recId" : component.get("v.recordId")});
        myEvent.fire();
    },
    
    
    updateCaseDescription : function(component, event, helper){
        
        var descVal = component.get("v.descriptionVal");
        console.log('descVal -->'+descVal);
        var oldDescVal = '';
        var rtName = component.get("v.simpleNewCase.RecordType.DeveloperName");
        if(rtName == 'Interaction_MVN'){
            oldDescVal = component.get("v.simpleNewCase.Interaction_Notes_MVN__c");
            
        }
        if(rtName == 'Request_MVN'){
            oldDescVal = component.get("v.simpleNewCase.Details_MVN__c");
            
        }
        if(rtName == 'Combo_Case_MVN' || rtName == 'Adverse_Event_MVN' || rtName == 'Product_Complaint_MVN'){
            oldDescVal = component.get("v.simpleNewCase.MSD_CORE_AE_Description__c");
        }
        if(rtName == 'MSD_CORE_Temperature_Excursion'){
            oldDescVal = component.get("v.simpleNewCase.Details_MVN__c");
        }
        if(rtName == 'MSD_CORE_Compensation_Request'){
            oldDescVal = component.get("v.simpleNewCase.Details_MVN__c");
        } 
        if((oldDescVal == null && helper.isNotBlank(descVal)) || (oldDescVal != null && oldDescVal != descVal && helper.isNotBlank(descVal))){
            var action = component.get('c.updateCaseDesc');
            action.setParams({
                "caseId": component.get("v.recordId"),
                "descVal": component.get("v.descriptionVal")
            });
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if(state === "SUCCESS"){
                    console.log('descVal save successful');
                    //$A.get('e.force:refreshView').fire();
                }
            });
            $A.enqueueAction(action);
        }        
    }
})