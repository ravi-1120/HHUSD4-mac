public without sharing class VeevaSocialBindingActivityHandler {
    private static String PENDING_STATUS = 'Pending_vod';
    private static String APPROVED_STATUS = 'Approved_vod';
    private static String DENIED_STATUS = 'Denied_vod';
    
    private static String UNBIND_TYPE = 'Unbind_vod';
    private static String CHANGE_TYPE = 'Change_vod';
    
    private static String BIND_STATUS = 'Bind_vod';
    private static String UNBIND_STATUS = 'Unbind_vod';
    
    private static String REJECTED_ACTION = 'Rejected';
    private static String APPROVED_ACTION = 'Approved';
    
    private static String OPT_OUT_TYPE = 'Opt_Out_vod';
    
    public void handleTrigger() {
        System.TriggerOperation triggerOperation = Trigger.operationType;
        switch on triggerOperation {
            when BEFORE_UPDATE {
                Decimal UnbindingApprovalMode = WeChat_Settings_vod__c.getInstance().AW_UNBINDING_APPROVAL_MODE_vod__c;    
                if (UnbindingApprovalMode < 0.0 || UnbindingApprovalMode > 3.0) {
                    return;
                }
                List<Social_Binding_Activity_vod__c> validSbas = getValidSbas(Trigger.Old, Trigger.New);
                if (validSbas.size() > 0) {
                    handleApprovalProcessesRelated(validSbas);
                }
            }
        }
    }
       
    private List<Social_Binding_Activity_vod__c> getValidSbas(List<Social_Binding_Activity_vod__c> oldSbas, List<Social_Binding_Activity_vod__c> newSbas) {
        List<Social_Binding_Activity_vod__c> sbas = new List<Social_Binding_Activity_vod__c>();    
        for (Integer i = 0; i < newSbas.size(); i++) {        
            Social_Binding_Activity_vod__c oldSba = oldSbas.get(i);
            Social_Binding_Activity_vod__c newSba = newSbas.get(i);        
            if(oldSba.Status_vod__c == PENDING_STATUS 
               && (newSba.Type_vod__c == UNBIND_TYPE || newSba.Type_vod__c == CHANGE_TYPE) 
               && (newSba.Status_vod__c == APPROVED_STATUS || newSba.Status_vod__c == DENIED_STATUS)) {
                sbas.add(newSba);
            }
        }
        return sbas;
    }
    
    private void handleApprovalProcessesRelated(List<Social_Binding_Activity_vod__c> validSbas) {        
       
        List<String> allSbaIds = new List<String>();
        for (Social_Binding_Activity_vod__c sba : validSbas) {
            allSbaIds.add(sba.Id);
        }
        Map<String, sObject> workitemsMap = new Map<String, sObject>();
        for (sObject workitem : [SELECT ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem where ProcessInstance.TargetObjectId IN : allSbaIds GROUP BY ProcessInstance.TargetObjectId HAVING COUNT(Id) = 1]) {
            workitemsMap.put((String)workitem.get('TargetObjectId'), workitem);
        }
        
        List<Social_Binding_Activity_vod__c> finalSbas = new List<Social_Binding_Activity_vod__c>();
        for (Social_Binding_Activity_vod__c sba : validSbas) {
            if (workitemsMap.get(sba.Id) != null) {
                finalSbas.add(sba);
            } else {
                sba.Status_vod__c = PENDING_STATUS;
            }
        }
        if (finalSbas.size() > 0) {
            processFinalAction(finalSbas);
        }
    }
    
    private String getFinalApprovalStatus(String sbaId, List<ProcessInstanceStep> stepList) {
        String finalStatus = null; 
        if (stepList != null && stepList.size() > 0) {
            for (ProcessInstanceStep step : stepList) {
                if (REJECTED_ACTION == step.StepStatus) {
                    return DENIED_STATUS;
                } else if (APPROVED_ACTION == step.StepStatus) {
                    finalStatus = APPROVED_STATUS;
                }
            }
        }
        return finalStatus;
    }
    
    private Map<String, List<ProcessInstanceStep>> getStepsMap(List<String> sbaIds) {
        Map<String, List<ProcessInstanceStep>> stepsMap = new Map<String, List<ProcessInstanceStep>>();       
        for (ProcessInstanceStep step : [SELECT Id,ActorId,StepStatus,SystemModstamp,ProcessInstance.TargetObjectId FROM ProcessInstanceStep where ProcessInstance.TargetObjectId IN : sbaIds]) {
            String targetId = step.ProcessInstance.TargetObjectId;
            if (stepsMap.get(targetId) == null) {
                List<ProcessInstanceStep> stepList = new List<ProcessInstanceStep>();
                stepList.add(step);
                stepsMap.put(targetId, stepList);
            } else {
                stepsMap.get(targetId).add(step);
            }
        }
        return stepsMap;
    }
    
    private Map<String, Multichannel_Consent_vod__c> getMccsMap(Set<String> channelValues) {
        Map<String, Multichannel_Consent_vod__c> mccsMap = new Map<String, Multichannel_Consent_vod__c>();
        for (Multichannel_Consent_vod__c mcc : [SELECT Account_vod__c, Channel_Value_vod__c, RecordTypeId,
                                           Opt_Type_vod__c, Content_Type_vod__c, Consent_Type_vod__c,
                                           Union_Id_vod__c, Captured_By_vod__c, Capture_Datetime_vod__c, Disclaimer_Text_vod__c 
                                           FROM Multichannel_Consent_vod__c WHERE RECORDTYPE.DEVELOPERNAME = 'WeChat_vod' 
                                           AND CONTENT_TYPE_VOD__R.RECORDTYPE.DEVELOPERNAME = 'WeChat_WeChatWork_vod' 
                                           AND CONSENT_TYPE_VOD__R.RECORDTYPE.DEVELOPERNAME = 'WeChat_vod' 
                                           AND CONTENT_TYPE_VOD__R.SERVICE_ACCOUNT_APP_ID_VOD__C != NULL 
                                           AND CHANNEL_VALUE_VOD__C IN : channelValues
                                           ORDER BY NAME ASC]) {
            mccsMap.put(mcc.Channel_Value_vod__c, mcc);
        }
        return mccsMap;
    }
    
    private void processFinalAction(List<Social_Binding_Activity_vod__c> sbas) {
        List<String> siIds = new List<String>();
        List<String> sbaIds = new List<String>();
        for(Social_Binding_Activity_vod__c sba : sbas) {
            siIds.add(sba.Social_Account_vod__c);
            sbaIds.add(sba.Id);
        }
       
        Map<String, List<ProcessInstanceStep>> stepsMap = getStepsMap(sbaIds);
        Set<String> channelValues = new Set<String>();
        Map<String, Social_Identity_vod__c> sisMap = new Map<String, Social_Identity_vod__c>();
        for (Social_Identity_vod__c si : [SELECT Id, Status_vod__c,  
                                         Account_vod__c,  
                                         Channel_Value_vod__c, 
                                         Union_ID_vod__c
                                         FROM Social_Identity_vod__c   
                                         WHERE Id IN : siIds]) {
            String channelValue = si.Channel_Value_vod__c;
            if (String.isNotBlank(channelValue)) {
               channelValues.add(channelValue); 
            }
            sisMap.put(si.Id, si);
        }
         
        Map<String, Multichannel_Consent_vod__c> mccsMap = getMccsMap(channelValues);
        
        List<Social_Binding_Activity_vod__c> finalSbaList = new List<Social_Binding_Activity_vod__c>();
        List<UnbindingSba> unbindSbaList = new List<UnbindingSba>();
        Map<String, Multichannel_Consent_vod__c> sbaMccMap = new Map<String, Multichannel_Consent_vod__c>();
        for (Social_Binding_Activity_vod__c sba : sbas) {
            List<ProcessInstanceStep> stepList = stepsMap.get(sba.Id);
            String processInstanceId = null;
            if (stepList != null && stepList.size() > 0) {
               processInstanceId = stepList.get(0).ProcessInstanceId;
            }
            String finalStatus = getFinalApprovalStatus(sba.Id, stepsMap.get(sba.Id));
            if (finalStatus != null) {
                sba.Status_vod__c = finalStatus;
            } else {
                continue;
            }
           
            if (sba.Status_vod__c == APPROVED_STATUS) {
                Social_Identity_vod__c si = sisMap.get(sba.Social_Account_vod__c);
                if (si != null && si.Status_vod__c != BIND_STATUS 
                   || (sba.Type_vod__c == CHANGE_TYPE && String.isBlank(sba.Newly_Bound_To_vod__c))) { 
                    continue;
                }
                Multichannel_Consent_vod__c mcc = mccsMap.get(si.Channel_Value_vod__c);
                if (mcc == null || mcc.Account_vod__c == null || mcc.Channel_Value_vod__c == null) {
                    continue;
                }
                sbaMccMap.put(sba.Id, mcc);
                finalSbaList.add(sba);
                unbindSbaList.add(getUnbindingSba(sba, processInstanceId));
            } else if (sba.Status_vod__c == DENIED_STATUS) {
                unbindSbaList.add(getUnbindingSba(sba, processInstanceId));
            }
        }
        if (finalSbaList.size() > 0) {
            processAccountUnbindingMultichannelConsent(finalSbaList, sbaMccMap);
            processAccountUnbindingSocialIdentity(finalSbaList, sisMap);
        }
        if (unbindSbaList.size() > 0) {
            callWechatAPI(unbindSbaList, stepsMap);
        }
    }
    
    private UnbindingSba getUnbindingSba(Social_Binding_Activity_vod__c sba, String processInstanceId) {
        UnbindingSba unbindingSba = new UnbindingSba();                      
        unbindingSba.setSbaId(sba.Id);          
        unbindingSba.setStatus(sba.Status_vod__c);           
        unbindingSba.setProcessInstanceId(processInstanceId);
        return unbindingSba;
    }
    
    private void callWechatAPI(List<UnbindingSba> unbindSbaList, Map<String, List<ProcessInstanceStep>> stepsMap){
        String domainUrl = WeChat_Settings_vod__c.getInstance().DOMAIN_URL_vod__c;                   
        if (String.isNotBlank(domainUrl)) {                          
            Map<String,String> headers = new Map<String,String>();                
            String orgId = UserInfo.getOrganizationId();
            String ts = String.valueOf(datetime.now().getTime());
            headers = VeevaWechatServiceUtil.getPostHeaders(ts, orgId); 
            RequestBody requestBody = new RequestBody();
            requestBody.setTs(ts);
            requestBody.setSbaList(unbindSbaList);
            String url = domainUrl + '/qyaw-service/api/v1/external/wechatcrm/unbinding-approval-process';
            String body = JSON.serialize(requestBody);
            VEEVA_WEC_WEB_SERVICE_ASYNC_UTIL.post(url, headers, body);
        }
    }
    
    private void processAccountUnbindingSocialIdentity(List<Social_Binding_Activity_vod__c> sbas, Map<String, Social_Identity_vod__c> sisMap){
        List<Social_Identity_vod__c> siList = new List<Social_Identity_vod__c>();
        for (Social_Binding_Activity_vod__c sba : sbas) {
            Social_Identity_vod__c si = sisMap.get(sba.Social_Account_vod__c);
            String type = sba.Type_vod__c;
            String newlyBoundToId = sba.Newly_Bound_To_vod__c;
            if (type == UNBIND_TYPE) {
                si.Status_vod__c = UNBIND_STATUS;
            } else if (newlyBoundToId != null && type == CHANGE_TYPE) {
                si.Account_vod__c = newlyBoundToId;
                si.Capture_Time_vod__c = System.now();
            }
            siList.add(si);
        }
        if (siList.size() > 0) {
            update siList;
        }
    }
    
    private void processAccountUnbindingMultichannelConsent(List<Social_Binding_Activity_vod__c> sbas, Map<String, Multichannel_Consent_vod__c> sbaMccMap){
        List<Multichannel_Consent_vod__c> allMultichannelConsentList = new List<Multichannel_Consent_vod__c>();
        for (Social_Binding_Activity_vod__c sba : sbas) {
            String type = sba.Type_vod__c;
            Multichannel_Consent_vod__c mcc = sbaMccMap.get(sba.Id);
            if (mcc == null) {
                continue;
            }
            List<Multichannel_Consent_vod__c> multichannelConsentList = new List<Multichannel_Consent_vod__c>();
            String optType = mcc.Opt_Type_vod__c;
            String newAccountId = sba.Newly_Bound_To_vod__c;
            String captureBy = sba.OwnerId;
            if (type == UNBIND_TYPE && optType != OPT_OUT_TYPE) {
                //upsert mcc
                multichannelConsentList = prepareAbandonAccountMultichannelConsent(mcc, sba);
            } else if (type == CHANGE_TYPE) {
                if (optType != OPT_OUT_TYPE) {
                    //upsert mcc
                    multichannelConsentList = prepareChangeAccountMultichannelConsent(newAccountId, mcc, sba);
                } else {
                    //insert a new mc with new account
                    Multichannel_Consent_vod__c optOutMultichannelConsent = getMultichannelConsentWithLatestRecord(mcc, OPT_OUT_TYPE, false);
                    optOutMultichannelConsent.Captured_By_vod__c = captureBy;               
                    optOutMultichannelConsent.Account_vod__c = newAccountId;                
                    optOutMultichannelConsent.Opt_Expiration_Date_vod__c = null;
                    multichannelConsentList.add(optOutMultichannelConsent);
                }
            }
            if (multichannelConsentList.size() > 0) {
               allMultichannelConsentList.addAll(multichannelConsentList); 
            }
        }
        if (allMultichannelConsentList.size() > 0) {
           upsert allMultichannelConsentList; 
        }
    }
    
    //expire opt in old MCC, create one opt out new MCC with old account, create one opt in new MCC with new account
    private List<Multichannel_Consent_vod__c> prepareChangeAccountMultichannelConsent(String newAccountId, Multichannel_Consent_vod__c multichannelConsent, Social_Binding_Activity_vod__c socialBindingActivity) {
        List<Multichannel_Consent_vod__c> multichannelConsentList = new List<Multichannel_Consent_vod__c>();

        Multichannel_Consent_vod__c optOutMultichannelConsent = getMultichannelConsentWithLatestRecord(multichannelConsent, OPT_OUT_TYPE, false);
        Multichannel_Consent_vod__c optInMultichannelConsent = getMultichannelConsentWithLatestRecord(multichannelConsent, multichannelConsent.Opt_Type_vod__c, true);
        optInMultichannelConsent.Account_vod__c = newAccountId;
        String captureBy = socialBindingActivity.OwnerId;
        if (captureBy != null) {
            optOutMultichannelConsent.Captured_By_vod__c = captureBy;
            optInMultichannelConsent.Captured_By_vod__c = captureBy;
        }
        multichannelConsent.Opt_Expiration_Date_vod__c = Date.today().addDays(-1);

        multichannelConsentList.add(multichannelConsent);
        multichannelConsentList.add(optOutMultichannelConsent);
        multichannelConsentList.add(optInMultichannelConsent);
        
        return multichannelConsentList;
    }
    
    //expire old opt in MCC, create one new opt out MCC
    private List<Multichannel_Consent_vod__c> prepareAbandonAccountMultichannelConsent(Multichannel_Consent_vod__c multichannelConsent, Social_Binding_Activity_vod__c sba){
        list<Multichannel_Consent_vod__c> mccList = new List<Multichannel_Consent_vod__c>();
        Multichannel_Consent_vod__c optOutMultichannelConsent = getMultichannelConsentWithLatestRecord(multichannelConsent, OPT_OUT_TYPE, false);
        multichannelConsent.Opt_Expiration_Date_vod__c = Date.today().addDays(-1);
        Id captureBy = sba.OwnerId;
        if (captureBy != null) {
            optOutMultichannelConsent.Captured_By_vod__c = captureBy;
            multichannelConsent.Captured_By_vod__c = captureBy;
        }

        mccList.add(multichannelConsent);
        mccList.add(optOutMultichannelConsent);
        return mccList;
    }
    
    private Multichannel_Consent_vod__c getMultichannelConsentWithLatestRecord(Multichannel_Consent_vod__c originMultichannelConsent, String optType, boolean withOldCaptureTime){
        Multichannel_Consent_vod__c newMultichannelConsent = new Multichannel_Consent_vod__c();

        newMultichannelConsent.Account_vod__c = originMultichannelConsent.Account_vod__c;
        newMultichannelConsent.Content_Type_vod__c = originMultichannelConsent.Content_Type_vod__c;
        newMultichannelConsent.Consent_Type_vod__c = originMultichannelConsent.Consent_Type_vod__c;
        if (withOldCaptureTime) {
            newMultichannelConsent.Capture_Datetime_vod__c = originMultichannelConsent.Capture_Datetime_vod__c;
        } else {
            newMultichannelConsent.Capture_Datetime_vod__c = System.now();
        }
        newMultichannelConsent.RecordTypeId = originMultichannelConsent.RecordTypeId;
        newMultichannelConsent.Channel_Value_vod__c = originMultichannelConsent.Channel_Value_vod__c;
        newMultichannelConsent.Union_Id_vod__c = originMultichannelConsent.Union_Id_vod__c;
        newMultichannelConsent.Captured_By_vod__c = originMultichannelConsent.Captured_By_vod__c;
        newMultichannelConsent.Opt_Type_vod__c = optType;
        newMultichannelConsent.Disclaimer_Text_vod__c = originMultichannelConsent.Disclaimer_Text_vod__c;

        return newMultichannelConsent;
    }
    
    private class UnbindingSba {
        private String sbaId;
        private String status;
        private String processInstanceId;
        public void setSbaId(String sbaId) {
            this.sbaId = sbaId;
        }
        public void setStatus(String status) {
            this.status = status;
        }
        public void setProcessInstanceId(String processInstanceId) {
            this.processInstanceId = processInstanceId;
        }
    }
    
    private class RequestBody {
        private String ts;
        private List<UnbindingSba> sbaList;
        public void setTs(String ts) {
            this.ts = ts;
        }
        public void setSbaList(List<UnbindingSba> sbaList) {
            this.sbaList = sbaList;
        }
    }

}