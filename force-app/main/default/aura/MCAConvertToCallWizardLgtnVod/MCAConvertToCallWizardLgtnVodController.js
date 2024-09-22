({
    init: function(component) {
        var id = component.get("v.recordId");
        var flow = component.find("flowData");
        var inputVariables = [
            { name: "mcaId", type: "String", value: id }
        ];
        flow.startFlow("Save4LaterReconciliationFlow", inputVariables);
    },
    handleStatusChange: function(component, event) {
        component.set("v.spinner", false);
        var status = event.getParam("status");
        if(status === 'FINISHED') {
            var outputVariables = event.getParam("outputVariables");
            var outputVar;
            for(var i = 0; i < outputVariables.length; i++) {
                outputVar = outputVariables[i];
                var name = outputVar.name;
                var value = outputVar.value;
                if(name === "error" && value) {
                    toastErrorAndExit(value);
                    break;
                } else if(name === 'createdCallId' && value) {
                    redirectToSObject(value);
                    break;
                }
            }
            exit();
        }

        function redirectToSObject(id) {
            var workspaceAPI = component.find("workspace");
            workspaceAPI.openTab({
                pageReference: {
                    "type": "standard__recordPage",
                    "attributes": {
                        "recordId": id,
                        "actionName": "view"
                    }
                },
                focus: false
            });
        }

        function toastErrorAndExit(msg) {
            // display error msg as toast
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "message": msg
            });
            toastEvent.fire();
        }

        function exit() {
            $A.get("e.force:closeQuickAction").fire();
        }

    }
})