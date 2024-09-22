({
	
    doInit : function(component, event, helper) {
        console.log(component.get("v.recordId"));
        var action = component.get('c.requiresDCRProcessing');
        action.setParams({
            accountId: component.get('v.recordId')
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                var res = actionResult.getReturnValue();
                //alert('response for accountId DCR Processing-->'+JSON.stringify(actionResult.getReturnValue()));
                component.set('v.isDCRProcessingRequired', res.requiresDCRProcessing);
            }
        });
        $A.enqueueAction(action);
	},

        
    handleEdit : function(component, event, helper) {
        //alert(component.get('v.simpleRecord.Status_MRK__c'));
        if(component.get('v.simpleRecord.Status_MRK__c') =='INACTIVE'||component.get('v.simpleRecord.Status_MRK__c') =='PENDING' ){
            var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Info',
            message: $A.get("$Label.c.MSD_CORE_Unable_to_Edit_HCP_HBP_Accounts"),
            duration:'5000',
            key: 'info_alt',
            type: 'info',
            mode: 'dismissible'
        });
        toastEvent.fire();
        }
        else{ 
        
            if(component.get('v.isDCRProcessingRequired')){ //KRB DGF-223
                
               var urlEvent = $A.get("e.force:navigateToURL");//Edit_Account_DCR_vod
    	       urlEvent.setParams({
                   "url": '/apex/MSD_CORE_DCR_Account_Edit?id='+component.get("v.recordId")
               });
    	       
               urlEvent.fire();
            
            //KRB DGF-223
            }else{ //not DCR Processed, navigate to standard Edit Page...

               var editRecordEvent = $A.get("e.force:editRecord");
               editRecordEvent.setParams({
                      "recordId": component.get("v.recordId")
               });
               editRecordEvent.fire();

            }

        }
	}
})