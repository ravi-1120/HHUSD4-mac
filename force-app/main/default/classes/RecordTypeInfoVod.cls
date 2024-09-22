public with sharing class RecordTypeInfoVod {

    public class RecordTypeInfoObject {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String developerName;
        @AuraEnabled
        public String name;

        public RecordTypeInfoObject(Schema.RecordTypeInfo recordTypeInfo) {
            this.id = recordTypeInfo.getRecordTypeId();
            this.developerName = recordTypeInfo.getDeveloperName();
            this.name = recordTypeInfo.getName();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<RecordTypeInfoObject> getSobjectRecordTypeInfo(String objectApiName) {
        List<RecordTypeInfoObject> recordTypeInfoObjects = new List<RecordTypeInfoObject>();
        try {
            List<Schema.RecordTypeInfo> recordTypeInfos = ((SObject)Type.forName('Schema', objectApiName).newInstance())
            .getSObjectType()
            .getDescribe()
            .getRecordTypeInfos();
            if(recordTypeInfos != null && !recordTypeInfos.isEmpty()) {
                for(RecordTypeInfo rtInfo : recordTypeInfos) {
                    recordTypeInfoObjects.add(new RecordTypeInfoObject(rtInfo));
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return recordTypeInfoObjects;
    }
}