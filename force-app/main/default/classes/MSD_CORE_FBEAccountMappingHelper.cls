/** 
* Class Name	:	MSD_CORE_FBECustomerMappingHelper
* Purpose		:	This is a helper class to get mapping between FBEs and the associated accounts. 
* @version		:	1.0
* @author      :   Ambadas Joshi (FocalCXM)
*/
public class MSD_CORE_FBEAccountMappingHelper {
    
    public static List<Id> getTerritoriesOfUser(Id userId){
        List<Id> territoryIdList;
        try{
            territoryIdList = new List<Id>();
            for(UserTerritory2Association userterritoryRec : [SELECT Territory2Id FROM UserTerritory2Association 
                                                              WHERE IsActive = true AND UserId =: userId]){
                                                                  territoryIdList.add(userterritoryRec.Territory2Id);
                                                              }
        }
        catch(Exception ex){
            throw ex;
        }
        system.debug('getTerritoriesOfUser --> ' + territoryIdList);
        return territoryIdList;
    }
    
    public static List<Id> getObjectTerritoryAssociations(List<Id> territoryIdList, string sObjType){
        List<Id> objIdList;
        try{
            objIdList = new List<Id>();
            //30-July, 2024: If sObjectType is included in where clause, below query is not returning any results (sObjectType = 'Account')
            for(ObjectTerritory2Association obj : [SELECT ObjectId,Territory2Id FROM ObjectTerritory2Association 
                                                   WHERE IsDeleted = False AND 
                                                   Territory2Id in: territoryIdList]){
                                                       objIdList.add(obj.ObjectId);                            
                                                   }
        }
        catch(Exception ex){
            throw ex;
        }
        system.debug('getObjectTerritoryAssociations --> ' + objIdList);
        return objIdList;
    }
    
    public static List<Id> getFBEAccountMapping(Id userId){
        List<Id> accountIdList;
        try{
            List<Id> territoryIdList = MSD_CORE_FBEAccountMappingHelper.getTerritoriesOfUser(userId);
            accountIdList = MSD_CORE_FBEAccountMappingHelper.getObjectTerritoryAssociations(territoryIdList, 'Account');
        }
        catch(Exception ex){
            throw ex;
        }
        system.debug('getFBEAccountMapping --> ' + accountIdList);
        return accountIdList;
    }
}