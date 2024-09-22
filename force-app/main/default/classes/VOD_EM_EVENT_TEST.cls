@isTest(seeAllData=true)
private class VOD_EM_EVENT_TEST {
    public static EM_Event_Configuration_vod__c config;
    public static Country_vod__c country;
    
    
    static void init(){
        country = new Country_vod__c(Alpha_2_Code_vod__c = 'ZZ', Country_Name_vod__c='Test_ZZ');
        config = new EM_Event_Configuration_vod__c(End_Date_vod__c = Date.today(), Event_Type_vod__c ='Test_Event', Start_Date_vod__c = Date.today());
    }
    
    static testMethod void testStampingWalkInFieldsWithCountryOverride(){
		init();
        Test.startTest();
        insert country;
        insert config;
        List<EM_Event_Rule_vod__c> ruleList;
    	EM_Event_vod__c theEvent;
        EM_Event_Configuration_Country_vod__c configCountry;

        configCountry = new EM_Event_Configuration_Country_vod__c(Country_vod__c = country.Id, 	Event_Configuration_vod__c = config.Id);
        insert configCountry;
        
        ruleList = new List<EM_Event_Rule_vod__c>();
        String strRecordTypeId = [Select Id From RecordType Where SobjectType = 'EM_Event_Rule_vod__c' and DeveloperName = 'Walk_In_Fields_vod'].Id;
        ruleList.add(new EM_Event_Rule_vod__c(Walk_In_Fields_vod__c = 'Status_vod',Event_Configuration_vod__c = config.Id, RecordTypeId = strRecordTypeId));
        ruleList.add(new EM_Event_Rule_vod__c(Walk_In_Fields_vod__c = 'First_Name_vod',Event_Configuration_vod__c = config.Id, RecordTypeId = strRecordTypeId, Country_Override_vod__c = configCountry.Id));
        insert ruleList; 
        
        theEvent = new EM_Event_vod__c(Event_Configuration_vod__c = config.Id, Country_vod__c = country.Id);
        insert theEvent;
        
        
        EM_Event_vod__c resultEvent = [SELECT Walk_In_Fields_vod__c FROM EM_Event_vod__c where Id = :theEvent.Id];
                          
        System.assertEquals('First_Name_vod', resultEvent.Walk_In_Fields_vod__c);

    	Test.stopTest();
    }
}