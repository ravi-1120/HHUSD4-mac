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
                //{placeholder:'Phone',fieldName:"Phone",value:''},
                {placeholder:'City',fieldName:"PersonEmail",value:''},
                {placeholder:'Zip',fieldName:"Zip",value:''},
                {placeholder:'State',fieldName:"State",value:''},
                {placeholder:'Country',fieldName:"Country",value:'United States'}
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
})