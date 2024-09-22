({
    doInit : function(component, event, helper) {
        if(helper.isNotBlank(component.get("v.recordId"))){
            component.set("v.isEdit", true);
        }
    },
    
    handleLoad: function(component, event, helper) {
       /* if(helper.isNotBlank(component.get("v.recordId")) && component.get("v.mode") != 'VIEW'){
            console.log(JSON.stringify(event.getParams()));
            var record = event.getParam("recordUi").record;            
            var fields = record.fields;
            var fieldValue = fields.MSD_CORE_Related_to__c.value;
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
            
        }*/
    },
    
    handleSubmit: function(component, event, helper) {
        let failedValidationFields = helper.isFormValid(component, event, helper);
       	if(!helper.isNotBlank(failedValidationFields)){
            component.set('v.disabled', true);
            component.set('v.showSpinner', true);
              
        }
        else{
            event.preventDefault();
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Form Incomplete!",
                "type": "error",
                "message": "Please enter all required fields"
            });
            toastEvent.fire();
        }
    },
    
    handleError: function(component, event, helper) {
        // errors are handled by lightning:inputField and lightning:messages
        // so this just hides the spinner
        component.set('v.showSpinner', false);
    },
    
    handleSuccess: function(component, event, helper) {
        var params = event.getParams();
        component.set('v.showSpinner', false);
        component.set('v.saved', true);
        
        //fire close modal component event
        var compEvent = component.getEvent("MSD_CORE_CC_CloseModalEvt");
        compEvent.fire();
        if(component.get("v.isEdit")){
            try{
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                });
            }catch(e) {}
        }
        else{
            try{
            component.find('field').forEach(function(f) {
                f.reset();
            });
            }catch(e){}
        }
        /*
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": params.response.id,
            "slideDevName": "related"
        });
        navEvt.fire();*/
    },
    
    handleChange: function(component, event, helper) {
        /*
        var checkboxVal = component.get("v.checkboxVal");
        var ae = checkboxVal.indexOf("AE") > -1 ? true : false;
        var pqc = checkboxVal.indexOf("PQC") > -1 ? true : false;     
        if(pqc){
            component.set("v.primary", true);
        }
        else{
            component.set("v.primary", false);
        }
        
        var relatedToVal = '';
        console.log(ae + '::' + pqc)
        if(ae && pqc){
            relatedToVal = 'AE and PQC';
        }
        else if(ae){
            relatedToVal = 'AE';
        }
            else if(pqc){
                relatedToVal = 'PQC';
            }
        
        if(relatedToVal){
            console.log('relatedToVal -->'+relatedToVal);
            component.set("v.relatedToVal",relatedToVal);
        }*/
    },
    closeFocusedTab : function(component, event, helper) {
     component.set('v.showSpinner', false);
        
        if(component.get("v.isEdit")){
      try{
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                });
            }catch(e) {}
        }
      else{
            component.set("v.reloadForm", false);
        	component.set("v.reloadForm", true);
            //fire close modal component event
            var compEvent = component.getEvent("MSD_CORE_CC_CloseModalEvt");
            compEvent.fire();
            //component.set('v.saved', true);
        }
    }
})