({
    doInit: function(component, event, helper) {
        helper.helperInit(component, event, helper);
        //component.set('v.showSpinner', false);
    },
    Send : function(component, event, helper) {
        /*var email=helper._e('txtEmail').value;
        var Subject=helper._e('txtSubject').value;
        var Message=component.get("v.myMessage");        
        var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/; 
        
        if(email==''){
            alert('Email-Id is required');
        }
        else if(Subject==''){
            alert('Subject is required');
        }
            else if(Message==''){
                alert('Message is required');
            }
                else{
                    if(!email.match(regExpEmailformat)){
                        alert("Invalid Email Id");
                    }
                    else{
                        helper.SendEmail(component);
                    }
                }*/
        helper.SendEmail(component);
    },
    folderChange: function(component, event, helper) {        
        helper.helperFolderChange(component, event, helper);
    },
    templateChange: function(component, event, helper) {        
        helper.helperTemplateChange(component, event, helper);
    },
    showSpinner: function(component, event, helper) {        
        component.set("v.Spinner", true); 
    },
    hideSpinner : function(component,event,helper){        
        component.set("v.Spinner", false);
    },
    fillAttachIds : function(component,event,helper){
		var attIdList = event.getParam("attIds");

        // set the handler attributes based on event data
        component.set("v.attIdList", attIdList);
    },
    closeUtility : function(component, event, helper){
        var utilityAPI = component.find("utilitybar");
        utilityAPI.minimizeUtility();
        helper.helperInit(component, event, helper);
    }
})