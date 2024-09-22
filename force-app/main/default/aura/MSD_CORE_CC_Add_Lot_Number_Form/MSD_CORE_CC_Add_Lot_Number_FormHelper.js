({
	isFormValid: function(component, event, helper){
        let failedFields = [];
        let fields = component.find("field");
        for(let i in fields){
            console.log('field ->'+JSON.stringify(fields[i]));
            if(helper.isNotBlank(fields[i]) && typeof fields[i] === "object"){
                if(!helper.isNotBlank(fields[i].get("v.value"))){
                    failedFields.push(" "+fields[i]["fieldLabel"]);
                }
            }
        }
        console.log('failedFields -->'+JSON.stringify(failedFields));
        return failedFields;
        /*
        const requiredFields = component.find('required') || [];
        var isValid = true;
        requiredFields.forEach(e => {
            if (e.get('v.value')=='' || e.get('v.value').trim().length==0 ) {
                isValid = false;
            }
        });
        return isValid;*/
    },
})