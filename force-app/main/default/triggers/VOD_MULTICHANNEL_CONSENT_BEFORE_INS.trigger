trigger VOD_MULTICHANNEL_CONSENT_BEFORE_INS on Multichannel_Consent_vod__c (before insert) {
    List<RecordType> rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Multichannel_Consent_vod__c' AND DeveloperName IN ('Sample_Consent_vod', 'State_Distributor_Exempt_vod')];
    Set<Id> recordTypeIds = new Set<Id>();
    if (rt.size() == 0) {
        return;
    } else {
        for (RecordType recordType : rt) {
            recordTypeIds.add(recordType.Id);
        }
    }
    Id rtId = rt.get(0).Id;

    Map<Id, Multichannel_Consent_vod__c> consentMap = new Map<Id, Multichannel_Consent_vod__c>();
    Set<Id> accountId = new Set<Id>();

    for (Multichannel_Consent_vod__c consent : Trigger.new) {
        if (recordTypeIds.contains(consent.RecordTypeId)) {
            consentMap.put(consent.Id, consent);
            accountId.add(consent.Account_vod__c);
        }
    }

    Date today = Date.today();
    Consent_Template_vod__c template = null;
    List<Consent_Template_vod__c> templates = [SELECT Id, Calendar_Effective_Date_vod__c, Expiration_Type_vod__c, Expiration_Threshold_vod__c, Start_Date_vod__c, End_Date_vod__c, LastModifiedDate
                                               FROM Consent_Template_vod__c
                                               WHERE Start_Date_vod__c <= TODAY AND (End_Date_vod__c = NULL OR End_Date_vod__c >= TODAY)];
    if (templates.size() > 0) {
        template = templates.get(0);
    }

    for (Multichannel_Consent_vod__c consent : consentMap.values()) {
        if (template != null) {
            String startDate = template.Start_Date_vod__c.year() + '-' + template.Start_Date_vod__c.month() + '-' + template.Start_Date_vod__c.day();
            String endDate = 'Null';
            if (template.End_Date_vod__c != null) {
                endDate = template.End_Date_vod__c.year() + '-' + template.End_Date_vod__c.month() + '-' + template.End_Date_vod__c.day();
            }
            if (template.Expiration_Type_vod__c == 'Rolling_vod') {
                consent.Opt_Expiration_Date_vod__c = consent.Capture_Datetime_vod__c.addMonths(template.Expiration_Threshold_vod__c.intValue()).date();
                consent.Sample_Consent_Template_Data_vod__c = template.Expiration_Type_vod__c + '_' + template.Expiration_Threshold_vod__c + '_' + startDate +
                                                           '_' + endDate + '_' + template.LastModifiedDate;
            } else if (template.Expiration_Type_vod__c == 'Calendar_vod') {
                Decimal x = template.Expiration_Threshold_vod__c;
                Integer y = (consent.Capture_Datetime_vod__c.year() - template.Calendar_Effective_Date_vod__c.year()) * 12 +
                            consent.Capture_Datetime_vod__c.month() - template.Calendar_Effective_Date_vod__c.month();
                if (consent.Capture_Datetime_vod__c.day() < template.Calendar_Effective_Date_vod__c.day()) {
                    y = y - 1;
                }
                Integer z = (Integer) Math.ceil(y / x);
                if (y == 0 || (z != 0 && Math.mod(y, (Integer) x * z) == 0)) {
                    consent.Opt_Expiration_Date_vod__c = template.Calendar_Effective_Date_vod__c.addMonths(x.intValue() * (z+1)).addDays(-1);
                } else {
                    consent.Opt_Expiration_Date_vod__c = template.Calendar_Effective_Date_vod__c.addMonths(x.intValue() * z).addDays(-1);
                }
                String effectiveDate = template.Calendar_Effective_Date_vod__c.year() + '-' + template.Calendar_Effective_Date_vod__c.month() + '-' + template.Calendar_Effective_Date_vod__c.day();
                consent.Sample_Consent_Template_Data_vod__c = template.Expiration_Type_vod__c + '_' + template.Expiration_Threshold_vod__c + '_' + effectiveDate +
                                                           '_' + startDate + '_' + endDate + '_' + template.LastModifiedDate;
            }
            consent.Sample_Consent_Template_vod__c = template.Id;
        } else {
            consent.Sample_Consent_Template_Data_vod__c = 'No Matching Template';
        }
    }

    List<Multichannel_Consent_vod__c> existingConsents = [SELECT Id, Opt_Expiration_Date_vod__c
                                                          FROM Multichannel_Consent_vod__c
                                                          WHERE RecordTypeId =: rtId AND Account_vod__c IN : accountId AND Opt_Expiration_Date_vod__c >= TODAY];
    for (Multichannel_Consent_vod__c consent : existingConsents) {
        consent.Opt_Expiration_Date_vod__c = today - 1;
    }
    if (existingConsents.size() > 0) {
        update existingConsents;
    }
}