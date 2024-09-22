@IsTest
public class VeevaGASSearchConditionTest {

    @IsTest
    static void testConvertsImplicitFilterConditionToSearchCondition() {
        Implicit_Filter_vod__c filter = new Implicit_Filter_vod__c(Location_vod__c='Org_Default_vod', Inclusion_vod__c=true);
        insert filter;
        Implicit_Filter_Condition_vod__c filterCondition = new Implicit_Filter_Condition_vod__c(
            Object_Name_vod__c='Account',
            Field_Name_vod__c='Name',
            Criteria_vod__c='Something',
            Implicit_Filter_vod__c=filter.Id
        );
        VeevaGASSearchCondition condition = new VeevaGASSearchCondition(filterCondition, filter);
        System.assertEquals('Account', condition.getObjectName());
        System.assertEquals('Name', condition.getFieldName());
        System.assertEquals(VeevaGASSearchConditionOperator.EQUALS, condition.getOperator());
        System.assertEquals('\'Something\'', condition.getValue());
    }

    @IsTest
    static void testConvertsUserFilterToSearchCondition() {
        VeevaGASSearchCondition condition = new VeevaGASSearchCondition('Account', 'Specialty_1_vod__c', 'Cardiology');
        System.assertEquals('Account', condition.getObjectName());
        System.assertEquals('Specialty_1_vod__c', condition.getFieldName());
        System.assertEquals(VeevaGASSearchConditionOperator.EQUALS, condition.getOperator());
        System.assertEquals('\'Cardiology\'', condition.getValue());
    }

    @IsTest
    static void testConvertsMultiSelectPicklistValueToString() {
        Implicit_Filter_vod__c filter = new Implicit_Filter_vod__c(Location_vod__c='Org_Default_vod', Inclusion_vod__c=true);
        insert filter;
        Implicit_Filter_Condition_vod__c filterCondition = new Implicit_Filter_Condition_vod__c(
            Object_Name_vod__c='Account',
            Field_Name_vod__c='Order_Type_vod__c',
            Criteria_vod__c='Transfer_vod',
            Implicit_Filter_vod__c=filter.Id
        );

        Implicit_Filter_vod__c exclusiveFilter = new Implicit_Filter_vod__c(Location_vod__c='Org_Default_vod', Inclusion_vod__c=false);
        insert exclusiveFilter;
        Implicit_Filter_Condition_vod__c exclusiveFilterCondition = new Implicit_Filter_Condition_vod__c(
            Object_Name_vod__c='Account',
            Field_Name_vod__c='Order_Type_vod__c',
            Criteria_vod__c='Transfer_vod',
            Implicit_Filter_vod__c=exclusiveFilter.Id
        );

        VeevaGASSearchCondition conditionFromFilter = new VeevaGASSearchCondition(filterCondition, filter);
        VeevaGASSearchCondition exclusiveConditionFromFilter = new VeevaGASSearchCondition(exclusiveFilterCondition, exclusiveFilter);
        VeevaGASSearchCondition directCondition = new VeevaGASSearchCondition('Account', 'Order_Type_vod__c', 'Transfer_vod');

        System.assertEquals('Account', conditionFromFilter.getObjectName());
        System.assertEquals('Order_Type_vod__c', conditionFromFilter.getFieldName());
        System.assertEquals(VeevaGASSearchConditionOperator.INCLUDES, conditionFromFilter.getOperator());
        System.assertEquals('\'Transfer_vod\'', conditionFromFilter.getValue());

        System.assertEquals('Account', exclusiveConditionFromFilter.getObjectName());
        System.assertEquals('Order_Type_vod__c', exclusiveConditionFromFilter.getFieldName());
        System.assertEquals(VeevaGASSearchConditionOperator.EXCLUDES, exclusiveConditionFromFilter.getOperator());
        System.assertEquals('\'Transfer_vod\'', exclusiveConditionFromFilter.getValue());

        System.assertEquals('Account', directCondition.getObjectName());
        System.assertEquals('Order_Type_vod__c', directCondition.getFieldName());
        System.assertEquals(VeevaGASSearchConditionOperator.INCLUDES, directCondition.getOperator());
        System.assertEquals('\'Transfer_vod\'', directCondition.getValue());
    }

    @IsTest
    static void testConvertsImplicitFilterConditionExclusiveToSearchCondition() {
        Implicit_Filter_vod__c filter = new Implicit_Filter_vod__c(Location_vod__c='Org_Default_vod', Inclusion_vod__c=false);
        insert filter;
        Implicit_Filter_Condition_vod__c filterCondition = new Implicit_Filter_Condition_vod__c(
            Object_Name_vod__c='Account',
            Field_Name_vod__c='RecordTypeId',
            Criteria_vod__c='Something',
            Implicit_Filter_vod__c=filter.Id
        );
        VeevaGASSearchCondition condition = new VeevaGASSearchCondition(filterCondition, filter);
        System.assertEquals('Account', condition.getObjectName());
        System.assertEquals('RecordTypeId', condition.getFieldName());
        System.assertEquals(VeevaGASSearchConditionOperator.NOT_EQUALS, condition.getOperator());
        System.assertEquals('\'Something\'', condition.getValue());
    }

    @IsTest
    static void testConvertsImplicitFilterConditionValueToAppropriateTypeBoolean() {
        Implicit_Filter_vod__c filter = new Implicit_Filter_vod__c(Location_vod__c='Org_Default_vod', Inclusion_vod__c=false);
        insert filter;
        Implicit_Filter_Condition_vod__c filterCondition = new Implicit_Filter_Condition_vod__c(
            Object_Name_vod__c='Account',
            Field_Name_vod__c='IsPersonAccount',
            Criteria_vod__c='true',
            Implicit_Filter_vod__c=filter.Id
        );
        VeevaGASSearchCondition condition = new VeevaGASSearchCondition(filterCondition, filter);
        System.assertEquals('Account', condition.getObjectName());
        System.assertEquals('IsPersonAccount', condition.getFieldName());
        System.assertEquals(VeevaGASSearchConditionOperator.NOT_EQUALS, condition.getOperator());
        System.assertEquals('true', condition.getValue());
    }

    @IsTest
    static void testConvertsImplicitFilterConditionValueToAppropriateTypeNumber() {
        Implicit_Filter_vod__c filter = new Implicit_Filter_vod__c(Location_vod__c='Org_Default_vod', Inclusion_vod__c=false);
        insert filter;
        Implicit_Filter_Condition_vod__c filterCondition = new Implicit_Filter_Condition_vod__c(
            Object_Name_vod__c='Account',
            Field_Name_vod__c='Total_Sent_Message_vod__c',
            Criteria_vod__c='10',
            Implicit_Filter_vod__c=filter.Id
        );
        VeevaGASSearchCondition condition = new VeevaGASSearchCondition(filterCondition, filter);
        System.assertEquals('Account', condition.getObjectName());
        System.assertEquals('Total_Sent_Message_vod__c', condition.getFieldName());
        System.assertEquals(VeevaGASSearchConditionOperator.NOT_EQUALS, condition.getOperator());
        System.assertEquals('10', condition.getValue());
    }

    @IsTest
    static void testRetrievesAppropriateObjectType() {
        Implicit_Filter_vod__c filter = new Implicit_Filter_vod__c(Location_vod__c='Org_Default_vod', Inclusion_vod__c=false);
        insert filter;
        Implicit_Filter_Condition_vod__c filterCondition = new Implicit_Filter_Condition_vod__c(
            Object_Name_vod__c='Account',
            Field_Name_vod__c='Name',
            Criteria_vod__c='Something',
            Implicit_Filter_vod__c=filter.Id
        );
        VeevaGASSearchCondition condition = new VeevaGASSearchCondition(filterCondition, filter);
        System.assertEquals(Account.getSObjectType(), condition.getObject());
    }

    @IsTest
    static void testRetrievesAppropriateFieldDescribe() {
        Implicit_Filter_vod__c filter = new Implicit_Filter_vod__c(Location_vod__c='Org_Default_vod', Inclusion_vod__c=false);
        insert filter;
        Implicit_Filter_Condition_vod__c filterCondition = new Implicit_Filter_Condition_vod__c(
            Object_Name_vod__c='Account',
            Field_Name_vod__c='Name',
            Criteria_vod__c='Something',
            Implicit_Filter_vod__c=filter.Id
        );
        VeevaGASSearchCondition condition = new VeevaGASSearchCondition(filterCondition, filter);
        System.assertEquals(Account.Name.getDescribe(), condition.getField());
    }

    @IsTest
    static void testGetExpressionKeysAreEquivalentForSameCondition() {
        VeevaGASSearchCondition accountSpecialtyCardiology = new VeevaGASSearchCondition('Account', 'Specialty_1_vod__c', 'Cardiology');
        System.assertEquals(accountSpecialtyCardiology.getExpressionKey(), accountSpecialtyCardiology.getExpressionKey());
    }

    @IsTest
    static void testGetExpressionKeysAreEquivalentForTwoIdenticalObjectFieldAndOperator() {
        VeevaGASSearchCondition accountSpecialtyCardiology = new VeevaGASSearchCondition('Account', 'Specialty_1_vod__c', 'Cardiology');
        VeevaGASSearchCondition accountSpecialtyOther = new VeevaGASSearchCondition('Account', 'Specialty_1_vod__c', 'Other');
        System.assertEquals(accountSpecialtyCardiology.getExpressionKey(), accountSpecialtyOther.getExpressionKey());
        System.assertEquals(accountSpecialtyCardiology.getObjectName(), accountSpecialtyOther.getObjectName());
        System.assertEquals(accountSpecialtyCardiology.getFieldName(), accountSpecialtyOther.getFieldName());
        System.assertEquals(accountSpecialtyCardiology.getOperator(), accountSpecialtyOther.getOperator());
    }

    @IsTest
    static void testGetExpressionKeysAreNotEquivalentForNonTwoIdenticalObjectFieldAndOperator() {
        VeevaGASSearchCondition accountSpecialtyCardiology = new VeevaGASSearchCondition('Account', 'Specialty_1_vod__c', 'Cardiology');
        VeevaGASSearchCondition accountOrderTypeAll = new VeevaGASSearchCondition('Account', 'Order_Type_vod__c', 'All');
        System.assertNotEquals(accountSpecialtyCardiology.getExpressionKey(), accountOrderTypeAll.getExpressionKey());
        System.assertEquals(accountSpecialtyCardiology.getObjectName(), accountOrderTypeAll.getObjectName());
        System.assertNotEquals(accountSpecialtyCardiology.getFieldName(), accountOrderTypeAll.getFieldName());
        System.assertNotEquals(accountSpecialtyCardiology.getOperator(), accountOrderTypeAll.getOperator());
    }
}