/*
 *  KRB 2/4/2020 TM2.0 
 *  If a Territory is deleted, inactivate all the Rules associated with that Territory.
 */

trigger MSD_CORE_ProcessRuleUpdates on Territory2 (before delete) {
    
    List<String> m_territoryNames = new List<String>();
    
    for(sObject obj : Trigger.old){
       Territory2 Terr = (Territory2)obj;
        System.debug('MRK_TerritoryHandler: adding Territory Name: ' + Terr.name);
        m_territoryNames.add(Terr.name);
    }
    
    if(!m_territoryNames.isEmpty()){
       MRK_RuleGateway.setTerritoryRuleRecordsInactiveByTerritoryNameList(m_territoryNames);
    }
    
}