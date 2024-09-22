({
    doInit : function(component, event, helper) {
        if(!component.get("v.fromNice")){
            component.set("v.fieldListPerson",helper.getFields(component, event, helper)); 
            component.set("v.fieldListBusiness",helper.getFields(component, event, helper));
        }
        else{
            component.set("v.fieldListBusiness",component.get("v.fieldListPerson"));
        }
    },
	handleActive: function (component, event, helper) {
        var childComp = component.find("accSerhCmp");
        childComp.calldoInit();
    },
    handleActivePerson: function (component, event, helper) {
        var childComp = component.find("accSerhCmpPerson");
        childComp.calldoInit();
    },
    refreshCmp: function (component, event, helper) {
        var message = event.getParam("refreshCustInfo");
        component.set('v.recentlyAddedBusiness', message);
        component.set('v.recentlyAddedPerson', message);
    },
    
    handleSearchEvent : function (component, event, helper) {
        try{
            if(event.getParam("type") == 'Person')
            {
                var fieldList = event.getParam("fieldList");
                // set the handler attributes based on event data
                fieldList.Business[1].value = fieldList.Person[2].value;
                component.set("v.fieldListBusiness", fieldList);
                component.set("v.state",fieldList.CommonFields[2].value);
                component.set("v.country",fieldList.CommonFields[3].value);
            }
            else{
                var fieldList = event.getParam("fieldList");
                fieldList.Person[2].value = fieldList.Business[1].value;
                component.set("v.fieldListPerson", fieldList);
                component.set("v.state",fieldList.CommonFields[2].value);
                component.set("v.country",fieldList.CommonFields[3].value);
            }
        }
        catch(e){}
    }
})