public abstract class MSD_CORE_NewChildrecordTypeAutoSelect{
    private SObjectType parentSobType;
    private SObjectType childSobType;
    public MSD_CORE_NewChildrecordTypeAutoSelect(SObjectType parentSobType, SObjectType childSobType) {
        this.parentSobType = parentSobType;
        this.childSobType = childSobType;
        system.debug('Parent s object -->' +parentSobType );
        system.debug('Child s object -->'+childSobType );
    }
    
    public PageReference url() {
        PageReference p = new PageReference('/' + childSobType.getDescribe().getKeyPrefix() + '/e');
        
        Map<String, String> m = p.getParameters();
        m.putAll(ApexPages.currentPage().getParameters());
        
        String recordTypeName = getRecordTypeName(getParentSObjectId(m));
        
        if(recordTypeName.contains('Adverse Event') || recordTypeName.contains('Combo Case') || recordTypeName.contains('Product Complaint'))
        {
            p = new PageReference('/apex/CaseProductEditMVN');
        }
        
        p.getParameters().put('RecordType', getChildRecordTypeId(getParentSObjectId(m)));
        p.getParameters().put('CaseId', getParentSObjectId(m));
        p.getParameters().put('nooverride', '1');
        
        return p;
    }
    @TestVisible
    private String getRecordTypeName(Id parentId) {
        SObject parent = Database.query('select recordType.Name, recordType.DeveloperName from ' + String.valueOf(parentSobType)+ ' where Id = \''+parentId+'\'');
    
        String parentDeveloperName = (String) parent.getSobject('RecordType').get('Name');
        
        return parentDeveloperName;
    }
    @TestVisible
    private Id getChildRecordTypeId(Id parentId) {
        SObject parent = Database.query('select recordType.DeveloperName from ' + String.valueOf(parentSobType)+ ' where Id = \''+parentId+'\'');
        system.debug('select recordType.DeveloperName from ' + String.valueOf(parentSobType)+ ' where Id = \''+parentId+'\'');
        String parentDeveloperName = (String) parent.getSobject('RecordType').get('DeveloperName');
        return [select Id from RecordType where SObjectType = :String.valueOf(childSobType)
                and DeveloperName = :parentDeveloperName].Id;
    }
    @TestVisible
    private Id getParentSObjectId(Map<String, String> m) {
        for (String key : m.keySet()) {
            if (key.endsWith('_lkid')) {
            system.debug('Satish lookup: '+m.get(key));
                return m.get(key);
            }
        }
        return null;
    }
}