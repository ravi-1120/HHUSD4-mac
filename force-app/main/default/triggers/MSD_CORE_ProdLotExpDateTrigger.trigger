trigger MSD_CORE_ProdLotExpDateTrigger on MSD_CORE_TE_Product_Lot_Details__c (after insert, after update, after delete) {
    Set<Id> tempExProdSet = new Set<Id>();
    String str = '';
    
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (MSD_CORE_TE_Product_Lot_Details__c lot : trigger.new){
            tempExProdSet.add(lot.MSD_CORE_Temp_Excursion_Product__c);
        }
    }
    else if(Trigger.isDelete) {
        for (MSD_CORE_TE_Product_Lot_Details__c lot : trigger.old){
            tempExProdSet.add(lot.MSD_CORE_Temp_Excursion_Product__c);
        }
    }
    System.Debug('Satish Set: '+tempExProdSet);
    
    for (MSD_CORE_TE_Product_Lot_Details__c tep: [Select Name, MSD_CORE_Expiration_Date__c from MSD_CORE_TE_Product_Lot_Details__c where MSD_CORE_Temp_Excursion_Product__c IN: tempExProdSet])
    {
        Date dt = tep.MSD_CORE_Expiration_Date__c;
        if(dt != null){
            str += 'Lot#: '+tep.Name+ ' & ' + 'Expiration Date: '+(tep.MSD_CORE_Expiration_Date__c).format() + '\n';
        }
        else{
            str += 'Lot#: '+tep.Name+ ' & ' + 'Expiration Date: '+ '\n';
        }
    }
    System.Debug('Satish String: '+str);
    
    List <MSD_CORE_Temperature_Excursion_Product__c> tempExProdListUpd = new List<MSD_CORE_Temperature_Excursion_Product__c>();
    for(MSD_CORE_Temperature_Excursion_Product__c fin: [Select id, MSD_CORE_Lot_and_Expiration_Date__c from MSD_CORE_Temperature_Excursion_Product__c WHERE Id IN :tempExProdSet])
    {
        fin.MSD_CORE_Lot_and_Expiration_Date__c = str;
        tempExProdListUpd.add(fin);
    }
    update(tempExProdListUpd);
    
    public static String formatDate (Datetime d){
        return d.month() + '-' + d.day() + '-' + d.year();
    }
}