@IsTest
public class VeevaGASSearchClauseTest {

    private static Implicit_Filter_vod__c filterForTest =  new Implicit_Filter_vod__c(Location_vod__c='Org_Default_vod');

    @IsTest
    static void testGeneratesNothingWhenNoConditions(){
        List<VeevaGASSearchCondition> conditions = new List<VeevaGASSearchCondition>();
        VeevaGASSearchClause clause = new VeevaGASSearchClause(conditions);
        System.assertEquals('', clause.generateSOSLClause('Account'));
        System.assertEquals('', clause.generateSOSLClause('Address_vod__c'));
    }

    @IsTest
    static void testGeneratesNothingForObjectWithNoConditions(){
        List<VeevaGASSearchCondition> conditions = new List<VeevaGASSearchCondition>{ createSearchCondition('Account', 'Name', true, 'Some Name') };
        VeevaGASSearchClause clause = new VeevaGASSearchClause(conditions);
        System.assert(String.isNotBlank(clause.generateSOSLClause('Account')));
        System.assertEquals('', clause.generateSOSLClause('Address_vod__c'));
    }

    @IsTest
    static void testGeneratesSimpleClauseForAccount() {
        List<VeevaGASSearchCondition> conditions = new List<VeevaGASSearchCondition>{ createSearchCondition('Account', 'Name', true, 'Some Name') };
        VeevaGASSearchClause clause = new VeevaGASSearchClause(conditions);
        System.assertEquals('Name IN (\'Some Name\')', clause.generateSOSLClause('Account'));
    }

    @IsTest
    static void testGeneratesSimpleClauseForAddress() {
        List<VeevaGASSearchCondition> conditions = new List<VeevaGASSearchCondition>{ createSearchCondition('Address_vod__c', 'Name', true, 'Some Address') };
        VeevaGASSearchClause clause = new VeevaGASSearchClause(conditions);
        System.assertEquals('Name IN (\'Some Address\')', clause.generateSOSLClause('Address_vod__c'));
    }

    @IsTest
    static void testGeneratesClauseForAccountWithMultiPicklistFieldType() {
        VeevaGASSearchClause inclusiveConditions = new VeevaGASSearchClause(new List<VeevaGASSearchCondition>{
            createSearchCondition('Account', 'Order_Type_vod__c', true, 'All_vod')
        });
        VeevaGASSearchClause exclusiveConditions = new VeevaGASSearchClause(new List<VeevaGASSearchCondition>{
            createSearchCondition('Account', 'Order_Type_vod__c', false, 'All_vod'),
            createSearchCondition('Account', 'Order_Type_vod__c', false, 'Direct_vod')
        });

        System.assertEquals('Order_Type_vod__c INCLUDES (\'All_vod\')', inclusiveConditions.generateSOSLClause('Account'));
        System.assertEquals('Order_Type_vod__c EXCLUDES (\'All_vod\', \'Direct_vod\')', exclusiveConditions.generateSOSLClause('Account'));
    }

    @IsTest
    static void testGeneratesClauseForAccountWithMultipleUniqueConditions() {
        List<VeevaGASSearchCondition> conditions = new List<VeevaGASSearchCondition>{
            createSearchCondition('Account', 'Name', true, 'Some Name'),
            createSearchCondition('Account', 'Specialty_1_vod__c', true, 'Specialty'),
            createSearchCondition('Account', 'RecordTypeId', false, 'someRecordTypeId')
        };
        VeevaGASSearchClause clause = new VeevaGASSearchClause(conditions);
        System.assertEquals('Name IN (\'Some Name\') AND Specialty_1_vod__c IN (\'Specialty\') AND RecordTypeId NOT IN (\'someRecordTypeId\')', clause.generateSOSLClause('Account'));
    }

    @IsTest
    static void testGeneratesClauseForAccountWithMultipleIdenticalFields() {
        List<VeevaGASSearchCondition> conditions = new List<VeevaGASSearchCondition>{
            createSearchCondition('Account', 'Name', true, 'Some Name'),
            createSearchCondition('Account', 'Name', true, 'Some Other Name'),
            createSearchCondition('Account', 'RecordTypeId', false, 'someRecordTypeId'),
            createSearchCondition('Account', 'RecordTypeId', false, 'someOtherRecordTypeId')
        };
        VeevaGASSearchClause clause = new VeevaGASSearchClause(conditions);
        System.assertEquals('Name IN (\'Some Name\', \'Some Other Name\') AND RecordTypeId NOT IN (\'someRecordTypeId\', \'someOtherRecordTypeId\')', clause.generateSOSLClause('Account'));
    }

    private static VeevaGASSearchCondition createSearchCondition(String objectName, String fieldName, boolean includes, String value) {
        filterForTest.Inclusion_vod__c = includes;
        upsert filterForTest;
        Implicit_Filter_Condition_vod__c filterCondition = new Implicit_Filter_Condition_vod__c(
            Object_Name_vod__c=objectName,
            Field_Name_vod__c=fieldName,
            Criteria_vod__c=value,
            Implicit_Filter_vod__c=filterForTest.Id
        );
        return new VeevaGASSearchCondition(filterCondition, filterForTest);
    }
}