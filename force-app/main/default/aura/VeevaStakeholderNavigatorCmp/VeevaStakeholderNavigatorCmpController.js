({
    onPageReferenceChange: function(component, event, helper) {
        var newPageRef = component.get("v.pageReference");
        if (newPageRef.state.c__id !== component.get("v.rootId")) {
            $A.get('e.force:refreshView').fire();
        }
    },
    init: function(component, event, helper) {
    	var myPageRef = component.get("v.pageReference");
    	var id = myPageRef.state.c__id;
    	component.set("v.rootId", id);
	}
})