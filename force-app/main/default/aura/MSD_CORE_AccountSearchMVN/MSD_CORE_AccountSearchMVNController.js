({
    doInit : function(component, event, helper) {
        component.set("v.rerenderNewButtons", false);
        
        if(component.get("v.searchCriteria")["Person"] == undefined){
            component.set("v.fieldList", component.get("v.searchCriteria"));
        }
        else{
            component.set("v.fieldList", component.get("v.searchCriteria"));
            helper.searchAccount(component, event, helper);
            component.set("v.showCloseButton", true);
        }
            
        var fieldList = component.get("v.fieldList.Person");
       
        var action = component.get("c.countryList");
        action.setCallback(this, function(actionResult) {
            component.get("v.countryList");
            if(actionResult.getState() === "SUCCESS"){
                component.set("v.countryList", actionResult.getReturnValue());
                component.set("v.sel", "United States");
            }
        });
        $A.enqueueAction(action);
        
        action = component.get("c.stateList");
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                component.set("v.stateList", actionResult.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        
        action = component.get("c.userCountry");
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                component.set("v.userCountry", actionResult.getReturnValue());
            }
        });
        $A.enqueueAction(action);
		
        var ispersonAccount = (component.get('v.type') == 'Person' ? true : false);
		action = component.get("c.doChildSearch");
        action.setParams({
            isPersonSearch : ispersonAccount, 
            recentlyAddedBusiness: component.get('v.recentlyAddedBusiness'), 
            recentlyAddedPerson: component.get('v.recentlyAddedPerson')
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                var records = [];
                records = actionResult.getReturnValue();
                if(records != null){
                	component.set('v.dataList', actionResult.getReturnValue());
                }
            }
        });
        $A.enqueueAction(action);
    },
    formPress : function(component, event, helper) {
        if (event.keyCode === 13)
            helper.searchAccount(component, event, helper);
    },
    clearSearch : function(component, event, helper) {
        component.set("v.fieldList",helper.getFields(component, event, helper));
        component.set("v.dataList", []);
        component.set("v.rerenderNewButtons", false);
    },
    searchAccountJs : function(component, event, helper) {
        helper.searchAccount(component, event, helper);
    },
    setTypeText : function(component, event, helper) {
        component.set("v.typeText", event.currentTarget.dataset.id);
    },
    addCustomer : function(component, event, helper) {
        var ids = event.target.id.split('-');
        component.set("v.searchMsg",'Please wait...');
        component.set("v.rerenderAfterSearch", false);
        
        var action = component.get('c.updateCaseAura');
        action.setParams({
            selectedPersonId : ids[0], 
            selectedAddressId: ids[1], 
            csId: component.get('v.recordId')
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                component.set("v.searchMsg",'');
                component.set("v.rerenderAfterSearch", true);
                
                var myEvent2 = $A.get("e.c:MSD_CORE_AccountQuery");
                myEvent2.setParams({"refreshCustInfo": ids[0]});
                myEvent2.fire();
                if(component.get("v.showCloseButton"))
                {
                    var myEvent = $A.get("e.c:MSD_CORE_CC_RefreshCustInfoCTI");
                    myEvent.setParams({"refreshCustInfo": true});
                    myEvent.fire();
                }
                $A.get("e.c:MSD_CORE_CC_RefreshCustInfoCTI").fire();
            }
        });
        $A.enqueueAction(action);
    },
    addReferredByJS : function(component, event, helper) {
        var id = event.target.id;
        component.set("v.searchMsg",'Please wait...');
        component.set("v.rerenderAfterSearch", false);
        
        var action = component.get('c.addReferredBy');
        action.setParams({
            refId: id, 
            csId: component.get('v.recordId')
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                var myEvent2 = $A.get("e.c:MSD_CORE_AccountQuery");
                myEvent2.setParams({"refreshCustInfo": id});
                myEvent2.fire();
                
                component.set("v.searchMsg",'');
                component.set("v.rerenderAfterSearch", true);
                $A.get("e.c:MSD_CORE_CC_RefreshCustInfoCTI").fire();
            }
        });
        $A.enqueueAction(action);
    },
    addBusiness : function(component, event, helper) {
        var id = event.target.id;
        component.set("v.searchMsg",'Please wait...');
        component.set("v.rerenderAfterSearch", false);
        
        var action = component.get('c.addBusinessAura');
        action.setParams({
            businessId: id, 
            csId: component.get('v.recordId')
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                component.set("v.searchMsg",'');
                component.set("v.rerenderAfterSearch", true);
                
                var myEvent2 = $A.get("e.c:MSD_CORE_AccountQuery");
                myEvent2.setParams({"refreshCustInfo": id});
                myEvent2.fire();
                
                $A.get("e.c:MSD_CORE_CC_RefreshCustInfoCTI").fire();
            }
        });
        $A.enqueueAction(action);
    },
    openModal : function(component, event, helper) {
        component.set("v.searchMsg",'');
        var childComp = component.find("newAccCmp");
        var selectedType = component.get("v.typeText");
        var whichOne = event.getSource().getLocalId();
        component.set('v.whichOne', whichOne);
        var type = component.get('v.type');
        var ispersonAccount = (type == 'Person' ? true : false);
        //childComp.find('Class_of_Trade_Sub_MRK__c').set("v.value", "");
        //childComp.find('typeList').set("v.value", "");
        //childComp.find('classOfTrade').set("v.value", "");
        
        setTimeout(function(){
            if(ispersonAccount){
                childComp.find('Preferred_Salutation_MRK__c').set("v.value", "");
                childComp.find('Preferred_Suffix_MRK__c').set("v.value", "");
                childComp.find('Preferred_Middle_Name_MRK__c').set("v.value", "");
                childComp.find('PersonEmail').set("v.value", "");
                childComp.find('Fax').set("v.value", "");
                if(component.get("v.typeText") != 'All')
                    childComp.find('classOfTrade').set("v.value", component.get("v.typeText"));
                else
                    childComp.find('classOfTrade').set("v.value", "");
                
                /*if(childComp.find('MSD_CORE_Employee_Company__c') != undefined)
                	childComp.find('MSD_CORE_Employee_Company__c').set("v.value", "");
                if(childComp.find('MSD_CORE_Employee_Alias__c') != undefined)
                	childComp.find('MSD_CORE_Employee_Alias__c').set("v.value", "");
                if(childComp.find('MSD_CORE_Merck_Employee_ID__c') != undefined)
                	childComp.find('MSD_CORE_Merck_Employee_ID__c').set("v.value", "");*/
                
                childComp.find('Preferred_First_Name_MRK__c').set("v.value", component.get("v.firstName"));
                childComp.find('Preferred_Last_Name_MRK__c').set("v.value", component.get("v.lastName"));
                childComp.find('Phone').set("v.value", component.get("v.phone"));
                
                
                childComp.callTypeChange();
            }else{
                childComp.find('Account_vod__c').set("v.value", "");
                childComp.find('Preferred_Full_Name_MRK__c').set("v.value", component.get("v.name"));
            }    
            
            childComp.find('Name').set("v.value", "");
            childComp.find('Address_line_2_vod__c').set("v.value", "");
            childComp.find('MSD_CORE_Rep_Notes__c').set("v.value", "");
            childComp.find('City_vod__c').set("v.value", component.get("v.city"));
            childComp.find('State_vod__c').set("v.value", component.get("v.state"));
            childComp.find('Zip_vod__c').set("v.value", component.get("v.zip"));
            childComp.find('Country_vod__c').set("v.value", component.get("v.country"));
        }, 500);
        
        component.set("v.showSearch", true);
    },
    closeModal : function(component, event, helper) {
        component.set("v.showSearch", false);
        component.set("v.rerenderAfterSearch", false);
        component.set("v.rerenderAfterSearch", true);
        var myEvent = $A.get("e.c:MSD_CORE_CC_RefreshCustInfoCTI");
        myEvent.setParams({"refreshCustInfo": true});
        myEvent.fire();
    },
    formatPhoneNumber: function(component, helper, event) {
        try{
            var phoneNo = component.find("phoneInput");
            var phoneNumber = phoneNo.get('v.value');
            var s = (""+phoneNumber).replace(/\s/g, '').replace(/\D/g, '');
            var m = s.match(/^(\d{3})(\d{3})(\d{4})$/);
            var formattedPhone = (!m) ? null : "(" + m[1] + ") " + m[2] + "-" + m[3];
            phoneNo.set('v.value',formattedPhone);
        }
        catch(e){}
    },
    openAccount : function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var recId = selectedItem.dataset.id;
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            if(response.isSubtab){
                workspaceAPI.openSubtab({
                    parentTabId: response.parentTabId,
                    url: '/'+recId,
                    focus: true
                });
            }
            else{
                workspaceAPI.openTab({
                    url: '/'+recId,
                    focus: true
                });
            }
        }).catch(function(error) {
            console.log(error);
        });
    },
    closeSearchTab : function(component, event, helper) {
    	var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    handleCommonValueChange: function(component, event, helper) {
        var compEvent = component.getEvent("MSD_CORE_CC_SearchCriteria");
        compEvent.setParams({"fieldList" : component.get("v.fieldList"), 'type':component.get("v.type")});
        compEvent.fire();
    },
    
    stageChange : function(component, event, helper)
    {
        try{
            setTimeout(function(){
                var fieldList = component.get("v.fieldList");
                fieldList.CommonFields[2].value =  component.get("v.state");
                component.set("v.fieldList", fieldList);
            }, 1000);
        }
        catch(e){}
    }
    
})