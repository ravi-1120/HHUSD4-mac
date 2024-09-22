/*
* MSD_CORE_TouchFRWhenFRCaseNotesChanges
* Created By:    Kevin Brace
* Created Date:  6/5/2018
* Description:   This trigger handler 'touches' the associated Field Request (FR) Record when the MSD_CORE_Resolution_Notes__c
                 on the Case changes. Reason for this is that the MSD_CORE_Resolution_Notes__c field on the Field Request Object
                 is a Formula Field. Changes appear on line for the FR, but not on iRep. iRep does not know to sync the 
                 new value in the Formula Field unless the Last Modified Date on the FR is updated. 
*/  

public without sharing class MSD_CORE_TouchFRWhenFRCaseNotesChanges implements TriggersMVN.HandlerInterface{
    public void execute(map<Id, Case> newCaseMap, map<Id, Case> oldCaseMap) {
        
       String requestRecordTypeName = 'Request';
       List<Id> fieldRequestIdList = new List<Id>();
       List<MSD_CORE_Field_Request__c> fieldRequestsToTouchList = new List<MSD_CORE_Field_Request__c>();
        
       for (Case newCase : newCaseMap.values()) {  
           
          system.debug('KRB: Old Case Resolution Notes:' + oldCaseMap.get(newCase.Id).MSD_CORE_Resolution_Notes__c);
          system.debug('KRB: New Case Resolution Notes:' + newCase.MSD_CORE_Resolution_Notes__c);
           
           
          if (
              (newCase.Origin == 'Field Request') && 
              (!String.isBlank(newCase.MSD_CORE_Resolution_Notes__c)) &&
              (newCase.MSD_CORE_Resolution_Notes__c != oldCaseMap.get(newCase.Id).MSD_CORE_Resolution_Notes__c) &&
              (!String.isBlank(newCase.MSD_CORE_Field_Request__c)) &&
              (Schema.SObjectType.Case.getRecordTypeInfosById().get(newCase.recordtypeid).getname() == requestRecordTypeName )
             ){          
                 fieldRequestIdList.add(newCase.MSD_CORE_Field_Request__c);
                 System.debug('KRB:MSD_CORE_TouchFRWhenFRCaseNotesChanges: FR to Touch: ' + newCase.MSD_CORE_Field_Request__c);
             }
       }
       
        if(!fieldRequestIdList.isEmpty()){
            fieldRequestsToTouchList = new List<MSD_CORE_Field_Request__c>([
                SELECT Id, MSD_CORE_Type__c
                FROM   MSD_CORE_Field_Request__c
                WHERE  Id in: fieldRequestIdList
            ]);
            
            
            if(!fieldRequestsToTouchList.isEmpty()){
                for (MSD_CORE_Field_Request__c fr : fieldRequestsToTouchList ){
                   System.debug('KRB:MSD_CORE_TouchFRWhenFRCaseNotesChanges: RF Id Updating : ' + fr.Id);
                   String frType = fr.MSD_CORE_Type__c; 
                   fr.MSD_CORE_Type__c = frType;
                }
            
                update fieldRequestsToTouchList;
                System.debug('KRB:MSD_CORE_TouchFRWhenFRCaseNotesChanges: RF Updated....touched');
            
            }
            
        }
        
    }

    public void handle() {
        execute((Map<Id, Case>) trigger.newMap, (Map<Id, Case>) trigger.oldMap);
    }
         
}