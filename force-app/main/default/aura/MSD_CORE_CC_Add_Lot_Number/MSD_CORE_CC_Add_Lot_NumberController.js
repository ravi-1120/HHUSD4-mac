({
    addLotNumber : function(component, event, helper) {
       	var objCase = component.get("v.simpleRecord");
        var rtId = '';
        if(objCase.RecordType.Name.indexOf("CR") > -1)
        {
           rtId = '012U0000000MsmEIAS'; //comp req
        }
        else if (objCase.RecordType.Name.indexOf("Product") > -1){
            rtId = '012U0000000MsmFIAS'; //pqc
        }
        
        if(helper.isNotBlank(rtId)){
            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": "MSD_CORE_Lot_Number__c",
                "defaultFieldValues": {
                    'MSD_CORE_Case__c' : component.get("v.recordId")                   
                },
                "recordTypeId" : rtId
            });
            createRecordEvent.fire();
        }
        
	},
    
	addLot : function(component, event, helper) {
        var modal = component.find('addLot');
        $A.util.toggleClass(modal, 'slds-hide');
	},
    
    closeModal : function(component, event, helper) {
        var modal = component.find('addLot');
        $A.util.toggleClass(modal, 'slds-hide');
	},
    
    handleCloseEvent : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        var modal = component.find('addLot');
        $A.util.toggleClass(modal, 'slds-hide');
	},

})