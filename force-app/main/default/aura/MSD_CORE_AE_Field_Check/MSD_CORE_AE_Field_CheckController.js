({
	doInit: function(component, event, helper) {
        component.set('v.showSpinner', true);
        //setTimeout(function(){
            helper.helperInit(component, event, helper);
            component.set('v.showSpinner', false);
        //}, 1000);
    },
    handleLoad: function(component, event, helper) {
        component.set('v.showSpinner', false);
    },
    updateCaseFieldJS: function(component, event, helper) {
        var caseRT = component.get('v.casedata').RecordType.Name;
        
        var vl = component.get("v.showPopup");
        if(vl){
            if(caseRT == 'Request')
                component.find('recordRequestFormPopup').submit();
            else if(caseRT == 'CR Request')
                component.find('recordCRRequestFormPopup').submit();
            else
                component.find('recordViewFormPopup').submit();
        }
        else{
            if(caseRT == 'Request')
                component.find('recordRequestForm').submit();
            else if(caseRT == 'CR Request')
                component.find('recordCRRequestForm').submit();
            else
                component.find('recordViewForm').submit();
        }
        
        component.set('v.showSpinner', true);
    },
    handleSuccess: function(component, event, helper) {
        helper.helperInit(component, event, helper);
        component.set('v.showSpinner', false);
        $A.get('e.force:refreshView').fire();
    },
    handleError: function(component, event, helper) {
        component.set('v.showSpinner', false);
    },
    openModal : function(component, event, helper) {
        component.set("v.showPopup", true);
	},
	closeModal : function(component, event, helper) {
        component.set("v.showPopup", false);
    }
})