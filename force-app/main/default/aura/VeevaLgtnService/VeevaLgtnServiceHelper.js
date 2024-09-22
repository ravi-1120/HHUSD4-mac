({
    navigateToURL: function(url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    navigateToURLWithCurrentPageReference: function(url, navService, currentPageRef) {
        //by navigating to the current page reference first, any window.back navigation
        //is preserved on the next page
        navService.generateUrl(currentPageRef).then(function(pageRefURL) {
            let currentPageEvent = $A.get("e.force:navigateToURL");
            currentPageEvent.setParams({
                "url": pageRefURL
            });
            currentPageEvent.fire();
            
            //When navigating to the DCR page from a related list
            //the history is different.  To account for this, we
            //can make another navigation call to ensure back
            //and cancel buttons both work.
            if (this.navigationLocation === 'RELATED_LIST_ROW') {
                let repeatCurrentEvent = $A.get("e.force:navigateToURL");
                repeatCurrentEvent.setParams({
                    "url": pageRefURL
                });
                repeatCurrentEvent.fire();
            }
            
            let newPageEvent = $A.get("e.force:navigateToURL");
            newPageEvent.setParams({
                "url": url
            });
            newPageEvent.fire();
        }.bind(currentPageRef));
    },
    redirectToLgtnEdit: function(navService, recordId, recordTypeId) {
        //navigate to a standard edit modal with background context as the view page of the same object
        var viewPageReference = this.createRecordPageReference("view", recordId);
        var editPageReference = this.createRecordPageReference("edit", recordId, recordTypeId);
        this.doRedirectWithBackgroundContext(navService, editPageReference, viewPageReference);
    },
    redirectToLgtnEditWithCurrentPageReference: function(navService, currentPageRef, recordId, recordTypeId) {
        //navigate to a standard edit modal with the background context set by currentPageRef
        var editPageReference = this.createRecordPageReference("edit", recordId, recordTypeId);
        this.doRedirectWithBackgroundContext(navService, editPageReference, currentPageRef);
    },
    redirectToLgtnNewWithCurrentPageReference: function(navService, currentPageRef, objectInformation, defaultFieldValues, component) {
        //navigate to a standard record creation modal with the background context set by currentPageRef
        var newPageReference = this.createObjectPageReference("new", objectInformation, defaultFieldValues, component);
        this.doRedirectWithBackgroundContext(navService, newPageReference, currentPageRef);
    },
    doRedirectWithBackgroundContext: function(navService, editPageReference, backgroundReference) {
        //the only way to get an edit modal with the correct backgroundContext
        // is to use this iframe redirect "trick"
        Promise.all([navService.generateUrl(backgroundReference), navService.generateUrl(editPageReference)])
            .then(values => {
                var backgroundReferenceUrl = values[0];
                var editPageRefUrl = values[1];
                var baseUrl = document.location.origin;
                var editUrlWithBackgroundContext = baseUrl + editPageRefUrl + "&backgroundContext=" +  encodeURIComponent(backgroundReferenceUrl);
                var frame = document.createElement("iframe");
                frame.src = editUrlWithBackgroundContext;
                document.body.appendChild(frame);
            });
    },
    showErrorToast: function(response) {
        var errorMsg = response.getError()[0].message;
        var toastParams = {
            title: "Error",
            message: errorMsg, // Default error message
            type: "error"
        };
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
        var closeEvent = $A.get("e.force:closeQuickAction");
        closeEvent.fire();
    },
    getCurrentPageReference: function(pageRef, recordId, overridePageState) {
        var currentPageReference = this.getPageReferenceFromState(pageRef);
        if (currentPageReference == null) {
            //fallback case: use View page reference
            currentPageReference = this.createRecordPageReference("view", recordId, null, overridePageState);
        }
        return currentPageReference;
    },
    getRecordTypeId: function(pageRef) {
        var recordTypeId = null;
        if (pageRef && pageRef.state && pageRef.state.recordTypeId) {
            recordTypeId = pageRef.state.recordTypeId;
        }
        return recordTypeId;
    },
    //Create Page References documentation: https://developer.salesforce.com/docs/atlas.en-us.232.0.lightning.meta/lightning/components_navigation_page_definitions.htm
    createRecordPageReference: function(mode, recordId, recordTypeId, overridePageState) {
        var pageReference = {
            "type": "standard__recordPage",
            "attributes": {
                "recordId": recordId,
                "actionName": mode
            },
            "state":{
                "nooverride": "1"
            }
        };
        
        if (overridePageState) {
            //delete state to not include &nooverride=1 param
            delete pageReference.state;
        }

        if (recordTypeId) {
            pageReference.state.recordTypeId = recordTypeId;
        }
        return pageReference;
    },
    createObjectPageReference: function(mode, objectInformation, defaultFieldValues, component) {
        var pageReference = {
            "type": "standard__objectPage",
            "attributes": {
                "objectApiName": objectInformation.objectApiName,
                "actionName": mode,
            },
            "state":{
                "nooverride": "1"
            }
        };
        pageReference.state.defaultFieldValues = component.find("pageRefUtils").encodeDefaultFieldValues(defaultFieldValues);
        if (objectInformation.recordTypeId) {
            pageReference.state.recordTypeId = objectInformation.recordTypeId;
        }
        return pageReference;
    },
    getPageReferenceFromState: function(pageRef) {
        //get page reference from the state of another page reference
        var stateReference = null;
        if (pageRef != null) {
            var state = pageRef.state; // state holds any query params
            var base64Context = state.inContextOfRef;
            if (base64Context) {
                // ignore the first two characters "1.<rest>"
                // then we can get the original page reference if it exists
                stateReference = JSON.parse(atob(base64Context.substring(2)));
            }
            if (pageRef.state.navigationLocation == 'RELATED_LIST_ROW') {
                //store source for special navigation case
                stateReference.navigationLocation = 'RELATED_LIST_ROW';
            }
        }
        return stateReference;
    }
})