({
    helperInit : function(component, event, helper) {
        component.set('v.showSpinner', true);
        component.set("v.toEmail", '');
        component.set("v.ccEmail", '');
		var action = component.get("c.getSendEmailData"); 
        action.setParams({
            'csId' : component.get("v.recordId")                
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('response.getReturnValue()');
                console.log(response.getReturnValue());
                if(response.getReturnValue().isValid != undefined)
                    component.set('v.showSendEmail', response.getReturnValue().isValid);
                component.set('v.data', response.getReturnValue());
            } else {
                console.log('An exception');
            }
        });
        component.set('v.showSpinner', false);
        $A.enqueueAction(action);
	},
    helperFolderChange : function(component, event, helper) {
		component.set('v.showSpinner', true);
        var action = component.get("c.getEmailTemplateList"); 
        action.setParams({
            'folderId' : component.get("v.folderId")                
        });
        action.setCallback(this, function(response) {
            component.set('v.showSpinner', false);
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.data.emailTemplateList', response.getReturnValue());
                component.set('v.templateId', '');
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
	},
    helperTemplateChange : function(component, event, helper) {
		component.set('v.showSpinner', true);
        component.set('v.showBody', false);
        var action = component.get("c.getEmailBody"); 
        action.setParams({
            'csId' : component.get("v.recordId"),
            'templateId' : component.get("v.templateId")                
        });
        action.setCallback(this, function(response) {
            component.set('v.showSpinner', false);
            var state = response.getState();
            if (state === "SUCCESS") {
                var arr = response.getReturnValue().split('<~~~~>');
                component.set('v.data.subject', arr[0]);
                component.set('v.data.body', arr[1]);
        	    component.set('v.showBody', true);
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
	},
    SendEmail : function(component, event, helper) {
        component.set('v.showSpinner', true);
        var conId = component.find("CustomerSignedId").get("v.value");
        var action=component.get("c.SendeMail");
        action.setParams({
            data:component.get("v.data"),
            fromEmailId:component.get("v.fromEmail"),
            toEmail:component.get("v.toEmail"),
            ccEmail:component.get("v.ccEmail"),
            contactId: component.find("CustomerSignedId").get("v.value"),
            "attIds": component.get("v.attIdList")
        })
        action.setCallback(this,function(e){
            if(e.getState()=='SUCCESS'){
                var result=e.getReturnValue();
                if(result=='Success'){
                    this.helperInit(component, event, helper);
                    component.set('v.showSpinner', false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Success!",
                        "message": "Email sent successfully."
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": result
                    });
                    toastEvent.fire();
                    component.set('v.showSpinner', false);
                }
                var fileUploadComp = component.find("fileUploadComp");
                fileUploadComp.resetList();                
            }
            else{
                component.set('v.showSpinner', false);
                alert(JSON.stringify(e.getError()));
            }
        });
        $A.enqueueAction(action);
    },
    
    _e:function(ele){
        return document.getElementById(ele);
    },
})