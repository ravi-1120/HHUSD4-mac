({
    doInit: function (component, event, helper) {
        helper.startFlow(component);
    },

    handleMessage: function (component, message, helper) {
        helper.processMessageParams(component, message);
        const flowName = message.getParam('flowName');
        if (flowName) {
            $A.createComponent(
                "lightning:flow",
                {
                    "aura:id": "messageFlow",
                    "onstatuschange": component.getReference("c.handleFlowStatusChange")
                },
                helper.createComponentCallback(component)
            )
        }
    },

    handleFlowStatusChange: function (component, event, helper) {
        if (event.getParam('status') === "FINISHED") {
            const componentInContextOfRef = component.get('v.inContextOfRef');
            const navService = component.find("navService");
            helper.destroyFlow(component);
            if (componentInContextOfRef) {
                if (typeof sforce !== 'undefined' && sforce.one) {
                    const redirect = componentInContextOfRef.state && componentInContextOfRef.state.redirect;
                    sforce.one.navigateToURL(helper.getPageRefUrl(componentInContextOfRef), redirect);
                } else {
                    navService.navigate(componentInContextOfRef);
                }
            }

            const msgFlow = component.find('messageFlow');
            if (msgFlow) {
                msgFlow.destroy();
            }
            // It's also possible that we have inContextOfRef set in our state
            const stateInContextOfRef = helper.getInContextOfRefFromState(component);
            if (!componentInContextOfRef && stateInContextOfRef) {
                navService.navigate(stateInContextOfRef, true);
            }
            helper.clearMessageParams(component);
        }
    }
})