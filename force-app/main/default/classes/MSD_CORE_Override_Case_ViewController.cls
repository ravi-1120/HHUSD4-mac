public class MSD_CORE_Override_Case_ViewController {
	@AuraEnabled
    public static String getParentCaseId(String caseId){
        String parentCaseId = [SELECT ParentId FROM Case WHERE Id = :caseId].ParentId;
        System.debug('parentCaseId -->'+parentCaseId);
        return parentCaseId;
    }
}