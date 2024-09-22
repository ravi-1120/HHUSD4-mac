({
    doInit :  function(component, event, helper){
        if(component.get("v.recordId").startsWith("500")){
            var action = component.get('c.getCaseStatus');
            action.setParams({
                "csId": component.get('v.recordId')
            });
            action.setCallback(this, function(response) {
                if(response.getState() === "SUCCESS"){
                    var caseStatus = response.getReturnValue();
                    if(caseStatus == 'Open')
                    {
                        component.set("v.showAdd", true);
                        component.set("v.caseId",component.get("v.recordId"));
                        component.set('v.tabs', [{
                            id: '1',
                            label: 'Product 1',
                            recId: '',
                            mode:'NEW'
                        }]);
                    }
                }
            });
            $A.enqueueAction(action);
            
            
        } 
        else{
            component.set("v.isEdit", true);
            component.set("v.mode", 'Edit ');
        }
    }, 
    
    handleRecordUpdate :  function(component, event, helper){
        if(component.get("v.firstPass"))
        {
            var objTEProd = component.get("v.TEProd");
            component.set("v.caseId", objTEProd.MSD_CORE_Case__c);
            var objTEProd = component.get("v.TEProd");
            component.set("v.oldVaccAdministeredVal", objTEProd.MSD_CORE_Was_Vaccine_Administered__c);
            component.set('v.tabs', [{
                id: '1',
                label: objTEProd.Name + ' ('+objTEProd.MSD_CORE_Product__r.Name+')',
                recId: component.get("v.recordId"),
                mode:'EDIT'
            }]);
            component.set("v.firstPass", false);
            var modal = component.find('addProduct');
            $A.util.removeClass(modal, 'slds-hide');
        }
    }, 
    
    handleSelect: function (component, event, helper) {
        console.log(JSON.stringify(event.getParams()));
        if(event.getParam('id') == 'add_prod'){
            helper.addProduct(component, event, helper);
           /* try{
                
                
            var nextConfigs = component.get('v.tabs');
            console.log('tabs debug before -->'+JSON.stringify(nextConfigs));
            var lastProdId = nextConfigs.length + 1;
            var lottabs = [{
                    'id': '1',
                    'label': 'Lot Details 1',
                    'recId':'',
                    'mode':'NEW',
                    'lotParentId': '' 
                }];
            nextConfigs.push({'label': 'Product '+lastProdId, 
                              'id': JSON.stringify(lastProdId),
                              'recId': '',
                              'mode':'NEW',
                              'showLotDetailTabs':false
                              
                             });
            component.set("v.selectedTabId",JSON.stringify(lastProdId));
            console.log('tabs debug after-->'+JSON.stringify(nextConfigs));
            component.set('v.tabs', nextConfigs);
            }
            catch(e){}*/
        }
        /*var nextConfigs = component.get('v.tabs').map(function (config) {
            if (config.id === event.getParam('id')) {
                config.count += 1;
                config.content = 'Number of times "' + config.label + '" selected: ' + config.count;
            }
            return config;
        });
        cmp.set('v.tabs', nextConfigs);*/
    },
    
    
    
    addProduct : function(component, event, helper) {
		var modal = component.find('addProduct');
        $A.util.toggleClass(modal, 'slds-hide');
        component.set("v.caseId",component.get("v.recordId"));
        component.set('v.tabs', [{
            id: '1',
            label: 'Product 1',
            recId: '',
            mode:'NEW'
        }]);
        component.set("v.showAEPQCDialogbeforeClose", false);
        component.set("v.buttonDisabled",false);
        component.set("v.refreshRequired", false);
        component.set("v.selectedTabId", "1");
        component.set("v.refreshArticleSearch",true);
	},
    
    closeModal : function(component, event, helper) {
        if(component.get("v.isEdit")){
            if(component.get("v.oldVaccAdministeredVal") != 'Yes' && component.get("v.showAEPQCDialogbeforeClose")){
                var modal = component.find('addProduct');
                $A.util.toggleClass(modal, 'slds-hide');
                var modal = component.find('confirmPop');
            	$A.util.toggleClass(modal, 'slds-hide');
                component.set("v.refreshArticleSearch",false);
                //$A.get('e.force:refreshView').fire();
            }
            else{
                if(component.get("v.refreshRequired")){
                    var workspaceAPI = component.find("workspace");
                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                        var focusedTabId = response.parentTabId;
                        workspaceAPI.refreshTab({
                                  tabId: focusedTabId,
                                  includeAllSubtabs: true
                         });
                    })
                    .catch(function(error) {
                        console.log(error);
                    });
                }
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });
            }
        }
        else{
            var modal = component.find('addProduct');
            $A.util.toggleClass(modal, 'slds-hide');
            if(component.get("v.showAEPQCDialogbeforeClose")){
                var modal = component.find('confirmPop');
                $A.util.toggleClass(modal, 'slds-hide');
            }
            if(component.get("v.refreshRequired")){
                $A.get('e.force:refreshView').fire();
            }
            component.set("v.refreshArticleSearch",false);
        }
        
        var modal = component.find('knowledgePreviewSection');
        $A.util.addClass(modal, 'slds-hide');
        
        var modal = component.find('knowledgeSearch');
        $A.util.removeClass(modal, 'slds-hide');
        /*
        if(component.get("v.showAEPQCDialogbeforeClose")){
            if(!component.get("v.isEdit")){
                var modal = component.find('addProduct');
                $A.util.toggleClass(modal, 'slds-hide');
                var modal = component.find('confirmPop');
                $A.util.toggleClass(modal, 'slds-hide');
                $A.get('e.force:refreshView').fire();
            }
        }
        else{
            //var modal = component.find('addProduct');
            //$A.util.toggleClass(modal, 'slds-hide');
            if(component.get("v.isEdit")){
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.parentTabId;
                    workspaceAPI.refreshTab({
                              tabId: focusedTabId,
                              includeAllSubtabs: true
                     });
                })
                .catch(function(error) {
                    console.log(error);
                });
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });
            }
            else{
                if(component.get("v.refreshRequired")){
                    $A.get('e.force:refreshView').fire();
                }
            }
        }*/
	},
    
    closeAEPQCModal : function(component, event, helper) {
        var modal = component.find('confirmPop');
        $A.util.toggleClass(modal, 'slds-hide');
        if(component.get("v.isEdit")){
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.closeTab({tabId: focusedTabId});
            })
            .catch(function(error) {
                console.log(error);
            });
        }
	},
    
    addProductTab : function(component, event, helper) {
		var modal = component.find('addProduct');
        $A.util.toggleClass(modal, 'slds-hide');
	},
    
    handleTempProdCmpEvt : function(component, event, helper) {
        var tempProdName = event.getParam("tempProdName");
        var recId = event.getParam("recId");
        var lotName = event.getParam("lotName");
        var lotId = event.getParam("lotId");
        var wasVaccAdministered = event.getParam("wasVaccAdministered");
        if(wasVaccAdministered != null && wasVaccAdministered == 'Yes'){
            component.set("v.showAEPQCDialogbeforeClose", true);
        } 
        if(helper.isNotBlank(recId)){
            component.set("v.refreshRequired", true);
        }
        
        var selectedTabId = component.get("v.selectedTabId");
        var tabs = component.get('v.tabs');
        for(var i in tabs){
            if(tabs[i].id == selectedTabId){
                tabs[i].label = tempProdName;
                tabs[i].recId = recId;
                tabs[i].mode = 'VIEW';
                tabs[i].showLotDetailTabs =true;
                tabs[i].lottabs = [{
                                    'id': '1',
                                    'label': 'Lot Details 1',
                                    'recId': lotId,
                    				'mode': helper.isNotBlank(lotId) ? 'VIEW' : 'NEW',
                                    'lotParentId': recId }];
               /* tabs[i].lottabs = [{
                                    'id': '1',
                                    'label': 'Lot Details 1',
                                    'recId': '',
                    				'mode': 'NEW',
                                    'lotParentId': recId }]; */
            }
        }
        component.set("v.showTabs", false);
        component.set("v.tabs", tabs);
        setTimeout($A.getCallback(() => component.set("v.showTabs", true)),100);
	},
    
    handleSaveAddEvent : function(component, event, helper) {
        var nextConfigs = component.get('v.tabs');
        var lastProdId = nextConfigs.length + 1;
        
        nextConfigs.push({'label': 'Product '+lastProdId, 'id': JSON.stringify(lastProdId), 'recId': '', 'mode':'NEW'});
        component.set("v.selectedTabId",JSON.stringify(lastProdId));
        component.set('v.tabs', nextConfigs);
    },
    
    handleSubmit: function(component, event, helper) {
        
    },
    handleSuccess: function(component, event, helper) {
        
    },
    handleError: function(component, event, helper) {
        
    },
    
    handleVaccAdminEvent : function(component, event, helper) {
        component.set("v.showAEPQCDialogbeforeClose", true);
    },
    
    createAEPQC : function(component, event, helper) {
        component.set("v.buttonDisabled", true);
        var action = component.get("c.createChildComboCase");
        action.setParams({ "caseId" : component.get("v.caseId")
                         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var modal = component.find('confirmPop');
        		$A.util.toggleClass(modal, 'slds-hide');
                $A.get('e.force:refreshView').fire();
                var caseId = response.getReturnValue();
                var focusedTabId ='';
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    focusedTabId = response.tabId;
                });
                workspaceAPI.openSubtab({
                    parentTabId: focusedTabId,
                    recordId: caseId,
                    focus: true
                });
            }
            else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type": "error",
                    "message": "An exception has occured."
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
        
    handleKnowledgeSection : function(component, event, helper){
        var knowledgeArticleId = event.getParam("knowledgeArticleId");
        component.set("v.knowledgeArticleId", knowledgeArticleId);
        var modal = component.find('knowledgePreviewSection');
        $A.util.toggleClass(modal, 'slds-hide');
        
        var modal = component.find('knowledgeSearch');
        $A.util.toggleClass(modal, 'slds-hide');
    },    
    
})