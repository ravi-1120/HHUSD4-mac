public inherited sharing class VeevaMedicalInquiryFileProcessor extends VeevaFileObjectProcessorFactory.BaseProcessor{
    public VeevaMedicalInquiryFileProcessor() {
        super(new Set<String>{'Medical_Inquiry_vod__c'});
    }

     protected override void process(Set<Id> entityIds, Map<Id, SObject> entitiesToFileObj, boolean skipEditPermissions, String objectName, Set<Id> filterEntityIds, boolean isDelete) {
         if(filterEntityIds != null) {
            entityIds.retainAll(filterEntityIds);
         }
         super.process(entityIds, entitiesToFileObj, skipEditPermissions, objectName, filterEntityIds, isDelete);
     }
}