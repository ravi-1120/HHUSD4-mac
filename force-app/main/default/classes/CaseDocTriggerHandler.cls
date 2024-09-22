public class CaseDocTriggerHandler {

    public static void updateCaseCategory(List<Case_Document_MVN__c> casedocuments){
        Map<String,Case_Document_MVN__c> mapCaseArticles = New Map<String,Case_Document_MVN__c>();
        List<Case> cases = New List<Case>();
        for(Case_Document_MVN__c casedoc : casedocuments){
            if(!mapCaseArticles.containsKey(casedoc.Case_MVN__c) && String.isNotBlank(casedoc.Knowledge_Article_Version_ID_MVN__c)){
                mapCaseArticles.put(casedoc.Case_MVN__c,casedoc);
            }  
        }
        for(Case c :[SELECT Id,Type,Category_MVN__c,(SELECT Id,Document_Subtype_MVN__c,MSD_CORE_Category__c FROM Case_Article_Data__r) FROM Case WHERE Id IN : mapCaseArticles.keySet()]){
            if(c.Case_Article_Data__r.size() ==1){
                c.Type              = mapCaseArticles.get(c.Id).Document_Subtype_MVN__c;
                c.Category_MVN__c   = mapCaseArticles.get(c.Id).MSD_CORE_Category__c;
                cases.add(c);
            }
            else 
            {
                c.Type              = null;
                c.Category_MVN__c   = null;
                cases.add(c);
            }
        }
        if(!cases.isEmpty()){
            Update cases;
        }
    }
    
    public static void deleteCaseCategory(List<Case_Document_MVN__c> casedocuments){
        Map<String,Case_Document_MVN__c> mapCaseArticles = New Map<String,Case_Document_MVN__c>();
        List<Case> cases = New List<Case>();
        for(Case_Document_MVN__c casedoc : casedocuments){
            if(!mapCaseArticles.containsKey(casedoc.Case_MVN__c) && String.isNotBlank(casedoc.Knowledge_Article_Version_ID_MVN__c)){
                mapCaseArticles.put(casedoc.Case_MVN__c,casedoc);
            }  
        }
        for(Case c :[SELECT Id,Type,Category_MVN__c,(SELECT Id,Document_Subtype_MVN__c,MSD_CORE_Category__c FROM Case_Article_Data__r ORDER BY CreatedDate ASC) FROM Case WHERE Id IN : mapCaseArticles.keySet()]){
            system.debug('====c.Case_Article_Data__r.size()====='+c.Case_Article_Data__r.size());
            if(c.Case_Article_Data__r.size() >0){
                if(c.Case_Article_Data__r[0].Id == mapCaseArticles.get(c.Id).Id){
                    c.Type ='';
                    c.Category_MVN__c = '';
                    cases.add(c);
                }
            }
        }
        if(!cases.isEmpty()){
            //Update cases;
        }
    }
    
    public static void updateAlertLegalOnCase(List<Case_Document_MVN__c> casedocuments)
    {
        Map<String, String> mapCaseArticles = new Map<String, String>();
        
        for(Case_Document_MVN__c casedoc : casedocuments){
            if(casedoc.Knowledge_Article_Version_ID_MVN__c != null){
                mapCaseArticles.put(casedoc.Knowledge_Article_Version_ID_MVN__c, casedoc.Case_MVN__c);
            }  
        }
        
        List<Case> caseUpdateList = new List<Case>();
        for(Knowledge__kav k : [select id, MSD_CORE_Subtype__c from Knowledge__kav where id in : mapCaseArticles.keyset()])
        {
            if(k.MSD_CORE_Subtype__c == 'Legal / Privacy')
                caseUpdateList.add(new Case(id = mapCaseArticles.get(k.Id),
                                            MSD_CORE_Legal_Alert__c = true));
        }
        
        if(caseUpdateList.size() > 0)
            update caseUpdateList;
    }
}