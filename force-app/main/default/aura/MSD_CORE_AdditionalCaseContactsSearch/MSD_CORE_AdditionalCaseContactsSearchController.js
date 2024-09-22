({
	doInit : function(component, event, helper) {
		component.set("v.fieldList",helper.getFields(component, event, helper));
		//helper.searchCaseContacts(component, event, helper);
	},
    
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
    
    searchCaseContacts : function(component, event, helper){        
    	helper.searchCaseContacts(component, event, helper);
    },
    
    saveSelected : function(component, event, helper){
        helper.saveSelected(component, event, helper);
    },
    
    createNew : function(component, event, helper){
        helper.createNew(component, event, helper);
    },
    
    closeModal : function(component, event, helper){
        component.set("v.popUpOpen", false);
    },
    
    handleKeyEnter : function(component, event, helper){
        if (event.keyCode === 13)
            helper.searchCaseContacts(component, event, helper);
    }
})