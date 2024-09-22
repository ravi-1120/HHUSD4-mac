({
    doInit : function(component, event, helper) {
        var myPageRef = component.get("v.pageReference");
        console.log("mypageRef");
        if(myPageRef && myPageRef.state)
        	component.set("v.parentId", myPageRef.state.c__recordId);
        
        if(helper.isNotBlank(component.get("v.recordId"))){
            component.set('v.showSpinner', true);
            console.log (component.get("v.mode"));
            var action = component.get("c.getProdInfo");
            action.setParams({ "prodId" : component.get('v.recordId')});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var res = response.getReturnValue();
                    component.set("v.parentRT", res.MSD_CORE_Adverse_Event__r.RecordType.Name);
                    component.set("v.parentIdForEdit", res.MSD_CORE_Adverse_Event__c);
                    component.set("v.disableReturnDate", res.MSD_CORE_Adverse_Event__r.IsClosed);
                    component.set("v.createdById", res.CreatedById);
                    component.set("v.createdByName", res.CreatedBy.Name);                    
                    component.set("v.isEdit", true);
                    component.set('v.showSpinner', false);
                    component.set('v.primary', res.MSD_CORE_Primary_Product__c);
                    if(res.MSD_CORE_Adverse_Event__r.MSD_CORE_Is_Submitted__c){
                        component.set('v.lockedParent', true);
                        component.set('v.disableSave',true);
                    }
                    var relTo = res.MSD_CORE_Related_to__c;
                    /*PT ----CEF2F-22314/-------------*/
                    //component.set("v.checkboxVal",relTo);
                    
                    if(helper.isNotBlank(relTo)){
                        if(relTo == 'AE'){
                            component.set("v.aeChecked", true);
                            component.set("v.checkboxVal", 'AE');
                        }
                        if(relTo == 'PQC'){
                            component.set("v.pqcChecked", true);
                            component.set("v.checkboxVal", 'PQC');
                        }
                        if(relTo == 'AE and PQC'){
                            component.set("v.aeChecked", true);
                            component.set("v.pqcChecked", true);
                            var chekedList = [];
                            chekedList.push('AE');
                            chekedList.push('PQC');
                            component.set("v.checkboxVal",chekedList);
                        }
                    }
                }
            });
            $A.enqueueAction(action);
        }
        
        var action = component.get('c.getProfileName');
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                var res = actionResult.getReturnValue();
                component.set('v.userProfileName', res);
            }
        });
        $A.enqueueAction(action);
    },
    
    handleLoad: function(component, event, helper) {
        
        var workspaceAPI = component.find("workspace1");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "Product Details"
            });
        })
        .catch(function(error) {
            console.log(error);
        });
        
        if(helper.isNotBlank(component.get("v.recordId")) && component.get("v.mode") != 'VIEW' && component.get("v.parentRT") != 'Request'){
            try{
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
            }catch(e){}
            console.log ('Related to Add product form Handle Load');
        }
    },
    
    handleSave: function(component, event, helper) {
        component.set("v.buttonClicked",event.getSource().get("v.name"));
        //$A.get('e.force:refreshView').fire();
    },
    
    handleSubmit: function(component, event, helper) {
        let failedValidationFields = helper.isFormValid(component, event, helper);
        if(!failedValidationFields){
            var eventFields = event.getParam("fields");
            var checkboxVal = component.get("v.checkboxVal");
            var ae = checkboxVal.indexOf("AE") > -1 ? true : false;
            var pqc = checkboxVal.indexOf("PQC") > -1 ? true : false;   
            
            var relatedToVal = '';
            if(ae && pqc)
                relatedToVal = 'AE and PQC';
            else if(ae)
                relatedToVal = 'AE';
            else if(pqc)
                relatedToVal = 'PQC';
            console.log('eventFields');
            console.log(eventFields);
            eventFields.MSD_CORE_Related_to__c = relatedToVal;
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
        if(component.get("v.isEdit")){
            
            var myEvent = $A.get("e.c:refreshRecordTypeMVNEvent");
            myEvent.setParams({"refreshCustInfo": true});
            myEvent.fire();
            
        //    $A.get('e.force:refreshView').fire();
            //helper.closeEditTab(component, event, helper);
            if(component.get("v.buttonClicked") == 'save'){
                helper.closeEditTab(component, event, helper);
            }
            else{
                component.set("v.reloadForm", false);
                component.set("v.reloadForm", true);
                component.set("v.recordId",'');
                component.set("v.checkboxVal",[]);
                component.set("v.relatedToVal",null);
                component.set("v.primary", false);
                component.set("v.parentId", component.get("v.parentIdForEdit"));
            }
        }
        else{
            component.set("v.reloadForm", false);
            component.set("v.reloadForm", true);
            component.set("v.checkboxVal",[]);
            component.set("v.relatedToVal",null);
            component.set("v.primary", false);
            if(component.get("v.buttonClicked") == 'save'){
                //fire close modal component event
              //  var compEvent = component.getEvent("MSD_CORE_CC_CloseModalEvt");
               // compEvent.fire();
                
                var myEvent = $A.get("e.c:refreshRecordTypeMVNEvent");
                myEvent.setParams({"refreshCustInfo": true});
                myEvent.fire();
                
                helper.closeEditTab(component, event, helper);
            }            
            //$A.get('e.force:refreshView').fire();
        }
    },
    
    handleChange: function(component, event, helper) {
        //try{
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
            component.set("v.relatedToVal",relatedToVal);
        }
        /*}
        catch(e){
            console.log('Test for PQC check box');
        }*/
    },
    closeFocusedTab : function(component, event, helper) {
        component.set('v.showSpinner', false);
        //component.set('v.reloadForm', false);
       
     //   if(component.get("v.isEdit")){
            try{
                 console.log("Closing the tab...");
                var workspaceAPI = component.find("workspace1");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                });
            }catch(e) {
                console.log("Error closing the tab;");
                console.log(e);
            }
       /* }
        else{
            component.set("v.reloadForm", false);
            component.set("v.reloadForm", true);
            component.set("v.checkboxVal",[]);
            component.set("v.relatedToVal",null);
            //fire close modal component event
            var compEvent = component.getEvent("MSD_CORE_CC_CloseModalEvt");
            compEvent.fire();
            //component.set('v.saved', true);
            try{
                component.find('required').forEach(function(f) {
                    f.reset();
                });
                component.find('field1').forEach(function(f1) {
                    f1.reset();
                });
                
            }catch(e){}
        }*/
    },
    
    enableSave : function(component, event, helper){
        if(component.get("v.lockedParent")){
            component.set('v.disableSave',false);
        }                        
    },
    
    handleKeyPress : function(component, event, helper){
        if (event.keyCode == 13){            
            component.set("v.buttonClicked",'save');
        }
    },
    
    handleUserNav : function(component, event, helper){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.createdById")
        });
        navEvt.fire();
    },
})