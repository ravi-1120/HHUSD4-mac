({
    clone : function(component, event, helper) {
        var newRecId = component.get("v.recordId");
        var navigate = component.get("v.navigateFlow");
        navigate("FINISH");
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            url: '#/sObject/'+newRecId+'/view',
            focus: true
        });
        component.set('v.loaded', !component.get('v.loaded'));
    },
    clone1 : function(component, event, helper) {
        var action = component.get('c.requestAECaseClone');
       
        action.setParams({
            recordId: component.get('v.recordId'),
            objectAPIName: component.get('v.objectAPIName'),
            deepClone : component.get('v.isDeepClone'),
            fieldSetName:component.get('v.fieldSetName'),
        });
        console.log('recordId>>>>'+recordId);
        console.log('objectAPIName>>>>>>>'+objectAPIName);
        console.log('deepClone>>>>>>>'+deepClone);
        console.log('fieldSetName>>>>>>'+fieldSetName);
        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS"){
                var res = response.getReturnValue();
                console.log('Issue'+JSON.stringify(res.oRecordId));
                var navigate = component.get("v.navigateFlow");
                navigate("FINISH");
                var workspaceAPI = component.find("workspace");
                workspaceAPI.openTab({
                    url: '#/sObject/'+res.oRecordId+'/view',
                    focus: true
                });
                component.set('v.loaded', !component.get('v.loaded'));
            }
            
            else
            {
                console.log('Issue'+response.getState());
            }
        });
        $A.enqueueAction(action);
    }
})