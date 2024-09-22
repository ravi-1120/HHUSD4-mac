({
    getKnowledgeArticle : function(component, event, helper) {
        component.set("v.showSpinner",true);
        var action = component.get('c.getKnowledge');
        action.setParams({
            kavId: component.get('v.knowledgeArticleId')
        });       
        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS"){
                component.set("v.showSpinner",false);
                component.set('v.kav', response.getReturnValue().kav); 
                console.log('kav -->'+JSON.stringify(response.getReturnValue().kav));
                if(response.getReturnValue().profileName.indexOf('Agent') != -1)
                {
                    component.set('v.isAgentProfile',true);
                }
                else{
                    component.set('v.isAgentProfile',false);
                }
            }
        });
        $A.enqueueAction(action);
    }
})