/******************************************************************************
 *
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems, Inc.
 *
 * Copyright (c) 2022 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/
@isTest
public with sharing class VeevaBaseObjectTest{
  
    @isTest
    public static void createObjectTest(){
        VeevaBaseObject veevaBaseObj = VeevaBaseObject.create('Account');
        System.assertEquals( veevaBaseObj.getDescribe(), VeevaBaseObject.create(Account.getSObjectType()).getDescribe());
        System.assertEquals(veevaBaseObj.getName(), 'Account');
    }
    
    private static VeevaBaseObject createObject(String name){
        VeevaBaseObject veevaBaseObj = VeevaBaseObject.create(name);
        System.assert(veevaBaseObj != null);
        return veevaBaseObj;
    }
    
    @isTest
    public static void describeTest(){
        VeevaBaseObject veevaBaseObj = createObject('Account');
        System.assert(veevaBaseObj.getDescribe()!= null);
    }
    
	@isTest
    public static void describeFieldsTest(){
 		VeevaBaseObject veevaBaseObj = createObject('Account');
        DescribeFieldResult fieldDescribe = veevaBaseObj.getFieldDescribe('Name');
        System.assert(fieldDescribe != null);
        System.assertEquals(fieldDescribe.getName(), 'Name');
    }

    @isTest
    public static void getAccessibleFieldsTest(){
 		VeevaBaseObject veevaBaseObj = createObject('Account');
        Set<String> fields = new Set<String>();
        fields.add('Name');
        fields.add('RecordTypeId');
        Set<String> accessibleFields = veevaBaseObj.getAccessibleFields(fields);
        System.assert(accessibleFields != null);
        System.assert(accessibleFields.contains('Name'));
        System.assert(accessibleFields.contains('RecordTypeId'));
    }

    @isTest
    public static void getAccessibleFieldsWithFormatTest(){
 		VeevaBaseObject veevaBaseObj = createObject('Account');
        Set<String> fields = new Set<String>();
        fields.add('Name');
        fields.add('RecordTypeId');
        fields.add('CreatedDate');
        fields.add('Parent.Name');
        fields.add('Ownership');
        fields.add('OwnerId');
        fields.add('NumberOfEmployees');
        veevaBaseObj.getField('NumberOfEmployees');
        Set<String> accessibleFields = veevaBaseObj.getAccessibleFields(fields, true);
        System.debug(accessibleFields);
        System.assert(accessibleFields != null);
        System.assert(accessibleFields.contains('Name'));
        System.assert(accessibleFields.contains('toLabel(RecordType.Name)'));
        System.assert(!accessibleFields.contains('Parent.Name'));
        System.assert(accessibleFields.contains('FORMAT(CreatedDate)'));
        System.assert(accessibleFields.contains('toLabel(Ownership) toLabel_Ownership'));
        System.assert(accessibleFields.contains('Owner.Name'));
        System.assert(accessibleFields.contains('FORMAT(NumberOfEmployees)'));
    }


    @isTest
    public static void getAccessibleFieldsWithNoFormatting(){
        VeevaBaseObject veevaBaseObj = createObject('Account');
       Set<String> fields = new Set<String>();
       fields.add('Name');
       fields.add('RecordTypeId');
       fields.add('CreatedDate');
       fields.add('Parent.Name');
       fields.add('Ownership');
       fields.add('NumberOfEmployees');
       Set<String> accessibleFields = veevaBaseObj.getAccessibleFields(fields, false);
       System.assert(accessibleFields != null);
       System.assert(accessibleFields.contains('Name'));
       System.assert(accessibleFields.contains('RecordTypeId'));
       System.assert(!accessibleFields.contains('Parent.Name'));
       System.assert(accessibleFields.contains('CreatedDate'));
       System.assert(accessibleFields.contains('Ownership'));
       System.assert(accessibleFields.contains('NumberOfEmployees'));
   }
    

   @isTest
   public static void getAccessibleFieldsWithParent(){
       VeevaBaseObject veevaBaseObj = createObject('Account');
       veevaBaseObj.addRelationship('Owner', createObject('User'));
       veevaBaseObj.addRelationship('Parent', veevaBaseObj);
       Set<String> fields = new Set<String>();
       fields.add('Name');
       fields.add('RecordTypeId');
       fields.add('Parent.Name');
       fields.add('Parent.Ownership');
       fields.add('Parent.Owner.Name');
       Set<String> accessibleFields = veevaBaseObj.getAccessibleFields(fields, true);
       System.assert(accessibleFields != null);
       System.assert(accessibleFields.contains('Name'));
       System.assert(accessibleFields.contains('toLabel(RecordType.Name)'));
       System.assert(accessibleFields.contains('Parent.Name'));
       System.assert(accessibleFields.contains('Parent.Owner.Name'));
       System.assert(accessibleFields.contains('toLabel(Parent.Ownership) toLabel_Parent_Ownership'));
    }

}