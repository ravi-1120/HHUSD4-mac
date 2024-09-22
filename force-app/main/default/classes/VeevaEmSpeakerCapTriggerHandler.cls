public without sharing class VeevaEmSpeakerCapTriggerHandler extends VeevaTriggerHandler{
        
    private static final Set<String> NON_MODIFIABLE_PRODUCT_CAP_FIELDS = new Set<String>{'Speaker_vod__c', 'Product_vod__c', 'Starting_Year_vod__c'};
    private static final Set<String> START_END_DATE_FIELDS = new Set<String>{'Start_Date_vod__c','End_Date_vod__c'};
    private static final String EM_MESSAGE_CATEGORY = 'EVENT_MANAGEMENT';
    private static final String SPEAKER_CAP_INCORRECT_YEAR_ERROR_KEY = EM_MESSAGE_CATEGORY + ';;SPEAKER_CAP_INCORRECT_YEAR';
    private static final String DUPLICATE_SPEAKER_PRODUCT_CAPS_ERROR_KEY = EM_MESSAGE_CATEGORY + ';;DUPLICATE_SPEAKER_PRODUCT_CAPS';
    private static final String CANNOT_EDIT_PRODUCT_CAP_ERROR_KEY = EM_MESSAGE_CATEGORY + ';;CANNOT_EDIT_PRODUCT_CAP';
    private static final String ANNUAL_CAP_EXCEEDED_ERROR_KEY = EM_MESSAGE_CATEGORY + ';;ANNUAL_CAP_EXCEEDED';
    private static final String CANNOT_EDIT_PAST_PRODUCT_CAP_ERROR_KEY  = EM_MESSAGE_CATEGORY + ';;CANNOT_EDIT_PAST_PRODUCT_CAP';
    private static final String NEXT_YEAR_SPEAKER_CAP_SETTING_FALSE_ERROR_KEY = EM_MESSAGE_CATEGORY + ';;NEXT_YEAR_SPEAKER_CAP_SETTING_FALSE';
    private static final String SPEAKER_CAP_INCORRECT_YEAR_ERROR_MSG = 'The Speaker Cap record cannot be created because the year is either too far in the future or in the past';
    private static final String DUPLICATE_SPEAKER_PRODUCT_CAPS_ERROR_MSG = 'The Speaker Cap record is a duplicate';
    private static final String CANNOT_EDIT_PRODUCT_CAP_ERROR_MSG = 'The Speaker, Product, and/or Year fields cannot be edited';
    private static final String ANNUAL_CAP_EXCEEDED_ERROR_MSG = 'The sum of the product caps is larger than the annual cap';
    private static final String CANNOT_EDIT_PAST_PRODUCT_CAP_ERROR_MSG  = 'A past Speaker Cap record cannot be edited';
    private static final String NEXT_YEAR_SPEAKER_CAP_SETTING_FALSE_ERROR_MSG = 'The Next Year Speaker Cap setting must be true in order to create Speaker Cap records. Please contact your Administrator';

    private static Set<String> validStartingYearsOnInsert;
    private static Map<String, String> veevaMessageMap = new Map<String, String>();

    private List<EM_Speaker_Cap_vod__c> newEMSpeakerCaps;
    private List<EM_Speaker_Cap_vod__c> oldEMSpeakerCaps;
    private Map<Id, EM_Speaker_Cap_vod__c> newEMSpeakerCapsMap;
    private Map<Id, EM_Speaker_Cap_vod__c> oldEMSpeakerCapsMap;
    
    private Set<Id> speakerIdsToCalculate;
    private Set<String> uniqueProductCapRecordKeys;
    private Set<String> editableProductCapFieldsOnUpdate;
    private List<EM_Speaker_Cap_vod__c> productCapRecords;
    private Map<Id, EM_Speaker_vod__c> associatedSpeakersMap;
    private Map<Id, Map<String, Decimal>> speakerIdToTotalProductCapsMap;

    protected override boolean doRecursionCheck(){
        return true;
    }

    protected override String sObjectType() {
        return 'EM_Speaker_Cap_vod__c';
    }

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        newEMSpeakerCaps = (List<EM_Speaker_Cap_vod__c>) triggerNew;
        oldEMSpeakerCaps = (List<EM_Speaker_Cap_vod__c>) triggerOld;
        newEMSpeakerCapsMap = (Map<Id, EM_Speaker_Cap_vod__c>) triggerNewMap;
        oldEMSpeakerCapsMap = (Map<Id, EM_Speaker_Cap_vod__c>) triggerOldMap;
    }

    protected override void beforeInsert(){
        handleProductCapsBeforeInsertOrUpdate();
    }

    protected override void beforeUpdate() {
        handleProductCapsBeforeInsertOrUpdate();
    }

    protected override void afterInsert() {
        handleProductCapsAfterInsertOrUpdate();
    }

    protected override void afterUpdate() {
        handleProductCapsAfterInsertOrUpdate();
    }
    
    private void handleProductCapsBeforeInsertOrUpdate() {
        if(!VeevaEmSpeakerCapUtil.isNextYearAnnualCapSettingEnabled()) {
            for(EM_Speaker_Cap_vod__c speakerCap : newEMSpeakerCaps) {
                speakerCap.addError(getVeevaMessage(NEXT_YEAR_SPEAKER_CAP_SETTING_FALSE_ERROR_KEY));                
            }
            return;
        }
        if(validStartingYearsOnInsert == null) {
            Integer currentYear = System.Today().year();
            validStartingYearsOnInsert = new Set<String> {String.valueOf(currentYear-1), String.valueOf(currentYear), String.valueOf(currentYear+1)};
        }
        if(productCapRecords == null) {
            prepareDataForProductCapValidations();
        }    
        for(EM_Speaker_Cap_vod__c productCapRecord : productCapRecords) {
            if(productCapRecord != null) {
                EM_Speaker_vod__c associatedSpeaker = associatedSpeakersMap.get(productCapRecord.Speaker_vod__c);
                if(associatedSpeaker != null && (Trigger.isInsert || (Trigger.isUpdate && haveFieldsChanged(productCapRecord.Id, START_END_DATE_FIELDS)))) {
                    VeevaEmSpeakerCapUtil.setStartAndEndDates(productCapRecord, associatedSpeaker);                                                                                                  
                }
            }
        }
    }
    
    private void handleProductCapsAfterInsertOrUpdate() {
        if(productCapRecords == null) {
            prepareDataForProductCapValidations();
        }
        for(EM_Speaker_Cap_vod__c productCapRecord : productCapRecords) {
            if(productCapRecord == null || productCapRecord.hasErrors()) {
                continue;
            }
            if(Trigger.isUpdate && haveFieldsChanged(productCapRecord.Id, NON_MODIFIABLE_PRODUCT_CAP_FIELDS)) {
                productCapRecord.addError(getVeevaMessage(CANNOT_EDIT_PRODUCT_CAP_ERROR_KEY));
                continue;
            }
            if(Trigger.isInsert && !isValidStartingYear(productCapRecord)) {
                productCapRecord.Starting_Year_vod__c.addError(getVeevaMessage(SPEAKER_CAP_INCORRECT_YEAR_ERROR_KEY));
                continue;
            }
            if(Trigger.isInsert && isDuplicateProductCap(productCapRecord)) {
                productCapRecord.addError(getVeevaMessage(DUPLICATE_SPEAKER_PRODUCT_CAPS_ERROR_KEY));
                continue;
            }
            if(Trigger.isInsert || haveFieldsChanged(productCapRecord.Id, editableProductCapFieldsOnUpdate)) {
                if(isEndDateInPast(productCapRecord)) {
                    productCapRecord.addError(getVeevaMessage(CANNOT_EDIT_PAST_PRODUCT_CAP_ERROR_KEY));
                    continue;
                }
                if(isOverallAnnualCapExceeded(productCapRecord)) {
                    productCapRecord.Annual_Cap_vod__c.addError(String.format(getVeevaMessage(ANNUAL_CAP_EXCEEDED_ERROR_KEY), new List<String>{productCapRecord.Starting_Year_vod__c}));
                    continue;
                }
            }
            
            Boolean isCapCalculationRequired = !productCapRecord.hasErrors() && (Trigger.isInsert || (Trigger.isUpdate && haveFieldsChanged(productCapRecord.Id, START_END_DATE_FIELDS)));   
            if(isCapCalculationRequired) {
                if (speakerIdsToCalculate == null) {
                    speakerIdsToCalculate = new Set<Id>();
                }
                speakerIdsToCalculate.add(productCapRecord.Speaker_vod__c);
            }
        }
        calculateSpeakerCapUtilization();
    }
    
    private void prepareDataForProductCapValidations() {
        productCapRecords = new List<EM_Speaker_Cap_vod__c>();
        Id productCapRecordTypeId = VeevaEmSpeakerCapUtil.getProductCapRecordTypeId();
        Set<Id> associatedSpeakerIds = new Set<Id>();
        Set<Id> associatedProductIds = new Set<Id>();
    
        for(EM_Speaker_Cap_vod__c speakerCap : newEMSpeakerCaps) {
            if(speakerCap.RecordTypeId.equals(productCapRecordTypeId)){
                productCapRecords.add(speakerCap);
                associatedSpeakerIds.add(speakerCap.Speaker_vod__c);
                associatedProductIds.add(speakerCap.Product_vod__c);
            }
        }
        
        if(Trigger.isInsert) {
            uniqueProductCapRecordKeys = getExistingProductCapsKey(associatedSpeakerIds, associatedProductIds, validStartingYearsOnInsert);
        }
        editableProductCapFieldsOnUpdate = getEditableProductCapFieldsOnUpdate();
        associatedSpeakersMap = VeevaEmSpeakerCapUtil.getSpeakerDataWithCurrencyConversion(associatedSpeakerIds);
        speakerIdToTotalProductCapsMap = VeevaEmSpeakerCapUtil.getSpeakerToTotalProductAnnualCapByYear(associatedSpeakerIds);
    }

    private Set<String> getExistingProductCapsKey(Set<Id> speakers, Set<Id> products, Set<String> startingYears) {
        Set<String> productCapRecordKeys = new Set<String>();
        List<EM_Speaker_Cap_vod__c> existingProductCapRecords = [
            SELECT Id, Speaker_vod__c, Product_vod__c, Starting_Year_vod__c
            FROM EM_Speaker_Cap_vod__c
            WHERE Id NOT IN :newEMSpeakerCapsMap.keySet()
            AND Speaker_vod__c IN :speakers 
            AND Product_vod__c IN :products 
            AND Starting_Year_vod__c IN :startingYears
        ];

        for(EM_Speaker_Cap_vod__c existingProductCapRecord : existingProductCapRecords) {
            productCapRecordKeys.add(VeevaEmSpeakerCapUtil.getUniqueProductCapKey(existingProductCapRecord));
        }    
        return productCapRecordKeys;
    }
    
    private Boolean isOverallAnnualCapExceeded(EM_Speaker_Cap_vod__c productCapRecord) {
        return getSumOfProductAnnualCap(productCapRecord) > getSpeakerAnnualCap(productCapRecord);
    }

    private Boolean isEndDateInPast(EM_Speaker_Cap_vod__c speakerCap) {
        return speakerCap.End_Date_vod__c != null && speakerCap.End_Date_vod__c < System.Today();
    }

    private Boolean isDuplicateProductCap(EM_Speaker_Cap_vod__c productCap) {
        return !uniqueProductCapRecordKeys.isEmpty() && uniqueProductCapRecordKeys.contains(VeevaEmSpeakerCapUtil.getUniqueProductCapKey(productCap));
    }
    
    private String getVeevaMessage(String messageKey) {
        if(veevaMessageMap == null || veevaMessageMap.isEmpty()) {
            List<String> messageKeyList = new List<String>{
                SPEAKER_CAP_INCORRECT_YEAR_ERROR_KEY,
                DUPLICATE_SPEAKER_PRODUCT_CAPS_ERROR_KEY,
                CANNOT_EDIT_PRODUCT_CAP_ERROR_KEY,
                ANNUAL_CAP_EXCEEDED_ERROR_KEY,
                CANNOT_EDIT_PAST_PRODUCT_CAP_ERROR_KEY,
                NEXT_YEAR_SPEAKER_CAP_SETTING_FALSE_ERROR_KEY
            };
            
            Map<String, String> defaultMessageMap = new Map<String, String>{
                SPEAKER_CAP_INCORRECT_YEAR_ERROR_KEY => SPEAKER_CAP_INCORRECT_YEAR_ERROR_MSG,
                DUPLICATE_SPEAKER_PRODUCT_CAPS_ERROR_KEY => DUPLICATE_SPEAKER_PRODUCT_CAPS_ERROR_MSG,
                CANNOT_EDIT_PRODUCT_CAP_ERROR_KEY => CANNOT_EDIT_PRODUCT_CAP_ERROR_MSG,
                ANNUAL_CAP_EXCEEDED_ERROR_KEY => ANNUAL_CAP_EXCEEDED_ERROR_MSG,
                CANNOT_EDIT_PAST_PRODUCT_CAP_ERROR_KEY => CANNOT_EDIT_PAST_PRODUCT_CAP_ERROR_MSG,
                NEXT_YEAR_SPEAKER_CAP_SETTING_FALSE_ERROR_KEY => NEXT_YEAR_SPEAKER_CAP_SETTING_FALSE_ERROR_MSG
            };
            
            veevaMessageMap = VOD_VEEVA_MESSAGE.getVeevaMessages(messageKeyList);
            
            for (String key : defaultMessageMap.keySet()){
                if(veevaMessageMap.get(key) == null) {
                    veevaMessageMap.put(key, defaultMessageMap.get(key));
                }
            }
        }
        return veevaMessageMap.get(messageKey);
    }

    private Decimal getSumOfProductAnnualCap(EM_Speaker_Cap_vod__c speakerCap) {
        if(speakerCap == null || speakerIdToTotalProductCapsMap == null || !speakerIdToTotalProductCapsMap.containsKey(speakerCap.Speaker_vod__c)){
            return 0;
        }
    
        Map<String, Decimal> annualProductCaps = speakerIdToTotalProductCapsMap.get(speakerCap.Speaker_vod__c);
        String startingYear = speakerCap.Starting_Year_vod__c;
    
        if(annualProductCaps != null && annualProductCaps.containsKey(startingYear)){
            return annualProductCaps.get(startingYear);
        }   
        return 0;
    }

    private Decimal getSpeakerAnnualCap(EM_Speaker_Cap_vod__c speakerCap){
        EM_Speaker_vod__c associatedSpeaker = associatedSpeakersMap.get(speakerCap.Speaker_vod__c);    
        if(associatedSpeaker != null) {
            if(speakerCap.End_Date_vod__c < associatedSpeaker.Next_Year_Reset_Date_vod__c) {        
                return associatedSpeaker.Annual_Cap_vod__c != null ? associatedSpeaker.Annual_Cap_vod__c : 0;
            } else if(speakerCap.Start_Date_vod__c >= associatedSpeaker.Next_Year_Reset_Date_vod__c) {                              
                return associatedSpeaker.Next_Year_Annual_Cap_vod__c != null ? associatedSpeaker.Next_Year_Annual_Cap_vod__c : 0;
            }
        }
        return 0;
    }
    
    private Boolean haveFieldsChanged(String speakerId, Set<String> fieldNames) {
        EM_Speaker_Cap_vod__c newSpeakerCap = newEMSpeakerCapsMap.get(speakerId);
        EM_Speaker_Cap_vod__c oldSpeakerCap = oldEMSpeakerCapsMap.get(speakerId);
        if(newSpeakerCap != null && oldSpeakerCap != null) {
            for(String fieldName : fieldNames){
                if(newSpeakerCap.get(fieldName) != oldSpeakerCap.get(fieldName)){
                    return true;
                }
            }
        }
        return false;
    }
    
    private void calculateSpeakerCapUtilization(){
        if(speakerIdsToCalculate != null && !speakerIdsToCalculate.isEmpty()){
            SpeakerYTDCalculator.calculate(speakerIdsToCalculate);
        }
    }
    
    /**
     * Validates the starting year of a given speaker.
     *
     * Returns true if:
     * - The current year equals the speaker's starting year, or
     * - The speaker's reset year equals the current year and the speaker's starting year is the previous year, or
     * - The speaker's reset year and starting year are both next year.
     *
     * Otherwise, returns false.
    */
    private Boolean isValidStartingYear(EM_Speaker_Cap_vod__c speakerCap) {
        if(!associatedSpeakersMap.containsKey(speakerCap.Speaker_vod__c) || !speakerCap.Starting_Year_vod__c.isNumeric()) {
            return false;
        }
    
        Integer currentYear = System.Today().year();
        Integer startingYear = Integer.valueOf(speakerCap.Starting_Year_vod__c);
        Integer speakersResetYear = associatedSpeakersMap.get(speakerCap.Speaker_vod__c).Next_Year_Reset_Date_vod__c.year();
        
        return (currentYear == startingYear) || 
               (speakersResetYear == currentYear && startingYear == currentYear - 1) ||
               (speakersResetYear == currentYear + 1 && startingYear == currentYear + 1);
    }
    
    private Set<String> getEditableProductCapFieldsOnUpdate() {
        Set<String> editableFields = new Set<String>{'Annual_Cap_vod__c'};
        
        if(MultiCurrencyUtil.isMultiCurrencyOrg()) {
            editableFields.add('CurrencyIsoCode');
        }
        
        return editableFields;
    }
}