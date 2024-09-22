({
	handleIRMSClick : function(component, event, helper) {
        var action = component.get("c.getRequestLinks");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var url = response.getReturnValue();
                var IRMSClick =  url.MSD_CORE_CC_IRMS_Click__c ;
                window.open(IRMSClick);
            }
        });
        $A.enqueueAction(action);
		/*var urlEvent = $A.get("e.force:navigateToURL");
    	urlEvent.setParams({
            "url": 'http://irms-cms.merck.com/irmscms/Login/Login.aspx?ReturnUrl=/default.aspx?'
    });
    	urlEvent.fire();*/
        
	},
    closeFlowModal : function(component, event, helper) {
        component.set("v.isOpen", false);
    },

closeModalOnFinish : function(component, event, helper) {
        
            component.set("v.isOpen", false);
        },
    handleSampleCenterClick : function(component, event, helper) {
        var action = component.get("c.getRequestLinks");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var url = response.getReturnValue();
                var sampleCenterClick =  url.MSD_CORE_CC_Sample_Center_Click__c ;
                window.open(sampleCenterClick);
            }
        });
        $A.enqueueAction(action);
		/*var urlEvent = $A.get("e.force:navigateToURL");
    	urlEvent.setParams({
      "url": 'http://fastmsc.merck.com/'
    });
    	urlEvent.fire();*/
	},
    handleROMEClick : function(component, event, helper) {
        var action = component.get("c.getRequestLinks");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var url = response.getReturnValue();
                var romeClick =  url.MSD_CORE_CC_ROME_Click__c; 
               window.open( romeClick);
            }
        });
        $A.enqueueAction(action);
		/*var urlEvent = $A.get("e.force:navigateToURL");
    	urlEvent.setParams({
      "url": 'http://rome.merck.com/rome/rsrchome.do?ReturnUrl=/default.aspx?'
    });
    	urlEvent.fire();*/
	},
    
    handleSAPClick : function(component, event, helper) {
        var action = component.get("c.getRequestLinks");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var url = response.getReturnValue();
                var sapClick =  url.MSD_CORE_CC_SAP_Click__c ;
                window.open(sapClick);
            }
        });
        $A.enqueueAction(action);
		/*var urlEvent = $A.get("e.force:navigateToURL");
    	urlEvent.setParams({
      "url": 'https://usctap5131.merck.com/Citrix/AccessPlatform/site/default.aspx?'
    });
    	urlEvent.fire();*/
	},
    handleTeamspaceClick : function(component, event, helper) {
        var action = component.get("c.getRequestLinks");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var url = response.getReturnValue();
                var teamspaceClick =  url.MSD_CORE_CC_Teamspace_Click__c ;
                window.open(teamspaceClick);
            }
        });
        $A.enqueueAction(action);
		/*var urlEvent = $A.get("e.force:navigateToURL");
    	urlEvent.setParams({
      "url": 'http://teamspaceext.merck.com/sites/us3c/Representative%20Resources/Representative%20Resources.aspx?'
    });
    	urlEvent.fire();*/
	},
    openModal : function(component, event, helper) {
        
        var workspaceAPI = component.find("workspace");
        var recordId = component.get("v.recordId");
        var currentOwnerId = null
        //alert ('userID:'+ userId+',caseOwner:'+currentOwnerId);
        
        var campaign = null
        var product =  null
        var state =  null
       // var package = null
         var action = component.get("c.getRequestFieldsData"); 
            action.setParams({
                csId: component.get("v.recordId")
            });
            action.setCallback(this, function(response) {
                console.log(response.getReturnValue())
                var state = response.getState();
                console.log('state -->'+state);
                if (state === "SUCCESS") {
                    var records =response.getReturnValue();
                    
        var currentOwnerId = records.OwnerId
        //alert ('userID:'+ records+',caseOwner:'+currentOwnerId);
        
        var campaign = records.MSD_CORE_Campaign__c;
        var product =  records.Product_MVN__c;
        var state =  records.case_State_MVN__c;
        var isclosed = records.MSD_CORE_PCC_Agent_Request_Case_Closed__c;
                    
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        //alert ('state:'+ state);
                    if (isclosed){
                        alert($A.get("$Label.c.MSD_CORE_DTC_Script_completed"));
                    }
                    else{
        if(campaign == null || product == null){
		alert($A.get("$Label.c.MSD_CORE_Campaign_Required"));
		}else{
        if(state == null ){
		alert($A.get("$Label.c.MSD_CORE_Address_Required"));
        }else{
            if (userId != currentOwnerId){
                alert($A.get("$Label.c.MSD_CORE_User_Must_be_Owner"));
            }
            else{
                
        var tabs = workspaceAPI.getFocusedTabInfo();
        console.log(tabs);
        workspaceAPI.openTab({
          url: '/flow/MSD_CORE_PCC_Fulfillment?varCaseRecordID='+recordId+'&retURL='+recordId,
         focus: true
        });
        component.set("v.showPopup", true);
        }
            }
    }
                }
                } else {
                    console.log('An exception while getting request values');
                }
            });
            $A.enqueueAction(action);
      /*  component.set('v.isOpen', true);
        if (component.get('v.isOpen') == true){
             var inputVariables = [
         { name : "varCaseRecordID", type : "String", value: recordId }, 
         { name : "retURL", type : "String", value: recordId}
       ];
       var flow = component.find('v.flow');
        console.log(flow);
       flow.startFlow('MSD_CORE_PCC_Fulfillment',inputVariables);
        }
        */       
        
        }
    
})