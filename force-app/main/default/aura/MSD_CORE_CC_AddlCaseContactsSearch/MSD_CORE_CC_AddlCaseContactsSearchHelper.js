({
	 getFields : function(component, event, helper){
        return {
            Fields: [
                {placeholder:'First Name',fieldName:"First Name",value:''},
                {placeholder:'Last Name',fieldName:"Last Name",value:''}
                
             ],
            Address : [
                {placeholder:'Phone',fieldName:"Phone",value:''},
                {placeholder:'City',fieldName:"City",value:''},
                {placeholder:'Zip',fieldName:"Zip",value:''}
            ],
            RadioOptions : [
                {'label': 'All', 'value': 'All'},
                {'label': 'CONSUMER', 'value': 'CONSUMER'},
                {'label': 'EMPLOYEE', 'value': 'EMPLOYEE'},
                {'label': 'HEALTHCARE BUSINESS PROF', 'value': 'HEALTHCARE BUSINESS PROF'},
                {'label': 'INDIV HEALTHCARE PROF', 'value': 'INDIV HEALTHCARE PROF'}
            ]
         }
    },
    
    getFieldsToSearch : function(component, event, helper){
        var accSearchFields = component.get("v.fieldList").Fields;
        var addressSearchFields = component.get("v.fieldList").Address;
        var fieldsToSearch = {};
        for(var i in accSearchFields){
            if(helper.isNotBlank(accSearchFields[i].value)){
                fieldsToSearch[accSearchFields[i].fieldName] = accSearchFields[i].value;                
            }
        }
        
        for(var i in addressSearchFields){
            if(helper.isNotBlank(addressSearchFields[i].value)){
                fieldsToSearch[addressSearchFields[i].fieldName] = addressSearchFields[i].value;                
            }
        }
        return fieldsToSearch;
    }
})