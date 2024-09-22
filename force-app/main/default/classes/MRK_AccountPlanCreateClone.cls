public without sharing class MRK_AccountPlanCreateClone {

    private final Id apId; 
    public Account_Plan_vod__c oldAP {get;set;}
    public Account_Plan_vod__c newAP {get;set;}
    
    public MRK_AccountPlanCreateClone(ApexPages.StandardController controller) {
         this.apId = controller.getId();
    }
    
    public PageReference autoClone() {
        //Get custom settings
        MRK_Account_Plan_Clone_Settings__c settings = MRK_Account_Plan_Clone_Settings__c.getInstance('Main');
        String accountPlanFields = String.escapeSingleQuotes(settings.Account_Plan_Clone_Fields__c);
        String goalFields = String.escapeSingleQuotes(settings.Goals_Clone_Fields__c);
        String objectiveFields = String.escapeSingleQuotes(settings.Objective_Clone_Fields__c);
        String tacticFields = String.escapeSingleQuotes(settings.Tactic_Clone_Fields__c);
        String KeyStakeholdersFields = String.escapeSingleQuotes(settings.Key_Stakeholders_Clone_Fields__c);
        String TeamMembersFields = String.escapeSingleQuotes(settings.Team_Members_Clone_Fields__c);
        
        
        Id APRecordTypeId = Schema.SObjectType.Account_Plan_vod__c.getRecordTypeInfosByName().get('MRK_AP_Draft').getRecordTypeId();
        Id ATRecordTypeId = Schema.SObjectType.Account_Tactic_vod__c.getRecordTypeInfosByName().get('MRK_AP_TACTIC').getRecordTypeId();
        Id CORecordTypeId = Schema.SObjectType.Call_Objective_vod__c.getRecordTypeInfosByName().get('MRK Call Objective').getRecordTypeId();
        
        newAP = new Account_Plan_vod__c();
        //Get the details of the Account Plan we are cloning
        String apId = this.apId;
        oldAp = Database.query('SELECT ' + accountPlanFields + ' FROM Account_Plan_vod__c WHERE Id = :apId');
        String oldApId = oldAp.Id;
        String AccountId = oldAp.Account_vod__c;
        /*
        oldAP = [SELECT Id, Account_vod__c, Name, End_Date_MRK__c, Opportunities__c, 
                        Percent_Complete_vod__c, Start_Date_MRK__c, Strategies_MRK__c, 
                        Strengths__c, Tactics_Initiatives_MRK__c, Threats__c, Weaknesses__c
                 FROM Account_Plan_vod__c
                 WHERE Id = :this.apId];
        */
    
        //Set up new Account Plan with clone
        newAP = oldAP.clone(false,true);
        newAP.Name = 'This is a cloned plan. Please change the name.';
        newAP.MSD_CORE_Confirmed__c = true; //Rel 23R1.0.
        newAP.Status__c = 'Draft';
        newAP.RecordTypeId = APRecordTypeId;
        
        //Create new Account Plan
 
        try {
            insert newAP;
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
       
        }
        
        
        
         //Account_Team_Member_vod__c

        Map<Id,Account_Team_Member_vod__c> oldATMIdToNewATM = new Map<Id,Account_Team_Member_vod__c>();
        for (Account_Team_Member_vod__c t : Database.query('SELECT ' + TeamMembersFields + ' FROM Account_Team_Member_vod__c WHERE Account_Plan_vod__c = :oldAPId')) {
            Account_Team_Member_vod__c newATM = t.clone(false,true);

        system.debug('New ATM ' + newATM);
            newATM.Account_Plan_vod__c = newAP.Id;

            oldATMIdToNewATM.put(t.Id,newATM); 
        system.debug('New ATM 2 ' + newATM);                            
        system.debug('Old ATM 2 ' + oldATMIdToNewATM);  
        }

        system.debug(Logginglevel.INFO,'am - inserting tactics:' + oldATMIdToNewATM.values());

        try {
            insert oldATMIdToNewATM.values();
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
            system.debug(Logginglevel.INFO,'jk - error inserting tactics:' + ex.getMessage());
        }

        //Key_Stakeholder_vod__c

        Map<Id,Key_Stakeholder_vod__c> oldKSIdToNewKS = new Map<Id,Key_Stakeholder_vod__c>();
        for (Key_Stakeholder_vod__c t : Database.query('SELECT ' + KeyStakeholdersFields + ' FROM Key_Stakeholder_vod__c WHERE Account_Plan_vod__c = :oldAPId')) {
            Key_Stakeholder_vod__c newKS = t.clone(false,true);

        system.debug('New KS ' + newKS);
            newKS.Account_Plan_vod__c = newAP.Id;

            oldKSIdToNewKS.put(t.Id,newKS); 
        system.debug('New KS 2 ' + newKS);                            
        system.debug('Old KS 2 ' + oldKSIdToNewKS);  
        }

        system.debug(Logginglevel.INFO,'am - inserting KS:' + oldKSIdToNewKS.values());

        try {
            insert oldKSIdToNewKS.values();
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
            system.debug(Logginglevel.INFO,'AM - error inserting tactics:' + ex.getMessage());
        }
        
        
        //MSD_CORE_Strategic_Goals__c 
        //Get Goals for the Account Plan
        Map<Id,MSD_CORE_Strategic_Goals__c> oldGoalIdToNewGoal = new Map<Id,MSD_CORE_Strategic_Goals__c>();
        
        for (MSD_CORE_Strategic_Goals__c g : Database.query('SELECT ' + goalFields + ' FROM MSD_CORE_Strategic_Goals__c WHERE   MSD_CORE_Account_Plan__c = :oldApId')) {
            MSD_CORE_Strategic_Goals__c newGoal = g.clone(false,true);
            newGoal.MSD_CORE_Account_Plan__c = newAP.Id;
            oldGoalIdToNewGoal.put(g.Id,newGoal);
        }
       
        try {
            insert oldGoalIdToNewGoal.values();
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
         
        }
        
        
        /*  Commented as part of 8.0 release
        //Objective_MRK__c
        Map<Id,Objective_MRK__c> oldObjIdToNewObj = new Map<Id,Objective_MRK__c>();
        
        for (Objective_MRK__c o : Database.query('SELECT ' + objectiveFields + ' FROM Objective_MRK__c WHERE Account_Plan_MRK__c = :oldAPId')) {
            Objective_MRK__c newObj = o.clone(false,true);
            newObj.Account_Plan_MRK__c = newAP.Id;
            newObj.Goal_Opportunity_MRK__c = oldGoalIdToNewGoal.get(o.Goal_Opportunity_MRK__c).Id;
            oldObjIdToNewObj.put(o.Id,newObj);
                
        }
       
        for (Objective_MRK__c o : [SELECT RecordTypeId, Period_MRK__c, Opportunity_Category_MRK__c, Name, 
                                          Goal_Opportunity_MRK__c, Contact_MRK__c, Account_Plan_MRK__c, Id 
                                   FROM Objective_MRK__c
                                   WHERE Account_Plan_MRK__c = :oldAP.Id]) {
            Objective_MRK__c newObj = o.clone(false,true);
            newObj.Account_Plan_MRK__c = newAP.Id;
            newObj.Goal_Opportunity_MRK__c = oldGoalIdToNewGoal.get(o.Goal_Opportunity_MRK__c).Id;
            oldObjIdToNewObj.put(o.Id,newObj);
                
        }
        
        system.debug(Logginglevel.INFO,'jk - inserting objectives:' + oldObjIdToNewObj.values());
        try {
            insert oldObjIdToNewObj.values();
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
            system.debug(Logginglevel.INFO,'jk - error inserting objectives:' + ex.getMessage());
        }
        */
        
        //Account_Tactic_vod__c 
        Map<Id,Account_Tactic_vod__c> oldTacticIdToNewTactic = new Map<Id,Account_Tactic_vod__c>();
          
        //Looping through Account Tactics
        for (Account_Tactic_vod__c t : Database.query('SELECT ' + tacticFields + ' FROM Account_Tactic_vod__c WHERE Account_Plan_vod__c = :oldAPId')) {
            Account_Tactic_vod__c newTactic = t.clone(false,true); //Cloning the Account Tactics
            
            system.debug('Tracking AT clone ' + newTactic.Account_Plan_vod__c + ' space ' + newTactic.getCloneSourceId());
            
            newTactic.Account_Plan_vod__c = newAP.Id;  //Assigning the new Account Plan Id
            newTactic.RecordTypeId = ATRecordTypeId; //Assigning the record type
            oldTacticIdToNewTactic.put(t.Id,newTactic);  // Assigning List to Map
            
            String TacticsId = t.Id;
            
      
                                     
        }
        

        try {
            insert oldTacticIdToNewTactic.values();
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
            system.debug(Logginglevel.INFO,'jk - error inserting tactics:' + ex.getMessage());
        }
        
      SET<ID> AccountTacticskeys = oldTacticIdToNewTactic.KeySet();  //Code to bring old Tactics Id
        system.debug('Set of Account Ids' + AccountTacticskeys );
        
        
          Set<Id> NewATIds = new Set<Id>();  //Code to bring new Tactics Id to the set
        for(Account_Tactic_vod__c NAT : [Select Id from Account_Tactic_vod__c where Account_Plan_vod__c = :newAP.Id]){
            NewATIds.add(NAT.Id);
           }

        
        Map<Id, Account_Tactic_vod__c> NewATRecords = new Map<Id,Account_Tactic_vod__c>();
        
      
        for(Account_Tactic_vod__c AT:[Select MSD_CORE_Temp_Account_Tactics_Id__c, Id from Account_Tactic_vod__c where Account_Plan_vod__c = :newAP.Id ]){
        NewATRecords.put(AT.MSD_CORE_Temp_Account_Tactics_Id__c, AT);
        }
        
        system.debug('Map123456789 ' + NewATRecords);
        
        
        //Looping through Call Objectives tied to Account Tactics
      Map<Id,Call_Objective_vod__c> oldCOIdToNewCO = new Map<Id,Call_Objective_vod__c>();   
       // for (Call_Objective_vod__c co : Database.query('SELECT ' + objectiveFields + ' FROM Call_Objective_vod__c WHERE Account_vod__c = :AccountId and  Account_Tactic_vod__c in :AccountTacticskeys')) {
        for (Call_Objective_vod__c co : Database.query('SELECT ' + objectiveFields + ' FROM Call_Objective_vod__c WHERE Account_Tactic_vod__c in :AccountTacticskeys')) {
               Call_Objective_vod__c newCallObj = co.clone(false,true);
             //   newCallObj.Account_Tactic_vod__c = t.Id;

        system.debug('Call Objective ' + newCallObj);


         newCallObj.MSD_CORE_VAR_Clone__c = 'Y';
         newCallObj.RecordTypeId = CORecordTypeId;
         
         
          oldCOIdToNewCO.put(co.Id,newCallObj);
          }
      try {
            insert oldCOIdToNewCO.values();
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
            system.debug(Logginglevel.INFO,'jk - error inserting tactics:' + ex.getMessage());
        }
       
 



//Call_Objective_vod__c -- Code to update the new Tactics Id

      List<Call_Objective_vod__c> CallObj = new List<Call_Objective_vod__c>();
      
     // for(Call_Objective_vod__c cobj :[select Id,Account_Tactic_vod__c,MSD_CORE_VAR_Clone__c from  Call_Objective_vod__c WHERE Account_vod__c = :AccountId and  Account_Tactic_vod__c in :AccountTacticskeys  and createddate = today and MSD_CORE_VAR_Clone__c = 'Y']){
            for(Call_Objective_vod__c cobj :[select Id,Account_Tactic_vod__c,Account_Plan_vod__c,MSD_CORE_VAR_Clone__c from  Call_Objective_vod__c WHERE Account_Tactic_vod__c in :AccountTacticskeys  and createddate = today and MSD_CORE_VAR_Clone__c = 'Y']){

     system.debug('cobj ' + cobj.Account_Tactic_vod__c + ' Source Id ' + NewATRecords.get(cobj.Account_Tactic_vod__c).Id );
      cobj.Account_Tactic_vod__c = NewATRecords.get(cobj.Account_Tactic_vod__c).Id; 
      cobj.Account_Plan_vod__c = newAP.Id;  
      cobj.MSD_CORE_VAR_Clone__c = ''; 
     CallObj.add(cobj);
      }
      update CallObj;

       // Map<Id,Call_Objective_vod__c> oldCOIdToNewCO = new Map<Id,Call_Objective_vod__c>();
      //  for (Call_Objective_vod__c t : Database.query('SELECT ' + objectiveFields + ' FROM Call_Objective_vod__c WHERE Account_vod__c = :AccountId and  Account_Tactic_vod__c in :AccountTacticskeys')) {
        
    //    system.debug('Call Objective to be cloned' + t.Id  + '  New Tactics Id ' + NewATRecords.get(t.Account_Tactic_vod__c));
     //   }


        // set record type to Draft for all records that make up account plan
       // MRK_AccountPlanServices.getInstance().updateAccountPlanAndChildObjectRecordTypesForStatus(newAP.Id, 'Draft');
        
        
        if (!Apexpages.hasMessages(ApexPages.severity.ERROR)) {
            PageReference pageRef = new PageReference('/' + newAP.Id);
            pageRef.setRedirect(true);
            return pageRef;     
        } else {
            //has errors, show page
            return null;
        }       
    }
}