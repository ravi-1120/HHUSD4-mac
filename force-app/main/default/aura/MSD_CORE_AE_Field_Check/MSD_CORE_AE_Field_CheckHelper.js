({
    helperInit : function(component, event, helper) {
        component.set('v.isCaseRecord', true);
        console.log('RecordId-->'+component.get("v.recordId"));
        
        var action = component.get("c.getUserData"); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.userProfileName', response.getReturnValue().Profile.Name);
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
        
        action = component.get("c.getAEFieldsData"); 
        action.setParams({
            'csId' : component.get("v.recordId")                
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var cs = response.getReturnValue();
                component.set('v.casedata', cs);
                
                var caseRT = cs.RecordType.Name;
                var userProfileName = component.get('v.userProfileName');
                
                if(caseRT == 'Request'){
                    if((cs.Product_MVN__c != null || userProfileName == 'MSD_CORE Contact Center - MVCC Agent' || userProfileName == 'MSD_CORE Contact Center - MVCC Agent Non-SSO') 
                       && cs.Type != null && cs.Category_MVN__c != null)
                        component.set('v.isCaseRecord', false);
                }
                else if(caseRT == 'CR Request'){
                    if(cs.Type != null && cs.Category_MVN__c != null)
                       component.set('v.isCaseRecord', false);
                }
                    else if(caseRT == 'Product Complaint'){
                        if(cs.Type != null && cs.Category_MVN__c != null)
                            component.set('v.isCaseRecord', false);
                    }
            } else {
                console.log('An exception');
            }
        });
        $A.enqueueAction(action);
        
        action = component.get("c.queryAERequiredFields"); 
        action.setParams({
            'csId' : component.get("v.recordId")                
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.aefielddata', response.getReturnValue());
                
                var result = response.getReturnValue();
                
                if(result.length == 0){
                    component.set('v.isCaseRecord', false);
                }
                
                if(result.length > 0){
                    component.set('v.sectionName', result[0].sectionName);
                }
            } else {
                console.log('An exception');
            }
        });
        setTimeout(function(){
            $A.enqueueAction(action);
        }, 1000);
    }
})