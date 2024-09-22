({
	helperInit : function(component, event, helper) {
        
		var action = component.get("c.setDisclaimer"); 
        action.setParams({
            'csId' : component.get("v.recordId")                
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.disclaimer', response.getReturnValue());
                
                var caseType = response.getReturnValue().cs.MSD_CORE_Event_Case_Type__c;
                var recordTypeName = response.getReturnValue().cs.RecordType.Name;
                
                component.set("v.recordTypeName", recordTypeName.replace("Combo Case", "AE & PQC"));
            	component.set("v.isAccessiable", response.getReturnValue().isAccess);
                
                if(response.getReturnValue().cs.RecordType.Name == 'Product Complaint' ||
                   response.getReturnValue().cs.RecordType.Name == 'Combo Case')
                	component.set("v.hidePQC", "true");
                /*-----------start Priyanka CEF2F-18174-----------------------------------------------*/
                if(response.getReturnValue().cs.RecordType.Name == 'Adverse Event' &&
                   response.getReturnValue().cs.Type == 'Improperly Stored/Expired Product' &&
                   response.getReturnValue().cs.MSD_CORE_Is_Cloned__c==true &&
                  response.getReturnValue().cs.MSD_CORE_Org_Case_Cloned__c != null)
                {
                     component.set("v.AECloneRec", "true");               
                }
              /*---------------------------End Priyanka CEF2F-18174------------------------------------*/  
                if(document.getElementById("productComplaint") != null && caseType != undefined){
            		if(recordTypeName === 'Product Complaint' &&  caseType.indexOf('PQC') != -1){
                        document.getElementById("productComplaint").disabled = true;
                        document.getElementById("productComplaint").checked = true;
                    }       
                }
            } else {
                
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
	},
    aeChangeHelper : function(component, event, helper) {
        var type = component.find('csType').get('v.value');
        var currentRecord = component.get("v.disclaimer");          
        
        if(currentRecord != null && type != '' && currentRecord.cs.Type != type)  
        {         
            component.set("v.hidePQC", "true");
        }
      
        
        
        if(type != '')
        {
        	var action = component.get("c.saveCase"); 
            action.setParams({
                'csId' : component.get("v.recordId"),
                'csType' : component.find('csType').get('v.value')       
            });
            action.setCallback(this, function(response) {
                console.log(type);
    		    var state = response.getState();
                if (state === "SUCCESS") {
                    //window.location.reload();
                    this.refreshFocusedTab(component, event, helper);
                    $A.get('e.force:refreshView').fire();
                } else {
                    console.log('An exception');
                }
            });
            $A.enqueueAction(action);    
        }
	},
    updateCaseHelper : function(component, event, helper) {
        component.set("v.hideAE", true);
        var action = component.get("c.updateRecordType"); 
        action.setParams({
            'csId' : component.get("v.recordId")      
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //window.location.reload();
                console.log('response2 -->'+JSON.stringify(response.getReturnValue()));
                $A.get('e.force:refreshView').fire();
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);   
    },
    refreshFocusedTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.refreshTab({
                      tabId: focusedTabId,
                      includeAllSubtabs: true
             });
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})