({
	doInit: function(component, event, helper) {
        helper.helperInit(component, event, helper);
        var workspaceAPI = component.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.disableTabClose({
                    tabId: focusedTabId,
                    disabled: false,
                    closeable:true
                    
                })
                .then(function(tabInfo) {
                    console.log(tabInfo);
                })
                .catch(function(error) {
                    console.log(error);
                });
            })
            .catch(function(error) {
                console.log(error);
            });
    },
    
    handleRefreshRecordTypeMVN: function(component, event, helper) {
        component.set('v.refreshRL', false);
        component.set('v.refreshRL', true);
        //helper.helperInit(component, event, helper);
    }, 
    doEdit: function(component, event, helper) {
           if(component.get("v.casestatus") == 'Open'){
            component.set('v.isEdit', true);
           var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "warning",
                "message": "You cannot close this tab when you are in Edit mode."
            });
            toastEvent.fire();
            
            
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.disableTabClose({
                    tabId: focusedTabId,
                    disabled: true,
                    closeable:true
                    
                })
                .then(function(tabInfo) {
                    console.log(tabInfo);
                })
                .catch(function(error) {
                    console.log(error);
                });
            })
            .catch(function(error) {
                console.log(error);
            });
                      
        }
        else if (component.get("v.casestatus") == 'Submitted' && component.get(" v.fielddata[0].cs.MSD_CORE_PQC_QIR_Requested__c")){
             component.set('v.isEditForQIR', true);
             var workspaceAPI = component.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.disableTabClose({
                    tabId: focusedTabId,
                    disabled: true,
                    closeable:true
                    
                })
                .then(function(tabInfo) {
                    console.log(tabInfo);
                })
                .catch(function(error) {
                    console.log(error);
                });
            })
            .catch(function(error) {
                console.log(error);
            });
                      
        }
        else{
            helper.showToast(component, event, helper, 'Error!', 'You are not allowed to Edit Cases in Submitted/Closed State' ,'error');
        }
    },
    doEditForQIR: function(component, event, helper) {
       if(component.get("v.casestatus") == 'Open'  ){
        	component.set('v.isEditForQIR', true);
        }
        else{
            helper.showToast(component, event, helper, 'Error!', 'You are not allowed to Edit Cases in Submitted/Closed State' ,'error');
        }
    },
    stopEdit: function(component, event, helper) {
        component.set("v.showAlert", false);
        component.set('v.isEdit', false);
        component.set('v.isEditForQIR', false);
        component.set('v.reloadForm', false);
        helper.helperInit(component, event, helper);
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.disableTabClose({
                tabId: focusedTabId,
                disabled: false,
                closeable:true
            })
            .then(function(tabInfo) {
                console.log(tabInfo);
            })
            .catch(function(error) {
                console.log(error);
            });
        })
        .catch(function(error) {
            console.log(error);
        });       
        
    },
    doSave: function(component, event, helper) {
        console.log('in save');
        //component.find('recordViewForm').submit();
        //component.set('v.showSpinner', true);
    },
    handleSubmit: function(component, event, helper) {
        //component.find('recordViewForm').submit();
        component.set('v.showSpinner', true);
    },
    
    handleError: function(component, event, helper) {
        component.set('v.showSpinner', false);
        var error = event.getParam("error");
        console.log(JSON.stringify(error)); // main error message
        
    },
    handleLoad: function(component, event, helper) {
        //component.find("ownername").set("v.value",component.get("v.ownerId"));
    },
    handleSuccess: function(component, event, helper) {
        component.set("v.showAlert", false);
        component.set('v.isEdit', false);
        component.set('v.showSpinner', false);
        component.set('v.isEditForQIR', false);
        setTimeout(function(){ helper.helperInit(component, event, helper); }, 500);
        
        var myEvent = $A.get("e.c:refreshRecordTypeMVNEvent");
        myEvent.setParams({"refreshCustInfo": true});
        myEvent.fire();
        
        
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.disableTabClose({
                tabId: focusedTabId,
                disabled: false,
                closeable:true
            })
            .then(function(tabInfo) {
                console.log(tabInfo);
            })
            .catch(function(error) {
                console.log(error);
            });
        })
        .catch(function(error) {
            console.log(error);
        });
        
        
        
        $A.get('e.force:refreshView').fire();
    },
    selectTab : function(component, event, helper) { 
        var selected = component.get("v.key");
    },
    tabSelected : function(component, event, helper){
        var tabId = component.get("v.selTabId");
        if(tabId == 'All'){
            component.set("v.showAll", true);
        }else{
            component.set("v.showAll", false);
        }
    },
    setAlertField : function(component, event, helper){
        component.find('MSD_CORE_Legal_Alert__c').set('v.value', component.find('chkMSD_CORE_Legal_Alert__c').get('v.value'));
        component.find('MSD_CORE_Alert_Pregnancy__c').set('v.value', component.find('chkMSD_CORE_Alert_Pregnancy__c').get('v.value'));
        component.find('MSD_CORE_Alert_Security__c').set('v.value', component.find('chkMSD_CORE_Alert_Security__c').get('v.value'));
        component.find('MSD_CORE_Alert_VZV__c').set('v.value', component.find('chkMSD_CORE_Alert_VZV__c').get('v.value'));
    },
    showAlertPopup : function(component, event, helper){
        component.set("v.showAlert", !component.get("v.showAlert"));
    },
    hideAlertPopup : function(component, event, helper){
        component.set("v.showAlert", false);
    },
    changeAECheckbox : function(component, event, helper){
        var checkCmp = component.find("aeCheckbox");
        component.set("v.showAETab", !checkCmp.get("v.value"));
    }
    ,
    changePQCCheckbox : function(component, event, helper){
        var checkCmp = component.find("pqcCheckbox");
        component.set("v.showPQCTab", !checkCmp.get("v.value"));
    },
    showPButton : function(component, event, helper){
        component.set("v.showProductButton", true);
    },
    hidePButton : function(component, event, helper){
        component.set("v.showProductButton", false);
    },
    handleChange : function(component, event, helper){
        var selectedOptionValue = event.getParam("value");
        
        if(selectedOptionValue == 'Pregnancy')
        {
            if(component.find("MSD_CORE_Alert_Pregnancy__c").get("v.value"))
                component.find("MSD_CORE_Alert_Pregnancy__c").set("v.value", false);
        	else
                component.find("MSD_CORE_Alert_Pregnancy__c").set("v.value", true);
        }
        if(selectedOptionValue == 'Legal')
        {
            if(component.find("MSD_CORE_Legal_Alert__c").get("v.value"))
                component.find("MSD_CORE_Legal_Alert__c").set("v.value", false);
        	else
                component.find("MSD_CORE_Legal_Alert__c").set("v.value", true);
        }
        if(selectedOptionValue == 'Security')
        {
            if(component.find("MSD_CORE_Alert_Security__c").get("v.value"))
                component.find("MSD_CORE_Alert_Security__c").set("v.value", false);
        	else
                component.find("MSD_CORE_Alert_Security__c").set("v.value", true);
        }
        if(selectedOptionValue == 'VZV')
        {
            if(component.find("MSD_CORE_Alert_VZV__c").get("v.value"))
                component.find("MSD_CORE_Alert_VZV__c").set("v.value", false);
        	else
                component.find("MSD_CORE_Alert_VZV__c").set("v.value", true);
        }
    }
})