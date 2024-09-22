/*
* ChangeCaseOwnershipTriggerMVN
*    Created By:     Kai Chen
*    Created Date:   September 25, 2013
*    Description:    Change case ownership from queue to user when a case owned by a queue
*                    is modified by a user with the exception of cases received via email.
*                    KRB - 3/31/2017 - If Integration User is making the change, Bypass this Logic. 
*                                      Case ownership should not change. 
*/
public class ChangeCaseOwnershipTriggerMVN implements TriggersMVN.HandlerInterface{
    
    public void execute(Map<Id, Case> newCases, Map<Id, Case> oldCases){
        
        String usrProfileName;
        
        //DFG-157 KRB
        if (UserInfo.getName() != 'Automated Process'){
            //KRB 3/31/2017 - Bypass Logic if Integration User making updates. 
            usrProfileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;
        }
        
        //Bypass Logic is Integration User is making a change.  
        //Out for DFG-157 KRB
        //if (usrProfileName != 'MRK - Integration User'){ 
        //IN for DFG-157 KRB
        // 24R2.1 CEF2F-30678 : Exclude GSMA portal and DE TempExService Users from the logic
        if (usrProfileName != 'MRK - Integration User' && UserInfo.getName() != 'Automated Process' && UserInfo.getName() != 'GMSA Portal' && UserInfo.getName() != 'DE TempExService'){ 
            
            
            Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
            
            Set<Id> casesToCheck = new Set<Id>();
            
            for(Case newCase : newCases.values()){
                Case oldCase = oldCases.get(newCase.Id);
                
                if(newCase.OwnerId == oldCase.OwnerId){
                    casesToCheck.add(newCase.Id);
                }
            }
            
            if(!casesToCheck.isEmpty()){
                List<Case> cases = [select Id, Owner.Type from Case 
                                    where Id in :casesToCheck 
                                    and (RecordType.DeveloperName != :settings.Interaction_Record_Type_MVN__c
                                         or Origin != :settings.MSD_CORE_Case_Origin_Email__c)];
                
                List<Id> casesToUpdate = new List<Id>();
                for(Case caseToCheck : cases){
                    if(caseToCheck.Owner.Type == 'Queue'){
                        casesToUpdate.add(caseToCheck.Id);
                    }
                }
                if(casesToUpdate.size() > 0) {
                    updateOwnership(casesToUpdate,UserInfo.getUserId());
                }
            }
            
        }else{
            system.debug('Skipping Case Owner Update Logic - Integration User making the Update. ');
        }
        
    }
    
    public void handle() {
        if(!System.isBatch()) {
            execute((Map<Id, Case>) trigger.newMap, (Map<Id, Case>) trigger.oldMap);
        }
    }
    
    @future
    public static void updateOwnership(List<Id> caseIDs, Id ownerId) {
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.EmailHeader.triggerUserEmail = false;
        
        List<Case> casesToUpdate = [select OwnerId from Case where Id in :caseIDs];
        
        for(Case c : casesToUpdate) {
            c.OwnerId = ownerId;
        }
        
        Database.update(casesToUpdate, dmo);
    }
}