({
    doInit :  function(component, event, helper){
        var action = component.get("c.getAttachments");   
        action.setParams({
            "recordId": component.get("v.recordId")  
        });  
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){ 
                component.set("v.attachments",response.getReturnValue());
            }
        });  
        $A.enqueueAction(action); 
    },
    
    checkDocProperties : function(component,event,helper,documentId) {
        var action = component.get("c.getDocProperties");   
        //alert('File Name'+fName);  
        action.setParams({"documentId":documentId,
                          "recordId": component.get("v.recordId")  
                         });  
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){  
                helper.showToast(component, event, helper, 'Success!', 'Upload Successful' ,'success');
                /*if(component.get("v.attachmentSize") == 0){
                    component.set("v.message", "Do not attach a zip file to this case. To proceed, attach each document in the zip file.");
                    component.set("v.accept", "['.jpg', '.jpeg', '.pdf', '.png', '.docx']");
                }*/
                helper.doInit(component, event, helper);
            }
            else{
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                       helper.showToast(component, event, helper, 'Error!', errors[0].message ,'error');
                    }
                }
            }
        });  
        $A.enqueueAction(action);
    }
})