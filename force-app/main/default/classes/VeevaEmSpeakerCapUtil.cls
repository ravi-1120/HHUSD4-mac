public with sharing class VeevaEmSpeakerCapUtil {

    public static Id getProductCapRecordTypeId() {
        Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.EM_Speaker_Cap_vod__c.getRecordTypeInfosByDeveloperName();
        Schema.RecordTypeInfo recordTypeInfo = recordTypeMap.get('Product_Cap_vod');
        return recordTypeInfo.recordtypeid;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean isNextYearAnnualCapSettingEnabled(){
        Events_Management_Settings_vod__c emSetting = Events_Management_Settings_vod__c.getInstance();
       	return emSetting != null && emSetting.Next_Year_Speaker_Cap_vod__c;
    }
    
    public static Map<Id, Map<String, Decimal>> getSpeakerToTotalProductAnnualCapByYear(Set<Id> speakerIds){        
        Map<Id, Map<String, Decimal>> speakerToTotalProductAnnualCaps = new Map<Id, Map<String, Decimal>>();
        Id productRecordTypeId = getProductCapRecordTypeId();
        List<AggregateResult> productCapAggregates = [
            SELECT Speaker_vod__c, Starting_Year_vod__c, SUM(Annual_Cap_vod__c) totalAnnualSum
            FROM EM_Speaker_Cap_vod__c
            WHERE Speaker_vod__c IN :speakerIds
            AND RecordTypeId = :productRecordTypeId
            GROUP BY Speaker_vod__c, Starting_Year_vod__c
        ];
    
        for(AggregateResult productCapAggregate : productCapAggregates) {
            String speakerId = (String) productCapAggregate.get('Speaker_vod__c');
            String year = (String) productCapAggregate.get('Starting_Year_vod__c');
            Decimal totalAnnualSum = (Decimal) productCapAggregate.get('totalAnnualSum') != null ? (Decimal) productCapAggregate.get('totalAnnualSum') : 0;
            
            if(!speakerToTotalProductAnnualCaps.containsKey(speakerId)) {
                speakerToTotalProductAnnualCaps.put(speakerId, new Map<String, Decimal>{year => totalAnnualSum});
            } else {
                Map<String, Decimal> annualProductCaps = speakerToTotalProductAnnualCaps.get(speakerId);
                annualProductCaps.put(year, totalAnnualSum);
            }
        }       
        return speakerToTotalProductAnnualCaps;      
    }
        
    public static void setStartAndEndDates(EM_Speaker_Cap_vod__c speakerCap, EM_Speaker_vod__c speaker) {        
        Date speakerResetDate = speaker.Next_Year_Reset_Date_vod__c;
        Integer resetDay = speakerResetDate.day(); 
        Integer resetMonth = speakerResetDate.month(); 
        String startingYear = speakerCap.Starting_Year_vod__c;
        
        if(resetDay != null && resetMonth != null && startingYear != null) {
            Date startDate = Date.newInstance(Integer.valueOf(startingYear), resetMonth, resetDay);
            Date endDate = startDate.addYears(1).addDays(-1);            
            speakerCap.Start_Date_vod__c = startDate;
            speakerCap.End_Date_vod__c = endDate;
        }        
    }
    
    public static List<EM_Speaker_Cap_vod__c> getProductCapsWithFutureEndDate(Set<Id> speakerId) {
        Id productRecordTypeId = getProductCapRecordTypeId();
        return [SELECT Id, Speaker_vod__c, Start_Date_vod__c, End_Date_vod__c, Starting_Year_vod__c 
                FROM EM_Speaker_Cap_vod__c 
                WHERE End_Date_vod__c >= :System.Today()
                AND RecordTypeId = :productRecordTypeId
                AND Speaker_vod__c IN :speakerId];
    }
    
    @AuraEnabled
    public static Boolean hasProductCapsWithFutureEndDate(Id speakerId) {
        Id productRecordTypeId = getProductCapRecordTypeId();
        List<EM_Speaker_Cap_vod__c> speakerCaps = [
            SELECT Id, Speaker_vod__c, Start_Date_vod__c, End_Date_vod__c, Starting_Year_vod__c 
            FROM EM_Speaker_Cap_vod__c 
            WHERE End_Date_vod__c >= :System.Today()
            AND RecordTypeId = :productRecordTypeId
            AND Speaker_vod__c = :speakerId
            LIMIT 1
        ];    
        return !speakerCaps.isEmpty();
    }

    public static String getUniqueProductCapKey(EM_Speaker_Cap_vod__c speakerCap) {
        return getUniqueProductCapKey(speakerCap.Speaker_vod__c, speakerCap.Product_vod__c, speakerCap.Starting_Year_vod__c);
    }
    
    public static String getUniqueProductCapKey(Id speaker, Id product, String year){
        return speaker + '-' + product + '-' + year;
    }
    
    public static Map<Id, EM_Speaker_vod__c> getSpeakerDataWithCurrencyConversion(Set<Id> speakerIds) {
        //Using the SUM function automatically convernts currency fields into the orgs default currency.
        List<AggregateResult> aggregateResults = [
            SELECT Id, SUM(Annual_Cap_vod__c) Annual_Cap_vod__c, SUM(Next_Year_Annual_Cap_vod__c) Next_Year_Annual_Cap_vod__c, Next_Year_Reset_Date_vod__c
            FROM EM_Speaker_vod__c 
            WHERE Id IN :speakerIds
            GROUP BY Id, Next_Year_Reset_Date_vod__c
        ];
        
        Map<Id, EM_Speaker_vod__c> speakerIdToSpeaker = new Map<Id, EM_Speaker_vod__c>(); 
        for(AggregateResult aggregateResult : aggregateResults) {
            Id speakerId = (Id) aggregateResult.get('Id');
            speakerIdToSpeaker.put(
                speakerId,
                new EM_Speaker_vod__c(
                    Id = speakerId,
                    Annual_Cap_vod__c = (Decimal) aggregateResult.get('Annual_Cap_vod__c'),
                    Next_Year_Annual_Cap_vod__c = (Decimal) aggregateResult.get('Next_Year_Annual_Cap_vod__c'),
                    Next_Year_Reset_Date_vod__c = (Date) aggregateResult.get('Next_Year_Reset_Date_vod__c')
                )
            );
        }
        return speakerIdToSpeaker;
    }
}