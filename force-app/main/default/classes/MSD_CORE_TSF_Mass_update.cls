public class MSD_CORE_TSF_Mass_update {
    
    /*Pubali: POC to enable mass update My target field for medical users using LWC */
@AuraEnabled(cacheable=true)    
public static List<TSF_vod__c> TSFQuery(string searchKey, String sortBy, String sortDirection)
{
/* get the current user's id */
Id user_Id= UserInfo.getUserId();
set<Id> accIds = new set<Id>();
Set <Id> userTerritoryId = new set <Id>();
Set <String> userTerritoryName = new Set <String>();

List<Tsf_vod__c> tsfList = new List<Tsf_vod__c>();
 
/* get the territories assigned to the user */   
for (UserTerritory2Association u2t : [SELECT Id,Territory2.Name,Territory2Id,UserId FROM UserTerritory2Association WHERE UserId=:user_Id])
{
userTerritoryId.add(u2t.Territory2Id);
userTerritoryName.add(u2t.Territory2.Name);
}
/* get all the accounts belonging to the user territory */
     
//for(ObjectTerritory2Association objterr: [SELECT Id,ObjectId,SobjectType,Territory2Id FROM ObjectTerritory2Association where Territory2Id=:userTerritoryId and Object.Recordtype.DeveloperName='MSD_CORE_Professional' limit 49999])
//for(ObjectTerritory2Association objterr: [SELECT Id,ObjectId,SobjectType,Territory2Id FROM ObjectTerritory2Association limit 49999])
for(ObjectTerritory2Association objterr: [SELECT Id,ObjectId,SobjectType,Territory2Id FROM ObjectTerritory2Association where Territory2Id=:userTerritoryId limit 49999])
{
accIds.add(objterr.ObjectId);
}
/* get the TSF records of those accounts whose territory isequal to user's territory */
//string query = 'select id,Account_vod__c,Account_vod__r.Name,MSD_CORE_My_Target__c,Call_Deck_Status_MRK__c,Last_Activity_Date_vod__c,Address_vod__r.Name,Territory_vod__c,Preferred_Account_vod__r.Name from TSF_vod__c where Account_vod__c = : accIds and Territory_vod__c = : userTerritoryName order by MSD_CORE_My_Target__c asc nulls first';
//string query = 'select id,Account_vod__c,Account_vod__r.Name,MSD_CORE_My_Target__c,Call_Deck_Status_MRK__c,Territory_vod__c from TSF_vod__c where Account_vod__c = : accIds and Territory_vod__c = : userTerritoryName order by MSD_CORE_My_Target__c';  
string query = 'select id,Account_vod__c,Account_vod__r.Name,MSD_CORE_My_Target__c,Territory_vod__c,Call_Deck_Status_MRK__c,Preferred_Account_vod__c,Preferred_Account_vod__r.Name,Last_Activity_Date_vod__c,Address_vod__c,Address_vod__r.Name,Address_vod__r.Concatenated_Address_MRK__c from TSF_vod__c where Account_vod__c = : accIds and Territory_vod__c = : userTerritoryName';
//string query = 'select id,Account_vod__c,Account_vod__r.Name,MSD_CORE_My_Target__c,Territory_vod__c from TSF_vod__c where Account_vod__c = : accIds and Territory_vod__c = : userTerritoryName';

 if ( searchKey != null && searchKey != '' ) {
           String key = '%' + searchKey + '%';
           query += ' and Account_vod__r.Name LIKE :key';
       }
 if ( sortBy != null && sortDirection != null ) {
           query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
       }    
tsfList = Database.query(query);  
system.debug('Ankur ' +tsfList);  
return tsfList;
}

}