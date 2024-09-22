public without sharing class VeevaEmSpeakerTriggerHandler extends VeevaTriggerHandler{

    private static final String EMAIL_REQUIRED_WITH_SP_ACCOUNT_KEY = 'SPEAKER_PORTAL;;EMAIL_REQUIRED_WITH_SP_ACCOUNT';
    private static final String EMAIL_REQUIRED_WITH_SP_ACCOUNT_MESSAGE = 'Email is required when there is an associated Speaker Portal account.';
    private static final String ANNUAL_CAP_EXCEEDED_ERROR_KEY = 'EVENT_MANAGEMENT;;ANNUAL_CAP_EXCEEDED';
    private static final String ANNUAL_CAP_EXCEEDED_DEFAULT_MSG = 'The total of all product caps exceeds the overall Speaker annual cap.';

    private static Map<String, String> veevaMessageMap;

    private List<EM_Speaker_vod__c> newEMSpeakers;
    private List<EM_Speaker_vod__c> oldEMSpeakers;
    private Map<ID, EM_Speaker_vod__c> newEMSpeakersMap;
    private Map<ID, EM_Speaker_vod__c> oldEMSpeakersMap;
    private Map<ID, Map<String, Decimal>> speakerIdToTotalProductCapsMap;
    private Map<ID, EM_Speaker_vod__c>  annualCapsInBaseCurrencyMap;

    protected override boolean doRecursionCheck() {
        return true;
    }

    protected override String sObjectType() {
        return 'EM_Speaker_vod__c';
    }

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        newEMSpeakers = (List<EM_Speaker_vod__c>) triggerNew;
        oldEMSpeakers = (List<EM_Speaker_vod__c>) triggerOld;
        newEMSpeakersMap = (Map<ID, EM_Speaker_vod__c>) triggerNewMap;
        oldEMSpeakersMap = (Map<ID, EM_Speaker_vod__c>) triggerOldMap;
    }

    protected override void beforeInsert() {
        vodEmSpeakerBeforeInsertUpdate();
    }

    protected override void beforeUpdate() {
        vodEmSpeakerBeforeInsertUpdate();
    }

    protected override void afterInsert() {
        handleSpeakerPortalActions();
    }

    protected override void afterUpdate() {
        handleSpeakerPortalActions();
        handleSpeakerCapValidations();
    }

    protected override void afterDelete() {
        handleSpeakerPortalDelete();
    }

    private void handleSpeakerPortalDelete() {
        Set<ID> speakersToDeleteFromPortal = new Set<ID>();
        for (EM_Speaker_vod__c oldSpeaker : oldEMSpeakers) {
            if (oldSpeaker.Portal_Account_Creation_Date_vod__c != null) {
                speakersToDeleteFromPortal.add(oldSpeaker.Id);
            }
        }
        if (!speakersToDeleteFromPortal.isEmpty()) {
            VeevaSpeakerPortalService.deleteSpeakers(speakersToDeleteFromPortal);
        }
    }

    private void handleSpeakerPortalActions() {
        List<EM_Speaker_vod__c> speakersToUpdate = new List<EM_Speaker_vod__c>();
        Set<ID> speakerIdsForRegistration = new Set<ID>();
        Map<ID,String> speakerToChangedFieldsMap = new Map<ID,String>();
        for (EM_Speaker_vod__c newSpeaker : newEMSpeakers) {
            if (newSpeaker.Send_Speaker_Registration_Email_vod__c == true) {
                if (newSpeaker.Portal_Account_Creation_Date_vod__c == null && (Trigger.isInsert || (Trigger.isUpdate
                        && oldEMSpeakersMap.get(newSpeaker.Id).Send_Speaker_Registration_Email_vod__c == false))) {
                    speakerIdsForRegistration.add(newSpeaker.Id);
                }
                EM_Speaker_vod__c speakerToUpdate = new EM_Speaker_vod__c();
                speakerToUpdate.Id = newSpeaker.Id;
                speakerToUpdate.Send_Speaker_Registration_Email_vod__c = false;
                speakersToUpdate.add(speakerToUpdate);
            }

            if (Trigger.isUpdate && newSpeaker.Portal_Account_Creation_Date_vod__c != null) {
                List<String> changedFields = new List<String>();
                for (String speakerPortalField : VeevaSpeakerPortalService.SPEAKER_BODY_FIELD_MAP.keySet()) {
                    if (isSpeakerFieldChanged(newSpeaker.Id, speakerPortalField)) {
                        changedFields.add(speakerPortalField);
                    }
                }
                if (!changedFields.isEmpty()) {
                    speakerToChangedFieldsMap.put(newSpeaker.Id, String.join(changedFields, ','));
                }
            }
        }
        if (!speakersToUpdate.isEmpty()) {
            update speakersToUpdate;
        }
        if (!speakerIdsForRegistration.isEmpty()) {
            VeevaSpeakerPortalService.sendSpeakerInvitations(speakerIdsForRegistration);
        }
        if (!speakerToChangedFieldsMap.isEmpty()) {
            VeevaSpeakerPortalService.updateSpeakers(speakerToChangedFieldsMap);
        }
    }

    private void vodEmSpeakerBeforeInsertUpdate() {
        Set<String> accountSet = new Set<String>();
        Map<String, Account> accountMap = new Map<String, Account>();
        Boolean isNextYearAnnualCapEnabled = VeevaEmSpeakerCapUtil.isNextYearAnnualCapSettingEnabled();

        Integer defaultDay = 1;
        Integer defaultMonth = 1;

        Schema.DescribeFieldResult dayField = EM_Speaker_vod__c.Year_To_Date_Reset_Day_vod__c.getDescribe();
        List <Schema.PicklistEntry> dayPickVals = dayField.getPicklistValues();
        for (Schema.PicklistEntry pv: dayPickVals) {
            if (pv.isDefaultValue()) {
                defaultDay = Integer.valueOf(pv.getValue());
            }
        }

        Schema.DescribeFieldResult monthField = EM_Speaker_vod__c.Year_To_Date_Reset_Month_vod__c.getDescribe();
        List <Schema.PicklistEntry> monthPickVals = monthField.getPicklistValues();
        for (Schema.PicklistEntry pv: monthPickVals) {
            if (pv.isDefaultValue()) {
                defaultMonth = Integer.valueOf(pv.getValue());
            }
        }

        for (EM_Speaker_vod__c speaker : newEMSpeakers) {
            String account = speaker.Account_vod__c;
            if (account != null) {
                accountSet.add(account);
            }

            Integer day = speaker.Year_To_Date_Reset_Day_vod__c != null ? Integer.valueOf(speaker.Year_To_Date_Reset_Day_vod__c): defaultDay;
            Integer month = speaker.Year_To_Date_Reset_Month_vod__c != null ? Integer.valueOf(speaker.Year_To_Date_Reset_Month_vod__c): defaultMonth;
            Date resetDate = Date.newInstance(System.Today().year(), month, day);           
            if(resetDate <= System.Today()) {
                speaker.Next_Year_Reset_Date_vod__c = Date.newInstance(System.Today().year() + 1, month, day);
            } else {
                speaker.Next_Year_Reset_Date_vod__c = resetDate;
            }

            if(Trigger.isUpdate && isNextYearAnnualCapEnabled) {
                EM_Speaker_vod__c oldSpeaker = oldEMSpeakersMap.get(speaker.Id);            
            	if(oldSpeaker.Next_Year_Reset_Date_vod__c != null && oldSpeaker.Next_Year_Reset_Date_vod__c.year() + 1 == speaker.Next_Year_Reset_Date_vod__c.year()) {
                    speaker.Annual_Cap_vod__c = speaker.Next_Year_Annual_Cap_vod__c != null ? speaker.Next_Year_Annual_Cap_vod__c : 0;
            	}
            }
        }
        
        for (Account account : [SELECT Id, Formatted_Name_vod__c, FirstName, LastName, Credentials_vod__c, PersonTitle, Furigana_vod__c, VL_URL_vod__c
                                FROM Account
                                WHERE Id IN :accountSet]) {
            accountMap.put(account.Id, account);
        }

        for (EM_Speaker_vod__c speaker : newEMSpeakers) {
            if (speaker.Account_vod__c != null) {
                Account account = accountMap.get(speaker.Account_vod__c);
                String name = account.Formatted_Name_vod__c;
                if(name != null && name.length() > 80) {
                    speaker.Name = name.subString(0,80);
                } else {
                    speaker.Name = name;
                }
                speaker.First_Name_vod__c = account.FirstName;
                speaker.Last_Name_vod__c = account.LastName;
                speaker.Credentials_vod__c = account.Credentials_vod__c;
                speaker.Title_vod__c = account.PersonTitle;
                speaker.Furigana_vod__c = account.Furigana_vod__c;
                speaker.VL_URL_vod__c = account.VL_URL_vod__c;
            }
            if (Trigger.isUpdate && speaker.Portal_Account_Creation_Date_vod__c != null && speaker.Email_vod__c == null) {
                speaker.addError(getVeevaMessage(EMAIL_REQUIRED_WITH_SP_ACCOUNT_KEY, EMAIL_REQUIRED_WITH_SP_ACCOUNT_MESSAGE));
            }
        }
    }

    private String getVeevaMessage(String messageKey, String defaultMessage) {
        if (veevaMessageMap == null) {
            List<String> messageKeyList = new List<String>();
            messageKeyList.add(EMAIL_REQUIRED_WITH_SP_ACCOUNT_KEY);
            messageKeyList.add(ANNUAL_CAP_EXCEEDED_ERROR_KEY);
            veevaMessageMap = VOD_VEEVA_MESSAGE.getVeevaMessages(messageKeyList);
        }
        String message = veevaMessageMap.get(messageKey);
        if (message == null) {
            String[] splitKey = messageKey.split(';;', 2);
            message = VOD_VEEVA_MESSAGE.getMsgWithDefault(splitKey[0], splitKey[1], defaultMessage);
            veevaMessageMap.put(messageKey, message);
        }
        return message;
    }

    private Boolean isSpeakerFieldChanged(String speakerId, String fieldName) {
        Boolean fieldChanged = true;
        EM_Speaker_vod__c newSpeaker = newEMSpeakersMap.get(speakerId);
        EM_Speaker_vod__c oldSpeaker = oldEMSpeakersMap.get(speakerId);
        if (newSpeaker != null && oldSpeaker != null) {
            fieldChanged = newSpeaker.get(fieldName) != oldSpeaker.get(fieldName);
        }
        return fieldChanged;
    }
    
    private void performAnnualCapValidations(EM_Speaker_vod__c speaker, Boolean isMultiCurrencyOrg) {
        Boolean hasAnnualCapChanged = isSpeakerFieldChanged(speaker.Id, 'Annual_Cap_vod__c');
        Boolean hasNextYearAnnualCapChanged = isSpeakerFieldChanged(speaker.Id, 'Next_Year_Annual_Cap_vod__c');
        Boolean hasCurrencyChanged = isMultiCurrencyOrg && isSpeakerFieldChanged(speaker.Id, 'CurrencyIsoCode');
        
        if(hasAnnualCapChanged || hasNextYearAnnualCapChanged || hasCurrencyChanged) {
            if(speakerIdToTotalProductCapsMap == null){
                speakerIdToTotalProductCapsMap = VeevaEmSpeakerCapUtil.getSpeakerToTotalProductAnnualCapByYear(newEMSpeakersMap.keySet());
            }
            if(!speakerIdToTotalProductCapsMap.isEmpty() && speakerIdToTotalProductCapsMap.containsKey(speaker.Id)) {
                Map<String, Decimal> annualProductCaps = speakerIdToTotalProductCapsMap.get(speaker.Id);
                Integer currentYear = System.Today().year();
                Integer nextYear = currentYear + 1;
                
                if(speaker.Next_Year_Reset_Date_vod__c.year() == currentYear) {
                    nextYear = currentYear;
                    currentYear--;
                }
                
                Decimal totalCurrentYearProductCap = (annualProductCaps != null && annualProductCaps.containsKey(String.valueOf(currentYear))) ? annualProductCaps.get(String.valueOf(currentYear)) : 0;  
                Decimal totalNextYearProductCap = (annualProductCaps != null && annualProductCaps.containsKey(String.valueOf(nextYear))) ? annualProductCaps.get(String.valueOf(nextYear)) : 0;
				Decimal speakersAnnualCap = 0;
                Decimal speakersNextYearAnnualCap = 0;
                
                if(isMultiCurrencyOrg) {
                    if(annualCapsInBaseCurrencyMap == null) {
                        annualCapsInBaseCurrencyMap = VeevaEmSpeakerCapUtil.getSpeakerDataWithCurrencyConversion(newEMSpeakersMap.keySet());
                    }
                    EM_Speaker_vod__c speakerWithConvertedAnnualCaps = (annualCapsInBaseCurrencyMap != null && annualCapsInBaseCurrencyMap.containsKey(speaker.Id)) ? annualCapsInBaseCurrencyMap.get(speaker.Id) : null;
                    if(speakerWithConvertedAnnualCaps != null) {
                        speakersAnnualCap = speakerWithConvertedAnnualCaps.Annual_Cap_vod__c != null ? speakerWithConvertedAnnualCaps.Annual_Cap_vod__c : 0;
                        speakersNextYearAnnualCap = speakerWithConvertedAnnualCaps.Next_Year_Annual_Cap_vod__c != null ? speakerWithConvertedAnnualCaps.Next_Year_Annual_Cap_vod__c : 0;
                    }
                } else {
                    speakersAnnualCap = speaker.Annual_Cap_vod__c != null ? speaker.Annual_Cap_vod__c : 0;
                    speakersNextYearAnnualCap = speaker.Next_Year_Annual_Cap_vod__c != null ? speaker.Next_Year_Annual_Cap_vod__c : 0;
                }
                if((hasAnnualCapChanged || hasCurrencyChanged) && speakersAnnualCap < totalCurrentYearProductCap) {
                    speaker.Annual_Cap_vod__c.addError(getAnnualCapErrorMessage(String.valueOf(currentYear)));
                }
                if((hasNextYearAnnualCapChanged || hasCurrencyChanged) && speakersNextYearAnnualCap < totalNextYearProductCap) {
                    speaker.Next_Year_Annual_Cap_vod__c.addError(getAnnualCapErrorMessage(String.valueOf(nextYear)));
                }
            }
        }
    }
  
    private void handleSpeakerCapValidations(){
        if(VeevaEmSpeakerCapUtil.isNextYearAnnualCapSettingEnabled()){
            Set<Id> speakersWithResetDateChanged = new Set<Id>();
            Boolean isMultiCurrencyOrg = MultiCurrencyUtil.isMultiCurrencyOrg();

            for(Id speakerId : newEMSpeakersMap.keySet()){
                EM_Speaker_vod__c speaker = newEMSpeakersMap.get(speakerId);
                performAnnualCapValidations(speaker, isMultiCurrencyOrg);
                if(speaker.hasErrors()){
                    continue;
                }
                if(isSpeakerFieldChanged(speakerId, 'Year_To_Date_Reset_Month_vod__c') || isSpeakerFieldChanged(speakerId, 'Year_To_Date_Reset_Day_vod__c')) {
                    speakersWithResetDateChanged.add(speakerId);
                }
            }
            if(!speakersWithResetDateChanged.isEmpty()) {
                updateProductCapsStartAndEndDates(speakersWithResetDateChanged);
            }
        }
    }
    
    private void updateProductCapsStartAndEndDates(Set<Id> speakerIds) {
        if(speakerIds != null && !speakerIds.isEmpty()) {
            List<EM_Speaker_Cap_vod__c> speakerCapsToBeUpdated = VeevaEmSpeakerCapUtil.getProductCapsWithFutureEndDate(speakerIds);
            if(speakerCapsToBeUpdated != null) {
                for(EM_Speaker_Cap_vod__c speakerCap : speakerCapsToBeUpdated) {
                    VeevaEmSpeakerCapUtil.setStartAndEndDates(speakerCap, newEMSpeakersMap.get(speakerCap.Speaker_vod__c));
                }
                if(!speakerCapsToBeUpdated.isEmpty()) {
                    update(speakerCapsToBeUpdated);
                }
            }
        }
    }

    private String getAnnualCapErrorMessage(String year) {
        return String.format(getVeevaMessage(ANNUAL_CAP_EXCEEDED_ERROR_KEY, ANNUAL_CAP_EXCEEDED_DEFAULT_MSG), new List<String>{year});
    }
}