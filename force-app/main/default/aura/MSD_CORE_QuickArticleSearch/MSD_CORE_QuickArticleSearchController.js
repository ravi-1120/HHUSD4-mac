({
	handleRefreshEvent : function(component, event, helper) {
        if(component.get("v.displayOnRecordPage"))
        {
         	component.set("v.refreshArticleSearch", false);
        	component.set("v.refreshArticleSearch", true);   
        }
	}
})