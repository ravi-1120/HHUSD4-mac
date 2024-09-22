({
	checkAccAffiliation : function(component, event, helper) {
		var action = component.get('c.checkCaseAffliation');
        action.setParams({
            csId: component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS"){
                var res = response.getReturnValue();
                if(res != null)
                { 
                    component.set("v.showAffiliationModal", true);
                    component.set("v.affiliationFrom", res.affiliationFrom);
                    component.set("v.affiliationTo", res.affiliationTo);
                    component.set("v.affiliation", res.affiliation);                    
                }
                if(!component.get("v.editInfo")){
                    component.set("v.showSearch", false);
                }
                else{
                    if(!component.get("v.showAffiliationModal"))
                    {
                        component.destroy();
                    }
                    else{
                        component.set("v.editInfo", false);
                        component.set("v.showSearch", false);
                        component.set("v.destroyEdit", true);
                    }
                }
                
                var myEvent = $A.get("e.c:MSD_CORE_CC_RefreshCustInfoEvent");
                myEvent.setParams({"refreshCustInfo": true});
                myEvent.fire();
            }
        });
        $A.enqueueAction(action);
	}
})