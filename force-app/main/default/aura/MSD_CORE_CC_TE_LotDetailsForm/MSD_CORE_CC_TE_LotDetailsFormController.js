({
    handleLotSelect : function (component, event, helper) {
        if(event.getParam('id') == 'add_lot'){
            var nextConfigs = component.get('v.lottabs');
            var lastLotId = nextConfigs.length + 1;
            nextConfigs.push({'label': 'Lot Details '+lastLotId, 'id': JSON.stringify(lastLotId), mode:'NEW'});
            component.set("v.selectedLotTabId",JSON.stringify(lastLotId));
            component.set('v.lottabs', nextConfigs);
        }
    },
    
    handleSave : function(component, event, helper){
        var inputCmp = component.find("field");
        var value = inputCmp.get("v.value");
        if(helper.isNotBlank(value)){        
            component.set("v.buttonClicked",'Save');
            var action = component.get("c.createLotDetails");
            action.setParams({ "prodId": component.get("v.parentId"),
                        "lotNumber": component.get("v.lotNum"),
                        "expDate": component.get("v.expDate")});
    
            // Create a callback that is executed after 
            // the server-side action returns
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.mode","VIEW");
                    var rec = response.getReturnValue();
                    component.set("v.recordId",rec.Id);
                    var recName = rec.Name;
                    var recId =  rec.Id;
                    var compEvent = component.getEvent("MSD_CORE_CC_TE_LotDetailsEvent");
                    compEvent.setParams({"lotName" : recName,
                                         "recId" : recId});
                    }
                    //compEvent.fire();
                
            });
            $A.enqueueAction(action);
        }
    },
    
    handleSaveAdd : function(component, event, helper){
        var inputCmp = component.find("field");
        var value = inputCmp.get("v.value");
        if(helper.isNotBlank(value)){ 
            component.set("v.buttonClicked",'SaveAdd');
            var action = component.get("c.createLotDetails");
            action.setParams({ "prodId": component.get("v.parentId"),
                        "lotNumber": component.get("v.lotNum"),
                        "expDate": component.get("v.expDate")});
    
            // Create a callback that is executed after 
            // the server-side action returns
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.mode","VIEW");
                    var rec = response.getReturnValue();
                    component.set("v.recordId",rec.Id);
                    var recName = rec.Name;
                    var recId =  rec.Id;
                    var compEvent = component.getEvent("MSD_CORE_CC_TE_LotDetailsEvent");
                    compEvent.setParams({"lotName" : recName,
                                         "recId" : recId});
                    //compEvent.fire();
                    var compEvent = component.getEvent("MSD_CORE_CC_TE_LotDetailsFormEvent");
                    compEvent.setParams({"eventType" : 'SaveAdd'})
                    compEvent.fire();
                }
                
            });
            $A.enqueueAction(action);
        }
    },
    
    handleLotSubmit : function(component, event, helper){
        component.set('v.showSpinner', true); 
    },
    
    handleLotSuccess : function(component, event, helper){
        component.set('v.showSpinner', false); 
        var params = event.getParams();
        component.set('v.recordId', params.response.id);
        component.set('v.lotParentId', params.response.id);
        component.set('v.showSpinner', false);
        component.set("v.mode",'VIEW');
        var recName = params.response.fields.Name.value;
        var recId =  params.response.id;
        var compEvent = component.getEvent("MSD_CORE_CC_TE_LotDetailsEvent");
        compEvent.setParams({"lotName" : recName,
                             "recId" : recId});
        compEvent.fire();
        console.log('recId -->'+ params.response.id);
        if(component.get("v.buttonClicked") == 'SaveAdd'){
            var compEvent = component.getEvent("MSD_CORE_CC_TE_LotDetailsFormEvent");
            compEvent.setParams({"eventType" : 'SaveAdd'})
            compEvent.fire();
        }
    },
    
    
    handleLotError : function(component, event, helper){
        component.set('v.showSpinner', false); 
    },
    
    closeFocusedTab : function(component, event, helper){
    },
    
})