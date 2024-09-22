trigger Primary_Zipcode_upd on MSD_CORE_Field_Request__c (after insert) {

   if (MRKFieldRequestUTLCls.BypasssPrimary_Zipcode_updTrigger) {
        return;
    }

Set<Id> AccountIds = new Set<Id>();
Set<Id> FRIds = new Set<Id>();
for(MSD_CORE_Field_Request__c FR : Trigger.new) {
AccountIds.add(FR.MSD_CORE_Account__c);
FRIds.add(FR.Id);
}

Map<Id,Address_vod__c> PrimaryAddress = new Map<Id,Address_vod__c>();
for(Address_vod__c PAddr :[Select Account_vod__c, Zip_vod__c from Address_vod__c where Account_vod__c in :AccountIds and Primary_vod__c = true]){
PrimaryAddress.put(PAddr.Account_vod__c, PAddr);
}

List <MSD_CORE_Field_Request__c> FRZipUpdateloop = [select Id,MSD_CORE_Account__c,MSD_CORE_Primary_Address_Zipcode__c from MSD_CORE_Field_Request__c where MSD_CORE_Account__c in :AccountIds and Id in :FRIds];
List <MSD_CORE_Field_Request__c> FRZipUpdate = new List <MSD_CORE_Field_Request__c>();

if (!PrimaryAddress.isEmpty()){ 
for(MSD_CORE_Field_Request__c FRU : FRZipUpdateloop ) {
     FRU.MSD_CORE_Primary_Address_Zipcode__c = PrimaryAddress.get(FRU.MSD_CORE_Account__c).Zip_vod__c;
     FRZipUpdate.add(FRU);
 }
 }
update FRZipUpdate;

}