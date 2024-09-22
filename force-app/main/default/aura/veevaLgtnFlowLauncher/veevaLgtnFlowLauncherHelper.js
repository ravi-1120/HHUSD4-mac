({
    startFlow: function (component) {
        const flowName = this.getFlowName(component);
        if (flowName) {
            this.destroyFlow(component);
            $A.createComponent(
                "lightning:flow",
                {
                    "aura:id": "flow",
                    "onstatuschange": component.getReference("c.handleFlowStatusChange")
                },
                this.createComponentCallback(component)
            )
        }
    },
    processMessageParams: function (component, message) {
        ['flowName', 'flowVariables', 'inContextOfRef'].forEach(param => {
            const paramVal = message.getParam(param);
            if (paramVal) {
                component.set(`v.${param}`, paramVal);
            }
        });
    },
    clearMessageParams: function (component) {
        ['flowName', 'flowVariables', 'inContextOfRef'].forEach(param => {
            component.set(`v.${param}`, '');
        });
    },
    getPageRefUrl: function (pageRef) {
        let url = '';
        let params = ''
        if (pageRef) {
            if (pageRef.type === 'standard__recordPage') {
                const attrs = pageRef.attributes;
                url = `${url}lightning/r/${attrs.objectApiName}/${attrs.recordId}/${attrs.actionName}`;
            }
            if (pageRef.state) {
                for (const param in pageRef.state) {
                    if (pageRef.state.hasOwnProperty(param)) {
                        params = `${params}${param}=${pageRef.state[param]}&`
                    }
                }
            }
        }
        return `/${url}?${params}`;
    },
    showErrorToast: function (component, errorItem, errorLog) {
        if (errorLog) {
            console.error(errorLog);
        }
        const messageAction = component.get('c.getMsgWithDefault');
        messageAction.setParams({
            key: 'CHILD_CALL_ERROR',
            category: 'CallReport',
            defaultMessage: 'There are errors for {0}'
        });
        messageAction.setCallback(this, function (response) {
            let errorMessage = 'There are errors for {0}';
            var state = response.getState();
            if (state === "SUCCESS") {
                errorMessage = response.getReturnValue();
            } else if (state === "INCOMPLETE") {
                console.warn('Error Veeva Message request incomplete; using default');
            } else if (state === "ERROR") {
                console.warn(`Error Veeva Message request failed; using default. Reason: ${response.getError()}`);
            }
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "message": errorMessage.replace('{0}', errorItem)
            });
            toastEvent.fire();
        });
        $A.enqueueAction(messageAction);
    },
    getFlowName: function (component) {
        const pageRef = component.get('v.pageReference');
        let flowName = component.get('v.flowName');
        if (!flowName && pageRef && pageRef.state) {
            flowName = pageRef.state.c__flowName;
        }
        if (!flowName && !component.get('v.noDefaultFlow')) {
            // default flow name if not specified
            flowName = 'VeevaRecordTypeSelectorFlow';
        }
        return flowName;
    },
    getFlowVariables: function (component) {
        const pageRef = component.get('v.pageReference');
        let flowVariables = component.get('v.flowVariables');
        if (!flowVariables && pageRef && pageRef.state && pageRef.state.c__flowVariables) {
            flowVariables = JSON.parse(pageRef.state.c__flowVariables.replaceAll('\\\\\\*','*').replaceAll('\\\\\\\'','\''));
            const defaultFieldValues = flowVariables.find(variable => variable.name === "defaultFieldValues");
            if (defaultFieldValues && !(typeof (defaultFieldValues.value) === 'string' || defaultFieldValues.value instanceof String)) {
                // We will pass defaultFieldValues to a Lightning flow so we will need to make it a string
                defaultFieldValues.value = JSON.stringify(defaultFieldValues.value);
            }
        }
        if (!flowVariables && pageRef && pageRef.attributes && pageRef.attributes.objectApiName) {
            flowVariables = [{
                name: 'objectApiName',
                value: pageRef.attributes.objectApiName,
                type: 'String'
            }];
            if (pageRef.state) {
                if (pageRef.state.inContextOfRef){
                    flowVariables.push(
                        {
                            name: 'flowContext',
                            value: JSON.stringify(pageRef.state.inContextOfRef),
                            type: 'String'
                        }
                    )
                }
                if (pageRef.state.defaultFieldValues){
                    flowVariables.push(
                        {
                            name: 'defaultFieldValues',
                            value: (typeof pageRef.state.defaultFieldValues === 'string') ? pageRef.state.defaultFieldValues : JSON.stringify(pageRef.state.defaultFieldValues),
                            type: 'String'
                        }
                    )
                }
            }
        }
        return flowVariables;
    },
    getInContextOfRefFromState: function (component) {
        const pageRef = component.get('v.pageReference');
        if (pageRef && pageRef.state && pageRef.state.c__inContextOfRef) {
            return JSON.parse(pageRef.state.c__inContextOfRef)
        } else if (pageRef && pageRef.state && pageRef.state.inContextOfRef) {
            if (typeof pageRef.state.inContextOfRef === 'string'){ 
                let base64Context = pageRef.state.inContextOfRef;
                if (base64Context.startsWith("1.")) {
                    base64Context = base64Context.substring(2);
                }
                return JSON.parse(window.atob(base64Context));
            } else {
                return pageRef.state.inContextOfRef;
            }
        }
        return null;
    },
    destroyFlow: function (component) {
        const flow = component.find("flow");
        if (flow && flow.destroy) {
            flow.destroy();
        }
    },
    createComponentCallback: function (component) {
        return function (flowComponent, status, errorMessage) {
            if (status === "SUCCESS") {
                const body = component.get("v.body");
                body.push(flowComponent);
                component.set("v.body", body);

                const flowName = this.getFlowName(component);
                const flowVariables = this.getFlowVariables(component);
                if (flowVariables) {
                    flowComponent.startFlow(flowName, flowVariables);
                } else {
                    flowComponent.startFlow(flowName);
                }
            } else if (status === "INCOMPLETE") {
                this.showErrorToast(component, 'messageFlow', 'Flow creation was incomplete: ' + errorMessage);
            } else if (status === "ERROR") {
                this.showErrorToast(component, 'messageFlow', 'Flow creation error: ' + errorMessage);
            }
        }.bind(this);
    }
})