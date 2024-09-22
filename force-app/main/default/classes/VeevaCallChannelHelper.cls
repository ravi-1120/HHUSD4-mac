public without sharing class VeevaCallChannelHelper {

    public static void setCallChannel (Boolean isAfter, Boolean isUpdate, List<Call2_vod__c> calls) {
        //check for FLS
        Boolean callChannelFormulaFls = Schema.SObjectType.Call2_vod__c.fields.Call_Channel_Formula_vod__c.isAccessible();
        Boolean lastDeviceFls = Schema.SObjectType.Call2_vod__c.fields.Last_Device_vod__c.isAccessible();
        Boolean callChannelFls = Schema.SObjectType.Call2_vod__c.fields.Call_Channel_vod__c.isAccessible();
        
        if (lastDeviceFls) {
            //get picklist values
            Set<String> callChannelValues = new Set<String>{'Email_vod', 'Face_to_face_vod', 'Message_vod', 'Other_vod', 'Phone_vod', 'Video_vod'};
            List<Call2_vod__c> callsToSetChannel = new List<Call2_vod__c>();
            List<Call2_vod__c> childCallsToSetChannel = new List<Call2_vod__c>();
            List<Call2_vod__c> childCallsToClear = new List<Call2_vod__c>();
            List<Id> parentCallIds = new List<Id>();
            List<Id> parentIds = new List<Id>();
            Boolean disableChannelReq = getDisableCallChannelSetting();
            //loop through calls and check for all calls with submitted or saved status
            for (Call2_vod__c currCall : calls) {
                String lastDevice = currCall.Last_Device_vod__c;
                Boolean offlineCheck = !String.isBlank(lastDevice) && lastDevice != 'Online_vod';
                if ((currCall.Status_vod__c == 'Submitted_vod' || currCall.Status_vod__c == 'Saved_vod') && !offlineCheck) {
                    if (canStampOrCleared(currCall, disableChannelReq, callChannelFls, callChannelValues, childCallsToClear, isAfter)) {
                        //if we create parent and child calls on insert
                        if (currCall.Parent_Call_vod__c != null && isAfter) {
                            if (!parentCallIds.contains(currCall.Parent_Call_vod__c)) {
                                parentCallIds.add(currCall.Parent_Call_vod__c);
                            }
                            childCallsToSetChannel.add(currCall);
                        }
                        //if parent call formula is updated, we update existing child calls
                        else if (currCall.Is_Parent_Call_vod__c == 1.0 && isAfter && isUpdate) {
                            parentIds.add(currCall.Id);
                        }
                        //for calls with no parents or children, set channel on before insert, before update
                        else if (currCall.Parent_Call_vod__c == null && !isAfter) {
                            callsToSetChannel.add(currCall);
                        }
                    }
                }
            }
            //evaluate the call formulas and set the call channel field value
            evaluateCallChannelFormula(callsToSetChannel, callChannelValues, callChannelFormulaFls);
            evaluateParentCallChannelFormula(childCallsToSetChannel, parentCallIds, callChannelValues, callChannelFormulaFls);
            evaluateChildCallChannelFormula(parentIds, callChannelValues, callChannelFormulaFls);
            clearCallChannelIds(childCallsToClear);
        }
    }
    private static void clearCallChannelIds(List<Call2_vod__c> clearChildCalls) {
        if (!clearChildCalls.isEmpty()) {
            List<Call2_vod__c> clearedCalls = new List<Call2_vod__c>();
            for (Call2_vod__c currCall : clearChildCalls) {
                Call2_vod__c updateCall = new Call2_vod__c(Id = currCall.Id, Call_Channel_vod__c = '');
                clearedCalls.add(updateCall);
            }
            update clearedCalls;
        }
    }
    private static void evaluateCallChannelFormula(List<Call2_vod__c> callsToSetChannel, Set<String> callChannelValues, Boolean formulaFls) {
        if (!callsToSetChannel.isEmpty() && formulaFls) {
            for (Call2_vod__c currCall : callsToSetChannel) {
                String formula = currCall.Call_Channel_Formula_vod__c;
                if (!String.isBlank(formula)) {
                    if (callChannelValues.contains(formula)) {
                        currCall.Call_Channel_vod__c = formula;
                    }
                    else {
                        currCall.Call_Channel_vod__c = '';
                    }
                }
            }
        }
        
    }
    private static void evaluateParentCallChannelFormula(List<Call2_vod__c> childCalls, List<String> parentIds, Set<String> callChannelValues, Boolean formulaFls) {
        if (!childCalls.isEmpty()) {
            Map<Id, Call2_vod__c> queriedCalls = getCallMapFromIds(parentIds);
            List<Call2_vod__c> callsToUpdate = new List<Call2_vod__c>();
            for (Integer i = 0; i < childCalls.size(); i++) {
            
                Call2_vod__c currCall = new Call2_vod__c(Id = childCalls[i].Id, Parent_Call_vod__c = childCalls[i].Parent_Call_vod__c,
                Call_Channel_vod__c = childCalls[i].Call_Channel_vod__c);
                Call2_vod__c parentCall = queriedCalls.get(currCall.Parent_Call_vod__c);
                String formula = parentCall.Call_Channel_vod__c;
                if (formulaFls && !String.isBlank(parentCall.Call_Channel_Formula_vod__c)) {
                    formula = parentCall.Call_Channel_Formula_vod__c;
                }
                
                if (callChannelValues.contains(formula) && currCall.Call_Channel_vod__c != formula) {
                    currCall.Call_Channel_vod__c = formula;
                    currCall.Override_Lock_vod__c = true;
                    callsToUpdate.add(currCall);
                }
            }
            update callsToUpdate;
        }
    }
    private static void evaluateChildCallChannelFormula(List<Id> parentIds, Set<String> callChannelValues, Boolean formulaFls) {
        if (!parentIds.isEmpty()) {
            List<Call2_vod__c> parentCalls = [SELECT Call_Channel_vod__c, Call_Channel_Formula_vod__c, (SELECT Call_Channel_vod__c FROM Call2_vod__r) FROM Call2_vod__c WHERE Id=:parentIds];
            List<Call2_vod__c> updateChildCalls = new List<Call2_vod__c>();
            for (Call2_vod__c parent : parentCalls) {
                String formula = parent.Call_Channel_vod__c;
                if (formulaFls && !String.isBlank(parent.Call_Channel_Formula_vod__c)) {
                    formula = parent.Call_Channel_Formula_vod__c;
                }
                for (Call2_vod__c child : parent.Call2_vod__r) {
                    Call2_vod__c childObj = new Call2_vod__c(Id = child.Id, Call_Channel_vod__c = formula, Override_Lock_vod__c = true);
                    updateChildCalls.add(childObj);
                }
            }
            update updateChildCalls;
        }
    }

    private static Map<Id, Call2_vod__c> getCallMapFromIds(List<String> callIds) {
        List<Call2_vod__c> queriedCalls = [SELECT Id, Call_Channel_vod__c, Call_Channel_Formula_vod__c, Parent_Call_vod__c FROM Call2_vod__c WHERE Id=:callIds];
        Map<Id, Call2_vod__c> callMap = new Map<Id, Call2_vod__c>();
        for (Call2_vod__c call : queriedCalls) {
            callMap.put(call.Id, call);
        }
        return callMap;
    }
     private static Boolean canStampOrCleared(Call2_vod__c call, Boolean disabled, Boolean callChannelFls, Set<String> standardValues, List<Call2_vod__c> toClear, Boolean isAfter) {
        if (!disabled) {
            if (call.Status_vod__c == 'Submitted_vod') {
                String currCallChannel = call.Call_Channel_vod__c;
                if (!standardValues.contains(currCallChannel) || !callChannelFls) {
                    String errorMessage = VOD_VEEVA_MESSAGE.getMsgWithDefault('CHANNEL_REQUIRED_ERROR', 'CallReport', 'Channel selection is required');
                    call.addError(errorMessage);
                    return false;
                }
            }
            return true;
        }
        if (call.Is_Parent_Call_vod__c == 0.0 && String.isNotBlank(call.Call_Channel_vod__c) && isAfter) {
            toClear.add(call);
        }
        return false;
    }
    private static Boolean getDisableCallChannelSetting() {
        Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance();
        Map<String, Object> settingsMap = settings.getPopulatedFieldsAsMap();
        Object disableValue = settingsMap.get('DISABLE_CALL_CHANNEL_REQUIRED_vod__c');
        if (disableValue != null && disableValue == 1) {
            return true;
        }
        return false;
    }
}