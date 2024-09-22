@IsTest
public class VeevaGASSearchExpressionKeyTest {
    @IsTest
    static void testEquals(){
        Test.startTest();
        VeevaGASSearchExpressionKey nameEquals = new VeevaGASSearchExpressionKey('Account', 'Name', VeevaGASSearchConditionOperator.EQUALS);
        VeevaGASSearchExpressionKey nameEquals2 = new VeevaGASSearchExpressionKey('Account', 'Name', VeevaGASSearchConditionOperator.EQUALS);
        VeevaGASSearchExpressionKey addressNameEquals = new VeevaGASSearchExpressionKey('Address_vod__c', 'Name', VeevaGASSearchConditionOperator.EQUALS);
        VeevaGASSearchExpressionKey addressNameEqualsDifferentCasing = new VeevaGASSearchExpressionKey('ADDRESS_vod__c', 'NAME', VeevaGASSearchConditionOperator.EQUALS);
        VeevaGASSearchExpressionKey nameNotEquals = new VeevaGASSearchExpressionKey('Account', 'Name', VeevaGASSearchConditionOperator.NOT_EQUALS);
        Test.stopTest();

        System.assert(nameEquals.equals(nameEquals2));
        System.assert(addressNameEquals.equals(addressNameEqualsDifferentCasing));
        System.assert(!nameNotEquals.equals(nameEquals));
        System.assert(!nameNotEquals.equals(nameEquals2));
        System.assert(!nameEquals.equals(addressNameEquals));
        System.assert(!nameEquals2.equals(addressNameEquals));
        System.assert(!nameNotEquals.equals(addressNameEquals));
    }

    @IsTest
    static void testHashCode(){
        Test.startTest();
        VeevaGASSearchExpressionKey nameEquals = new VeevaGASSearchExpressionKey('Account', 'Name', VeevaGASSearchConditionOperator.EQUALS);
        VeevaGASSearchExpressionKey nameEquals2 = new VeevaGASSearchExpressionKey('Account', 'Name', VeevaGASSearchConditionOperator.EQUALS);
        VeevaGASSearchExpressionKey addressNameEquals = new VeevaGASSearchExpressionKey('Address_vod__c', 'Name', VeevaGASSearchConditionOperator.EQUALS);
        VeevaGASSearchExpressionKey addressNameEqualsDifferentCasing = new VeevaGASSearchExpressionKey('ADDRESS_vod__c', 'NAME', VeevaGASSearchConditionOperator.EQUALS);
        VeevaGASSearchExpressionKey nameNotEquals = new VeevaGASSearchExpressionKey('Account', 'Name', VeevaGASSearchConditionOperator.NOT_EQUALS);
        Test.stopTest();

        System.assertEquals(nameEquals.hashCode(), nameEquals2.hashCode());
        System.assertEquals(addressNameEquals.hashCode(), addressNameEqualsDifferentCasing.hashCode());
        System.assertNotEquals(nameNotEquals.hashCode(), nameEquals.hashCode());
        System.assertNotEquals(nameNotEquals.hashCode(), nameEquals2.hashCode());
        System.assertNotEquals(addressNameEquals.hashCode(), nameEquals.hashCode());
        System.assertNotEquals(addressNameEquals.hashCode(), nameEquals2.hashCode());
        System.assertNotEquals(addressNameEquals.hashCode(), nameNotEquals.hashCode());
    }
}