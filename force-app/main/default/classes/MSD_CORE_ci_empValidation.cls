public class MSD_CORE_ci_empValidation {
    @AuraEnabled(cacheable=true)
    public static Boolean EmployeeValidation(String winId, String lastName) {
        try {
            System.debug('Received winId: ' + winId);
            System.debug('Received lastName: ' + lastName);
            String externalId = String.escapeSingleQuotes(winId);
            String escapedLastName = String.escapeSingleQuotes(lastName);
            System.debug('Escaped winId: ' + externalId);
            System.debug('Escaped lastName: ' + escapedLastName);
            Integer count = [
                SELECT COUNT() 
                FROM Account 
                WHERE External_ID_vod__c = :externalId 
                AND RecordType.DeveloperName = 'Employee_MVN' 
                AND Preferred_Last_Name_MRK__c = :escapedLastName
            ];
            System.debug('Number of matching records: ' + count);
            return count > 0;
        } catch (Exception e) {
            System.debug('Error in EmployeeValidation: ' + e.getMessage());
            return false;
        }
    }
}