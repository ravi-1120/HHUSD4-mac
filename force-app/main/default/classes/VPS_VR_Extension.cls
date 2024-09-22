public class VPS_VR_Extension {
    
    public String obj{get;set;}
    public List<VPS_Object_Selector_Cont.Wrapper> retWrapper{get;set;}
    public Visibility_Rule_MRK__c rule{get;set;}
    public Map<String,String> rtMap = new Map<String,String>();
    public Set<String> current{get;set;}
    public Boolean refreshPage {get; set;}
    
    public VPS_VR_Extension(ApexPages.StandardController cont){
        rule = (Visibility_Rule_MRK__c)cont.getRecord();
        current = new Set<String>();
        for(Visibility_Rule_Record_MRK__c rec : [SELECT Object_Id__c FROM Visibility_Rule_Record_MRK__c WHERE Visibility_Rule_MRK__c = :rule.Id]){
            current.add(rec.Object_Id__c);
        }
        
        refreshPage=false;
    }
    
    public VPS_VR_Extension getCont(){
        return this;
    }
    
    public List<SelectOption> getObjects(){
        List<SelectOption> ret = new List<SelectOption>();
        for(RecordType rt : [SELECT DeveloperName,Name,Id FROM RecordType WHERE SobjectType = 'Visibility_Rule_Record_MRK__c']){
            ret.add(new SelectOption(rt.DeveloperName + '__c', rt.Name));
            rtMap.put(rt.DeveloperName + '__c',rt.Id);
        }
        return ret;
    }
    
    public PageReference create(){
        if (retWrapper == null){
           return null;
        }

        List<Visibility_Rule_Record_MRK__c> ins = new List<Visibility_Rule_Record_MRK__c>();
        for(VPS_Object_Selector_Cont.Wrapper w : retWrapper){
            if(w.include){
                Visibility_Rule_Record_MRK__c vrr = new Visibility_Rule_Record_MRK__c();
                //vrr.MSD_CORE_Access_Level__c = w.accessLevel;
                vrr.Object_Name__c = String.valueOf(w.obj.get('Name'));
                vrr.Object_Id__c = String.valueOf(w.obj.get('Id'));
                vrr.Visibility_Rule_MRK__c = rule.Id;
                vrr.recordTypeId = rtMap.get(obj);
                ins.add(vrr);
                current.add(vrr.Object_Id__c);
            }
        }
        
        try{
        insert ins;
        }catch(DMLException e){
           //Note: SF will handle displaying the Error on the VF Page. Just need to have the Try/Catch
           return null;
        }
        refreshPage=true;
        return null;
    }
}