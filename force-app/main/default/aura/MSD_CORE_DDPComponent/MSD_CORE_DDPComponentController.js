({
    doInit: function(component, event, helper) {
        helper.helperInit(component, event, helper);
    },
	openModal : function(component, event, helper) {
        helper.openModalHelper(component, event, helper);
	},
	closeModal : function(component, event, helper) {
        component.set("v.showPopup", false);
    }
})