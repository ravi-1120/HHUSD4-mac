({
    setEditPageProperties: function(component) {
        setPageReference(component);
        setObjectApiName(component);

        function setPageReference(component) {
            let refToSet;
            
            const origRef = component.get('v.pageReference');
            if (!origRef) {
                refToSet = {
                    "attributes": {
                        "objectApiName": component.get('v.objectApiName'),
                        "actionName": "edit"
                    },
                    "state": {
                        "recordId": component.get('v.recordId'),
                    }
                };
                const flowContext = component.get('v.flowContext');
                if (flowContext && typeof flowContext === 'string') {
                    const inContextOfRef = JSON.parse(flowContext);
                    if (inContextOfRef) {
                        refToSet.state.inContextOfRef = inContextOfRef;
                    }
                }
            }
            if (refToSet) {
                component.set('v.pageReference', refToSet);
            }
        }

        function setObjectApiName(component) {
            if (!component.get('v.objectApiName')) {
                const pageRef = component.get('v.pageReference');
                if (pageRef && pageRef.attributes) {
                    component.set('v.objectApiName', pageRef.attributes.objectApiName);
                }
            }
        }
    },
})