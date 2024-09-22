@isTest
public class MSD_CORE_ae_WrapperTest {

    @isTest
    static void testWrapper() {
        Account testAccount = new Account(
            Preferred_First_Name_MRK__c = 'John',
            Phone = '1234567890',
            PersonEmail = 'john.doe@example.com',
            MSD_CORE_Primary_Address_Line_1__c = '1234 Main Street',
            MSD_CORE_Primary_Address_Line_2__c = 'Suite 101',
            MSD_CORE_Primary_Zip__c = '98765',
            MSD_CORE_Primary_City__c = 'Anytown',
            PersonMailingCountryCode = 'US',
            MSD_CORE_Primary_State__c = 'CA'
        );

        Test.startTest();
        MSD_CORE_ae_Wrapper wrapper = new MSD_CORE_ae_Wrapper(testAccount);
        Test.stopTest();
        System.assertEquals('J**n', wrapper.MaskedFirstName, 'First name masking failed.');
        System.assertEquals('12******90', wrapper.MaskedPhone, 'Phone masking failed.');
        System.assertEquals('j******e@*******.com', wrapper.MaskedEmail, 'Email masking failed.');
        System.assertEquals('1**************t', wrapper.MaskedAddressLine1, 'Address line 1 masking failed.');
        System.assertEquals('S*******1', wrapper.MaskedAddressLine2, 'Address line 2 masking failed.');
        System.assertEquals('9***5', wrapper.MaskedZipCode, 'Zip code masking failed.');
        System.assertEquals('A*****n', wrapper.MaskedCity, 'City masking failed.');
        System.assertEquals('John', wrapper.FirstName, 'First name unmasked check failed.');
        System.assertEquals('1234567890', wrapper.Phone, 'Phone unmasked check failed.');
        System.assertEquals('john.doe@example.com', wrapper.Email, 'Email unmasked check failed.');
        System.assertEquals('1234 Main Street', wrapper.AddressLine1, 'Address Line 1 unmasked check failed.');
        System.assertEquals('Suite 101', wrapper.AddressLine2, 'Address Line 2 unmasked check failed.');
        System.assertEquals('98765', wrapper.ZipCode, 'Zip code unmasked check failed.');
        System.assertEquals('Anytown', wrapper.City, 'City unmasked check failed.');
    }
}