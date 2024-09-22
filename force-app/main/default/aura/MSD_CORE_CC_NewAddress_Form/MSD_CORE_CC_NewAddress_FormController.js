({
    doInit : function(component, event, helper) {
        //console.log('entered');
        
          
            component.set('v.showSpinner', true);
            var action = component.get("c.addFields");
        //console.log('calling.....'+ component.get('v.parentRT'));
            action.setParams({ "RTName" : component.get('v.parentRT')});
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log(response.getState());
                if (state === "SUCCESS") {
                    console.log(response.getReturnValue());
                    //component.set("v.addFields", response.getReturnValue());

               }
            });
            $A.enqueueAction(action);
                    component.set('v.showSpinner', false);        
    },
    
    handleLoad: function(component, event, helper) {
        if(helper.isNotBlank(component.get("v.recordId")) && component.get("v.mode") != 'VIEW'){
            console.log(JSON.stringify(event.getParams()));
            var record = event.getParam("recordUi").record;            
            var fields = record.fields;
            var fieldValue = fields.MSD_CORE_Related_to__c.value;
            if(helper.isNotBlank(fieldValue)){
                if(fieldValue == 'AE'){
                    component.set("v.checkboxVal","AE");
                }
                if(fieldValue == 'PQC'){
                    component.set("v.checkboxVal","PQC");
                }
                if(fieldValue == 'AE and PQC'){
                    var chekedList = [];
                    chekedList.push('AE');
                    chekedList.push('PQC');
                    component.set("v.checkboxVal",chekedList);
                }
            }
            
        }
    },
    
    handleSave: function(component, event, helper) {
        console.log(component.get('v.parentId'));
        console.log('entered handle save----------');
        component.set('v.Account_vod__c', component.get('v.parentId'));
          component.set('v.Inactive_vod__c', true);
        console.log(component.get('v.parentId'));
        var error =''
        
        
        console.log(component.get('v.Mailing_vod__c'));
        console.log(component.get('v.Business_vod__c'));
        console.log(component.get('v.Home_and_Office_MRK__c'));
        if(component.get('v.parentRT') == 'HCP' || component.get('v.parentRT') == 'HBP'){
         if(component.get("v.Mailing_vod__c") == false || component.get("v.Mailing_vod__c") == null ) {
              if(component.get("v.Business_vod__c") == false || component.get("v.Business_vod__c") == null ){
                   if(component.get("v.Home_and_Office_MRK__c") == false  || component.get("v.Home_and_Office_MRK__c")== null){
                       error = 'error';
                       var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Form Incomplete!",
                "type": "error",
                "message": "Please select atleast 1 Address Type"
            });
            toastEvent.fire();
                }
             }
           }
         }
         
         
          //Business Accounts Validation Rule 
         if(component.get('v.parentRT') == 'Organization_vod' || component.get('v.parentRT') == 'Pharmacy_vod' || component.get('v.parentRT') == 'Hospital_vod'){
         if(component.get("v.Mailing_vod__c") == false || component.get("v.Mailing_vod__c")  == null ) {
              if(component.get("v.Physical_Address_MRK__c")  == false || component.get("v.Physical_Address_MRK__c") == null ){
				 error = 'error';
                  var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Form Incomplete!",
                "type": "error",
                "message": "Please select atleast 1 Address Type"
            });
            toastEvent.fire();
             }
           }
         }
        if (error != 'error'){
            console.log("entered without error")
            component.find('addressViewForm').submit();
        }
    },
    
    handleSubmit: function(component, event, helper) {
    },
    
    handleError: function(component, event, helper) {
        // errors are handled by lightning:inputField and lightning:messages
        // so this just hides the spinner
        component.set('v.showSpinner', false);
    },
    
    handleSuccess: function(component, event, helper) {
        component.set('v.showSpinner', true);
            var action = component.get("c.CreateDCR");
        //console.log('calling.....'+ component.get('v.parentRT'));
            action.setParams({ "Addob" : component.get('v.Address_vod__c')});
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log(response.getState());
                if (state === "SUCCESS") {
                    console.log(response.getReturnValue());
                    //component.set("v.addFields", response.getReturnValue());

               }
            });
            $A.enqueueAction(action);
                    component.set('v.showSpinner', false);    
        
    },
    
    handleChange: function(component, event, helper) {
    },
  closeFocusedTab : function(component, event, helper) {
     component.set('v.showSpinner', false);
        
       
      try{
                var workspaceAPI = component.find("workspace1");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                });
            }catch(e) {}
    }
})