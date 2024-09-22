({
	helperMethod : function() {
		
	},
    
    handleErrors : function(errors) {
       
       // Configure an error toast
       let toastParams = {
        title: "Error",
        message: "Unknown error", // Default error message
        type: "error"
       };

        //// Parse custom error data & report it       
       if (errors && Array.isArray(errors) && errors.length > 0) {
          
          // Parse custom error data & report it 
          // We are only handling one error...in Production, report out all!! 
          // ..Do the same loop in the Controller to report on all! 
          
          let errorData = JSON.parse(errors[0].message);
          //console.error("In Helper Function -" + errorData.name +" (code "+ errorData.code +"): "+ errorData.message);           
                      
          //production code, check for null/blanks etc...
          toastParams.title = errorData.name;
          toastParams.message = errorData.code + " : " + errorData.message;
         }
       
       // Fire error toast
       let toastEvent = $A.get("e.force:showToast");
       toastEvent.setParams(toastParams);
       toastEvent.fire();
    }
})