({
	saveNote : function(component, event, helper) {        
        component.set("v.saveDisabled",true);
        if(helper.isNotBlank(component.get("v.note"))){
            var buttonName = event.getSource().get("v.name");
            var action = component.get("c.saveCaseNote");
            action.setParams({
                caseId : component.get("v.caseId"),
                note : component.get("v.note")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();            
                if(state === "SUCCESS"){
                    if(buttonName == 'Save'){
                        component.set("v.saveDisabled",false);
                        component.find("overlayLib1").notifyClose();                        
                    }
                    else{
                        component.set("v.note",'');
                        component.set("v.error", false);
                        component.set("v.saveDisabled",false);
                    }
                    $A.get("e.force:showToast").setParams({
                        "title": "SUCCESS",
                        "message": "Note successfully created",
                        "type": "success"
                    }).fire();
                }   
            });
            $A.enqueueAction(action);
    	}
        else{
            component.set("v.error", true);
            
            //KRB 1/8/2020 Defect Fix 
            component.set("v.saveDisabled",false);
        }
	},
    
    handleCancel : function(component, event, helper) {
        component.find("overlayLib1").notifyClose();
    }
})