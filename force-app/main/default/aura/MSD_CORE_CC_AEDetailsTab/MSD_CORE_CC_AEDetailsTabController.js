({
	doInit: function(component, event, helper) {
        helper.helperInit(component, event, helper);
    },
    doEdit: function(component, event, helper) {
        component.set('v.isEdit', true);
    },
    stopEdit: function(component, event, helper) {
        component.set('v.isEdit', false);
    },
    doSave: function(component, event, helper) {
        component.find('recordViewForm').submit();
        component.set('v.showSpinner', true);
    },
    handleSuccess: function(component, event, helper) {
        component.set('v.isEdit', false);
        component.set('v.showSpinner', false);
        //$A.get('e.force:refreshView').fire();
    },
    selectTab : function(component, event, helper) { 
        /* General utility */
        var selected = component.get("v.key");
        //alert('sdf');
        //component.find("tabs").set("v.selectedTabId",selected);
    },
    tabSelected : function(component, event, helper){
        var tabId = component.get("v.selTabId");
        if(tabId == 'All'){
            component.set("v.showAll", true);
        }else{
            component.set("v.showAll", false);
        }
    }
})