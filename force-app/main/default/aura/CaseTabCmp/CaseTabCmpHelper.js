({
    doInit : function(component, event, helper) {
        var action = component.get("c.getCase");
        action.setParams({
            caseId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                component.set("v.articleSettings", res.articleSettings);
                var objCase = res.objCase;
                component.set("v.recTypeName", objCase.RecordType.DeveloperName);
                component.set("v.firstAttachedArticle", objCase.First_Attached_Article__c);
                component.set('v.isReadOnlyUser',res.isReadOnlyUser);
                component.set('v.customerType', objCase.Customer_Type_MVN__c);
                if(objCase.Status != 'Open'){
                    component.set('v.isClosed', true);
                }
                else{
                    if(!res.isReadOnlyUser){
                        if(helper.isNotBlank(res.objCase.Customer_Type_MVN__c) && (helper.isNotBlank(res.objCase.MSD_CORE_AE_Description__c) ||  helper.isNotBlank(res.objCase.Customer_Type_MVN__c))){
                            var quickSearchObj =  {"sobjectType":"Case_Document_MVN__c","Document_Type_MVN__c":"General_MVN__kav","Document_Language_MVN__c":"en_US","Country_MVN__c":"US"}
                            component.set("v.objDetail", quickSearchObj);
                            var rtName = res.objCase.RecordType.DeveloperName;
                            
                            var descriptionVal = '';
                            if(rtName == 'Interaction_MVN'){
                                var descriptionVal = res.objCase.Interaction_Notes_MVN__c;
                            }
                            if(rtName == 'Request_MVN'){
                                var descriptionVal = res.objCase.Details_MVN__c;
                            }
                            if(rtName == 'Combo_Case_MVN' || rtName == 'Adverse_Event_MVN' || rtName == 'Product_Complaint_MVN'){
                                var descriptionVal = res.objCase.MSD_CORE_AE_Description__c;
                            }
                            if(rtName == 'MSD_CORE_Temperature_Excursion'){
                                var descriptionVal = res.objCase.Details_MVN__c;
                            }
                            if(rtName == 'MSD_CORE_Compensation_Request'){
                                var descriptionVal = res.objCase.Details_MVN__c;
                            }
                            
                            if(!component.get("v.displayOnRecordPage")){
                            	helper.searchDocs(component, event, helper, descriptionVal);
                            }
                        }
                    }
                }
                if(helper.isNotBlank(JSON.stringify(res.attachedArticles))){
                    component.set("v.knowledgeArticles",res.attachedArticles);
                }
                
                var showQuickSearch = component.get("v.showQuickSearch");
                if(showQuickSearch){
                    //helper.searchArticles(component, event, helper);
                }
            } else {
                console.log('An exception has occured');
            }
        });
        $A.enqueueAction(action);	
    },
    
    fetchPicklistValues: function(component,objDetails,controllerField, dependentField,mapAttrName) {
        $A.util.removeClass(component.find("spinner"),"slds-hide");
        // call the server side function  
        var action = component.get("c.getDependentMap");
        // pass paramerters [object definition , contrller field name ,dependent field name] -
        // to server side function 
        action.setParams({
            'objDetail' : objDetails,
            'contrfieldApiName': controllerField,
            'depfieldApiName': dependentField 
        });
        //set callback   
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                $A.util.addClass(component.find("spinner"),"slds-hide");
                //store the return response from server (map<string,List<string>>)  
                var StoreResponse = response.getReturnValue();
                // once set #StoreResponse to depnedentFieldMap attribute 
                component.set(mapAttrName,StoreResponse);
                
                if(mapAttrName == 'v.depnedentFieldMap'){
                    
                    // create a empty array for store map keys(@@--->which is controller picklist values) 
                    var listOfkeys = []; // for store all map keys (controller picklist values)
                    var ControllerField = []; // for store controller picklist value to set on lightning:select. 
                    
                    // play a for loop on Return map 
                    // and fill the all map key on listOfkeys variable.
                    for (var singlekey in StoreResponse) {
                        listOfkeys.push(singlekey);
                    }
                    
                    //set the controller field value for lightning:select
                    if (listOfkeys != undefined && listOfkeys.length > 0) {
                        ControllerField.push('-- None --');
                    }
                    
                    for (var i = 0; i < listOfkeys.length; i++) {
                        ControllerField.push(listOfkeys[i]);
                    }  
                    // set the ControllerField variable values to country(controller picklist field)
                    component.set("v.listControllingValues", ControllerField);
                }
            }else{
                alert('Something went wrong..');
            }
        });
        $A.enqueueAction(action);
    },
    
    fetchDepValues: function(component, ListOfDependentFields,lstAttrName) {
        // create a empty array var for store dependent picklist values for controller field  
        var dependentFields = [];
        dependentFields.push('-- None --');
        for (var i = 0; i < ListOfDependentFields.length; i++) {
            dependentFields.push(ListOfDependentFields[i]);
        }
        // set the dependentFields variable values to store(dependent picklist field) on lightning:select
        component.set(lstAttrName, dependentFields);
        
    },
    
    fetchOtherPicklistValues : function(component,event,helper) {
        $A.util.removeClass(component.find("spinner"),"slds-hide");
        var action = component.get("c.getFieldsMapPicklists"); 
        
        var picklist_fields = ["Document_Language_MVN__c","Country_MVN__c"];
        
        var cmp_attributes = ["v.Document_Language_MVN__c","v.Country_MVN__c"];
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.util.addClass(component.find("spinner"),"slds-hide");
                var values = response.getReturnValue();
                for(var k=0;k < picklist_fields.length;k++){
                    var picklist_field_values = values[picklist_fields[k]];
                    var picklist_values=[];
                    picklist_values.push({value: '', label: '--None--'});
                    for(var key in picklist_field_values){
                        picklist_values.push({value: key, label:picklist_field_values[key]});
                    }
                    component.set(cmp_attributes[k], picklist_values); 
                }
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
    },
    
    onControllingFieldChange : function(component, event, helper, fieldVal){
        var controllerValueKey = fieldVal; // get selected controller field value
        var depnedentFieldMap = component.get("v.depnedentFieldMap");
        
        if (controllerValueKey != '-- None --') {
            // disable and reset sub dependent field 
            var ListOfDependentFields = depnedentFieldMap[controllerValueKey];            
            if(ListOfDependentFields.length > 0){
                component.set("v.bDisabledDependentFld" , false);  
                helper.fetchDepValues(component, ListOfDependentFields,"v.listDependingValues");    
            }else{
                component.set("v.bDisabledDependentFld" , true); 
                component.set("v.listDependingValues", ['-- None --']);
            }  
            
        } else {
            component.set("v.listDependingValues", ['-- None --']);
            component.set("v.bDisabledDependentFld" , true);
        }
        
        component.set("v.bDisabledSubDependentFld" , true);
        component.set("v.listSubDependingValues", ['-- None --']);
    },
    
    searchArticles : function(component, event, helper) {
        var custType = component.get("v.customerType");
        if(helper.isNotBlank(custType)){
            component.set("v.productId",'');
            const columns = [
                {type: 'button', initialWidth: 20, typeAttributes:
                 { variant: 'base', label: { fieldName: 'actionLabel'}, title: 'Add Document', name: 'edit_status', iconName: {fieldName: 'attachIconName'}, disabled: {fieldName: 'actionDisabled'}, class: 'btn_next'}},
                /*{label: '', fieldName: 'attach', initialWidth:34, cellAttributes: { iconName: { fieldName: 'attachIconName' }, iconLabel: { fieldName: 'attachIconLabel' } }},*/
                { label: 'Title', fieldName: 'linkName', type:"url", tooltip : 'Tool tip', typeAttributes: {label: { fieldName: 'Document_Title_MVN__c' },target: '_parent'}, sortable: true},
                { label: 'Subtype', initialWidth: 150, fieldName: 'Document_Subtype_MVN__c', type: 'text', sortable: true },
                { label: 'Category', initialWidth: 150, fieldName: 'MSD_CORE_Category__c', type: 'text', sortable: true },
                { label: 'Language', initialWidth: 80, fieldName: 'Document_Language_MVN__c', sortable: true }
            ];
            
            component.set("v.columns",columns);
            
            const qscolumns = [
                {type: 'button', initialWidth: 20, typeAttributes:
                 { variant: 'base', label: { fieldName: 'actionLabel'}, title: 'Add Document', name: 'edit_status', iconName: {fieldName: 'attachIconName'}, disabled: {fieldName: 'actionDisabled'}, class: 'btn_next'}},
                { label: 'Title', fieldName: 'linkName', type:"url", tooltip : 'Tool tip', typeAttributes: {label: { fieldName: 'Document_Title_MVN__c' },target: '_blank'}, sortable: true}
            ];
            
            component.set("v.qscolumns",qscolumns);
            
            var modal = component.find('searchArticleSection');
            var showQuickSearch = component.get("v.showQuickSearch");
            if(!showQuickSearch)
                $A.util.toggleClass(modal, 'slds-hide');
            
            var controllingFieldAPI = component.get("v.controllingFieldAPI");
            var dependingFieldAPI = component.get("v.dependingFieldAPI");
            var subDependingFieldAPI = component.get("v.subDependingFieldAPI");
            
            var objDetails = component.get("v.objDetail");
            // call the helper function
            helper.fetchPicklistValues(component,objDetails,controllingFieldAPI, dependingFieldAPI, "v.depnedentFieldMap");
            
            // 2nd and 3ed picklist 
            helper.fetchPicklistValues(component,objDetails,dependingFieldAPI, subDependingFieldAPI, "v.subDepnedentFieldMap");
            
            var action = component.get("c.getPage"); 
            var picklist_fields = ["Document_Type_MVN__c","Document_Subtype_MVN__c","MSD_CORE_Category__c","Document_Language_MVN__c","Country_MVN__c","Product_vod__c"];
            var cmp_attributes = ["v.Document_Type_MVN__c","v.Document_Subtype_MVN__c","v.MSD_CORE_Category__c","v.Document_Language_MVN__c","v.Country_MVN__c","v.Product_vod__c"];
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var values = response.getReturnValue().optionsMap;
                    component.set("v.objDetail.Document_Language_MVN__c",response.getReturnValue().defaultLanguage);
                    component.set("v.objDetail.Country_MVN__c",'US');
                    component.set("v.objDetail.Document_Type_MVN__c",'General');
                    for(var k=0;k < picklist_fields.length;k++){
                        var picklist_field_values = values[picklist_fields[k]];
                        var picklist_values=[];
                        for(var key in picklist_field_values){
                            picklist_values.push({value: key, label:picklist_field_values[key]});
                        }
                        component.set(cmp_attributes[k], picklist_values); 
                    }
                    helper.onControllingFieldChange(component, event, helper, 'General');
                } else {
                    console.log('An exception');
                }
            });
            $A.enqueueAction(action);
            
            var action = component.get("c.getAttachedKnowledgeArticles"); 
            action.setParams({
                caseId: component.get("v.recordId")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var records =response.getReturnValue();
                    component.set("v.knowledgeArticles", records);
                } else {
                    console.log('An exception');
                }
            });
            $A.enqueueAction(action);
            
        }
        else{
            if(!showQuickSearch){
                //helper.showToast(component,event,helper,'Error',$A.get("$Label.c.MSD_CORE_Specify_a_Customer_Type"),'error');
            }
        }
    },
    
    searchDocs : function(component, event, helper, searchText){
        var articleSettings = component.get("v.articleSettings");
        var numOfWordsToSearch;
        if(articleSettings.MSD_CORE_CC_Limit_Flag__c)
        {
            numOfWordsToSearch = articleSettings.MSD_CORE_CC_Limit_Words__c;
        }        
        console.log('searchText -->'+searchText);
        if(helper.isNotBlank(searchText) && searchText.length >= 3){
            var searchWords = searchText.toLowerCase().replace(/[\n\r]/g, ' ').split(' ');
            
            var stopWords = $A.get("$Label.c.MSD_CORE_CC_ArticleSearchStopWords").toLowerCase().split(',');
            var finalSearchText = [];
            var count = 0; 
            for(var i in searchWords)
            {
                if((numOfWordsToSearch >= count) || numOfWordsToSearch == null)
                {
                    var s = searchWords[i];
                    if((s.length >= 3 && !stopWords.includes(searchWords[i])) || s == 'AE' || s == 'ae')
                    { 
                        finalSearchText.push(s);
                    }  
                    count++;
                }
                else{
                    break;
                }
            }
            
            var uniquesearchWords = [];
            // Loop through array values
            for(i=0; i < finalSearchText.length; i++){
                if(uniquesearchWords.indexOf(finalSearchText[i]) === -1) {
                    uniquesearchWords.push(finalSearchText[i]);
                }
            }
            console.log('finalSearchText length-->'+finalSearchText.length);
            searchText = uniquesearchWords.join(' ');
            console.log('searchText -->'+searchText);
            var obj =  {"sobjectType":"Case_Document_MVN__c","Document_Type_MVN__c":"General_MVN__kav","Document_Language_MVN__c":"en_US","Country_MVN__c":"US"}
            
            var prodId = component.get("v.productId");
            var searchTypeOverride = component.get("v.searchTypeOverride");
            
            var isQuickSearch = component.get("v.showQuickSearch");
            if(isQuickSearch){
                var quickSearchObj =  {"sobjectType":"Case_Document_MVN__c","Document_Type_MVN__c":"General_MVN__kav","Document_Language_MVN__c":"en_US","Country_MVN__c":"US"}
                component.set("v.objDetail", quickSearchObj);
            }
            if(helper.isNotBlank(searchText)){
                if(component.get("v.prevSearchText") != searchText){
                    component.set("v.searchMsg",'Searching...');
                component.set("v.prevSearchText", searchText);
                var action = component.get("c.search"); 
                action.setParams({
                    'documentSearchText' : searchText,
                    'objDetail': component.get('v.objDetail'),
                    'caseId': component.get("v.recordId") ,
                    'searchTypeOverride' : prodId != '' ? prodId : 'All',
                    'productId' : searchTypeOverride != '' ? searchTypeOverride : null,
                    'isQuickSearch' : true
                });
                /*action.setStorable();*/
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        console.log('Search response time -->'+((new Date().getTime())-requestInitiatedTime));
                        
                        var records = [];
                        records = response.getReturnValue();
                        component.set("v.caseDocWrapperLst",response.getReturnValue());
                        
                        if(records.length > 0){
                            var data = [];
                            records.forEach(function(record){
                                var rowData = record.caseDocument;
                                rowData.linkName = '/'+rowData.Document_ID_MVN__c;
                                rowData.attachIconName = 'action:add_relationship';
                                rowData.actionDisabled = record.isAttached;
                                data.push(rowData);
                            });
                            //component.set("v.allData", data);
                            component.set("v.data", data);
                            component.set("v.searchMsg",'');
                        }
                        else{
                            component.set("v.searchMsg",'No records found..');
                            component.set("v.data", null);
                        }
                    } else {
                        console.log('An exception');
                    }
                });
                var requestInitiatedTime = new Date().getTime();
                $A.enqueueAction(action);
                }
            }
            else{
                component.set("v.searchMsg",'No search words found.');
                component.set("v.data", null);
            }
        }
        else{
            component.set("v.searchMsg",'Your search term must have 3 or more characters.');
            component.set("v.data", null);
        }
    },
    
    searchDocsAdvanced : function(component, event, helper, searchText){
        component.set("v.searchMsg",'Searching...');
        var objDetail = component.get('v.objDetail');        
        if(helper.isNotBlank(searchText)){
            var articleSettings = component.get("v.articleSettings");
            var numOfWordsToSearch;
            if(articleSettings.MSD_CORE_CC_Limit_Flag__c)
            {
                numOfWordsToSearch = articleSettings.MSD_CORE_CC_Limit_Words__c;
            }            
            component.set("v.searchMsg",'Searching...');
            var searchWords = searchText.toLowerCase().split(' ');
            var stopWords = $A.get("$Label.c.MSD_CORE_CC_ArticleSearchStopWords").toLowerCase().split(',');
            var finalSearchText = [];
            var count = 0;
            for(var i in searchWords)
            {
                if(numOfWordsToSearch > count)
                {
                    var s = searchWords[i];
                    if((s.length >= 3 && !stopWords.includes(searchWords[i])) || s == 'AE' || s == 'ae')
                    { 
                        finalSearchText.push(s);
                        //searchText.replace(searchWords[i], '');
                    }  
                    count++;
                }
                else{
                    break;
                }
            }
            searchText = finalSearchText.join(' ');
        }
        var prodId = component.get("v.productId");
        var searchTypeOverride = component.get("v.searchTypeOverride");
        var action = component.get("c.search"); 
        action.setParams({
            'documentSearchText' : searchText,
            'objDetail': component.get('v.objDetail'),
            'caseId': component.get("v.recordId") ,
            'searchTypeOverride' : searchTypeOverride != '' ? searchTypeOverride : null,
            'productId' : prodId != '' ? prodId : 'All',
            'isQuickSearch' : false
        });   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.searchMsg",'');
                var records = [];
                records = response.getReturnValue();
                component.set("v.caseDocWrapperLst",response.getReturnValue());
                if(records.length > 0){
                    var data = [];
                    records.forEach(function(record){
                        var rowData = record.caseDocument;                        
                        rowData.linkName = '/lightning/r/Knowledge__kav/'+rowData.Document_ID_MVN__c+'/view';
                        rowData.attachIconName = 'action:add_relationship';
                        rowData.actionDisabled = record.isAttached;
                        data.push(rowData);
                    });
                    
                    component.set("v.totalPages", Math.ceil(response.getReturnValue().length/component.get("v.pageSize")));
                    component.set("v.allData", data);
                    component.set("v.currentPageNumber",1);
                    helper.buildData(component, helper);   
                }
                else{
                    component.set("v.searchMsg",'No records found..');
                    component.set("v.data", null);
                }
                
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);        
    },
    
    buildData : function(component, helper) {
        var data = [];
        var pageNumber = component.get("v.currentPageNumber");
        var pageSize = component.get("v.pageSize");
        var allData = component.get("v.allData");
        var x = (pageNumber-1)*pageSize;
        
        //creating data-table data
        for(; x<(pageNumber)*pageSize; x++){
            if(allData[x]){
                data.push(allData[x]);
            }
        }
        component.set("v.data", data);
        
        helper.generatePageList(component, pageNumber);
    },
    
    generatePageList : function(component, pageNumber){
        pageNumber = parseInt(pageNumber);
        var pageList = [];
        var totalPages = component.get("v.totalPages");
        if(totalPages > 1){
            if(totalPages <= 10){
                var counter = 2;
                for(; counter < (totalPages); counter++){
                    pageList.push(counter);
                } 
            } else{
                if(pageNumber < 5){
                    pageList.push(2, 3, 4, 5, 6);
                } else{
                    if(pageNumber>(totalPages-5)){
                        pageList.push(totalPages-5, totalPages-4, totalPages-3, totalPages-2, totalPages-1);
                    } else{
                        pageList.push(pageNumber-2, pageNumber-1, pageNumber, pageNumber+1, pageNumber+2);
                    }
                }
            }
        }
        component.set("v.pageList", pageList);
    },
})