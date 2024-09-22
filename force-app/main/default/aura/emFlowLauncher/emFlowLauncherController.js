({
  handleMessage: function(component, message, helper) {
    helper.processMessageParams(component, message);
    const flowName = message.getParam("flowName");
    if (flowName) {
      helper.destroyFlow(component);
      $A.createComponent(
        "lightning:flow",
        {
          "aura:id": "emFlow",
          onstatuschange: component.getReference("c.handleFlowStatusChange")
        },
        function(flowComponent, status, errorMessage) {
          if (status === "SUCCESS") {
            const placeholder = component.get("v.body");
            placeholder.push(flowComponent);
            component.set("v.body", placeholder);

            const flowName = component.get("v.flowName");
            const flowVariables = component.get("v.flowVariables");
            if (flowVariables) {
              flowComponent.startFlow(flowName, flowVariables);
            } else {
              flowComponent.startFlow(flowName);
            }
          } else if (status === "INCOMPLETE" || status === "ERROR") {
            helper.showErrorToast(component);
          }
        }
      );
    }
  },
  handleFlowStatusChange: function(component, event, helper) {
    if (event.getParam("status") === "STARTED") {
      const flowCmp = component.find("emFlow");
      $A.util.addClass(flowCmp, "hide-spinner")
    }
    if (event.getParam("status") === "FINISHED" || event.getParam("status") === "FINISHED_SCREEN") {
      helper.destroyFlow(component);
      helper.handleRefresh(event);
    }
  }
});