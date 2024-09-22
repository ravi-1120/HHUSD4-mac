trigger MSD_CORE_CC_Notes_Trigger on MSD_CORE_Note__c (before insert, before update) {
   /* 
    if(Trigger.isUpdate){
        for(MSD_CORE_Note__c objNote : Trigger.New){
            if(objNote.MSD_CORE_Note__c != Trigger.OldMap.get(objNote.Id).MSD_CORE_Note__c){
                String oldNoteVersionStr = Trigger.OldMap.get(objNote.Id).MSD_CORE_Note_Versions__c;
                objNote.MSD_CORE_Note_Versions__c = objNote.MSD_CORE_Note__c + '\n'+ 'Updated by : '+ UserInfo.getName() + ' on ' + Date.today().format() + '\n' + '-------------' + '\n' + objNote.MSD_CORE_Note_Versions__c;
            }
        }
    }
    if(Trigger.isinsert){
        for(MSD_CORE_Note__c objNote : Trigger.New){
            objNote.MSD_CORE_Note_Versions__c = objNote.MSD_CORE_Note__c;
        }
    }
*/
}