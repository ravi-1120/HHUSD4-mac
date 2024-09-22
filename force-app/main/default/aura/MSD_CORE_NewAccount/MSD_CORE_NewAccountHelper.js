({
    helperInit : function(component, event, helper) {
        var action = component.get("c.getTypeSelectOptions"); 
        action.setParams({
            'isPersonSearch' : component.get('v.isPersonSearch')            
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.showSpinner", false);
                component.set('v.typeNewSelectOptions', response.getReturnValue());
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
        
        action = component.get("c.getServiceCloudSettings");
        action.setCallback(this, function(response){
            if(component.isValid() && response !== null && response.getState() == 'SUCCESS'){
                component.set("v.showSpinner", false);
                component.set("v.settings", response.getReturnValue());
                console.log('settings');
                console.log(response.getReturnValue());
                
                //this.helperTypeSelected(component, event, helper);
            }
        });
        
        $A.enqueueAction(action);
    },
    helperTypeSelected : function(component, event, helper) {
        //component.set("v.showSpinner", true); 
        var action = component.get("c.typeSelected"); 
        action.setParams({
            'selectedType' : component.get("v.classOfTrade")         
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.showSpinner", false);
                if(response.getReturnValue() != null)
                    component.set('v.recordTypeId', response.getReturnValue());
                else
                    component.set('v.recordTypeId', '');
                
                var fieldValue = component.get('v.classOfTrade');
                var actualValue = component.get('v.classOfTrade');
                
                var prescriberType = component.get('v.prescriberType');
                if(fieldValue.toLowerCase().indexOf(prescriberType.toLowerCase()) != -1)
                {
                    component.set('v.isPrescriber', true);
                    
                    if(component.find('IMS_Specialty_MRK__c') != undefined)
                        component.find('IMS_Specialty_MRK__c').set("v.value", "");
                    if(component.find('IMS_Sub_Specialty_MRK__c') != undefined)
                        component.find('IMS_Sub_Specialty_MRK__c').set("v.value", "");
                }else
                    component.set('v.isPrescriber', false);
                
                component.set('v.HCPType', false);
                if(fieldValue.indexOf('INDIV HEALTHCARE PROF') != -1){
                    fieldValue = 'INDIV HEALTHCARE PROF';
                    component.set('v.HCPType', true);
                    
                    if(component.find('MSD_CORE_Employee_Company__c') != undefined)
                        component.find('MSD_CORE_Employee_Company__c').set("v.value", "");
                    if(component.find('MSD_CORE_Employee_Alias__c') != undefined)
                        component.find('MSD_CORE_Employee_Alias__c').set("v.value", "");
                    if(component.find('MSD_CORE_Merck_Employee_ID__c') != undefined)
                        component.find('MSD_CORE_Merck_Employee_ID__c').set("v.value", "");
                }
                
                component.set('v.classOfTrade', '');
                component.set('v.classOfTrade', actualValue);
                
                if(component.find('typeList') != undefined)
                    component.find('typeList').set('v.value', fieldValue);
                
                 
            } else {
                component.set("v.showSpinner", false);
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
    },
    
    
    isFormValid: function(component, event, helper){
        
        let failedFields = [];
        var errorString = '';
        
        var classOfTrade = component.get("v.classOfTrade");
        if(classOfTrade == '' || classOfTrade == 'Select'){
            errorString += "Please select a type.\n";
        }
        
        let Class_of_Trade_Sub_MRK__c = component.find("Class_of_Trade_Sub_MRK__c");
        
        for(let i in Class_of_Trade_Sub_MRK__c){
            if(helper.isNotBlank(Class_of_Trade_Sub_MRK__c[i]) && typeof Class_of_Trade_Sub_MRK__c[i] === "object"){
                if(!helper.isNotBlank(Class_of_Trade_Sub_MRK__c[i].get("v.value"))){
                    errorString += "Sub-Type is required.\n";                  
                }
            }
        }
        
        var isPersonSearch = component.get("v.isPersonSearch");
        if(isPersonSearch){
            /*var Preferred_First_Name_MRK__c = component.find("Preferred_First_Name_MRK__c").get("v.value");
            if(Preferred_First_Name_MRK__c == ''){
                errorString += "Must enter a First Name.\n";
            }*/
            
            var Preferred_Last_Name_MRK__c = component.find("Preferred_Last_Name_MRK__c").get("v.value");
            if(Preferred_Last_Name_MRK__c == ''){
                errorString += "Must enter a Last Name.\n";
            }
        }
        else{
            var Preferred_Full_Name_MRK__c = component.find("Preferred_Full_Name_MRK__c").get("v.value");
            if(Preferred_Full_Name_MRK__c == ''){
                errorString += "Must enter a Name.\n";
            }
            
            var Name = component.find("Name").get("v.value");
            if(Name == ''){
                errorString += "Must enter a Address Line 1.\n";
            }
            
            var City_vod__c = component.find("City_vod__c").get("v.value");
            if(City_vod__c == ''){
                errorString += "Must enter a City.\n";
            }
            
            /*var State_vod__c = component.find("State_vod__c").get("v.value");
        if(State_vod__c == ''){
            errorString += "Must enter a State.\n";
        }*/
            
            var Zip_vod__c = component.find("Zip_vod__c").get("v.value");
            if(Zip_vod__c == ''){
                errorString += "Must enter a Zip.\n";
            }
            
            var Country_vod__c = component.find("Country_vod__c").get("v.value");
            if(Country_vod__c == ''){
                errorString += "Must enter a Country.\n";
            }
            
           /* var MSD_CORE_Rep_Notes__c = component.find("MSD_CORE_Rep_Notes__c").get("v.value");            
            if(MSD_CORE_Rep_Notes__c == ''){
                errorString += "Must enter a Rep Notes.";
            }*/
        }
        
        if(errorString != ''){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "mode": "sticky",
                "title": "Errors",
                "type": "error",
                "message": errorString
            });
            toastEvent.fire();
            failedFields.push("Error");
        }
        
        return helper.isNotBlank(failedFields);
    }
})