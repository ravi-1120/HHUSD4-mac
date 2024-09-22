({
    MAX_FILE_SIZE: 84000000, //Max file size 4.5 MB 
    CHUNK_SIZE: 550000,      //Chunk Max size 550Kb 
    
    doInit :  function(component, event, helper){
        var action = component.get("c.getAttachments");   
        if(action){
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
        }   
    },
    //Ramesh: 06/15/2020 - Added this function to retrieve VF Host.
    getVfHostUrl : function(component){
        var action =  component.get("c.getVFHostURL");
        action.setCallback(this, function(response){
            var state =  response.getState();
            if(state == "SUCCESS"){
                component.set("v.vfHosturl",response.getReturnValue());
            } else{
                console.log("Error getting VF host url");
            }
            
        });
        $A.enqueueAction(action);
    },
      uploadHelper: function(component, event) {
        //KRB Defect Fix 1/8/2020
        //remove Upload Button while uploading..
        component.set("v.showUploadButton", false);
        
        // start/show the loading spinner   
        component.set("v.showLoadingSpinner", true);
        // get the selected files using aura:id [return array of files]
        var fileInput = component.find("fileId").get("v.files");
        // get the first file using array index[0]  
        var file = fileInput[0];
        var self = this;
        // check the selected file size, if select file size greter then MAX_FILE_SIZE,
        // then show a alert msg to user,hide the loading spinner and return from function  
        if (file.size > self.MAX_FILE_SIZE) {
            component.set("v.showLoadingSpinner", false);
            
            //KRB Defect Fix 1/8/2020
            component.set("v.showUploadButton", true);
            
            component.set("v.fileName", $A.get("$Label.c.MSD_CORE_Attachment_Size_Exceeded_Warning"));
            return;
        }
 
        // create a FileReader object 
        var objFileReader = new FileReader();
        // set onload function of FileReader object   
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
 
            fileContents = fileContents.substring(dataStart);
            // call the uploadProcess method 
            self.uploadProcess(component, file, fileContents);
        });
 
        objFileReader.readAsDataURL(file);
    },
 
    uploadProcess: function(component, file, fileContents) {
        // set a default size or startpostiton as 0 
        var startPosition = 0;
        // calculate the end size or endPostion using Math.min() function which is return the min. value   
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
 		
        // start with the initial chunk, and set the attachId(last parameter)is null in begin
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition, '');
    },
 	
    refreshFileList :  function(component, event, helper){
        var action = component.get("c.getAttachmentByIds");   
        action.setParams({
            "recordId": component.get("v.recordId"),
            "attIds": component.get("v.attIdList")
        });  
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){ 
                component.set("v.attachments",response.getReturnValue());
            }
        });  
        $A.enqueueAction(action); 
    },
 
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId) {
        // call the apex method 'saveChunk'
        var getchunk = fileContents.substring(startPosition, endPosition);
        var action = component.get("c.saveChunk");
        action.setParams({
            parentId: component.get("v.recordId"),
            fileName: file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type,
            fileId: attachId
        });
 
        // set call back 
        action.setCallback(this, function(response) {
            // store the response / Attachment Id   
            attachId = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                // update the start position with end postion
                startPosition = endPosition;
                endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
                // check if the start postion is still less then end postion 
                // then call again 'uploadInChunk' method , 
                // else, diaply alert msg and hide the loading spinner
                if (startPosition < endPosition) {
                    this.uploadInChunk(component, file, fileContents, startPosition, endPosition, attachId);
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type": "success",
                        "message": "Your file is uploaded successfully."
                    });
                    toastEvent.fire();
                    this.doInit(component, event);
                    component.set("v.showLoadingSpinner", false);
                    component.set("v.fileName", "No File Selected..");
                    
                    //KRB Defect Fix 1/8/2020
                    component.set("v.showUploadButton", true);
                    
                    var showAsTable = component.get("v.showAsTable");
        
                    if(showAsTable == true){
                        var lst = component.get("v.attIdList");
                        lst.push(attachId);
                        component.set("v.attIdList", lst);
                        
                        var compEvent = component.getEvent("childAttachEvent");
                        compEvent.setParams({"attIds" : lst });
                        compEvent.fire();
                        
                        this.refreshFileList(component);
                    }
                	else
                        $A.get('e.force:refreshView').fire();
                }
                // handel the response errors        
            } else if (state === "INCOMPLETE") {
                alert("From server: " + response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        component.set("v.fileName", errors[0].message);
                        component.set("v.showLoadingSpinner", false);
                        
                        //KRB Defect Fix 1/8/2020
                        component.set("v.showUploadButton", true);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    }
})