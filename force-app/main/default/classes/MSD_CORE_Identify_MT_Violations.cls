global class MSD_CORE_Identify_MT_Violations implements Database.Batchable<sObject> {
global Date myDate = date.today();

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT MSD_CORE_Text_Owner_Manager__c,MSD_CORE_DCO_Email__c,Parent_Monitored_Text_vod__c  from Monitored_Text_vod__c where MSD_CORE_Numbers_of_Days__c > 10 and Is_Parent_vod__c = 0 and Recordtype.Name = \'Flagged Phrase\' and Status_vod__c <> \'Closed_vod\' order by MSD_CORE_DCO_Email__c'; 
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Monitored_Text_vod__c > scope) {
   
   //Delete DCO Monitored Text Violation Object
    List<MSD_CORE_DCO_Monitored_Text__c> ProcLst = [select id from MSD_CORE_DCO_Monitored_Text__c limit 50000] ;
          if(ProcLst.size() > 0)
          delete ProcLst ;
    
    //Set of Parent Monitored text Ids - Parent_Monitored_Text_vod__c  
    Set<Id> ParentIds = new Set<Id>();
    
    //Add Parent Ids to the set
         for(Monitored_Text_vod__c usr : Scope){
            ParentIds.add(usr.Parent_Monitored_Text_vod__c);
           }
            
    
    
    //List for insertion
         List<MSD_CORE_DCO_Monitored_Text__c> BKP = new List<MSD_CORE_DCO_Monitored_Text__c>();
            
            String EM = 'abcd@gmil.com';
                              
         //for(Monitored_Text_vod__c a : [SELECT MSD_CORE_Text_Owner_Manager__c,MSD_CORE_DCO_Email__c FROM Monitored_Text_vod__c where Id in :ParentIds]) 
         for(Monitored_Text_vod__c a : Scope) 
          {    
          
              
              if(a.MSD_CORE_DCO_Email__c != EM){
                  MSD_CORE_DCO_Monitored_Text__c bkpRecord= new MSD_CORE_DCO_Monitored_Text__c();
                 
                  bkpRecord.MSD_CORE_Text_Owner_Manager__c = a.MSD_CORE_Text_Owner_Manager__c;
                  bkpRecord.MSD_CORE_DCO_Email__c = a.MSD_CORE_DCO_Email__c;
                              
                  EM = a.MSD_CORE_DCO_Email__c;
                  BKP.add(bkpRecord);
              }
              
           }
           
           
           set<MSD_CORE_DCO_Monitored_Text__c > myset = new Set<MSD_CORE_DCO_Monitored_Text__c >();
            List<MSD_CORE_DCO_Monitored_Text__c> result = new List<MSD_CORE_DCO_Monitored_Text__c >();
            for (MSD_CORE_DCO_Monitored_Text__c s : BKP) {
              if (myset.add(s)) {
                result.add(s);
              }
            }
           
           
         insert BKP;
  
   
}
    
       
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('Monitored Text Violation');
mail.setSubject('Refresh DCO Monitored Text Violation object complete');
mail.setPlainTextBody('Refresh DCO Monitored Text Violation object complete');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}