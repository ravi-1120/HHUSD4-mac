({
    doInit: function(component, event, helper) {
        var url;
        /*var actionURL = component.get('c.getRedirectingURLForPrintArticles');
        actionURL.setParams({});
        actionURL.setCallback(this, function(responses){
            if(responses.getState() == "SUCCESS"){
                url  = responses.getReturnValue();
            }
        });
        $A.enqueueAction(actionURL);*/
        
        var action = component.get('c.getKnowledgeArticleId');
        action.setParams({
            "recordId": component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS"){
                $A.get("e.force:closeQuickAction").fire();
                var caseStatus = response.getReturnValue();
                window.open('/knowledge/articlePrintableView.apexp?id=' + caseStatus);                
            }
        });
        $A.enqueueAction(action);
    },
    closeQA: function(component, event, helper) {
        
    }
})