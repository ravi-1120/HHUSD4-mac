({
  processMessageParams: function(component, message) {
    ["flowName", "flowVariables"].forEach(param => {
      const paramVal = message.getParam(param);
      if (paramVal) {
        component.set(`v.${param}`, paramVal);
      }
    });
  },
  showErrorToast: function(component) {
    const getMessage = component.get("c.getMsgWithDefault");
    getMessage.setParams({
      key: "SYSTEM_ERROR",
      category: "Common",
      defaultMessage:
        "A system error has occurred and Veeva Systems has been notified. Please try again."
    });
    getMessage.setCallback(this, function(response) {
      let errorMessage =
        "A system error has occurred and Veeva Systems has been notified. Please try again.";
      if (response.getState() === "SUCCESS") {
        errorMessage = response.getReturnValue();
      } // Use default otherwise
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        message: errorMessage,
        type: "error"
      });
      toastEvent.fire();
    });
  },
  destroyFlow: function(component) {
    const flow = component.find("emFlow");
    if (flow && flow.destroy) {
      flow.destroy();
    }
  },
  handleRefresh: function(event) {
    let outputVariables = event.getParam("outputVariables");
    if (outputVariables) {
      for (var i = 0; i < outputVariables.length; i++) {
        let outputVar = outputVariables[i];
        if (outputVar.name === "refreshPage" && outputVar.value) {
          $A.get('e.force:refreshView').fire();
        }
      }
    }
  }
});