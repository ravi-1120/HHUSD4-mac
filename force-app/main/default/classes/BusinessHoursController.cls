/*
    Class not Used anywhere - can be deleted later
*/
public with sharing class BusinessHoursController {
    public BusinessHoursController() {
        System.debug('test');
    }
    /*
    @AuraEnabled(cacheable=true)
    public static List<Time_Slots__c> getBusinessHours(Id operatingHoursId){
        
        try {
            return [
                SELECT Id, End_Time__c, Day_of_Week__c, Start_Time__c
                from Time_Slots__c where Operating_Hours__c = :operatingHoursId
            ];
            
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }*/
}