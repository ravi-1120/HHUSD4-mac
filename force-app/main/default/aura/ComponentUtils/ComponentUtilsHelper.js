({
    isNotBlank : function(checkString) {
        return (checkString != '' && checkString != null &&
                !$A.util.isEmpty(checkString) && !$A.util.isUndefined(checkString));
    },
    
    showToast : function(component,event,helper,title,msg,type){
        let showToast = $A.get("e.force:showToast");
        if(showToast){
            showToast.setParams({
                "title": title,
                "message": msg,
                "type": type
            }).fire();
        }
    },
})