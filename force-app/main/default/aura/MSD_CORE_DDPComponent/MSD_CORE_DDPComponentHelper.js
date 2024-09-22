({
	helperInit : function(component, event, helper) {
		var action = component.get("c.getSessionIdFromVFPage"); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.sessionId', response.getReturnValue());
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
        
        action = component.get("c.getAEFieldsData"); 
        action.setParams({
            'csId' : component.get("v.recordId")                
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.casedata', response.getReturnValue());
                var cs = response.getReturnValue();
                component.set("v.caseAccId",cs.AccountId);
                if(cs.RecordType.Name == 'Adverse Event' || cs.RecordType.Name == 'Adverse Event - Closed' || cs.RecordType.Name == 'Adverse Event - Submitted')
                    component.set('v.ddpFilter', 'AE');
                else if(cs.RecordType.Name == 'Product Complaint' || cs.RecordType.Name == 'Product Complaint - Closed' || cs.RecordType.Name == 'Product Complaint - Submitted')
                    component.set('v.ddpFilter', 'PQC');
                else if(cs.RecordType.Name == 'CR Request' || cs.RecordType.Name == 'CR Request - Closed')
                    component.set('v.ddpFilter', 'Comp');
                else if(cs.RecordType.Name == 'Temperature Excursion' || cs.RecordType.Name == 'Temperature Excursion - Closed')
                    component.set('v.ddpFilter', 'TempEx');
                else if(cs.RecordType.Name == 'Combo Case' || cs.RecordType.Name == 'Combo Case - Closed' || cs.RecordType.Name == 'Combo Case - Submitted')
                    component.set('v.ddpFilter', 'AE and PQC');
                else if(cs.RecordType.Name == 'Request' || cs.RecordType.Name == 'Request - Closed' || cs.RecordType.Name == 'Request - Email Case')
                    component.set('v.ddpFilter', 'General');
            
            	this.registerUtilityClickHandler(component, event, helper);
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
        
        action = component.get("c.getValidCase"); 
        action.setParams({
            'csId' : component.get("v.recordId")                
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.isValid', response.getReturnValue());
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
	}, 
    registerUtilityClickHandler: function(component, event, helper){
        var utilityBarAPI = component.find("utilitybar");
                
        utilityBarAPI.getAllUtilityInfo().then(function(response) {
            var utilityId = response[0].id;
            var numRecords = component.get("v.numRecords");
            
            var eventHandler = function(response){
                //utilityBarAPI.minimizeUtility();
                //helper.openModalHelper(component, event, helper); 
            };
            
            utilityBarAPI.onUtilityClick({ 
                eventHandler: eventHandler 
            }).then(function(result){
                
            }).catch(function(error){
                console.log(error);
            });

        })
        .catch(function(error) {
            console.log('-------> utilityAPI ERROR: ' + error);
        });
    },
	openModalHelper : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        var recordId = component.get("v.recordId");
        var sessionId = component.get("v.sessionId");
        var ddpFilter = component.get("v.ddpFilter");
        var caseAccId = component.get("v.caseAccId");
        var tabs = workspaceAPI.getFocusedTabInfo();
        console.log(tabs);
        
        var url = encodeURI('/apex/loop__looplus?sessionId='+sessionId+'&eid='+recordId+'&lightningExperience=false&accountId='+caseAccId+'&header=false&hidecontact=true&filter='+ddpFilter);
        
        if(caseAccId == undefined)
            url = encodeURI('/apex/loop__looplus?sessionId='+sessionId+'&eid='+recordId+'&lightningExperience=false&header=false&hidecontact=true&filter='+ddpFilter);
        
        var url = '/apex/loop__looplus?sessionId='+sessionId+'&eid='+recordId+'&lightningExperience=false&accountId='+caseAccId+'&header=false&hidecontact=true&filter='+ddpFilter;
        
        if(caseAccId == undefined)
        	url = '/apex/loop__looplus?sessionId='+sessionId+'&eid='+recordId+'&lightningExperience=false&header=false&hidecontact=true&filter='+ddpFilter;
        
        let newWin = window.open(url, 'Send DDP', 'height=700,width=1050');
        
        var pollTimer = setInterval(function(){
            if (newWin.closed) {
                $A.get('e.force:refreshView').fire();
                
                window.clearInterval(pollTimer);
            }
        }, 1000);
	}
})