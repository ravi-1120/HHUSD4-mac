({
    doInit : function(component, event, helper) {
    },
    
    handleSubmit: function(component, event, helper) {
        let failedValidationFields = helper.isFormValid(component, event, helper);
        if(!failedValidationFields ){
    		if(!component.get("v.isEdit")){
                component.set("v.lotNumber", component.find("MSD_CORE_Lot_Number__c").get("v.value"));
                component.set("v.expDate", component.find("MSD_CORE_Expiration_Date__c").get("v.value"));
			}
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
    
    handleSave: function(component, event, helper) {
        component.set("v.buttonClicked",'Save');
    },
    
    handleError: function(component, event, helper) {
        component.set('v.showSpinner', false);
        var error = event.getParam("error");
        console.log('lot creation erroe ->'+JSON.stringify(error));
        
    },
    
    handleSuccess: function(component, event, helper) {
        var params = event.getParams();
       	/*component.set('v.recordId', params.response.id);
        component.set('v.lotParentId', params.response.id);
        component.set('v.showSpinner', false);
        component.set("v.mode",'VIEW');*/
        var recName = params.response.fields.Name.value;
        var prodVal = params.response.fields.MSD_CORE_Product__r.displayValue;
        var recId =  params.response.id;
        var lotNum = params.response.fields.MSD_CORE_Lot_Number__c.value;
        var expDate = params.response.fields.MSD_CORE_Expiration_Date__c.value;
        var wasVaccAdministered = params.response.fields.MSD_CORE_Was_Vaccine_Administered__c.value;
        /*
        var compEvent = component.getEvent("MSD_CORE_CC_TempProdEvent");
        compEvent.setParams({"tempProdName" : recName+' ('+prodVal+')',
                             "recId" : recId});
        compEvent.fire();
        $A.get('e.force:refreshView').fire();
        
        if(component.get("v.buttonClicked") == 'SaveAdd'){
            var compEvent = component.getEvent("MSD_CORE_CC_TempProdFormEvent");
            compEvent.fire();
        }
        */
        if(helper.isNotBlank(recId)){
            console.log('recId inside prod form controller'+recId);
            
            if(helper.isNotBlank(lotNum) && !component.get("v.isEdit")){
                var action = component.get("c.createLotDetails");
        action.setParams({ "prodId": recId,
                    "lotNumber": lotNum,
                    "expDate": expDate});

        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                console.log('res -->'+JSON.stringify(res));
                component.set('v.lottabs', [{
                            id: '1',
                            label: res.Name,
                            recId: res.Id,
                            mode:'NEW',
                            lotParentId:recId
                        }]);
                component.set('v.recordId', params.response.id);
                component.set('v.lotParentId', params.response.id);
                component.set('v.showSpinner', false);
                component.set("v.mode",'VIEW');
                
                var compEvent = component.getEvent("MSD_CORE_CC_TempProdEvent");
                compEvent.setParams({"tempProdName" : recName+' ('+prodVal+')',
                                     "recId" : recId,
                                     "lotName" : res.Name,
                                     "lotId" : res.Id,
                                     "wasVaccAdministered" : wasVaccAdministered
                                    });
                compEvent.fire();
                //$A.get('e.force:refreshView').fire();
                if(component.get("v.buttonClicked") == 'SaveAdd'){
                    var compEvent = component.getEvent("MSD_CORE_CC_TempProdFormEvent");
                    
                    compEvent.fire();
                }
                component.set("v.showLotDetailTabs", true);
            }
            
        });

        // optionally set storable, abortable, background flag here

        // A client-side action could cause multiple events, 
        // which could trigger other events and 
        // other server-side action calls.
        // $A.enqueueAction adds the server-side action to the queue.
        $A.enqueueAction(action);
                
                
            }
            
            else{
                console.log(' else');
                component.set('v.lottabs', [{
                    id: '1',
                    label: 'Lot Details 1',
                    recId:'',
                    mode:'NEW',
                    lotParentId:recId
                }]);
                component.set('v.recordId', params.response.id);
                component.set('v.lotParentId', params.response.id);
                component.set('v.showSpinner', false);
                component.set("v.mode",'VIEW');
                component.set("v.showLotDetailTabs", true);
                var compEvent = component.getEvent("MSD_CORE_CC_TempProdEvent");
                compEvent.setParams({"tempProdName" : recName+' ('+prodVal+')',
                                     "recId" : recId,
                                     "lotName" : 'Lot Details 1',
                                     "lotId" : '',
                                     "wasVaccAdministered" : wasVaccAdministered
                                    });
                compEvent.fire();
                //$A.get('e.force:refreshView').fire();
                
                if(component.get("v.buttonClicked") == 'SaveAdd'){
                    var compEvent = component.getEvent("MSD_CORE_CC_TempProdFormEvent");
                    
                    compEvent.fire();
                }
            }
           
            /*
            var action = component.get('c.createLotDetails');
            action.setParams({
                "prodId": recId,
                "lotNumber": lotNum,
                "expDate": expDate
            });
            action.setCallback(this, function(response) {
                if(response.getState() === "SUCCESS"){
                    
                }
            });
            $A.enqueueAction(action);
            */
            
            
            //setTimeout($A.getCallback(() => component.set("v.showLotDetailTabs", true)));
            /*
            component.set('v.lotParentId', recId);
            component.set("v.showLotDetailTabs", true);
            component.set('v.recordId', params.response.id);*/
        }
    },
    
    handleChange: function(component, event, helper) {
        var wasVaccAdministered = component.find("wasVaccAdministered").get("v.value");
        if(helper.isNotBlank(wasVaccAdministered) && wasVaccAdministered == 'Yes'){ 
            var compEvent = component.getEvent("MSD_CORE_CC_VaccAdministeredEvent");
            compEvent.fire();
            /*var modal = component.find('confirmPop');
            $A.util.toggleClass(modal, 'slds-hide');*/
        }
    },
    closeModal : function(component, event, helper) {
        var modal = component.find('confirmPop');
        $A.util.toggleClass(modal, 'slds-hide');
    },
    
    createAEPQC : function(component, event, helper) {
        var modal = component.find('confirmPop');
        $A.util.toggleClass(modal, 'slds-hide');
        var compEvent = component.getEvent("MSD_CORE_CC_CloseModalEvt");
        compEvent.fire();
        var action = component.get("c.createChildComboCase");
        action.setParams({ "caseId" : component.get("v.parentId")
                         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                var caseId = response.getReturnValue();
                console.log('Record Id created -- >'+caseId);
                var focusedTabId ='';
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    focusedTabId = response.tabId;
                });
                workspaceAPI.openSubtab({
                    parentTabId: focusedTabId,
                    recordId: caseId,
                    focus: true
                });
            }
            else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type": "error",
                    "message": "An exception has occured."
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    handleRecordUpdated : function(component, event, helper){
        
    },
    
    handleSaveAdd : function(component, event, helper){
        component.set("v.buttonClicked",'SaveAdd');
    },
    
    handleLotSelect : function (component, event, helper) {
        if(event.getParam('id') == 'add_lot'){
            try{
                var nextConfigs = component.get('v.lottabs');
                var lastLotId = nextConfigs.length + 1;
                console.log('component.get("v.recordId") -->'+component.get("v.recordId"));
                nextConfigs.push({'label': 'Lot Details '+lastLotId,
                                  'id': JSON.stringify(lastLotId), 
                                  'recId':'', 
                                  'mode':'NEW',
                                  'lotParentId' : component.get("v.recordId")
                                 });
                component.set("v.selectedLotTabId",JSON.stringify(lastLotId));
                component.set('v.lottabs', nextConfigs);
            }catch(e){}
        }
    },
    handleLotSave : function(component, event, helper){
    },
    handleLotSubmit : function(component, event, helper){
    },
    handleLotSuccess : function(component, event, helper){
        
        var params = event.getParams();
        component.set('v.recordId', params.response.id);
        component.set('v.showSpinner', false);
        //component.set("v.mode",'VIEW');
        var recName = params.response.fields.Name.value;
        console.log('recName -->'+recName);
        var recId =  params.response.id;
        console.log('recId -->'+ params.response.id);
        var selectedLotTabId = component.get("v.selectedLotTabId");
        var lottabs = component.get('v.lottabs');
        for(var i in lottabs){
            console.log('lottab id -->'+lottabs[i].id);
            console.log(lottabs[i].id == selectedLotTabId);
            if(lottabs[i].id == selectedLotTabId){
                lottabs[i].label = recName;
                lottabs[i].recId = recId;
                lottabs[i].mode = 'VIEW';
            }
        }
        
        component.set("v.showLotDetailTabs", false);
        console.log('lottabs -->'+JSON.stringify(component.get("v.lottabs")));
        component.set("v.lottabs", lottabs);
        console.log('lottabs -->'+JSON.stringify(component.get("v.lottabs")));
        setTimeout($A.getCallback(() => component.set("v.showLotDetailTabs", true)));
        
        
    },
    handleLotError : function(component, event, helper){
        var error = event.getParam("error");
        console.log('lot creation erroe ->'+JSON.stringify(error));
    },
    
    handleTELotDetailsFormEvent : function(component, event, helper){
        var eventType = event.getParam("eventType");
        console.log('eventType -->'+eventType);
        if(eventType == 'SaveAdd'){
            helper.handleSaveAddEvent(component, event, helper);
        }

    }, 
    
    handleTELotDetailsEvent : function(component, event, helper){
        var lotName = event.getParam("lotName");
        var recId = event.getParam("recId");
        var selectedLotTabId = component.get("v.selectedLotTabId");
       /* var lottabs = component.get('v.lottabs');
        console.log('check ---->'+lotName+recId+component.get("v.recordId"));
        for(var i in lottabs){
            if(lottabs[i].id == selectedLotTabId){
                lottabs[i].label = lotName;
                lottabs[i].recId = recId;
                lottabs[i].mode = 'VIEW';
                lottabs[i].lotParentId = component.get("v.recordId");
            }
        } */
        
        
        var nextConfigs = component.get('v.lottabs').map(function (config) {
            if(config.id == selectedLotTabId){
                config.label = lotName;
                config.recId = recId;
                config.mode = 'VIEW';
                config.lotParentId = component.get("v.recordId");
            }
            return config;
        });
        
        console.log('lottabs -->'+JSON.stringify(component.get("v.lottabs")));
        component.set("v.showLotDetailTabs", false);
 
        component.set('v.tabs', nextConfigs);
        setTimeout($A.getCallback(() => component.set("v.showLotDetailTabs", true)));
	},
    
})