/*
* Trigger: MSD_CORE_PW_W9_Info_Upd
*When a new record is inserted into the Expense Line object by the PW integration,
*gather the point-in-time W9 information from the PW_W9_Information object for the Payee Speaker
*in the expense header for the correct expense type and stamp the information onto the expense line and expense header
*stamping to the expense header is temporary for a few months after trigger creation and will eventually be commented out.
* Author: Ankur Mehrota 9/27/2020 20r3.0
*/

trigger MSD_CORE_PW_W9_Info_Upd on Expense_Line_vod__c (after insert) {

 Id profileId=userinfo.getProfileId();
    String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
    
        if (profileName != 'MSD_CORE_Events_PW_Integration'){
        return;
    }
    
    Set<Id> SpeakerIds = new Set<Id>();
    Set<Id> HeaderIds = new Set<Id>();
    Set<Id> LineIds = new Set<Id>();
    Set<String> ExpType = new Set<String>();

 for(Expense_Line_vod__c EL : Trigger.new) {
      //  SpeakerIds.add(EL.Expense_Header_vod__r.Payee_Speaker_vod__r.Speaker_vod__c);
        LineIds.add(EL.Id);
        HeaderIds.add(EL.Expense_Header_vod__c);
        ExpType.add('%' + EL.Expense_Type_vod__c + '%');
 }
 
 for(Expense_Header_vod__c EHdr : [Select Id,Name,Payee_Speaker_vod__r.Speaker_vod__c from Expense_Header_vod__c Where Id in :HeaderIds]){
 SpeakerIds.add(EHdr.Payee_Speaker_vod__r.Speaker_vod__c);
 }
 
 /*system.debug('Ankur SpeakerIds ' + SpeakerIds);
  system.debug('Ankur HeaderIds ' + HeaderIds);
   system.debug('Ankur LineIds ' + LineIds);
    system.debug('Ankur ExpType ' + ExpType);
 */
 
 Map<Id,PW_W9_Information__c> PW_W9_Info = new Map<Id,PW_W9_Information__c>();
 for(PW_W9_Information__c inf:[SELECT Name,PW_Veeva_Speaker__c,PW_W9_Address1__c,PW_W9_Address2__c,PW_W9_City__c,PW_W9_Payee_Name__c,PW_W9_Payment_Category_ID__c,PW_W9_Payment_Category__c,PW_W9_StateName__c,PW_W9_TIN__c,PW_W9_Type__c,PW_W9_W9TPID__c,PW_W9_ZipCode__c FROM PW_W9_Information__c WHERE PW_Veeva_Speaker__c in :SpeakerIds and PW_W9_Payment_Category_ID__c like :ExpType]){
 PW_W9_Info.put(inf.PW_Veeva_Speaker__c,inf);
 }
 
 //system.debug('Ankur PW_W9_Info Map' + PW_W9_Info);
 
 List <Expense_Header_vod__c> ExpHdrUpd = new List <Expense_Header_vod__c>();
 List <Expense_Line_vod__c> ExpLineUpd = new List <Expense_Line_vod__c>();
 
    if (!PW_W9_Info.isEmpty()) 
    {
        for(Expense_Line_vod__c ELine : [Select Id,Expense_Header_vod__r.Payee_Speaker_vod__r.Speaker_vod__c,MSD_CORE_W9_Payee_Name__c,MSD_CORE_W9_TIN__c,MSD_CORE_W9_Address1__c,MSD_CORE_W9_Address2__c,MSD_CORE_W9_City__c,MSD_CORE_W9_State__c,MSD_CORE_W9_Zip__c,Expense_Type_Name_vod__c  from Expense_Line_vod__c where Id in :LineIds])
            {
                if (PW_W9_Info.ContainsKey(ELine.Expense_Header_vod__r.Payee_Speaker_vod__r.Speaker_vod__c) == true)
                {
                    ELine.MSD_CORE_W9_Payee_Name__c = PW_W9_Info.get(ELine.Expense_Header_vod__r.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_Payee_Name__c;
                    ELine.MSD_CORE_W9_TIN__c = PW_W9_Info.get(ELine.Expense_Header_vod__r.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_TIN__c;
                    ELine.MSD_CORE_W9_Address1__c = PW_W9_Info.get(ELine.Expense_Header_vod__r.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_Address1__c; 
                    ELine.MSD_CORE_W9_Address2__c = PW_W9_Info.get(ELine.Expense_Header_vod__r.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_Address2__c;
                    ELine.MSD_CORE_W9_City__c = PW_W9_Info.get(ELine.Expense_Header_vod__r.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_City__c;
                    ELine.MSD_CORE_W9_State__c = PW_W9_Info.get(ELine.Expense_Header_vod__r.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_StateName__c;
                    ELine.MSD_CORE_W9_Zip__c = PW_W9_Info.get(ELine.Expense_Header_vod__r.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_ZipCode__c;
                    ExpLineUpd.add(ELine);
                    
                    if(ELine.Expense_Type_Name_vod__c == 'Speaker Honoraria')
                    {
                            for(Expense_Header_vod__c EH : [Select Id,Name,MSD_CORE_Payee_Name__c,MSD_CORE_Payee_Address__c,Payee_Speaker_vod__r.Speaker_vod__c from Expense_Header_vod__c Where Id in :HeaderIds])
                            {
                                if (PW_W9_Info.ContainsKey(EH.Payee_Speaker_vod__r.Speaker_vod__c) == true)
                                    {
                                        EH.MSD_CORE_Payee_Name__c = PW_W9_Info.get(EH.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_Payee_Name__c;
                                        EH.MSD_CORE_Payee_Address__c = PW_W9_Info.get(EH.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_Address1__c + ' ' + PW_W9_Info.get(EH.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_City__c + ' ' + PW_W9_Info.get(EH.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_StateName__c + ' ' + PW_W9_Info.get(EH.Payee_Speaker_vod__r.Speaker_vod__c).PW_W9_ZipCode__c; 
                                        ExpHdrUpd.add(EH);
                                     }
                             }
                    }
                }
            }  
   //         system.debug('Ankur ExpLineUpd' + ExpLineUpd);
   //         system.debug('Ankur ExpHdrUpd' + ExpHdrUpd);
            update(ExpLineUpd);
          //  update(ExpHdrUpd);
            
            //Code to remove any duplicates in the Expense Header
            Set<Expense_Header_vod__c> Ehdrset = new Set<Expense_Header_vod__c>();
            List<Expense_Header_vod__c> EHdrUPD = new List<Expense_Header_vod__c>();
            Ehdrset.addAll(ExpHdrUpd);
            EHdrUPD.addAll(Ehdrset);
            
   //         system.debug('Ankur EHdrUPD' + EHdrUPD);
            update(EHdrUPD);
            
    }
     
}