@IsTest
public class VeevaGASSearchProcessorBuilderTest {

    @IsTest
    static void testsBuilderCreatesSearchProcessorWithDefault() {
        VeevaGASSearchProcessorBuilder builder = new VeevaGASSearchProcessorBuilder();
        VeevaGlobalAccountSearchProcessor processor = builder.build();
        System.assertNotEquals(null, processor);
        System.assert(processor.searchConfig instanceof VeevaGASConfigOnline);
        // Nothing to filter since there is no Implicit Filters
        System.assertEquals('', processor.searchClause.generateSOSLClause('Account'));
    }

    @IsTest
    static void testsBuilderCreatesSearchProcessorWithNullDoesNotOverrideDefault() {
        VeevaGASSearchProcessorBuilder builder = new VeevaGASSearchProcessorBuilder();
        VeevaGlobalAccountSearchProcessor processor = builder
            .withPlatform(null)
            .build();
        System.assertNotEquals(null, processor);
        System.assert(processor.searchConfig instanceof VeevaGASConfigOnline);
        // Nothing to filter since there is no Implicit Filters
        System.assertEquals('', processor.searchClause.generateSOSLClause('Account'));
    }

    @IsTest
    static void testsBuilderCreatesSearchProcessorWithOnlinePlatform() {
        VeevaGASSearchProcessorBuilder builder = new VeevaGASSearchProcessorBuilder();
        VeevaGlobalAccountSearchProcessor processor = builder
            .withPlatform('Online')
            .build();
        System.assertNotEquals(null, processor);
        System.assert(processor.searchConfig instanceof VeevaGASConfigOnline);
        // Nothing to filter since there is no Implicit Filters
        System.assertEquals('', processor.searchClause.generateSOSLClause('Account'));
    }

    @IsTest
    static void testsBuilderCreatesSearchProcessorWithMobilePlatform() {
        VeevaGASSearchProcessorBuilder builder = new VeevaGASSearchProcessorBuilder();
        VeevaGlobalAccountSearchProcessor processor = builder
            .withPlatform('Mobile')
            .build();
        System.assertNotEquals(null, processor);
        System.assert(processor.searchConfig instanceof VeevaGASConfigMobile);
        // Nothing to filter since there is no Implicit Filters
        System.assertEquals('', processor.searchClause.generateSOSLClause('Account'));
    }

    @IsTest
    static void whiteboxBuilderIntegrationTestForDefaults() {
        Implicit_Filter_vod__c testFilter = new Implicit_Filter_vod__c(Location_vod__c='Org_Default_vod', Inclusion_vod__c = true);
        insert testFilter;
        Implicit_Filter_Condition_vod__c testConditon = new Implicit_Filter_Condition_vod__c(Object_Name_vod__c='Account', Field_Name_vod__c='RecordTypeId', Criteria_vod__c='SomeRecordTypeId', Implicit_Filter_vod__c=testFilter.Id);
        insert testConditon;

        VeevaGASSearchProcessorBuilder builder = new VeevaGASSearchProcessorBuilder();
        VeevaGlobalAccountSearchProcessor processor = builder.build();
        System.assertEquals('RecordTypeId IN (\'SomeRecordTypeId\')', processor.searchClause.generateSOSLClause('Account'));
    }

    @IsTest
    static void whiteboxBuilderIntegrationTestWithUserFilters() {
        VeevaGASSearchProcessorBuilder builder = new VeevaGASSearchProcessorBuilder();
        VeevaGlobalAccountSearchProcessor processor = builder
            .withUserFilters(new List<Map<String,Object>>{
                new Map<String, Object>{
                    'objectApiName' => 'Account',
                    'fieldApiName' => 'Specialty_1_vod__c',
                    'selectedOptions' => new List<String>{
                        'Cardiology',
                        'Other'
                    }
                },
                new Map<String, Object>{
                    'objectApiName' => 'Address_vod__c',
                    'fieldApiName' => 'City_vod__c',
                    'selectedOptions' => new List<String>{
                        'Dublin',
                        'Columbus'
                    }
                }
            })
            .build();
        System.assertEquals('Specialty_1_vod__c IN (\'Cardiology\', \'Other\')', processor.searchClause.generateSOSLClause('Account'));
        System.assertEquals('City_vod__c IN (\'Dublin\', \'Columbus\')', processor.searchClause.generateSOSLClause('Address_vod__c'));
    }
}