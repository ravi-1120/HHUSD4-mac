({
	getFields : function(component, event, helper){
        return {
            Search: [
                {placeholder:'Last Name',fieldName:"LastName",value:''},
                {placeholder:'First Name',fieldName:"FirstName",value:''},
                {placeholder:'Phone',fieldName:"City_vod__c",value:''},
                {placeholder:'Emp Number',fieldName:"Zip_vod__c",value:''},
                {placeholder:'City',fieldName:"City",value:''},
                {placeholder:'Zip',fieldName:"Zip",value:''},
                {placeholder:'State',fieldName:"State_vod__c",value:'AA'},
                {placeholder:'Country',fieldName:"Country_vod__c",value:'US'}
             ]
         }
    },
    
    getPicklistValues: function(component,event,helper) {
        var picklist_fields = ["State_vod__c","Country_vod__c"];
        var cmp_attributes = ["v.statePicklistValues","v.countryPicklistValues"];
        var action = component.get("c.getFieldsMapPicklists");
        action.setCallback(this, function(response) {
            var values = response.getReturnValue();
            for(var k=0;k < picklist_fields.length;k++){	
                var picklist_field_values = values[picklist_fields[k]];
                var picklist_values=[];
                for(var key in picklist_field_values){
                	picklist_values.push({value: key, label:picklist_field_values[key]});
                }
                component.set(cmp_attributes[k], picklist_values); 
            }
        });
        $A.enqueueAction(action);
    },
})