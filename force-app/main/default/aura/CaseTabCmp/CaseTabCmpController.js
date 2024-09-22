({
    doInit : function(component, event, helper) {
        helper.doInit(component, event, helper);	
    },
    
    handleMyApplicationEvent : function(component, event, helper) {
        try{
            var articleSettings = component.get("v.articleSettings");
            if(articleSettings.MSD_CORE_CC_Enable_Auto_Search__c || event.getParam("bypassAutoSearch"))
            {
                var value = event.getParam("desc");
                if(component.get("v.recordId") == event.getParam("recId"))
                {
                    if(value){
                        var delayMillis = articleSettings.MSD_CORE_CC_Delay_in_Millis__c;
                        if( event.getParam("bypassAutoSearch"))
                        {
                            delayMillis = 50;
                        }
                        var timeoutId = component.get( "v.searchTimeoutId" );     
                        clearTimeout( timeoutId );
                        timeoutId = setTimeout( $A.getCallback( function() {
                            helper.searchDocs(component, event, helper, value);
                        }), delayMillis );
                        component.set( "v.searchTimeoutId", timeoutId );
                    }
                    else{
                        component.set("v.prevSearchText",'');
                        component.set("v.data", null);
                        component.set("v.allData", null);
                    }
                }
            }
        }
        catch(e)
        {
            
        }
    },
    
    handleKeyUp: function (component, event, helper) {
        if (event.keyCode === 13) {
            if(!helper.isNotBlank(component.get("v.objDetail"))){
                var quickSearchObj =  {"sobjectType":"Case_Document_MVN__c","Document_Type_MVN__c":"General_MVN__kav","Document_Language_MVN__c":"en_US","Country_MVN__c":"US"}
                component.set("v.objDetail", quickSearchObj);
            }
            helper.searchDocs(component, event, helper, component.get("v.documentSearchText"));
        }
    },
    handleKeyUpAdvanced: function (component, event, helper) {
        if (event.keyCode === 13) {
            helper.searchDocsAdvanced(component, event, helper, component.get("v.documentSearchText"));
        }
    },    
    
    searchArticles : function(component, event, helper) {
        helper.searchArticles(component, event, helper);
    },
    
    openModal : function(component, event, helper) {
        var modal = component.find('searchArticleSection');
        $A.util.toggleClass(modal, 'slds-hide');
        component.set("v.allData", component.get("v.data"));
        helper.searchArticles(component, event, helper);
    },
    
    closeModal : function(component, event, helper) {
        var modal = component.find('searchArticleSection');
        $A.util.toggleClass(modal, 'slds-hide');
    },
    
    searchDocs : function(component, event, helper) {
        var obj =  {"sobjectType":"Case_Document_MVN__c","Document_Type_MVN__c":"General_MVN__kav","Document_Language_MVN__c":"en_US","Country_MVN__c":"US"}
        component.set('v.objDetail',obj);
        if(component.get("v.documentSearchText") == null || component.get("v.documentSearchText") == '')
        {
            component.set("v.prevSearchText", '');
        }
        helper.searchDocs(component, event, helper, component.get("v.documentSearchText"));
        
    },
    searchDocsAdvanced : function(component, event, helper) {
        helper.searchDocsAdvanced(component, event, helper, component.get("v.documentSearchText"));		
    },
    
    reloadKnowledgeSearch : function(component, event, helper) {  
        if(component.get("v.customerType") == null){
            helper.doInit(component, event, helper);            
        }
    },
    
    onControllerFieldChange: function(component, event, helper) {  
        var controllerValueKey = event.getSource().get("v.value");
        helper.onControllingFieldChange(component, event, helper, controllerValueKey);
    },
    
    
    onSubControllerFieldChange : function(component, event, helper) {     
        var controllerValueKey = event.getSource().get("v.value"); // get selected sub controller field value
        var depnedentFieldMap = component.get("v.subDepnedentFieldMap");
        
        if (controllerValueKey != '-- None --') {
            var ListOfDependentFields = depnedentFieldMap[controllerValueKey];
            if(ListOfDependentFields.length > 0){
                component.set("v.bDisabledSubDependentFld" , false);  
                helper.fetchDepValues(component, ListOfDependentFields,"v.listSubDependingValues");    
            }else{
                component.set("v.bDisabledSubDependentFld" , true); 
                component.set("v.listSubDependingValues", ['-- None --']);
            }  
            component.set("v.objectDetail.MSD_CORE_Category__c", '--None--');
        } else {
            component.set("v.listSubDependingValues", ['-- None --']);
            component.set("v.bDisabledSubDependentFld" , true);
            component.set("v.objectDetail.Document_Subtype_MVN__c", '--None--');
        }
    },
    
    handleRowAction : function(component, event, helper){
        var isClosed = component.get('v.isClosed');
        if(!isClosed){
            $A.util.removeClass(component.find("spinner"),"slds-hide");
            var action = event.getParam('action');
            var row = event.getParam('row');            
            var wrapperLst = component.get("v.caseDocWrapperLst");
            
            var data = component.get('v.data');
            data = data.map(function(rowData) {
                
                if (rowData.Document_ID_MVN__c === row.Document_ID_MVN__c) {
                    rowData.actionDisabled = true;
                    rowData.linkName = '/lightning/r/Knowledge__kav/'+row.Document_ID_MVN__c;
                    rowData.attachIconName = "action:add_relationship";
                }
                return rowData;
            });
            component.set("v.data", data);
            
            var selectedCaseDoc = {};
            for(var i in wrapperLst){
                if(wrapperLst[i].caseDocument.Document_ID_MVN__c == row.Document_ID_MVN__c){
                    selectedCaseDoc = wrapperLst[i].caseDocument;
                    delete selectedCaseDoc['linkName'];
                    delete selectedCaseDoc['attachIconName'];
                    delete selectedCaseDoc['actionDisabled'];
                    var action = component.get("c.selectDocument"); 
                    action.setParams({
                        'selectedDocument' : selectedCaseDoc,
                        'caseId': component.get("v.recordId")                
                    });
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            $A.util.addClass(component.find("spinner"),"slds-hide");
                            var attachedArticles = component.get("v.knowledgeArticles");
                            attachedArticles.push(selectedCaseDoc);
                            component.set("v.knowledgeArticles", attachedArticles);
                            $A.get('e.force:refreshView').fire(); 
                        } else {
                            var errors = response.getError();
                            if (errors) {
                                if (errors[0] && errors[0].message) {
                                    /*alert("Error message: " + 
                                             errors[0].message);*/
                                    var toastEvent = $A.get("e.force:showToast");
                                    toastEvent.setParams({
                                        "type": "warning",
                                        "message": errors[0].message
                                    });
                                    toastEvent.fire();  
                                }
                            } else {
                                alert("Unknown error");
                            }
                        }
                    });
                    $A.enqueueAction(action);                    
                }
            }            
        }
        else{
            component.set("v.searchMsg",'Cannot attach on closed Case');
        }        
    },
    
    quickAttach : function(component, event, helper){
        component.set("v.showSpinner",true);
        if(!component.get("v.isClosed")){
            var index = event.getSource().get("v.name");
            var selectedCaseDoc = component.get("v.data")[index]; 
            delete selectedCaseDoc['linkName'];
            delete selectedCaseDoc['attachIconName'];
            delete selectedCaseDoc['actionDisabled'];            
            
            var data = component.get("v.data");            
            for(var i in data){
                if(i == index){
                    data[i].actionDisabled = true;
                    break;
                }
            }
            component.set("v.data", data);
            
            var action = component.get("c.selectDocument"); 
            action.setParams({
                'selectedDocument' : selectedCaseDoc,
                'caseId': component.get("v.recordId")                
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.knowledgeArticles", response.getReturnValue());
                    component.set("v.showSpinner",false);
                    $A.get('e.force:refreshView').fire();   
                    if(!component.get("v.displayOnRecordPage"))
                    {
                        var appEvt = $A.get("e.c:MSD_CORE_CC_RefreshQuickSearch");
                        appEvt.fire();
                    }
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            /*alert("Error message: " + 
                                     errors[0].message);*/
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "warning",
                                "message": errors[0].message
                            });
                            toastEvent.fire(); 
                            component.set("v.showSpinner",false);
                        }
                    } else {
                        alert("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
        }
        else{
            component.set("v.searchMsg",'Cannot attach on closed Case');
        }        
    },
    
    handleClick : function(component, event, helper){
        $A.util.removeClass(component.find("spinner"),"slds-hide");
        var index = event.currentTarget.getAttribute("data-attriVal");        
        var articles = component.get("v.knowledgeArticles");
        var articleId = '';
        var caseDocId = '';
        for(var i=0;i<articles.length;i++){
            if(i == index){
                articleId = articles[i].Document_ID_MVN__c;
                caseDocId = articles[i].Id;
            }
        }
        if(component.get("v.recTypeName") == 'Request_MVN')
        {
            var firstArticle = component.get("v.firstAttachedArticle");
            if(firstArticle == null)
            {
                var action2 = component.get("c.getFirstAttachedArticleId"); 
                action2.setParams({
                    caseId: component.get("v.recordId")
                });
                action2.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        component.set("v.firstAttachedArticle", response.getReturnValue());
                        if(caseDocId == response.getReturnValue())
                        {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "warning",
                                "message": "Please remember to check type and category for accuracy"
                            });
                            toastEvent.fire(); 
                        }
                    }
                });
                $A.enqueueAction(action2);
            }
            else{
                if(caseDocId == component.get("v.firstAttachedArticle"))
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "warning",
                        "message": "Please remember to check type and category for accuracy"
                    });
                    toastEvent.fire(); 
                }
            }
        }        
        
        component.set("v.showSpinner",true);
        var action = component.get("c.deleteArticle"); 
        action.setParams({
            caseDocId: caseDocId,
            caseId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                for(var i=0;i<articles.length;i++){
                    if(i == index){
                        articles.splice(i,1);
                    }
                }
                component.set("v.knowledgeArticles",articles);
                component.set("v.showSpinner",false);
                $A.util.addClass(component.find("spinner"),"slds-hide");
                var data = component.get('v.data');
                if(data){
                    data = data.map(function(rowData) {
                        if (rowData.Document_ID_MVN__c === articleId) {
                            rowData.actionDisabled = false;
                            rowData.linkName = '/'+articleId;
                            rowData.attachIconName = "action:add_relationship";
                        }
                        return rowData;
                    });
                    component.set("v.data", data);
                }
                if(!component.get("v.displayOnRecordPage"))
                {
                    var appEvt = $A.get("e.c:MSD_CORE_CC_RefreshQuickSearch");
                    appEvt.fire();
                }
                $A.get('e.force:refreshView').fire();
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
    },
    
    navigateToKnowledge : function(component, event, helper){        
        var articleId = event.target.getAttribute("data-knowledge-id");
        if(component.get("v.displayOnRecordPage"))
        {
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": articleId
            });
            navEvt.fire();
        }
        else{
            var myEvent = $A.get("e.c:MSD_CORE_CC_KnowledgePreviewEvt");
            myEvent.setParams({"knowledgeArticleId": articleId});
            myEvent.fire();
        }  
    },
    
    openPop : function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var componentid = selectedItem.dataset.record;
        var cmpTarget = document.getElementById(componentid);
        $A.util.removeClass(cmpTarget, 'slds-hide');
        $A.util.addClass(cmpTarget, 'slds-show');            
    },
    
    openPopFocus : function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var componentid = selectedItem.dataset.record;
        var cmpTarget = document.getElementById(componentid);
        component.set("v.popOverId",componentid);
        $A.util.addClass(cmpTarget, 'slds-show');
        $A.util.removeClass(cmpTarget, 'slds-hide');
    },
    
    
    setPopOver : function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var componentid = selectedItem.dataset.record;
        component.set("v.popOverId",componentid);
    },
    
    removePopOver : function(component, event, helper) {
        component.set("v.popOverId",null);
        
        var selectedItem = event.currentTarget;
        var componentid = selectedItem.dataset.record;
        var cmpTarget = document.getElementById(componentid);
        
        $A.util.addClass(cmpTarget, 'slds-hide');
        $A.util.removeClass(cmpTarget, 'slds-show');
        
    },
    
    closePop : function(component, event, helper) {          
        var selectedItem = event.currentTarget;
        var componentid = selectedItem.dataset.record;
        var cmpTarget = document.getElementById(componentid);
        
        window.setTimeout(
            $A.getCallback(function() {
                if(component.get("v.popOverId") != componentid){
                    $A.util.addClass(cmpTarget, 'slds-hide');
                    $A.util.removeClass(cmpTarget, 'slds-show');
                }
            }), 150
        );        
    },
    
    closePopFocus : function(component, event, helper) {
        component.set("v.popOverId",'');
        var selectedItem = event.currentTarget;
        var componentid = selectedItem.dataset.record;
        var cmpTarget = document.getElementById(componentid);
        
        $A.util.addClass(cmpTarget, 'slds-hide');
        $A.util.removeClass(cmpTarget, 'slds-show');        
    },
    
    onNext : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber+1);
        helper.buildData(component, helper);
    },
    
    onPrev : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber-1);
        helper.buildData(component, helper);
    },
    
    processMe : function(component, event, helper) {
        component.set("v.currentPageNumber", parseInt(event.target.name));
        helper.buildData(component, helper);
    },
    
    onFirst : function(component, event, helper) {        
        component.set("v.currentPageNumber", 1);
        helper.buildData(component, helper);
    },
    
    onLast : function(component, event, helper) {        
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.buildData(component, helper);
    },
})