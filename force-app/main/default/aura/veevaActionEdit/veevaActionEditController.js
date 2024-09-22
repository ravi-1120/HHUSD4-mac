({
    refreshView: function (component, event) {
        // console.log("refresh");
        $A.get("e.force:refreshView").fire();
    },

    doInit: function(component, event, helper) {
        helper.setEditPageProperties(component);
    },

    handleClose: function(component, event, helper) {
        const availableActions = component.get('v.availableActions');
        const useFlowNavAfterEdit = event.getParam('useFlowNavAfterEdit');
        if ((useFlowNavAfterEdit)
            && availableActions 
            && availableActions.length) {
            const navigate = component.get('v.navigateFlow');
            if (availableActions.indexOf('NEXT') >= 0) {
                if (event.getParam('saveAndNew') === true) {
                    component.set('v.saveAndNew', true);
                    const flowContext = JSON.stringify(event.getParam('flowContext'));
                    component.set('v.flowContext', flowContext);
                }
                navigate('NEXT');
            } else if (availableActions.indexOf('FINISH') >= 0) {
                navigate('FINISH');
            }
        }
    },

    handlePageCtrlFactoryLoaded: function(component, event, helper) {
        component.set('v.pageCtrlFactoryLoaded', true);
    },
});