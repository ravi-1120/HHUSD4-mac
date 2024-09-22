({
    doInit : function(component, event, helper) {
       component.set('v.userProfile','MSD_CORE Contact Center - Read Only User');
        try{
         console.log(component.get("v.recordId"));
        var action = component.get('c.getCaseInfo');
        action.setParams({ "csId" : component.get('v.recordId')});
        action.setCallback(this, function(actionResult) {
            console.log('actionResult.getState()  -->'+actionResult.getState() );
            if(actionResult.getState() === "SUCCESS"){
                var res = actionResult.getReturnValue();
                console.log('response for profile-->'+JSON.stringify(res));
                component.set('v.userProfile', res.userProfile);
                component.set("v.caseStatus", res.caseStatus);
            }
        });
        $A.enqueueAction(action);
            }
        catch(e){
            console.log('exception-->' , e)
        }
	},
	addProduct : function(component, event, helper) {
       // var modal = component.find('addProduct');
       // $A.util.toggleClass(modal, 'slds-hide');
         var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__MSD_CORE_CC_Add_Product_Form',
            },
            state: {
                "c__recordId": component.get("v.recordId")
            }
        };
        
        component.set("v.pageReference", pageReference);
        var navService = component.find("navService");
        
        event.preventDefault();
        navService.navigate(pageReference);
	},
    
    closeModal : function(component, event, helper) {
        var modal = component.find('addProduct');
        $A.util.toggleClass(modal, 'slds-hide');
       
	},
    
    handleCloseEvent : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        var modal = component.find('addProduct');
        $A.util.toggleClass(modal, 'slds-hide');
	}
})