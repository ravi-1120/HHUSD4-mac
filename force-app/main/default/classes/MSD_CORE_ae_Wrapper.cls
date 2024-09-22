public class MSD_CORE_ae_Wrapper {
    @AuraEnabled
    public Id Id;
    @AuraEnabled
    public String FirstName;
    @AuraEnabled
    public String MaskedFirstName;
    @AuraEnabled
    public String Phone;
    @AuraEnabled
    public String MaskedPhone;
    @AuraEnabled
    public String Email;
    @AuraEnabled
    public String MaskedEmail;
    @AuraEnabled
    public String AddressLine1;
    @AuraEnabled
    public String MaskedAddressLine1;
    @AuraEnabled
    public String AddressLine2;
    @AuraEnabled
    public String MaskedAddressLine2;
    @AuraEnabled
    public String ZipCode;
    @AuraEnabled
    public String MaskedZipCode;
    @AuraEnabled
    public String City;
    @AuraEnabled
    public String MaskedCity;
    @AuraEnabled
    public String CountryCode;
    @AuraEnabled
    public String State;

    public MSD_CORE_ae_Wrapper(Account acc) {
        this.Id = acc.Id;
        this.FirstName = acc.Preferred_First_Name_MRK__c;
        this.MaskedFirstName = maskFirstName(acc.Preferred_First_Name_MRK__c);
        this.Phone = acc.Phone;
        this.MaskedPhone = maskPhone(acc.Phone);
        this.Email = acc.PersonEmail;
        this.MaskedEmail = maskEmail(acc.PersonEmail);
        this.AddressLine1 = acc.MSD_CORE_Primary_Address_Line_1__c;
        this.MaskedAddressLine1 = maskAddressLine1(acc.MSD_CORE_Primary_Address_Line_1__c);
        this.AddressLine2 = acc.MSD_CORE_Primary_Address_Line_2__c;
        this.MaskedAddressLine2 = maskAddressLine2(acc.MSD_CORE_Primary_Address_Line_2__c);
        this.ZipCode = acc.MSD_CORE_Primary_Zip__c;
        this.MaskedZipCode = maskzipcode(acc.MSD_CORE_Primary_Zip__c);
        this.City = acc.MSD_CORE_Primary_City__c;
        this.MaskedCity = maskCity(acc.MSD_CORE_Primary_City__c);
        this.CountryCode = acc.PersonMailingCountryCode;
        this.State = acc.MSD_CORE_Primary_State__c;
    }
    
    private static String maskFirstName(String firstName) {
        if (firstName == null || firstName.length() < 2) return firstName;
        String masked = firstName.substring(0, 1);
        for(Integer i = 1; i < firstName.length() - 1; i++) {
            masked += '*';
        }
        return masked + firstName.substring(firstName.length() - 1);
    }
    private static String maskAddressLine1(String addressline1) {
        if (addressline1 == null || addressline1.length() < 2) return addressline1;
        String masked = addressline1.substring(0, 1);
        for(Integer i = 1; i < addressline1.length() - 1; i++) {
            masked += '*';
        }
        return masked + addressline1.substring(addressline1.length() - 1);
    }
    private static String maskAddressLine2(String addressline2) {
        if (addressline2 == null || addressline2.length() < 2) return addressline2;
        String masked = addressline2.substring(0, 1);
        for(Integer i = 1; i < addressline2.length() - 1; i++) {
            masked += '*';
        }
        return masked + addressline2.substring(addressline2.length() - 1);
    }
    private static String maskzipcode(String zipcode) {
        if (zipcode == null || zipcode.length() < 2) return zipcode;
        String masked = zipcode.substring(0, 1);
        for(Integer i = 1; i < zipcode.length() - 1; i++) {
            masked += '*';
        }
        return masked + zipcode.substring(zipcode.length() - 1);
    }
    private static String maskCity(String city) {
        if (city == null || city.length() < 2) return city;
        String masked = city.substring(0, 1);
        for(Integer i = 1; i < city.length() - 1; i++) {
            masked += '*';
        }
        return masked + city.substring(city.length() - 1);
    }

    private static String maskPhone(String phone) {
        if (phone == null || phone.length() < 9) return phone;
        String masked = phone.substring(0, 2);
        for(Integer i = 2; i < phone.length() - 2; i++) {
                            masked += '*';
        }
        return masked + phone.substring(phone.length() - 2);
    }

     private static String maskEmail(String email) {
         if (email == null || !email.contains('@')) {
             return email;
         }
         String[] parts = email.split('@', 2);
         String localPart = parts[0];
         String domainPart = parts[1];
         String maskedLocal = localPart.substring(0, 1);
         for (Integer i = 1; i < localPart.length() - 1; i++) {
              maskedLocal += '*';
         }
         if (localPart.length() > 1) {
             maskedLocal += localPart.substring(localPart.length() - 1);
         }
         Integer indexOfLastDot = domainPart.lastIndexOf('.');
         String domain = domainPart.substring(0, indexOfLastDot).replaceAll('.', '*').replaceAll('.', '*') + domainPart.substring(indexOfLastDot); // This line was corrected for logic
         return maskedLocal + '@' + domain;
      }
}