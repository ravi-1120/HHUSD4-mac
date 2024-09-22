Trigger MSD_CORE_CapException on EM_Speaker_Qualification_vod__c (after insert) { 

    //Map<Id,Decimal> SpkMap = new Map<Id,Decimal>();
    Map<ID,Schema.RecordTypeInfo> rt_Map = EM_Speaker_Qualification_vod__c.sObjectType.getDescribe().getRecordTypeInfosById();

    For (EM_Speaker_Qualification_vod__c SpkQual: Trigger.new) {  
    
       if (rt_map.get(SpkQual.RecordTypeId).getDeveloperName() =='MSD_CORE_CAP_EXCEPTION') {   
          
       // SpkMap.put(SpkQual.Speaker_vod__c,SpkQual.MSD_CORE_Cap_Exception_Amount__c);   
        EM_Speaker_vod__c Speaker = [SELECT Id, Annual_Cap_vod__c FROM EM_Speaker_vod__c WHERE id =: SpkQual.Speaker_vod__c];
        Speaker.Annual_Cap_vod__c =  Speaker.Annual_Cap_vod__c +   SpkQual.MSD_CORE_Cap_Exception_Amount__c;
        
        upsert Speaker;     
        } 
    } 
    
    
    /*List <EM_Speaker_vod__c> upSpkList = new List <EM_Speaker_vod__c> (); 
      
    for (EM_Speaker_vod__c Speaker: [SELECT Id, Annual_Cap_vod__c FROM EM_Speaker_vod__c WHERE id in: SpkMap.keySet()])
    {
       // Id SpkId = SpkMap.get(Speaker.Id);
             // Id SpkId = Speaker.Id;
        EM_Speaker_Qualification_vod__c Spk = trigger.newMap.get(Speaker.Id);
        Speaker.Annual_Cap_vod__c = Speaker.Annual_Cap_vod__c +Spk.MSD_CORE_Cap_Exception_Amount__c ;
             upSpkList.add(Speaker);
         
         upsert Speaker;
    }*/
}