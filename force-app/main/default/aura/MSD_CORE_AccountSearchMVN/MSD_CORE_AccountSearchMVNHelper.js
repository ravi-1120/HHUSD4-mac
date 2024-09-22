({
    getFields : function(component, event, helper){
        return {
            Person: [
                //{placeholder:"Reporter Type",fieldName:"MSD_CORE_Reporter_Type__c",value:''},
                {placeholder:'Last Name',fieldName:"FirstName",value:''},
                {placeholder:'First Name',fieldName:"LastName",value:''},
                //{placeholder:"Address",fieldName:"Name",value:''},
                {placeholder:'Phone',fieldName:"City_vod__c",value:''},
                {placeholder:'Employee Number',fieldName:"Zip_vod__c",value:''},
                {placeholder:'Master ID',fieldName:"Phone",value:''}
            ],CommonFields:[
                
                {placeholder:'City',fieldName:"PersonEmail",value:''},
                {placeholder:'Zip',fieldName:"Zip",value:''},
                {placeholder:'State',fieldName:"State",value:''},
                {placeholder:'Country',fieldName:"Country",value:''}
            ],Business:[
                //{placeholder:"Reporter Type",fieldName:"MSD_CORE_Reporter_Type__c",value:''},
                {placeholder:'Account Name',fieldName:"FirstName",value:''},
                {placeholder:'Phone',fieldName:"LastName",value:''},
                //{placeholder:"Address",fieldName:"Name",value:''},
                {placeholder:'Customer Number',fieldName:"City_vod__c",value:''},
                {placeholder:'Master ID',fieldName:"Zip_vod__c",value:''}
            ]
        }
    },
    searchAccount : function(component, event, helper){
        var type = component.get('v.type');
        var ispersonAccount = (type == 'Person' ? true : false);
        var action = component.get('c.doAuraSearch');
        component.set("v.searchMsg",'Searching...');
        component.set('v.dataList', []);
        component.set("v.rerenderNewButtons", true);
        
        var searchFirstName = '';
        var searchLastName = ''; 
        var searchName = '';
        var Preferred_Middle_Name_MRK = '';
        var Merck_Id_MRK = '';
        var Phone = '';
        var MSD_CORE_Merck_Employee_ID = '';
        var searchMerckID = '';
        var searchMerckIDpersonAccount = '';
        var typeText = '';
        var City_vod = '';
        var Zip_vod = '';
        var State_vod = '';
        var Country_vod = "US";
        var alternateId = '';    
        
        if(ispersonAccount)
        {
            var fields = component.get('v.fieldList.Person');
            
            for(var i=0; i < fields.length; i++){
                if(fields[i].fieldName == 'FirstName')
                    searchLastName = fields[i].value;
                if(fields[i].fieldName == 'LastName')
                    searchFirstName = fields[i].value;
                if(fields[i].fieldName == 'City_vod__c')
                    Phone = fields[i].value;
                if(fields[i].fieldName == 'Zip_vod__c')
                    MSD_CORE_Merck_Employee_ID = fields[i].value;
                if(fields[i].fieldName == 'Phone')
                    searchMerckIDpersonAccount = fields[i].value;
            }     
        }
        else{
            var businessfields = component.get('v.fieldList.Business');
            
            for(var i=0; i < businessfields.length; i++){
                if(businessfields[i].fieldName == 'FirstName')
                    searchName = businessfields[i].value;
                if(businessfields[i].fieldName == 'LastName' && !ispersonAccount)
                    Phone = businessfields[i].value;
                //if(businessfields[i].fieldName == 'City_vod__c')
                //City_vod = businessfields[i].value;
                if(businessfields[i].fieldName == 'Zip_vod__c')
                    searchMerckID = businessfields[i].value;
                if(businessfields[i].placeholder == 'Customer Number')
                    alternateId = businessfields[i].value;
            }
        }
        
        var commonfields = component.get('v.fieldList.CommonFields');
        
        for(var i=0; i < commonfields.length; i++){
            if(commonfields[i].fieldName == 'PersonEmail')
                City_vod = commonfields[i].value;
            if(commonfields[i].fieldName == 'State')
                State_vod = commonfields[i].value;
            if(commonfields[i].fieldName == 'Zip')
                Zip_vod = commonfields[i].value;
        }   
        
        Country_vod = component.get('v.userCountry');
        
        if(ispersonAccount)
            typeText = component.get('v.typeText');
        
        if(ispersonAccount){
            component.set('v.firstName', searchFirstName); 
            component.set('v.lastName', searchLastName); 
            component.set('v.city', City_vod); 
            component.set('v.zip', Zip_vod); 
            component.set('v.phone', Phone); 
            component.set('v.state', State_vod); 
            component.set('v.country', Country_vod); 
        }else{
            component.set('v.name', searchName); 
            component.set('v.city', City_vod); 
            component.set('v.zip', Zip_vod); 
            component.set('v.state', State_vod); 
            component.set('v.country', Country_vod); 
        }
        
        action.setParams({
            isPersonSearch : ispersonAccount, 
            searchFirstName: searchFirstName, 
            searchLastName: searchLastName, 
            searchName: searchName,
            Preferred_Middle_Name_MRK: Preferred_Middle_Name_MRK,
            Merck_Id_MRK: Merck_Id_MRK,
            Phone: Phone,
            MSD_CORE_Merck_Employee_ID: MSD_CORE_Merck_Employee_ID,
            searchMerckID: searchMerckID,
            searchMerckIDpersonAccount: searchMerckIDpersonAccount,
            typeText: typeText,
            City_vod: City_vod,
            Zip_vod: Zip_vod,
            State_vod: State_vod,
            Country_vod: Country_vod,
            alternateId: alternateId
        });
        action.setCallback(this, function(actionResult) {
            if(actionResult.getState() === "SUCCESS"){
                component.set("v.searchMsg",'');
                
                var records = [];
                records = actionResult.getReturnValue();
                if(records.length > 0){
                    component.set('v.dataList', []);
                    component.set('v.dataList', records);
                }
                else{
                    setTimeout(function(){
                        component.set("v.searchMsg",'No Records Founds');
                    }, 100);
                }
            }
            else{
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.searchMsg",errors[0].message);
                    }
                }
                
            }
        });
        $A.enqueueAction(action);
    }
})