public class MSD_CORE_AutoRefreshListViewCtrl {
    
    @AuraEnabled
    public static Map<String,List<refreshListWrp>> getLVDetails()
    {
        Set<String> ObjectAPINames = new Set<String>();
        List<String> listViewDevNames = new List<String>();
        Map<String,Integer> refreshIntMap = new Map<String,Integer>();
        Map<String,List<refreshListWrp>> returnMap = new Map<String,List<refreshListWrp>>();
        Map<String, MSD_CORE_List_View_Auto_Refresh__mdt> refreshMap = MSD_CORE_List_View_Auto_Refresh__mdt.getAll();
        for(String refreshName : refreshMap.keySet())
        {
            if(refreshMap.get(refreshName).MSD_CORE_Enable_Auto_Refresh__c == true)
            {
                ObjectAPINames.add(refreshMap.get(refreshName).MSD_CORE_SObject_API_Name__c);        
                if(!String.isBlank(refreshMap.get(refreshName).MSD_CORE_List_View_API_Names__c))
                {
                    String lvDevNames = refreshMap.get(refreshName).MSD_CORE_List_View_API_Names__c;
                    List<String> lvLists = lvDevNames.split(',');
                    listViewDevNames.addAll(lvLists);
                } 
                
                refreshIntMap.put(refreshMap.get(refreshName).MSD_CORE_SObject_API_Name__c.toUpperCase(),refreshMap.get(refreshName).MSD_CORE_Refresh_Interval__c.intValue());
            }  
        }
        if(ObjectAPINames.size() > 0)
        {
            for( ListView lv : [SELECT DeveloperName,Id,Name,SobjectType FROM ListView WHERE SobjectType IN :ObjectAPINames AND DeveloperName IN :listViewDevNames])
            {
                refreshListWrp wrp = new refreshListWrp();
                wrp.objectAPIName = lv.SobjectType.toUpperCase();
                wrp.refreshInterval = refreshIntMap.get(lv.SobjectType.toUpperCase());
                wrp.listViewIDs = lv.Id;
                if(returnMap.containsKey(lv.SobjectType.toUpperCase()))
                {
                    returnMap.get(lv.SobjectType.toUpperCase()).add(wrp);
                }
                else
                {
                    List<refreshListWrp> lstWrp = new  List<refreshListWrp>();
                    lstWrp.add(wrp);
                    returnMap.put(lv.SobjectType.toUpperCase(),lstWrp);
                }
            }
        }
        return returnMap;
    }
    public class refreshListWrp
    {
        @AuraEnabled public Integer refreshInterval;
        @AuraEnabled public String objectAPIName;
        @AuraEnabled public String listViewIDs;
    }
    
    
}