public class MSD_CORE_ci_Wrapper {
    @AuraEnabled
    public Id Id;
    @AuraEnabled
    public String FirstName;
    @AuraEnabled
    public String MaskedFirstName;

    public MSD_CORE_ci_Wrapper(Account acc) {
        this.Id = acc.Id;
        this.FirstName = acc.Preferred_First_Name_MRK__c;
        this.MaskedFirstName = maskFirstName(acc.Preferred_First_Name_MRK__c);
    }
    
    private static String maskFirstName(String firstName) {
        if (firstName == null || firstName.length() < 2) return firstName;
        String masked = firstName.substring(0, 1);
        for(Integer i = 1; i < firstName.length() - 1; i++) {
            masked += '*';
        }
        return masked + firstName.substring(firstName.length() - 1);
    }

}