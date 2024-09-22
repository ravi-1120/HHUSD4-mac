public inherited sharing class VeevaSNCustomDisplayOverrides {
    @AuraEnabled public List<String> personAccountDisplayFields { get; set; }
    @AuraEnabled public List<String> businessAccountDisplayFields { get; set; }
    @AuraEnabled public Map<String, String> accountIdentifiers  { get; set; }
    @AuraEnabled public List<String> customAffiliationPicklistFields { get; set; }

    public VeevaSNCustomDisplayOverrides() {}

    public VeevaSNCustomDisplayOverrides(List<String> personAccountDisplayFields, List<String> businessAccountDisplayFields, Map<String, String> accountIdentifiers, List<String> customAffiliationPicklistFields) {
        this.personAccountDisplayFields = personAccountDisplayFields;
        this.businessAccountDisplayFields = businessAccountDisplayFields;
        this.accountIdentifiers = accountIdentifiers;
        this.customAffiliationPicklistFields = customAffiliationPicklistFields;
    }
}