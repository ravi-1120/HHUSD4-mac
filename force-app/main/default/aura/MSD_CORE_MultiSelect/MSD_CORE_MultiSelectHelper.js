({
    setInfoText: function(component, labels) {
        
        if (labels.length == 0) {
            component.set("v.infoText", "Select an option...");
        }
        if (labels.length >= 1) {
            component.set("v.infoText", labels.toString());
        }
        else if (labels.length > 1) {
            component.set("v.infoText", labels.length + " options selected");
        }
        
        console.log('orgMypId'+component.get("v.orgMypId"));
        
        if(component.get("v.infoText") != 'Select an option...'){
            var addPermission = component.get("c.addPermission");  
            addPermission.setCallback(this, function(response) {
                var action = component.get("c.updateMYPprodLocation");
                
                action.setParams({
                    mypId:component.get("v.orgMypId"),
                    strProdLocation : component.get("v.infoText")
                });
                action.setCallback(this, function(response) {
                    //    this.hideSpinner(component);
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        console.log("value saved"); 
                    }
                    var deletePermission = component.get("c.deletePermission");  
                    deletePermission.setCallback(this, function(response) {
                        
                    });
                    $A.enqueueAction(deletePermission);
                });
                $A.enqueueAction(action);
            });
            $A.enqueueAction(addPermission);                                                    
        }
    },
    showSpinner: function (component) {
        var spinner = component.find("spinner2");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideSpinner: function (component) {
        var spinner = component.find("spinner2");
        $A.util.addClass(spinner, "slds-hide");
    },
    getSelectedValues: function(component){
        var options = component.get("v.options_");
        var values = [];
        options.forEach(function(element) {
            if (element.selected) {
                values.push(element.value);
            }
        });
        return values;
    },
    
    getSelectedLabels: function(component){
        var options = component.get("v.options_");
        var labels = [];
        options.forEach(function(element) {
            if (element.selected) {
                labels.push(element.label);
            }
        });
        return labels;
    },
    
    despatchSelectChangeEvent: function(component,values){
        var compEvent = component.getEvent("selectChange");
        compEvent.setParams({ "values": values });
        //compEvent.fire();
    }
})