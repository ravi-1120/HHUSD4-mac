@IsTest
public class VeevaGASFilterFieldConfigTest {
    @IsTest
    static void testDefaultImplicitFiltersAreRetrieved() {
        setupGASSettingField('GAS_Implicit_Filters_vod__c', null, null);

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        // Since we do not have any configuration for the GAS Settings we should expect the following default filter field
        VeevaGASFilterField expectedFilterField = new VeevaGASFilterField('Account', 'RecordTypeId');
        List<VeevaGASFilterField> implicitFilterFields = config.getImplicitFilterFields();

        System.assertEquals(1, implicitFilterFields.size());
        VeevaGASFilterField actualFilterField = implicitFilterFields.get(0);
        System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
        System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
    }

    @IsTest
    static void testReadsImplicitFiltersFromNullVeevaMessage() {
        setupGASSettingField('GAS_Implicit_Filters_vod__c', null, 'GAS_IMPLICIT_FILTERS');

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        VeevaGASFilterField expectedFilterField = new VeevaGASFilterField('Account', 'RecordTypeId');
        List<VeevaGASFilterField> implicitFilterFields = config.getImplicitFilterFields();

        System.assertEquals(1, implicitFilterFields.size());
        VeevaGASFilterField actualFilterField = implicitFilterFields.get(0);
        System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
        System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
    }

    @IsTest
    static void testReadsImplicitFiltersFromVeevaMessage() {
        setupGASSettingField(
            'GAS_Implicit_Filters_vod__c',
            'Account.Color_vod__c;Account.No_FLS_vod__c;Address_vod__c.Account_vod__c;Account.RecordTypeId;Account.Not_Valid_Field__c',
            'GAS_IMPLICIT_FILTERS'
        );

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Color_vod__c'),
            new VeevaGASFilterField('Address_vod__c', 'Account_vod__c'),
            new VeevaGASFilterField('Account', 'RecordTypeId')
        };
        List<VeevaGASFilterField> implicitFilterFields = config.getImplicitFilterFields();

        System.assertEquals(expectedFilterFields.size(), implicitFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = implicitFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    @IsTest
    static void testReadsImplicitFiltersDirectlyFromSettingField() {
        setupGASSettingField(
            'GAS_Implicit_Filters_vod__c',
            'Account.Name;Account.No_FLS_vod__c;Address_vod__c.Name;Account.RecordTypeId;Account.Abc__c;Address_vod__c.Account_vod__c',
            null
        );

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Name'),
            new VeevaGASFilterField('Address_vod__c', 'Name'),
            new VeevaGASFilterField('Account', 'RecordTypeId'),
            new VeevaGASFilterField('Address_vod__c', 'Account_vod__c')
        };
        List<VeevaGASFilterField> implicitFilterFields = config.getImplicitFilterFields();

        System.assertEquals(expectedFilterFields.size(), implicitFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = implicitFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    @IsTest
    static void testReadsImplicitFiltersIgnoringLeadingAndTrailingWhitespace() {
        setupGASSettingField(
            'GAS_Implicit_Filters_vod__c',
            '   Account.Name; Account.No_FLS_vod__c ;    Address_vod__c.Name;Account.RecordTypeId   ;Account.Abc__c;   ',
            null
        );

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Name'),
            new VeevaGASFilterField('Address_vod__c', 'Name'),
            new VeevaGASFilterField('Account', 'RecordTypeId')
        };
        List<VeevaGASFilterField> implicitFilterFields = config.getImplicitFilterFields();

        System.assertEquals(expectedFilterFields.size(), implicitFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = implicitFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    @IsTest
    static void testReadsImplicitFiltersFromVeevaMessageIgnoringLeadingAndTrailingWhitespace() {
        setupGASSettingField(
            'GAS_Implicit_Filters_vod__c',
            '   Account.Name; Account.No_FLS_vod__c ;    Address_vod__c.Name;Account.RecordTypeId   ;Account.Abc__c;   ',
            'GAS_IMPLICIT_FILTERS'
        );

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Name'),
            new VeevaGASFilterField('Address_vod__c', 'Name'),
            new VeevaGASFilterField('Account', 'RecordTypeId')
        };
        List<VeevaGASFilterField> implicitFilterFields = config.getImplicitFilterFields();

        System.assertEquals(expectedFilterFields.size(), implicitFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = implicitFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    @IsTest
    static void testDoesNotAddUnsupportedObjectTypes() {
        setupGASSettingField(
            'GAS_Implicit_Filters_vod__c',
            'Account.Name;Child_Account_vod__c.Name;Address_vod__c.Name;Contact.Name;Does_Not_Exist__c.Field__c',
            null
        );

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        // We currently only support Account and Address_vod__c object fields
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Name'),
            new VeevaGASFilterField('Address_vod__c', 'Name')
        };
        List<VeevaGASFilterField> implicitFilterFields = config.getImplicitFilterFields();

        System.assertEquals(expectedFilterFields.size(), implicitFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = implicitFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    @IsTest
    static void testImplicitFilterFieldsDoesNotAddUnsupportedFieldTypes() {
        setupGASSettingField(
            'GAS_Implicit_Filters_vod__c',
            'Account.Name;Child_Account_vod__c.Name;Address_vod__c.Name;Account.CreatedDate;Address_vod__c.CreatedDate;Account.Account_Call_Info_vod__c',
            null
        );

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        // We currently only support Account and Address_vod__c object fields
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Name'),
            new VeevaGASFilterField('Address_vod__c', 'Name')
        };
        List<VeevaGASFilterField> implicitFilterFields = config.getImplicitFilterFields();

        System.assertEquals(expectedFilterFields.size(), implicitFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = implicitFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    @IsTest
    static void testDoesNotAddDuplicateFilterFields() {
        setupGASSettingField(
            'GAS_Implicit_Filters_vod__c',
            'Account.Name;Address_vod__c.Name;Address_vod__c.Name;Account.Name;Account.RecordTypeId',
            null
        );

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        // We currently only support Account and Address_vod__c object fields
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Name'),
            new VeevaGASFilterField('Address_vod__c', 'Name'),
            new VeevaGASFilterField('Account', 'RecordTypeId')
        };
        List<VeevaGASFilterField> implicitFilterFields = config.getImplicitFilterFields();

        System.assertEquals(expectedFilterFields.size(), implicitFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = implicitFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    @IsTest
    static void testDefaultUserFiltersAreRetrieved() {
        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        // Since we do not have any configuration for the GAS Settings we should expect the following default filter fields
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Specialty_1_vod__c'),
            new VeevaGASFilterField('Account', 'Credentials_vod__c')
        };
        List<VeevaGASFilterField> userFilterFields = config.getUserFilterFields();

        System.assertEquals(expectedFilterFields.size(), userFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = userFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    @IsTest
    static void testReadsUserFiltersFromVeevaMessage() {
        setupGASSettingField(
            'GAS_User_Filters_vod__c',
            'Account.Color_vod__c;Address_vod__c.Account_vod__c;Account.Not_Valid_Field__c',
            'GAS_USER_FILTERS'
        );

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Color_vod__c'),
            new VeevaGASFilterField('Address_vod__c', 'Account_vod__c')
        };
        List<VeevaGASFilterField> userFilterFields = config.getUserFilterFields();

        System.assertEquals(expectedFilterFields.size(), userFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = userFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    @IsTest
    static void testReadsUserFiltersDirectlyFromSettingField() {
        setupGASSettingField(
            'GAS_User_Filters_vod__c',
            'Account.Name;Account.No_FLS_vod__c;Address_vod__c.Name;Account.RecordTypeId',
            null
        );

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Name'),
            new VeevaGASFilterField('Address_vod__c', 'Name'),
            new VeevaGASFilterField('Account', 'RecordTypeId')
        };
        List<VeevaGASFilterField> userFilterFields = config.getUserFilterFields();

        System.assertEquals(expectedFilterFields.size(), userFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = userFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    @IsTest
    static void testUserFilterFieldsDoesNotAddUnsupportedObjectOrFieldTypes() {
        setupGASSettingField(
            'GAS_User_Filters_vod__c',
            'Account.Name;Child_Account_vod__c.Name;Address_vod__c.Name;Account.CreatedDate;Address_vod__c.CreatedDate',
            null
        );

        VeevaGASFilterFieldConfig config = new VeevaGASFilterFieldConfig();
        // We currently only support Account and Address_vod__c object fields
        List<VeevaGASFilterField> expectedFilterFields = new List<VeevaGASFilterField>{
            new VeevaGASFilterField('Account', 'Name'),
            new VeevaGASFilterField('Address_vod__c', 'Name')
        };
        List<VeevaGASFilterField> userFilterFields = config.getUserFilterFields();

        System.assertEquals(expectedFilterFields.size(), userFilterFields.size());
        // Note that order must be preserved
        for (Integer i = 0; i < expectedFilterFields.size(); i++) {
            VeevaGASFilterField expectedFilterField = expectedFilterFields.get(i);
            VeevaGASFilterField actualFilterField = userFilterFields.get(i);
            System.assertEquals(expectedFilterField.objectApiName, actualFilterField.objectApiName);
            System.assertEquals(expectedFilterField.fieldApiName, actualFilterField.fieldApiName);
        }
    }

    private static void setupGASSettingField(String fieldApiName, String value, String gasVeevaMessageName) {
        Global_Account_Search_Settings_vod__c gasSettings = Global_Account_Search_Settings_vod__c.getInstance();
        if (String.isBlank(gasVeevaMessageName)) {
            gasSettings.put(fieldApiName, value);
        } else {
            gasSettings.put(fieldApiName, gasVeevaMessageName + ';;Global Account Search');
            Message_vod__c gasVeevaMessage = new Message_vod__c(
                Name = gasVeevaMessageName,
                Category_vod__c = 'Global Account Search',
                Type_vod__c = 'Custom_Setting_vod',
                Language_vod__c = 'en_US',
                Text_vod__c = value
            );
            insert gasVeevaMessage;
        }
        insert gasSettings;
    }
}