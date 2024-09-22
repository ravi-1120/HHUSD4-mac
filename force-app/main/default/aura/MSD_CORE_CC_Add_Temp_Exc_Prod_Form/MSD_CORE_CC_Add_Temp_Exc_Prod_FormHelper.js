({
	isFormValid: function(component, event, helper){
        let failedFields = [];
        let fieldVal = component.find("required").get("v.value");
        var isValid = true;
        if(helper.isNotBlank(fieldVal)){
            isValid = false;
        }
        return isValid;
    },
    
    handleSaveAddEvent : function(component, event, helper) {
        try{
            var nextConfigs = component.get('v.lottabs');
            var lastLotId = nextConfigs.length + 1;
            console.log('component.get("v.recordId") -->'+component.get("v.recordId"));
            nextConfigs.push({'label': 'Lot Details '+lastLotId,
                              'id': JSON.stringify(lastLotId), 
                              'recId':'', 
                              'mode':'NEW',
                              'lotParentId' : component.get("v.recordId")
                             });
            component.set("v.selectedLotTabId",JSON.stringify(lastLotId));
            component.set('v.lottabs', nextConfigs);
        }catch(e){}
    },
})