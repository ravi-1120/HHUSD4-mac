/*
* LockRelatedRecordsMVN
* Created By: Roman Lerman
* Created Date: 4/8/2013
* Description: This is class is used for locking Cases/Fulfillments, namely when either of these records are closed
*              the call center agents are prevented from adding Tasks/Events/Attachments to these records
*
*
* KRB Rel 10.0 5/19/2017 - For the 10.0 Release, we will be using a Cancelled Case to Archive Knowledge Articles. Logic was added
*                          to bypass validation that stops the assignment of Articles to a Cancelled Case. 
*/


global with sharing class LockRelatedRecordsMVN implements TriggersMVN.HandlerInterface {
    // The lookup from the child object to the parent
    private String parentIdFieldName;
    
    // Name of the object that will be locked
    private String objectName;
    
    // The boolean field on the parent object that will specify when it is locked
    private String lockedFieldName;
    
    // The first three characters in the id of the parent record
    private String parentKeyPrefix;
    
    // What gets displayed back to the user
    private String error;

    // Always prevent the mentioned action irrespective of the field
    private Boolean alwaysPrevent = false;
    
    public LockRelatedRecordsMVN(String parentIdFieldName, String objectName, String lockedFieldName, 
                                    String parentKeyPrefix, String error){
        this.parentIdFieldName = parentIdFieldName;
        this.objectName = objectName;
        this.lockedFieldName = lockedFieldName;
        this.parentKeyPrefix = parentKeyPrefix;
        this.error = error;
    }

    public LockRelatedRecordsMVN(String error){
        this.error = error;
        alwaysPrevent = true;
    }
    
    public void execute(List<SObject> records) {
        System.debug('Anonymizing: '+UtilitiesMVN.isAnonymizing);
        if(UtilitiesMVN.isAnonymizing){
            return;
        }
        
        if(!alwaysPrevent){
            List<SObject> relatedRecords = new List<SObject>();
            system.debug('KRB_1');
            Set<Id> recordIds = new Set<Id>();
            // If the child is related to the object of interest let's add it to a list and its parent id to a set
            for(SObject record:records){
                if(record.id != null && String.valueOf(record.id.getSobjectType()) == 'MSD_CORE_AE_Product__c'){
                    system.debug('KRB_2');
                    if(record.get('MSD_CORE_Product_Return_Date__c') == trigger.oldMap.get(record.id).get('MSD_CORE_Product_Return_Date__c')){
                        system.debug('KRB_3');
                        String parentId = returnParentId(record);
                        system.debug('KRB_4: Parent Id=' + parentId);
                        if(parentId != null && parentId.startsWith(parentKeyPrefix)){
                            relatedRecords.add(record);
                            recordIds.add(parentId);
                        }
                    }
                }
                else{
                    String parentId = returnParentId(record);
                    system.debug('KRB_5: Parent Id=' + parentId);
                    if(parentId != null && parentId.startsWith(parentKeyPrefix)){
                        relatedRecords.add(record);
                        recordIds.add(parentId);
                    }
                }
            }
            if(recordIds != null && recordIds.size() > 0){
                // Grab the parent field that determines that a parent is locked and check, if it is locked then display error
                Map<Id, SObject> sObjectMap = new Map<Id, SObject>(Database.query('select '+lockedFieldName+' from '+objectName+' where Id in :recordIds'));
                
                //KRB Rel 10.0 - grab the Parents MSD_CORE_Is_Archive_Article_Case__c value if it is a Case Object.
                Map<Id, SObject> caseMap = new Map<Id, SObject>();
                
                if(objectName == 'Case'){
                   system.debug('KRB_6');
                   caseMap = new Map<Id, SObject>(Database.query('select MSD_CORE_Is_Archive_Article_Case__c, '+lockedFieldName+' from Case where Id in :recordIds'));
                   system.debug('KRB_6a: LockedFieldName: ' + lockedFieldName);
                }
                
                
                for(SObject record:relatedRecords){
                    String parentId = returnParentId(record);
                    
                    //KRB Rel 10.0 out
                    /*
                     if(parentId != null && (boolean) sObjectMap.get(parentId).get(lockedFieldName)){
                     record.addError(error);
                    */
                    
                    //KRB Rel 10.0 in
                    if(objectName == 'Case'){
                        system.debug('KRB_7');
                        system.debug('parentId :::::' + parentId);
                        system.debug('parentId :::::' + caseMap.get(parentId));
                        
                        //Upated 24R1.0 to account for AE Portal Guest User Access
                        //if(parentId != null && !((boolean)caseMap.get(parentId).get('MSD_CORE_Is_Archive_Article_Case__c'))){
                        if(parentId != null && caseMap.containsKey(parentId) && !((boolean)caseMap.get(parentId).get('MSD_CORE_Is_Archive_Article_Case__c'))){
                            System.debug('KRB: This is NOT an Archive Article Case.');
                            system.debug('KRB_8');
                           if(parentId != null && (boolean) caseMap.get(parentId).get(lockedFieldName)){
                               system.debug('KRB_8a: Parent LockedFieldName Value: ' + caseMap.get(parentId).get(lockedFieldName));
                               system.debug('KRB_9');
                               system.debug('KRB_Error Added!');
                              record.addError(error);
                           }
                            
                        }else{
                            system.debug('KRB_10');
                            System.debug('KRB: This is an Archive Article Case or AE Portal Guest User Created Case. Lock field Ignored.');
                        }
                        
                        
                    }else{                   
                       if(parentId != null && (boolean) sObjectMap.get(parentId).get(lockedFieldName)){
                          system.debug('KRB_11');
                           system.debug('KRB_Error Added!');
                           record.addError(error);
                       }
                    }
                }
            }
        }else{
            for(SObject record:records){
                system.debug('KRB_Error Added!');
                record.addError(error);
            }
        }
    }
    
    public String returnParentId(SObject record){
        Object parentId = record.get(parentIdFieldName);
        return parentId != null ? (String) parentId : null;
    }
    
    public void handle() {
        execute(Trigger.isDelete ? (List<SObject>) trigger.old : (List<SObject>) trigger.new); 
    }
}